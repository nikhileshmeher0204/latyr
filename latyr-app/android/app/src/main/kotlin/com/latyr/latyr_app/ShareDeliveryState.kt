package com.latyr.latyr_app

internal class ShareDeliveryState {
    private var dartReady = false
    private var pendingText: String? = null

    fun offer(text: String): String? {
        if (dartReady) return text
        pendingText = text
        return null
    }

    fun readyAndTakeInitial(): String? {
        dartReady = true
        val text = pendingText
        pendingText = null
        return text
    }
}
