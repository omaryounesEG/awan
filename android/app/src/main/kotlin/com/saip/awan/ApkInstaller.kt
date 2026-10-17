package com.saip.awan

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hands a downloaded .apk to Android's own installer.
 *
 * There is no update SDK here and no store: the app checks one GitHub release
 * by itself (the Dart side) and all this does is say "install this file". The
 * file is exposed through a FileProvider so the installer gets a one-shot
 * content:// URI instead of raw filesystem access, and the user's "install
 * unknown apps" switch is *asked for*, never assumed.
 */
class ApkInstaller(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL).apply {
        setMethodCallHandler(this@ApkInstaller)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canInstall" -> result.success(canInstall())
            "install" -> {
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("bad_args", "path is required", null)
                    return
                }
                try {
                    startInstaller(File(path))
                    result.success(true)
                } catch (e: Exception) {
                    result.error("install_failed", e.message, null)
                }
            }
            // Where the running app's own APK lives. A delta patch is applied
            // against exactly these bytes, so the app must be able to name
            // them. Readable by the app itself without any permission.
            "installedApkPath" -> result.success(context.applicationInfo?.sourceDir)
            "openInstallSettings" -> {
                try {
                    openUnknownSourcesSettings()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("settings_unavailable", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun canInstall(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            context.packageManager.canRequestPackageInstalls()

    private fun startInstaller(apk: File) {
        if (!apk.exists()) throw IllegalStateException("file not found: ${apk.path}")
        val uri: Uri = FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            apk,
        )
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    private fun openUnknownSourcesSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${context.packageName}"),
            )
        } else {
            Intent(Settings.ACTION_SECURITY_SETTINGS)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    fun dispose() = channel.setMethodCallHandler(null)

    companion object {
        const val CHANNEL = "com.awan.app/updater"
    }
}
