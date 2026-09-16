package com.example.app

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.zip.CRC32
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

/**
 * The Android half of lib/service/app_sharing.dart: describes the installed
 * copy of this app and which phone-to-phone transfer apps are around, and
 * hands the installer (as .apk, or wrapped in a .zip) to the share sheet or
 * straight to one of those apps.
 */
class AppSharing(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private val mainThread = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "describe" -> result.success(describe())
            "share" -> share(
                zip = call.argument<String>("format") == "zip",
                packageName = call.argument<String>("package"),
                result = result,
            )
            "open" -> {
                val packageName = call.argument<String>("package")
                val launch = packageName?.let { activity.packageManager.getLaunchIntentForPackage(it) }
                if (launch == null) {
                    result.error("not_found", "No launcher for $packageName", null)
                } else {
                    activity.startActivity(launch)
                    result.success(null)
                }
            }
            else -> result.notImplemented()
        }
    }

    /**
     * `splitInstall` is true when Google Play installed this copy as base +
     * config splits (builds before configuration splits were disabled); such
     * a base.apk must not be shared, it cannot be installed on its own.
     * `shareApps` lists the transfer apps from [ShareApps.candidates] that are
     * installed; `apkReceivers` / `zipReceivers` count the apps that would
     * appear in the share sheet for each file type.
     */
    private fun describe(): Map<String, Any?> {
        val info = activity.applicationInfo
        val pm = activity.packageManager
        val apkReceivers = receivers(ApkProvider.APK_MIME_TYPE)
        val zipReceivers = receivers(ApkProvider.ZIP_MIME_TYPE)
        val shareApps = ShareApps.candidates.mapNotNull { candidate ->
            val label = try {
                pm.getApplicationLabel(pm.getApplicationInfo(candidate.packageName, 0)).toString()
            } catch (e: PackageManager.NameNotFoundException) {
                return@mapNotNull null
            }
            val sendsApk = candidate.packageName in apkReceivers
            val sendsZip = candidate.packageName in zipReceivers
            // A system service with neither a share entry nor a launcher is
            // nothing the user can act on.
            if (!sendsApk && !sendsZip && pm.getLaunchIntentForPackage(candidate.packageName) == null) {
                return@mapNotNull null
            }
            mapOf(
                "package" to candidate.packageName,
                "label" to label.ifBlank { candidate.label },
                "sendsApk" to sendsApk,
                "sendsZip" to sendsZip,
            )
        }
        return mapOf(
            "versionName" to ApkProvider.versionName(activity),
            "fileName" to ApkProvider.apkName(activity),
            "sizeBytes" to File(info.sourceDir).length(),
            "splitInstall" to !info.splitSourceDirs.isNullOrEmpty(),
            "shareApps" to shareApps,
            "apkReceivers" to apkReceivers.size,
            "zipReceivers" to zipReceivers.size,
        )
    }

    /** Packages with an activity that takes ACTION_SEND for [mimeType]. */
    private fun receivers(mimeType: String): Set<String> {
        val probe = Intent(Intent.ACTION_SEND).setType(mimeType)
        @Suppress("DEPRECATION")
        return activity.packageManager.queryIntentActivities(probe, 0)
            .map { it.activityInfo.packageName }
            .filter { it != activity.packageName }
            .toSet()
    }

    private fun share(zip: Boolean, packageName: String?, result: MethodChannel.Result) {
        if (!zip) {
            send(ApkProvider.apkName(activity), ApkProvider.APK_MIME_TYPE, packageName)
            result.success(null)
            return
        }
        // Wrapping 150 MB takes a few seconds on an old phone: off the UI thread.
        Thread {
            try {
                ensureZip()
                mainThread.post {
                    send(ApkProvider.zipName(activity), ApkProvider.ZIP_MIME_TYPE, packageName)
                    result.success(null)
                }
            } catch (e: Exception) {
                mainThread.post { result.error("zip_failed", e.toString(), null) }
            }
        }.start()
    }

    private fun send(name: String, mimeType: String, packageName: String?) {
        val uri = ApkProvider.uri(activity, name)
        val intent = Intent(Intent.ACTION_SEND)
            .setType(mimeType)
            .putExtra(Intent.EXTRA_STREAM, uri)
            .putExtra(Intent.EXTRA_SUBJECT, name)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        // The read grant travels with the ClipData; set it explicitly rather
        // than relying on the framework's EXTRA_STREAM migration.
        intent.clipData = ClipData.newUri(activity.contentResolver, name, uri)
        if (packageName != null) {
            activity.startActivity(intent.setPackage(packageName))
        } else {
            activity.startActivity(Intent.createChooser(intent, "分享膜法指南安装包"))
        }
    }

    /**
     * Builds `<cache>/share/膜法指南-<version>.zip` holding the APK as a single
     * stored (uncompressed: an APK is already a ZIP) entry, unless a fresh one
     * exists. Two passes over the file: one for the CRC the STORED method
     * needs up front, one to copy.
     */
    private fun ensureZip(): File {
        val apk = File(activity.applicationInfo.sourceDir)
        val zip = ApkProvider.zipFile(activity)
        if (zip.isFile && zip.lastModified() >= apk.lastModified() && zip.length() > apk.length()) {
            return zip
        }
        zip.parentFile?.mkdirs()
        val partial = File(zip.path + ".part")
        val crc = CRC32()
        val buffer = ByteArray(1 shl 16)
        apk.inputStream().use { input ->
            while (true) {
                val n = input.read(buffer)
                if (n < 0) break
                crc.update(buffer, 0, n)
            }
        }
        ZipOutputStream(BufferedOutputStream(FileOutputStream(partial), 1 shl 16)).use { out ->
            val entry = ZipEntry(ApkProvider.apkName(activity)).apply {
                method = ZipEntry.STORED
                size = apk.length()
                compressedSize = apk.length()
                this.crc = crc.value
            }
            out.putNextEntry(entry)
            apk.inputStream().use { it.copyTo(out, 1 shl 16) }
            out.closeEntry()
        }
        if (!partial.renameTo(zip)) throw IllegalStateException("Could not move ${partial.name}")
        return zip
    }

    companion object {
        const val CHANNEL = "mogicians_manual/app_sharing"
    }
}
