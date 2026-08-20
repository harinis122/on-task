//
//  FocusSession.swift
//  OnTask
//  Purpose: Source of truth for the current focus session.
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

    var hasCurrentTask: Bool {
        currentTask != nil
    }

    var requiresQuitConfirmation: Bool {
        hasCurrentTask
    }

    var elapsedTimeText: String {
        Self.formatElapsedTime(elapsedTime)
    }

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

    func resumeStopwatch() {
        guard currentTask != nil, !isStopwatchRunning else {
            return
        }

        currentRunStartedAt = Date()
        isStopwatchRunning = true
        startRefreshTimer()
    }

    func restartStopwatch() {
        guard currentTask != nil else {
            return
        }

        startStopwatch()
    }

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

    func completeCurrentTask() {
        currentTask = nil
        resetStopwatch()
    }

    private func startStopwatch() {
        stopRefreshTimer()
        accumulatedElapsedTime = 0
        elapsedTime = 0
        currentRunStartedAt = Date()
        isStopwatchRunning = true
        startRefreshTimer()
    }

    private func resetStopwatch() {
        stopRefreshTimer()
        accumulatedElapsedTime = 0
        elapsedTime = 0
        currentRunStartedAt = nil
        isStopwatchRunning = false
    }

    private func startRefreshTimer() {
        stopRefreshTimer()

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshElapsedTime()
        }

        stopwatchTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopRefreshTimer() {
        stopwatchTimer?.invalidate()
        stopwatchTimer = nil
    }

    private func refreshElapsedTime(now: Date = Date()) {
        guard let currentRunStartedAt else {
            elapsedTime = accumulatedElapsedTime
            return
        }

        let currentRunElapsedTime = max(0, now.timeIntervalSince(currentRunStartedAt))
        elapsedTime = accumulatedElapsedTime + currentRunElapsedTime
    }

    private static func formatElapsedTime(_ elapsedTime: TimeInterval) -> String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
