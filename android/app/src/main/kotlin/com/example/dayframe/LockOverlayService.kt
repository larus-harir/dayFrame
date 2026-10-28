package com.example.dayframe

import android.app.*
import android.content.*
import android.graphics.PixelFormat
import android.os.*
import android.provider.Settings
import android.view.*
import android.widget.Button
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class LockOverlayService : Service() {
    companion object { var active: LockOverlayService? = null; private set }
    var plannerEngine: FlutterEngine? = null
        private set
    var engineReady = false
        private set
    var darkMode = false
        private set
    var surfaceColor = 0xFFF6FAF7.toInt()
        private set
    private var channel: MethodChannel? = null
    private var launcher: Button? = null
    private val display = LockDisplayState()
    private val handler = Handler(Looper.getMainLooper())
    private var timeout: Runnable? = null
    private var launched: Int? = null
    private val windows get() = getSystemService(WINDOW_SERVICE) as WindowManager
    private val prefs get() = getSharedPreferences("lock_surface", MODE_PRIVATE)
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_ON -> requestAutomatic()
                Intent.ACTION_SCREEN_OFF, Intent.ACTION_USER_PRESENT -> flushAndHide {}
                Intent.ACTION_DATE_CHANGED, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED -> reload()
            }
        }
    }
    private fun locked() = (getSystemService(KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked
    private fun interactive() = (getSystemService(POWER_SERVICE) as PowerManager).isInteractive
    fun allows(token: Int) = display.allows(token, locked(), interactive()) && prefs.getBoolean("autoEnabled", false)
    private fun status(value: String) { prefs.edit().putString("displayStatus", value).apply() }

    override fun onCreate() {
        super.onCreate()
        active = this
        status("starting")
        val notifications = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        notifications.createNotificationChannel(NotificationChannel("lock_overlay", "잠금화면", NotificationManager.IMPORTANCE_LOW))
        val open = PendingIntent.getActivity(this, 0, Intent(this, LockPlannerActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val stop = PendingIntent.getService(this, 1, Intent(this, LockOverlayService::class.java).setAction("stop"), PendingIntent.FLAG_IMMUTABLE)
        val notification = Notification.Builder(this, "lock_overlay")
            .setSmallIcon(android.R.drawable.ic_menu_agenda).setContentTitle("DAYFRAME")
            .setContentText("잠금화면 사용 중").setContentIntent(open).setOngoing(true)
            .addAction(Notification.Action.Builder(null, "열기", open).build())
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
        ensureEngine()
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "stop") {
            prefs.edit().putBoolean("autoEnabled", false).apply()
            flushAndHide { stopSelf() }
            return START_NOT_STICKY
        }
        if (!prefs.getBoolean("autoEnabled", false) || !Settings.canDrawOverlays(this)) {
            stopSelf(); return START_NOT_STICKY
        }
        if (intent?.action == "show") {
            dismiss()
            startActivity(Intent(this, LockPlannerActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
        return START_STICKY
    }
    private fun ensureEngine() {
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        val flutter = FlutterEngine(this)
        plannerEngine = flutter
        channel = MethodChannel(flutter.dartExecutor.binaryMessenger, "dev.dayframe/overlay").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "ready" -> {
                        engineReady = true
                        status("ready")
                        if (LockPlannerActivity.current != null) reload(startBibleSession = true)
                        result.success(null)
                    }
                    "loadError" -> { status("engine_error"); result.success(null) }
                    "hide" -> { dismiss(); result.success(null) }
                    "appearance" -> {
                        darkMode = call.argument<Boolean>("dark") == true
                        surfaceColor = call.argument<Number>("surfaceColor")?.toInt()
                            ?: if (darkMode) 0xFF101512.toInt() else 0xFFF6FAF7.toInt()
                        LockPlannerActivity.current?.applySystemBars(darkMode)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        flutter.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(
            loader.findAppBundlePath(), "package:dayframe/lock_overlay.dart", "lockOverlayMain"))
    }
    private fun requestAutomatic() {
        dismiss()
        if (!Settings.canDrawOverlays(this)) { status("permission_missing"); return }
        if (!prefs.getBoolean("autoEnabled", false)) return
        val token = display.request(locked(), interactive()) ?: run { status("not_locked"); return }
        reload()
        // Android 15 이상에서는 보이는 오버레이가 있어야 백그라운드 실행을 요청할 수 있다.
        val button = Button(this).apply {
            text = "DAYFRAME 열기"
            setOnClickListener { launch(token) }
        }
        val params = WindowManager.LayoutParams((180 * resources.displayMetrics.density).toInt(),
            WindowManager.LayoutParams.WRAP_CONTENT, WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE, PixelFormat.TRANSLUCENT)
        params.gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
        params.y = (72 * resources.displayMetrics.density).toInt()
        try { windows.addView(button, params); launcher = button }
        catch (_: RuntimeException) { display.dismiss(); status("blocked"); return }
        status("pending")
        handler.postDelayed({
            if (allows(token)) launch(token)
            else if (display.expire(token)) removeLauncher()
        }, 250)
        timeout = Runnable {
            if (LockPlannerActivity.current == null && display.expire(token)) {
                removeLauncher(); status(if (locked() && interactive()) "blocked" else "dismissed")
            }
        }.also { handler.postDelayed(it, 4000) }
    }
    private fun launch(token: Int) {
        if (!allows(token) || launched == token) return
        launched = token
        try {
            startActivity(Intent(this, LockPlannerActivity::class.java)
                .putExtra("automatic", true).putExtra("session", token)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP))
        } catch (_: RuntimeException) { display.dismiss(); removeLauncher(); status("blocked") }
        // 실행 승인 전에 창을 없애면 Android 15 이상의 가시성 조건을 잃는다.
    }
    fun prepareManual() { dismiss(); reload() }
    fun opened() {
        timeout?.let(handler::removeCallbacks)
        removeLauncher()
        status("opened")
        if (engineReady) reload(startBibleSession = true)
    }
    fun closed() { launched = null; display.dismiss(); timeout?.let(handler::removeCallbacks); removeLauncher() }
    private fun removeLauncher() {
        launcher?.let { try { windows.removeViewImmediate(it) } catch (_: IllegalArgumentException) {} }
        launcher = null
    }
    private fun dismiss() {
        closed()
        LockPlannerActivity.current?.closePlanner()
    }
    fun reload(startBibleSession: Boolean = false) {
        channel?.invokeMethod("reload", mapOf("startBibleSession" to startBibleSession))
    }
    fun flushAndHide(done: () -> Unit) {
        // 저장 응답은 창을 다시 닫지 않는다. 화면을 다시 켠 요청과 섞일 수 있다.
        dismiss()
        val bridge = channel
        if (bridge == null) { done(); return }
        bridge.invokeMethod("flush", null, object : MethodChannel.Result {
            override fun success(result: Any?) { done() }
            override fun error(code: String, message: String?, details: Any?) { done() }
            override fun notImplemented() { done() }
        })
    }
    override fun onDestroy() {
        unregisterReceiver(receiver)
        dismiss(); handler.removeCallbacksAndMessages(null)
        channel?.setMethodCallHandler(null); plannerEngine?.destroy(); active = null
        super.onDestroy()
    }
    override fun onBind(intent: Intent?) = null
}
