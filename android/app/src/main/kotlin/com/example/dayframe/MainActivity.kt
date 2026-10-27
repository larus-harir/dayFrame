package com.example.dayframe

import android.content.Intent
import android.provider.Settings
import android.net.Uri
import android.os.Build
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
                    "overlayPermission" -> result.success(Settings.canDrawOverlays(this))
                    "requestOverlayPermission" -> {
                        startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
                        result.success(null)
                    }
                    "overlayRunning" -> result.success(LockOverlayService.active != null)
                    "stopOverlay" -> {
                        prefs.edit().putBoolean("autoEnabled", false).apply()
                        val service = LockOverlayService.active
                        if (service == null) result.success(null)
                        else service.flushAndHide { stopService(Intent(this, LockOverlayService::class.java)); result.success(null) }
                    }
                    "flushOverlay" -> {
                        val service = LockOverlayService.active
                        if (service == null) result.success(null)
                        else service.flushAndHide { result.success(null) }
                    }
                    "showOverlay" -> {
                        if (LockOverlayService.active == null) result.error("DISABLED", "먼저 잠금 플래너를 시작하세요.", null)
                        else {
                            LockOverlayService.active?.prepareManual()
                            startActivity(Intent(this, LockPlannerActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                            result.success(null)
                        }
                    }
                    "startOverlay" -> {
                        if (Build.VERSION.SDK_INT < 26 || !Settings.canDrawOverlays(this)) {
                            result.error("PERMISSION", "다른 앱 위에 표시 권한이 필요합니다.", null)
                        } else {
                            prefs.edit().putBoolean("autoEnabled", true).apply()
                            if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                                requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 24)
                            }
                            startForegroundService(Intent(this, LockOverlayService::class.java))
                            android.os.Handler(mainLooper).postDelayed({
                                if (LockOverlayService.active != null) result.success(null)
                                else result.error("START", "서비스 시작 상태를 확인해주세요.", null)
                            }, 250)
                        }
                    }
                    "displayStatus" -> {
                        val status = prefs.getString("displayStatus", null)
                        val service = LockOverlayService.active
                        result.success(if (service != null && !service.engineReady && status != "engine_error") "starting" else status)
                    }
                    "refresh" -> { LockOverlayService.active?.reload(); result.success(null) }
                    else -> result.notImplemented()
                }
            }
    }
}
