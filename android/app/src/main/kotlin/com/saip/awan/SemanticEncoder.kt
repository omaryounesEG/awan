package com.saip.awan

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.FloatBuffer
import java.nio.LongBuffer
import java.util.concurrent.Executors

/**
 * The query encoder for the offline semantic search.
 *
 * The model is a 118M-parameter multilingual sentence-transformer quantised to
 * int8; loading it costs a second or two, so the session is built once and kept,
 * and inference runs on a single background thread so two keystrokes can never
 * run the graph concurrently.
 *
 * Model resolution order:
 *   1. `filesDir/semantic/model_int8.onnx` — downloaded once by the app;
 *   2. `assets/semantic/model/model_int8.onnx` — copied out on first use,
 *      because ONNX Runtime wants a real file, not an asset stream.
 */
class SemanticEncoder(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "awan/semantic")
    private val executor = Executors.newSingleThreadExecutor()
    private var session: OrtSession? = null
    private var env: OrtEnvironment? = null
    private var inputName = "input_ids"
    private var maskName = "attention_mask"
    private var outputDim = 0

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(statusMap())
            "prepare" -> executor.execute {
                try {
                    val file = resolveModel()
                    if (file == null) {
                        mainThread(result) { it.success(mapOf("ready" to false, "error" to "no-model")) }
                        return@execute
                    }
                    ensureSession(file)
                    mainThread(result) { it.success(statusMap()) }
                } catch (error: Throwable) {
                    mainThread(result) {
                        it.success(
                            mapOf(
                                "ready" to false,
                                "error" to (error.message ?: error.javaClass.simpleName),
                            ),
                        )
                    }
                }
            }
            "encode" -> {
                val ids = call.argument<List<Int>>("ids")
                val mask = call.argument<List<Int>>("mask")
                if (ids == null || mask == null) {
                    result.error("bad-args", "ids and mask are required", null)
                    return
                }
                executor.execute {
                    try {
                        val vector = encode(ids, mask)
                        mainThread(result) { it.success(vector.toList()) }
                    } catch (error: Throwable) {
                        mainThread(result) {
                            it.error("encode-failed", error.message ?: "unknown", null)
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun statusMap(): Map<String, Any> {
        val file = modelFile()
        return mapOf(
            "ready" to (session != null),
            "bytes" to (if (file.exists()) file.length() else 0L),
            "dim" to outputDim,
        )
    }

    private fun modelFile(): File = File(File(context.filesDir, "semantic"), "model_int8.onnx")

    private fun resolveModel(): File? {
        val target = modelFile()
        if (target.exists() && target.length() > 1_000_000) return target

        // Not downloaded yet: copy the bundled copy if this build carries one.
        return try {
            context.assets.open("semantic/model/model_int8.onnx").use { input ->
                target.parentFile?.mkdirs()
                val temporary = File(target.parentFile, "model_int8.onnx.part")
                temporary.outputStream().use { output -> input.copyTo(output, 1 shl 16) }
                if (!temporary.renameTo(target)) {
                    temporary.delete()
                    return null
                }
                target
            }
        } catch (_: Throwable) {
            null
        }
    }

    @Synchronized
    private fun ensureSession(file: File) {
        if (session != null) return
        val environment = OrtEnvironment.getEnvironment()
        val options = OrtSession.SessionOptions().apply {
            setIntraOpNumThreads(1)
            setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
        }
        val created = environment.createSession(file.absolutePath, options)
        val names = created.inputNames.toList()
        if (names.isNotEmpty()) inputName = names[0]
        if (names.size > 1) maskName = names[1]
        env = environment
        session = created
        outputDim = 0
    }

    @Synchronized
    private fun encode(ids: List<Int>, mask: List<Int>): FloatArray {
        val active = session ?: throw IllegalStateException("model not prepared")
        val environment = env ?: throw IllegalStateException("environment missing")
        val shape = longArrayOf(1, ids.size.toLong())

        val inputTensor = OnnxTensor.createTensor(
            environment,
            LongBuffer.wrap(ids.map { it.toLong() }.toLongArray()),
            shape,
        )
        val maskTensor = OnnxTensor.createTensor(
            environment,
            LongBuffer.wrap(mask.map { it.toLong() }.toLongArray()),
            shape,
        )

        inputTensor.use { input ->
            maskTensor.use { maskInput ->
                val outputs = active.run(
                    mapOf(inputName to input, maskName to maskInput),
                )
                outputs.use { result ->
                    val tensor = result[0] as OnnxTensor
                    val buffer: FloatBuffer = tensor.floatBuffer
                    val vector = FloatArray(buffer.remaining())
                    buffer.get(vector)
                    outputDim = vector.size
                    return vector
                }
            }
        }
    }

    private fun mainThread(result: MethodChannel.Result, block: (MethodChannel.Result) -> Unit) {
        android.os.Handler(context.mainLooper).post { block(result) }
    }

    fun dispose() {
        session?.close()
        session = null
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }
}
