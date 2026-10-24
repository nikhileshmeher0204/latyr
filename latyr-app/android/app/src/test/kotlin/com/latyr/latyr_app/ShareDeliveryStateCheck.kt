package com.latyr.latyr_app

// Standalone JVM self-check: no Android runtime, emulator, network or test dependency.
fun main() {
    val coldStart = ShareDeliveryState()
    check(coldStart.offer("cold-start-content") == null)
    check(coldStart.readyAndTakeInitial() == "cold-start-content")
    check(coldStart.readyAndTakeInitial() == null)
    check(coldStart.offer("next-share") == "next-share")
    check(coldStart.readyAndTakeInitial() == null)

    val readyBeforeIntent = ShareDeliveryState()
    check(readyBeforeIntent.readyAndTakeInitial() == null)
    check(readyBeforeIntent.offer("late-startup-intent") == "late-startup-intent")
    check(readyBeforeIntent.readyAndTakeInitial() == null)

    // The transient startup slot keeps the latest input, matching prior behavior.
    val latestPending = ShareDeliveryState()
    latestPending.offer("older-share")
    latestPending.offer("newer-share")
    check(latestPending.readyAndTakeInitial() == "newer-share")
    check(latestPending.readyAndTakeInitial() == null)

    println("ShareDeliveryState: 10 checks passed")
}
