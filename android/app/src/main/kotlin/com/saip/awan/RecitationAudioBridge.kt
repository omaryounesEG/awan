package com.saip.awan

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel

/**
 * The microphone, at the only rate Whisper understands: 16 kHz, one channel,
 * 16-bit little-endian PCM.
 *
 * Written natively instead of pulling a recorder plugin because the project
 * already owns its sensor and model channels, and because the contract is
 * narrower than any plugin's: a stream of bytes while the screen is open, and a
 * hard release the moment it closes. No file is ever written — a recitation is
 * not a recording.
 *
 * The read loop runs on its own thread; the sink is fed on the main thread so
 * Flutter's message handling stays on the platform thread.
 */
class RecitationAudioBridge(private val context: Context) : EventChannel.StreamHandler {

    private var record: AudioRecord? = null
    private var thread: Thread? = null
    @Volatile private var running = false

    private val main = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        val sink = events ?: return

        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED) {
            sink.error("mic_denied", "RECORD_AUDIO not granted", null)
            return
        }

        val sampleRate = 16000
        val channel = AudioFormat.CHANNEL_IN_MONO
        val encoding = AudioFormat.ENCODING_PCM_16BIT
        val minBuffer = AudioRecord.getMinBufferSize(sampleRate, channel, encoding)
        // 4x the minimum: two full chunks of headroom, so a missed wake-up
        // during a garbage-collection pause does not drop audio.
        val bufferSize = if (minBuffer > 0) minBuffer * 4 else 8192

        val recorder = try {
            AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                sampleRate, channel, encoding, bufferSize
            )
        } catch (error: Exception) {
            sink.error("mic_failed", error.message, null)
            return
        }

        if (recorder.state != AudioRecord.STATE_INITIALIZED) {
            recorder.release()
            sink.error("mic_failed", "AudioRecord not initialised", null)
            return
        }

        record = recorder
        running = true
        recorder.startRecording()

        thread = Thread({
            val chunk = ByteArray(3200) // 100 ms at 16 kHz mono / 16-bit
            while (running) {
                val read = recorder.read(chunk, 0, chunk.size)
                if (read > 0) {
                    val payload = if (read == chunk.size) chunk.copyOf() else chunk.copyOf(read)
                    main.post { if (running) sink.success(payload) }
                } else if (read < 0) {
                    main.post {
                        if (running) sink.error("mic_read_failed", "AudioRecord.read=$read", null)
                    }
                    break
                }
            }
        }, "awan-recitation-audio").apply { start() }

        android.util.Log.i("AwanRecitation", "microphone opened")
    }

    override fun onCancel(arguments: Any?) {
        stop()
    }

    private fun stop() {
        running = false
        try {
            thread?.join(300)
        } catch (_: InterruptedException) {
        }
        thread = null
        record?.let {
            try {
                if (it.recordingState == AudioRecord.RECORDSTATE_RECORDING) it.stop()
            } catch (_: Exception) {
            }
            it.release()
        }
        record = null
        android.util.Log.i("AwanRecitation", "microphone released")
    }
}
