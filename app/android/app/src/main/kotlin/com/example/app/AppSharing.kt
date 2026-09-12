package com.example.app

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * The Android half of lib/service/app_sharing.dart: describes the installed
 * copy of this app and hands its installer to the system share sheet.
 */
class AppSharing(private val activity: Activity) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "describe" -> result.success(describe())
            "share" -> {
                share()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * `splitInstall` is true when Google Play installed this copy as base +
     * config splits (builds before configuration splits were disabled); such
     * a base.apk must not be shared, it cannot be installed on its own.
     */
    private fun describe(): Map<String, Any?> {
        val info = activity.applicationInfo
        return mapOf(
            "versionName" to ApkProvider.versionName(activity),
            "fileName" to ApkProvider.displayName(activity),
            "sizeBytes" to File(info.sourceDir).length(),
            "splitInstall" to !info.splitSourceDirs.isNullOrEmpty(),
        )
    }

    private fun share() {
        val uri = ApkProvider.uri(activity)
        val name = ApkProvider.displayName(activity)
        val send = Intent(Intent.ACTION_SEND)
            .setType(ApkProvider.MIME_TYPE)
            .putExtra(Intent.EXTRA_STREAM, uri)
            .putExtra(Intent.EXTRA_SUBJECT, name)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        // The read grant travels with the ClipData; set it explicitly rather
        // than relying on the framework's EXTRA_STREAM migration.
        send.clipData = ClipData.newUri(activity.contentResolver, name, uri)
        activity.startActivity(Intent.createChooser(send, "分享膜法指南安装包"))
    }

    companion object {
        const val CHANNEL = "mogicians_manual/app_sharing"
    }
}
