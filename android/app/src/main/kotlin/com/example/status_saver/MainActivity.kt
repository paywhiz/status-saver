package com.example.status_saver

import android.content.ContentUris
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.status_saver/saf")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readBytes" -> {
                        val uriStr = call.argument<String>("uri") ?: run {
                            result.error("INVALID_URI", "URI is null", null)
                            return@setMethodCallHandler
                        }
                        executor.execute {
                            try {
                                val bytes = contentResolver
                                    .openInputStream(Uri.parse(uriStr))
                                    ?.use { it.readBytes() }
                                mainHandler.post {
                                    if (bytes != null) result.success(bytes)
                                    else result.error("CANNOT_OPEN", "Cannot open: $uriStr", null)
                                }
                            } catch (e: Exception) {
                                mainHandler.post { result.error("READ_ERROR", e.message, null) }
                            }
                        }
                    }
                    "videoThumbnail" -> {
                        val uriStr = call.argument<String>("uri")
                        val path = call.argument<String>("path")
                        val maxSize = call.argument<Int>("maxSize") ?: 256
                        executor.execute {
                            val bytes = extractThumbnail(uriStr, path, maxSize)
                            mainHandler.post { result.success(bytes) }
                        }
                    }
                    "isPackageInstalled" -> {
                        val pkg = call.argument<String>("package")
                        if (pkg == null) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        result.success(isPackageInstalled(pkg))
                    }
                    "listGalleryAlbum" -> {
                        val album = call.argument<String>("albumName") ?: run {
                            result.error("INVALID_ALBUM", "albumName is null", null)
                            return@setMethodCallHandler
                        }
                        executor.execute {
                            val items = listGalleryAlbum(album)
                            mainHandler.post { result.success(items) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun extractThumbnail(uriStr: String?, path: String?, maxSize: Int): ByteArray? {
        val mmr = MediaMetadataRetriever()
        return try {
            when {
                uriStr != null -> mmr.setDataSource(this, Uri.parse(uriStr))
                path != null -> mmr.setDataSource(path)
                else -> return null
            }
            val frame = mmr.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                ?: return null
            val scaled = scaleToBox(frame, maxSize)
            if (scaled !== frame) frame.recycle()
            val baos = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.JPEG, 70, baos)
            scaled.recycle()
            baos.toByteArray()
        } catch (_: Exception) {
            null
        } finally {
            try { mmr.release() } catch (_: Exception) {}
        }
    }

    private fun listGalleryAlbum(albumName: String): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        queryBucket(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, albumName, "image", out)
        queryBucket(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, albumName, "video", out)
        out.sortByDescending { (it["modifiedMs"] as? Long) ?: 0L }
        return out
    }

    private fun queryBucket(
        contentUri: Uri,
        albumName: String,
        kind: String,
        out: MutableList<Map<String, Any?>>,
    ) {
        val idCol = MediaStore.MediaColumns._ID
        val nameCol = MediaStore.MediaColumns.DISPLAY_NAME
        val modCol = MediaStore.MediaColumns.DATE_MODIFIED
        val projection = arrayOf(idCol, nameCol, modCol)

        // The MediaColumns.BUCKET_DISPLAY_NAME / RELATIVE_PATH constants are
        // API 29+, but the underlying SQLite columns of those names exist on
        // older versions too via MediaStore.Images/Video. Use literal column
        // names so this compiles cleanly across the project's minSdk range.
        val (selection, args) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            "bucket_display_name = ? OR relative_path LIKE ?" to
                arrayOf(albumName, "%/$albumName/%")
        } else {
            "bucket_display_name = ?" to arrayOf(albumName)
        }

        try {
            contentResolver.query(
                contentUri,
                projection,
                selection,
                args,
                "$modCol DESC",
            )?.use { c ->
                val idIdx = c.getColumnIndexOrThrow(idCol)
                val nameIdx = c.getColumnIndexOrThrow(nameCol)
                val modIdx = c.getColumnIndexOrThrow(modCol)
                while (c.moveToNext()) {
                    val id = c.getLong(idIdx)
                    val name = c.getString(nameIdx) ?: continue
                    val modSec = c.getLong(modIdx)
                    val uri = ContentUris.withAppendedId(contentUri, id).toString()
                    out.add(
                        mapOf(
                            "uri" to uri,
                            "name" to name,
                            "kind" to kind,
                            "modifiedMs" to modSec * 1000L,
                        )
                    )
                }
            }
        } catch (_: Exception) {
            // Best-effort enumeration; partial results are fine.
        }
    }

    private fun isPackageInstalled(pkg: String): Boolean {
        return try {
            packageManager.getPackageInfo(pkg, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        } catch (_: Exception) {
            false
        }
    }

    private fun scaleToBox(src: Bitmap, maxSize: Int): Bitmap {
        val w = src.width
        val h = src.height
        if (w <= maxSize && h <= maxSize) return src
        val ratio = w.toFloat() / h.toFloat()
        val (nw, nh) = if (w >= h) {
            maxSize to (maxSize / ratio).toInt().coerceAtLeast(1)
        } else {
            (maxSize * ratio).toInt().coerceAtLeast(1) to maxSize
        }
        return Bitmap.createScaledBitmap(src, nw, nh, true)
    }
}
