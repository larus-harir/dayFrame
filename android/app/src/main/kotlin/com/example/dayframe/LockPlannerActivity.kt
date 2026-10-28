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
    companion object {
        var current: LockPlannerActivity? = null
            private set
    }

    private var view: FlutterView? = null
    private var platformPlugin: PlatformPlugin? = null
    private var automatic = false
    private var closeOnUnlock = false
    private var token = -1

    private fun locked() =
        (getSystemService(KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked

    private fun interactive() =
        (getSystemService(POWER_SERVICE) as PowerManager).isInteractive

    private fun allowed() =
        if (automatic) {
            LockOverlayService.active?.allows(token) == true
        } else {
            interactive()
        }

    override fun onCreate(state: Bundle?) {
        super.onCreate(state)

        automatic = intent.getBooleanExtra("automatic", false)
        token = intent.getIntExtra("session", -1)
        closeOnUnlock = automatic || locked()

        // OS가 실행을 미뤘다면 잠금 해제 뒤에는 화면을 만들지 않는다.
        if (!allowed()) {
            finish()
            return
        }

        current?.closePlanner()
        current = this

        if (android.os.Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
            )
        }

        val service = LockOverlayService.active
        val engine = service?.plannerEngine

        if (engine == null) {
            finish()
            return
        }

        platformPlugin = PlatformPlugin(this, engine.platformChannel)

        val flutter = FlutterView(this, FlutterTextureView(this))
        flutter.attachToFlutterEngine(engine)

        view = flutter
        setContentView(flutter)

        window.decorView.post {
            if (!isFinishing && !isDestroyed) {
                applySystemBars(service.darkMode)
            }
        }

        service.opened()
    }

    fun applySystemBars(dark: Boolean) {
        val surface = LockOverlayService.active?.surfaceColor
            ?: if (dark) 0xFF101512.toInt() else 0xFFF6FAF7.toInt()
        LockSystemBars.apply(window, surface, dark)
        view?.setBackgroundColor(surface)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) LockOverlayService.active?.let { applySystemBars(it.darkMode) }
    }

    fun closePlanner() {
        platformPlugin?.destroy()
        platformPlugin = null

        view?.visibility = android.view.View.INVISIBLE
        view?.detachFromFlutterEngine()
        view = null

        if (current === this) {
            current = null
            LockOverlayService.active?.closed()
            LockOverlayService.active?.plannerEngine
                ?.lifecycleChannel?.appIsPaused()
        }

        finish()
    }

    override fun onResume() {
        super.onResume()

        if (!allowed() || (closeOnUnlock && !locked())) {
            closePlanner()
            return
        }

        LockOverlayService.active?.let { service ->
            window.decorView.post {
                if (!isFinishing && !isDestroyed) {
                    applySystemBars(service.darkMode)
                }
            }
        }

        LockOverlayService.active?.plannerEngine
            ?.lifecycleChannel?.appIsResumed()
    }

    override fun onDestroy() {
        platformPlugin?.destroy()
        platformPlugin = null

        view?.detachFromFlutterEngine()
        view = null

        if (current === this) {
            current = null
            LockOverlayService.active?.closed()
            LockOverlayService.active?.plannerEngine
                ?.lifecycleChannel?.appIsPaused()
        }

        super.onDestroy()
    }
}
