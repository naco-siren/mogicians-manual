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
 * Serves this app's own installer to the share sheet, read-only and without
 * copying it: `content://<applicationId>.apk/膜法指南-<version>.apk` is the
 * installed APK itself (`ApplicationInfo.sourceDir`), and
 * `content://<applicationId>.apk/膜法指南-<version>.zip` is a ZIP wrapper
 * around it that [AppSharing] builds in the cache directory on demand (for
 * receivers that refuse .apk files, such as Bluetooth). The provider is not
 * exported: other apps reach it only through the per-intent URI grant. The
 * file name a receiver sees is the last path segment even if it never
 * queries.
 */
class ApkProvider : ContentProvider() {
    override fun onCreate() = true

    override fun getType(uri: Uri): String = if (uri.lastPathSegment?.endsWith(".zip") == true) {
        ZIP_MIME_TYPE
    } else {
        APK_MIME_TYPE
    }

    override fun query(
        uri: Uri,
        projection: Array<String>?,
        selection: String?,
        selectionArgs: Array<String>?,
        sortOrder: String?,
    ): Cursor {
        val file = fileFor(uri)
        val columns = projection ?: arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE, MIME_TYPE_COLUMN)
        val cursor = MatrixCursor(columns, 1)
        cursor.addRow(
            columns.map { column ->
                when (column) {
                    OpenableColumns.DISPLAY_NAME -> uri.lastPathSegment
                    OpenableColumns.SIZE -> file.length()
                    // MediaStore.MediaColumns.MIME_TYPE: some receivers (CatShare,
                    // DocumentFile users) query this and choke on a null.
                    MIME_TYPE_COLUMN -> getType(uri)
                    else -> null
                }
            },
        )
        return cursor
    }

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r") throw FileNotFoundException("The installer is read-only")
        return ParcelFileDescriptor.open(fileFor(uri), ParcelFileDescriptor.MODE_READ_ONLY)
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

    private fun fileFor(uri: Uri): File {
        val context = context ?: throw IllegalStateException("No context")
        if (uri.authority != authority(context)) throw FileNotFoundException(uri.toString())
        val file = when (uri.lastPathSegment) {
            apkName(context) -> File(context.applicationInfo.sourceDir)
            zipName(context) -> zipFile(context)
            else -> throw FileNotFoundException(uri.toString())
        }
        if (!file.isFile) throw FileNotFoundException(uri.toString())
        return file
    }

    companion object {
        const val APK_MIME_TYPE = "application/vnd.android.package-archive"
        const val ZIP_MIME_TYPE = "application/zip"
        private const val MIME_TYPE_COLUMN = "mime_type"

        fun authority(context: Context) = "${context.packageName}.apk"

        @Suppress("DEPRECATION")
        fun versionName(context: Context): String =
            context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "?"

        fun apkName(context: Context) = "膜法指南-${versionName(context)}.apk"

        fun zipName(context: Context) = "膜法指南-${versionName(context)}.zip"

        /** Where [AppSharing] keeps the ZIP wrapper; rebuilt when stale. */
        fun zipFile(context: Context) = File(File(context.cacheDir, "share"), zipName(context))

        fun uri(context: Context, name: String): Uri = Uri.Builder()
            .scheme("content")
            .authority(authority(context))
            .appendPath(name)
            .build()
    }
}
