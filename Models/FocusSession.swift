//
//  FocusSession.swift
//  OnTask
//  Purpose: Source of truth/logic for the current focus session.
//  Created by Harini Suresh on 8/18/26.
//

import Foundation
import Observation

@Observable
final class FocusSession {
    private static let menuBarTaskCharacterLimit = 20

    private(set) var currentTask: String?
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var isStopwatchRunning = false

    @ObservationIgnored private var accumulatedElapsedTime: TimeInterval = 0
    @ObservationIgnored private var currentRunStartedAt: Date?
    @ObservationIgnored private var stopwatchTimer: Timer?

    // Reports whether a task is currently active.
    var hasCurrentTask: Bool {
        currentTask != nil
    }

    // Indicates whether quitting needs user confirmation.
    var requiresQuitConfirmation: Bool {
        hasCurrentTask
    }

    // Formats elapsed time for menu display.
    var elapsedTimeText: String {
        Self.formatElapsedTime(elapsedTime)
    }

    // Provides a shortened menu-bar task title.
    var menuBarTaskTitle: String? {
        guard let currentTask else {
            return nil
        }

        if currentTask.count <= Self.menuBarTaskCharacterLimit {
            return currentTask
        }

        let truncatedText = currentTask.prefix(Self.menuBarTaskCharacterLimit)
        return "\(truncatedText)..."
    }

    // Validates and starts a new focus task.
    @discardableResult
    func startTask(_ taskText: String) -> Bool {
        let trimmedTask = taskText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTask.isEmpty else {
            return false
        }

        currentTask = trimmedTask
        startStopwatch()
        return true
    }

    // Pauses timing and stores accumulated elapsed time.
    func pauseStopwatch() {
        guard isStopwatchRunning else {
            return
        }

        refreshElapsedTime()
        accumulatedElapsedTime = elapsedTime
        currentRunStartedAt = nil
        isStopwatchRunning = false
        stopRefreshTimer()
    }

    // Resumes timing from accumulated elapsed time.
    func resumeStopwatch() {
        guard currentTask != nil, !isStopwatchRunning else {
            return
        }

        currentRunStartedAt = Date()
        isStopwatchRunning = true
        startRefreshTimer()
    }

    // Restarts timing for the current task.
    func restartStopwatch() {
        guard currentTask != nil else {
            return
        }

        startStopwatch()
    }

    // Renames the task without changing timing.
    @discardableResult
    func renameTask(_ taskText: String) -> Bool {
        guard currentTask != nil else {
            return false
        }

        let trimmedTask = taskText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTask.isEmpty else {
            return false
        }

        currentTask = trimmedTask
        return true
    }

    // Clears the task and resets timer state.
    func completeCurrentTask() {
        currentTask = nil
        resetStopwatch()
    }

    // Initializes a fresh running stopwatch state.
    private func startStopwatch() {
        stopRefreshTimer()
        accumulatedElapsedTime = 0
        elapsedTime = 0
        currentRunStartedAt = Date()
        isStopwatchRunning = true
        startRefreshTimer()
    }

    // Clears all stopwatch state to inactive.
    private func resetStopwatch() {
        stopRefreshTimer()
        accumulatedElapsedTime = 0
        elapsedTime = 0
        currentRunStartedAt = nil
        isStopwatchRunning = false
    }

    // Starts UI refresh ticks for elapsed time.
    private func startRefreshTimer() {
        stopRefreshTimer()

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshElapsedTime()
        }

        stopwatchTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    // Stops any active elapsed-time refresh timer.
    private func stopRefreshTimer() {
        stopwatchTimer?.invalidate()
        stopwatchTimer = nil
    }

    // Recalculates elapsed time from timestamps.
    private func refreshElapsedTime(now: Date = Date()) {
        guard let currentRunStartedAt else {
            elapsedTime = accumulatedElapsedTime
            return
        }

        let currentRunElapsedTime = max(0, now.timeIntervalSince(currentRunStartedAt))
        elapsedTime = accumulatedElapsedTime + currentRunElapsedTime
    }

    // Converts elapsed seconds into display text.
    private static func formatElapsedTime(_ elapsedTime: TimeInterval) -> String {
        let totalSeconds = Int(elapsedTime)
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
