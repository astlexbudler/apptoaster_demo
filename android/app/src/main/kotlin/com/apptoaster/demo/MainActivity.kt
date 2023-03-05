package com.apptoaster.demo

import android.content.Intent
import android.net.Uri

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "dev.fluttercommunity.plus/android_intent"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launch") {
                val intent = call.arguments as? Map<String, Any>
                intent?.let {
                    startActivity(
                        Intent(Intent.ACTION_VIEW).apply {
                            it["uri"]?.let { uri ->
                                data = Uri.parse(uri.toString())
                            }
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                        }
                    )
                    result.success(true)
                } ?: result.success(false)
            } else {
                result.notImplemented()
            }
        }
    }
}