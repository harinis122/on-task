//
//  SessionClock.swift
//  OnTask
//  Purpose: Reusable active-time tracking mechanics.
//  Created by Harini Suresh on 9/8/26.
//

import Foundation

struct SessionClock {
    private(set) var accumulatedElapsedTime: TimeInterval = 0
    private(set) var currentRunStartedAt: Date?
    private(set) var isRunning = false

    // Starts a fresh active timing run.
    mutating func start(now: Date = Date()) {
        accumulatedElapsedTime = 0
        currentRunStartedAt = now
        isRunning = true
    }

    // Pauses and stores active elapsed time.
    mutating func pause(now: Date = Date()) {
        guard isRunning else {
            return
        }

        accumulatedElapsedTime = elapsedTime(now: now)
        currentRunStartedAt = nil
        isRunning = false
    }

    // Resumes timing without losing accumulated time.
    mutating func resume(now: Date = Date()) {
        guard !isRunning else {
            return
        }

        currentRunStartedAt = now
        isRunning = true
    }

    // Restarts timing from zero immediately.
    mutating func restart(now: Date = Date()) {
        start(now: now)
    }

    // Clears all active timing state.
    mutating func reset() {
        accumulatedElapsedTime = 0
        currentRunStartedAt = nil
        isRunning = false
    }

    // Calculates active elapsed time from timestamps.
    func elapsedTime(now: Date = Date()) -> TimeInterval {
        guard let currentRunStartedAt else {
            return accumulatedElapsedTime
        }

        let currentRunElapsedTime = max(0, now.timeIntervalSince(currentRunStartedAt))
        return accumulatedElapsedTime + currentRunElapsedTime
    }
}
