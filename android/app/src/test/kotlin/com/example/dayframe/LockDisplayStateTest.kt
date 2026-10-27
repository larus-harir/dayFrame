package com.example.dayframe

import org.junit.Assert.*
import org.junit.Test

class LockDisplayStateTest {
    @Test fun unlockBeforeLaunchRejectsPendingScreen() {
        val state = LockDisplayState()
        val request = state.request(locked = true, interactive = true)!!
        assertTrue(state.allows(request, locked = true, interactive = true))
        assertFalse(state.allows(request, locked = false, interactive = true))
        state.dismiss()
        assertFalse(state.allows(request, locked = true, interactive = true))
    }
    @Test fun rapidOffOnDiscardsOldLaunchButAllowsNewOne() {
        val state = LockDisplayState()
        val old = state.request(locked = true, interactive = true)!!
        state.dismiss()
        val next = state.request(locked = true, interactive = true)!!
        assertFalse(state.allows(old, locked = true, interactive = true))
        assertTrue(state.allows(next, locked = true, interactive = true))
        assertFalse(state.allows(next, locked = true, interactive = false))
    }
    @Test fun oldTimeoutCannotCancelTheNextScreenOn() {
        val state = LockDisplayState()
        val old = state.request(locked = true, interactive = true)!!
        val next = state.request(locked = true, interactive = true)!!
        assertFalse(state.expire(old))
        assertTrue(state.allows(next, locked = true, interactive = true))
        assertTrue(state.expire(next))
        assertFalse(state.allows(next, locked = true, interactive = true))
    }
    @Test fun unlockedOrSleepingPhoneDoesNotQueueAWindow() {
        val state = LockDisplayState()
        assertNull(state.request(locked = false, interactive = true))
        assertNull(state.request(locked = true, interactive = false))
    }
}
