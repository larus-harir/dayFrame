package com.example.dayframe

import android.app.Activity
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.view.View
import android.view.WindowInsetsController
import android.view.WindowManager.LayoutParams
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [35, 36], manifest = Config.NONE)
class LockSystemBarsTest {
    @Test
    fun drawsBehindBothBarsWithoutLegacyTranslucency() {
        Robolectric.buildActivity(Activity::class.java).setup().use { controller ->
            val activity = controller.get()
            val window = activity.window
            window.addFlags(LayoutParams.FLAG_TRANSLUCENT_STATUS or LayoutParams.FLAG_TRANSLUCENT_NAVIGATION)
            LockSystemBars.apply(window, Color.WHITE, false)
            assertTrue(window.attributes.flags and LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS != 0)
            assertEquals(0, window.attributes.flags and
                (LayoutParams.FLAG_TRANSLUCENT_STATUS or LayoutParams.FLAG_TRANSLUCENT_NAVIGATION))
            assertFalse(window.isStatusBarContrastEnforced)
            assertFalse(window.isNavigationBarContrastEnforced)
            assertEquals(LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS,
                window.attributes.layoutInDisplayCutoutMode)
        }
    }

    @Test
    fun themeChangesKeepBackgroundAndBothSetsOfIconsTogether() {
        Robolectric.buildActivity(Activity::class.java).setup().use { controller ->
            val window = controller.get().window
            for (dark in listOf(false, true, false)) {
                val color = if (dark) Color.rgb(16, 21, 18) else Color.rgb(246, 250, 247)
                LockSystemBars.apply(window, color, dark)
                val mask = WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or
                    WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
                assertEquals(if (dark) 0 else mask,
                    window.insetsController!!.systemBarsAppearance and mask)
                val background = window.decorView.background as ColorDrawable
                assertEquals(color, background.color)
                assertEquals(View.VISIBLE, window.decorView.visibility)
            }
        }
    }
}
