package com.example.app

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import java.io.File
import java.io.FileNotFoundException

/**
 * Serves this app's own installed APK (`ApplicationInfo.sourceDir`) read-only
 * and without copying it, so that "分享安装包" can hand it to the share sheet.
 * The provider is not exported: other apps reach it only through the
 * per-intent URI grant attached to the share intent. The single valid URI is
 * `content://<applicationId>.apk/膜法指南-<versionName>.apk`, so the file name
 * a receiver sees is the last path segment even if it never queries.
 */
class ApkProvider : ContentProvider() {
    override fun onCreate() = true

    override fun getType(uri: Uri) = MIME_TYPE

    override fun query(
        uri: Uri,
        projection: Array<String>?,
        selection: String?,
        selectionArgs: Array<String>?,
        sortOrder: String?,
    ): Cursor {
        val file = apkFile(uri)
        val columns = projection ?: arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE)
        val cursor = MatrixCursor(columns, 1)
        cursor.addRow(
            columns.map { column ->
                when (column) {
                    OpenableColumns.DISPLAY_NAME -> displayName(appContext())
                    OpenableColumns.SIZE -> file.length()
                    else -> null
                }
            },
        )
        return cursor
    }

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r") throw FileNotFoundException("The installer is read-only")
        return ParcelFileDescriptor.open(apkFile(uri), ParcelFileDescriptor.MODE_READ_ONLY)
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? =
        throw UnsupportedOperationException()

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<String>?,
    ): Int = throw UnsupportedOperationException()

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<String>?): Int =
        throw UnsupportedOperationException()

    private fun appContext(): Context = context ?: throw IllegalStateException("No context")

    private fun apkFile(uri: Uri): File {
        val context = appContext()
        if (uri.authority != authority(context) || uri.lastPathSegment != displayName(context)) {
            throw FileNotFoundException(uri.toString())
        }
        return File(context.applicationInfo.sourceDir)
    }

    companion object {
        const val MIME_TYPE = "application/vnd.android.package-archive"

        fun authority(context: Context) = "${context.packageName}.apk"

        @Suppress("DEPRECATION")
        fun versionName(context: Context): String =
            context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "?"

        fun displayName(context: Context) = "膜法指南-${versionName(context)}.apk"

        fun uri(context: Context): Uri = Uri.Builder()
            .scheme("content")
            .authority(authority(context))
            .appendPath(displayName(context))
            .build()
    }
}
