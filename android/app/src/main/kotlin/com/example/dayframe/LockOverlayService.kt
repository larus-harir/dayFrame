package com.example.dayframe

import android.app.*
import android.content.*
import android.os.*
import android.provider.Settings
import android.view.*
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.FlutterInjector
import io.flutter.plugin.common.MethodChannel

/** User-enabled overlay; foreground notification remains visible while monitoring screen-on. */
class LockOverlayService : Service() {
    companion object { var active: LockOverlayService? = null; private set }
    private var engine: FlutterEngine? = null
    private var view: FlutterView? = null
    private var channel: MethodChannel? = null
    private var receiverRegistered = false
    private var showing = false
    private val windows get() = getSystemService(WINDOW_SERVICE) as WindowManager
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_ON -> if ((getSystemService(KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked) show()
                Intent.ACTION_SCREEN_OFF, Intent.ACTION_USER_PRESENT -> flushAndHide {}
                Intent.ACTION_DATE_CHANGED, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> reload()
            }
        }
    }
    override fun onCreate() {
        super.onCreate()
        active = this
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(NotificationChannel("lock_overlay", "잠금 플래너 실행", NotificationManager.IMPORTANCE_LOW))
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val stop = PendingIntent.getService(this, 1, Intent(this, LockOverlayService::class.java).setAction("stop"), PendingIntent.FLAG_IMMUTABLE)
        val notification = Notification.Builder(this, "lock_overlay")
            .setSmallIcon(android.R.drawable.ic_menu_agenda)
            .setContentTitle("DAYFRAME 잠금 플래너 실행 중")
            .setContentText("화면을 켜면 표시 · 설정 또는 중지 버튼으로 종료")
            .setContentIntent(open).setOngoing(true)
            .addAction(Notification.Action.Builder(null, "중지", stop).build()).build()
        if (Build.VERSION.SDK_INT >= 34) startForeground(24, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        else startForeground(24, notification)
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON); addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT); addAction(Intent.ACTION_DATE_CHANGED)
            addAction(Intent.ACTION_TIME_CHANGED); addAction(Intent.ACTION_TIMEZONE_CHANGED)
        }
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        else registerReceiver(receiver, filter)
        receiverRegistered = true
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "stop") {
            getSharedPreferences("lock_surface", MODE_PRIVATE).edit().putBoolean("autoEnabled", false).apply()
            flushAndHide { stopSelf() }
            return START_NOT_STICKY
        }
        if (!getSharedPreferences("lock_surface", MODE_PRIVATE).getBoolean("autoEnabled", false) || !Settings.canDrawOverlays(this)) {
            stopSelf(); return START_NOT_STICKY
        }
        if (intent?.action == "show") show()
        return START_STICKY
    }
    private fun ensureEngine() {
        if (engine != null) return
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        val flutter = FlutterEngine(this)
        engine = flutter
        channel = MethodChannel(flutter.dartExecutor.binaryMessenger, "dev.dayframe/overlay").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "hide") { hide(); result.success(null) }
                else result.notImplemented()
            }
        }
        flutter.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(
            loader.findAppBundlePath(), "package:dayframe/lock_overlay.dart", "lockOverlayMain"))
    }
    private fun show() {
        if (!Settings.canDrawOverlays(this) || showing) return
        if (!getSharedPreferences("lock_surface", MODE_PRIVATE).getBoolean("autoEnabled", false)) return
        ensureEngine()
        val flutter = engine ?: return
        reload()
        val overlay = FlutterView(this, FlutterTextureView(this))
        overlay.attachToFlutterEngine(flutter)
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_SECURE,
            android.graphics.PixelFormat.OPAQUE)
        try {
            windows.addView(overlay, params)
            view = overlay; showing = true
            flutter.lifecycleChannel.appIsResumed()
        } catch (_: RuntimeException) {
            overlay.detachFromFlutterEngine()
            // Permission can be revoked while the foreground service is running.
            stopSelf()
        }
    }
    private fun hide() {
        val overlay = view ?: return
        try { windows.removeView(overlay) } catch (_: IllegalArgumentException) { /* Removed by system. */ }
        overlay.detachFromFlutterEngine()
        view = null; showing = false
        engine?.lifecycleChannel?.appIsPaused()
    }
    fun reload() { channel?.invokeMethod("reload", null) }
    fun flushAndHide(done: () -> Unit) {
        val bridge = channel
        if (bridge == null) { hide(); done(); return }
        bridge.invokeMethod("flush", null, object : MethodChannel.Result {
            override fun success(result: Any?) { hide(); done() }
            override fun error(code: String, message: String?, details: Any?) { hide(); done() }
            override fun notImplemented() { hide(); done() }
        })
    }
    override fun onDestroy() {
        if (receiverRegistered) unregisterReceiver(receiver)
        hide(); channel?.setMethodCallHandler(null); engine?.destroy()
        active = null
        super.onDestroy()
    }
    override fun onBind(intent: Intent?) = null
}
