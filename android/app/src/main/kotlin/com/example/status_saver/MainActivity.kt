package com.example.status_saver

import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
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
                    else -> result.notImplemented()
                }
            }
    }
}
