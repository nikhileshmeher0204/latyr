package com.latyr.latyr_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.latyr.latyr_app/share"
    private val shareDelivery = ShareDeliveryState()
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND && intent.type?.startsWith("text/") == true) {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (!text.isNullOrEmpty()) {
                val delivery = shareDelivery.offer(text)
                // Consume only the captured share payload so recreation cannot replay it.
                intent.removeExtra(Intent.EXTRA_TEXT)
                if (delivery != null) methodChannel?.invokeMethod("onSharedText", delivery)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel
        channel.setMethodCallHandler { call, result ->
            if (call.method == "getInitialSharedText") {
                result.success(shareDelivery.readyAndTakeInitial())
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        methodChannel = null
        super.onDestroy()
    }
}
