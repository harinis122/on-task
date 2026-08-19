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

    @ObservationIgnored private var taskStartedAt: Date?
    @ObservationIgnored private var stopwatchTimer: Timer?

    var hasCurrentTask: Bool {
        currentTask != nil
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

    func completeCurrentTask() {
        currentTask = nil
        resetStopwatch()
    }

    private func startStopwatch() {
        stopwatchTimer?.invalidate()
        taskStartedAt = Date()
        elapsedTime = 0

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshElapsedTime()
        }

        stopwatchTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func resetStopwatch() {
        stopwatchTimer?.invalidate()
        stopwatchTimer = nil
        taskStartedAt = nil
        elapsedTime = 0
    }

    private func refreshElapsedTime(now: Date = Date()) {
        guard let taskStartedAt else {
            elapsedTime = 0
            return
        }

        elapsedTime = max(0, now.timeIntervalSince(taskStartedAt))
    }

    private static func formatElapsedTime(_ elapsedTime: TimeInterval) -> String {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
