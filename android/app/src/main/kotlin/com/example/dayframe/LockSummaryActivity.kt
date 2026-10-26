package com.example.dayframe

import android.app.Activity
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** User-invoked surface. Never dismisses the keyguard or starts on screen-on. */
class LockSummaryActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (android.os.Build.VERSION.SDK_INT >= 27) setShowWhenLocked(true)
        else window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        window.decorView.setBackgroundColor(0xFF101A17.toInt())
    }
    override fun onResume() {
        super.onResume()
        val prefs = getSharedPreferences("lock_surface", MODE_PRIVATE)
        val summary = prefs.getString("summary", "").orEmpty()
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val content = when {
            !prefs.getBoolean("enabled", false) -> "앱 설정에서 잠금 요약을 활성화하세요."
            summary.substringBefore('\n') != today -> "오늘의 요약이 없습니다. 잠금을 해제한 뒤 DAYFRAME을 열어 갱신하세요."
            else -> summary
        }
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 24, 32, 24)
        }
        layout.addView(TextView(this).apply {
            text = "DAYFRAME · 잠금 요약\n\n$content"
            textSize = 16f
            setTextColor(0xFFF1F5F3.toInt())
        })
        layout.addView(Button(this).apply {
            text = "닫기 (휴대폰 잠금 유지)"
            setOnClickListener { finish() }
        })
        setContentView(ScrollView(this).apply { addView(layout) })
    }
}
