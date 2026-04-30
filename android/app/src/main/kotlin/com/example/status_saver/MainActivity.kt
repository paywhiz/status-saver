package com.example.status_saver

import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Handler
import android.os.Looper
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
