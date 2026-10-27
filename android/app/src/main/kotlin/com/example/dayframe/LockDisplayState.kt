package com.example.dayframe

internal class LockDisplayState {
    private var generation = 0
    private var requested: Int? = null

    fun request(locked: Boolean, interactive: Boolean): Int? {
        dismiss()
        if (!locked || !interactive) return null
        return generation.also { requested = it }
    }

    fun allows(token: Int, locked: Boolean, interactive: Boolean): Boolean =
        requested == token && locked && interactive

    fun expire(token: Int): Boolean {
        if (requested != token) return false
        dismiss()
        return true
    }

    fun dismiss() { generation++; requested = null }
}
