package com.example.dayframe

import android.app.Activity
import android.app.KeyguardManager
import android.os.Bundle
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.plugin.platform.PlatformPlugin

class LockPlannerActivity : Activity() {
    companion object { var current: LockPlannerActivity? = null; private set }
    private var view: FlutterView? = null
    private var platformPlugin: PlatformPlugin? = null
    private var automatic = false
    private var closeOnUnlock = false
    private var token = -1
    private fun locked() = (getSystemService(KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked
    private fun interactive() = (getSystemService(POWER_SERVICE) as PowerManager).isInteractive
    private fun allowed() = if (automatic) LockOverlayService.active?.allows(token) == true else interactive()

    override fun onCreate(state: Bundle?) {
        super.onCreate(state)
        automatic = intent.getBooleanExtra("automatic", false)
        token = intent.getIntExtra("session", -1)
        closeOnUnlock = automatic || locked()
        // OS가 실행을 미뤘다면 잠금 해제 뒤에는 화면을 만들지 않는다.
        if (!allowed()) { finish(); return }
        current?.closePlanner()
        current = this
        if (android.os.Build.VERSION.SDK_INT >= 27) setShowWhenLocked(true)
        else window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        val service = LockOverlayService.active
        val engine = service?.plannerEngine
        if (engine == null) { finish(); return }
        if (android.os.Build.VERSION.SDK_INT >= 30) window.setDecorFitsSystemWindows(false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.TRANSPARENT
        if (android.os.Build.VERSION.SDK_INT >= 29) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
        applySystemBars(service.darkMode)
        platformPlugin = PlatformPlugin(this, engine.platformChannel)
        val flutter = FlutterView(this, FlutterTextureView(this))
        flutter.attachToFlutterEngine(engine)
        view = flutter
        setContentView(flutter)
        service.opened()
    }
    fun applySystemBars(dark: Boolean) {
        if (android.os.Build.VERSION.SDK_INT >= 30) {
            val mask = android.view.WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or android.view.WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
            window.insetsController?.setSystemBarsAppearance(if (dark) 0 else mask, mask)
        } else {
            val mask = android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR or android.view.View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
            window.decorView.systemUiVisibility = if (dark) window.decorView.systemUiVisibility and mask.inv() else window.decorView.systemUiVisibility or mask
        }
    }
    fun closePlanner() {
        platformPlugin?.destroy(); platformPlugin = null
        view?.visibility = android.view.View.INVISIBLE
        view?.detachFromFlutterEngine()
        view = null
        if (current === this) {
            current = null
            LockOverlayService.active?.closed()
            LockOverlayService.active?.plannerEngine?.lifecycleChannel?.appIsPaused()
        }
        finish()
    }
    override fun onResume() {
        super.onResume()
        if (!allowed() || (closeOnUnlock && !locked())) { closePlanner(); return }
        LockOverlayService.active?.let { applySystemBars(it.darkMode) }
        LockOverlayService.active?.plannerEngine?.lifecycleChannel?.appIsResumed()
    }
    override fun onDestroy() {
        platformPlugin?.destroy(); platformPlugin = null
        view?.detachFromFlutterEngine()
        if (current === this) {
            current = null
            LockOverlayService.active?.closed()
            LockOverlayService.active?.plannerEngine?.lifecycleChannel?.appIsPaused()
        }
        super.onDestroy()
    }
}
