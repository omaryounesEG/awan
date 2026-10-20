package com.saip.awan

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodChannel

/**
 * One MediaPlayer for the adhkar recitations, with a position tick.
 *
 * Why not a plugin: the app already ships a native layer, and the requirement is
 * narrow — play a URL or a downloaded file, pause, resume, seek, and tell the UI
 * when it ends so the reader can be moved to the next dhikr. A full audio plugin
 * would be another dependency to audit for a feature that is one file.
 *
 * The instance lives in `MainActivity`; it is stopped when the screen closes,
 * because an adhkar recitation that keeps playing after the reader leaves is a
 * bug, not a feature (the car screen keeps it alive explicitly).
 */
class AdhkarAudio(private val channel: MethodChannel) {

    private var player: MediaPlayer? = null
    private val handler = Handler(Looper.getMainLooper())
    private var ticker: Runnable? = null

    private fun emit(map: Map<String, Any?>) {
        try {
            channel.invokeMethod("event", map)
        } catch (error: Exception) {
            Log.w(TAG, "event dropped: $error")
        }
    }

    fun play(source: String, title: String?) {
        stop()
        try {
            val created = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                setDataSource(source)
                setOnPreparedListener {
                    it.start()
                    emit(mapOf("state" to "playing", "duration" to it.duration, "title" to title))
                    startTicker()
                }
                setOnCompletionListener {
                    emit(mapOf("state" to "completed", "duration" to it.duration))
                    stopTicker()
                }
                setOnErrorListener { _, what, extra ->
                    Log.w(TAG, "media error $what/$extra")
                    emit(mapOf("state" to "error", "reason" to "media $what/$extra"))
                    true
                }
                prepareAsync()
            }
            player = created
            emit(mapOf("state" to "loading", "title" to title))
        } catch (error: Exception) {
            Log.w(TAG, "play failed: $error")
            emit(mapOf("state" to "error", "reason" to "${error.message}"))
        }
    }

    fun pause() {
        player?.let {
            if (it.isPlaying) {
                it.pause()
                emit(mapOf("state" to "paused", "position" to it.currentPosition))
            }
        }
        stopTicker()
    }

    fun resume() {
        player?.let {
            it.start()
            emit(mapOf("state" to "playing"))
            startTicker()
        }
    }

    fun seek(positionMs: Int) {
        player?.seekTo(positionMs)
        emit(mapOf("state" to "seek", "position" to positionMs))
    }

    fun stop() {
        stopTicker()
        player?.let {
            try {
                it.stop()
            } catch (_: IllegalStateException) {
                // Already stopped: nothing to undo.
            }
            it.release()
        }
        player = null
        emit(mapOf("state" to "idle"))
    }

    private fun startTicker() {
        stopTicker()
        val runnable = object : Runnable {
            override fun run() {
                player?.let {
                    if (it.isPlaying) {
                        emit(
                            mapOf(
                                "state" to "playing",
                                "position" to it.currentPosition,
                                "duration" to it.duration
                            )
                        )
                    }
                }
                handler.postDelayed(this, 500)
            }
        }
        ticker = runnable
        handler.postDelayed(runnable, 500)
    }

    private fun stopTicker() {
        ticker?.let { handler.removeCallbacks(it) }
        ticker = null
    }

    companion object {
        private const val TAG = "AwanAdhkarAudio"
    }
}
