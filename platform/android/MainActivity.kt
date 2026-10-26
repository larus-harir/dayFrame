package com.example.dayframe

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.dayframe/lock_surface")
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences("lock_surface", MODE_PRIVATE)
                when (call.method) {
                    "sync" -> {
                        val enabled = call.argument<Boolean>("enabled") == true
                        val summary = if (enabled) call.argument<String>("summary").orEmpty().take(2000) else ""
                        // commit avoids a tile launched immediately after sync reading old content.
                        val saved = prefs.edit().putBoolean("enabled", enabled)
                            .putString("summary", summary).commit()
                        if (saved) result.success(null) else result.error("SAVE", "요약 저장 실패", null)
                    }
                    "open" -> {
                        if (!prefs.getBoolean("enabled", false)) {
                            result.error("DISABLED", "설정에서 먼저 활성화하세요.", null)
                        } else {
                            startActivity(Intent(this, LockSummaryActivity::class.java))
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
