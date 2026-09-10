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
    private(set) var timingMode: TimingMode = .stopwatch
    private(set) var activeElapsedTime: TimeInterval = 0
    private(set) var displayedTime: TimeInterval = 0
    private(set) var isTimingRunning = false
    private(set) var isTimeVisible = true
    private(set) var isTimerExpired = false

    @ObservationIgnored private var sessionClock = SessionClock()
    @ObservationIgnored private let alarmSoundService: AlarmSoundPlaying
    @ObservationIgnored private let focusAlertService: FocusAlertScheduling
    @ObservationIgnored private var refreshTimer: Timer?

    // Creates a focus session with service support.
    init(
        alarmSoundService: AlarmSoundPlaying = AlarmSoundService(),
        focusAlertService: FocusAlertScheduling = FocusAlertService()
    ) {
        self.alarmSoundService = alarmSoundService
        self.focusAlertService = focusAlertService
    }

    // Reports whether a task is currently active.
    var hasCurrentTask: Bool {
        currentTask != nil
    }

    // Indicates whether quitting needs user confirmation.
    var requiresQuitConfirmation: Bool {
        hasCurrentTask
    }

    // Preserves old running name for existing callers.
    var isStopwatchRunning: Bool {
        isTimingRunning
    }

    // Preserves old visibility name for existing callers.
    var isStopwatchVisible: Bool {
        isTimeVisible
    }

    // Formats visible time for menu display.
    var displayedTimeText: String {
        Self.formatTime(displayedTime)
    }

    // Preserves old display name for existing callers.
    var elapsedTimeText: String {
        displayedTimeText
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

    // Validates and starts a Stopwatch task.
    @discardableResult
    func startTask(_ taskText: String) -> Bool {
        startTask(taskText, timingMode: .stopwatch)
    }

    // Validates and starts a timed focus task.
    @discardableResult
    func startTask(_ taskText: String, timingMode: TimingMode, now: Date = Date()) -> Bool {
        let trimmedTask = taskText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTask.isEmpty else {
            return false
        }

        guard Self.isValidTimingMode(timingMode) else {
            return false
        }

        stopRefreshTimer()
        alarmSoundService.stopAlarm()
        currentTask = trimmedTask
        self.timingMode = timingMode
        isTimeVisible = true
        isTimerExpired = false
        sessionClock.start(now: now)
        refreshTimingState(now: now)
        startRefreshTimer()
        startFocusCheckInsForCurrentTask()
        return true
    }

    // Pauses timing and stores active elapsed time.
    func pauseTiming(now: Date = Date()) {
        guard isTimingRunning else {
            return
        }

        sessionClock.pause(now: now)
        refreshTimingState(now: now)
        stopRefreshTimer()
        focusAlertService.stopCheckIns()
    }

    // Preserves old pause name for existing callers.
    func pauseStopwatch() {
        pauseTiming()
    }

    // Resumes timing from accumulated active time.
    func resumeTiming(now: Date = Date()) {
        guard currentTask != nil, !isTimingRunning, !isTimerExpired else {
            return
        }

        sessionClock.resume(now: now)
        refreshTimingState(now: now)
        startRefreshTimer()
        startFocusCheckInsForCurrentTask()
    }

    // Preserves old resume name for existing callers.
    func resumeStopwatch() {
        resumeTiming()
    }

    // Restarts timing for the current task.
    func restartTiming(now: Date = Date()) {
        guard currentTask != nil else {
            return
        }

        alarmSoundService.stopAlarm()
        isTimerExpired = false
        sessionClock.restart(now: now)
        refreshTimingState(now: now)
        startRefreshTimer()
        startFocusCheckInsForCurrentTask()
    }

    // Preserves old restart name for existing callers.
    func restartStopwatch() {
        restartTiming()
    }

    // Recomputes timing for lifecycle and checks.
    func refreshTiming(now: Date = Date()) {
        refreshTimingState(now: now)
    }

    // Toggles whether displayed time is shown.
    func toggleTimeVisibility() {
        isTimeVisible.toggle()
    }

    // Preserves old visibility toggle name.
    func toggleStopwatchVisibility() {
        toggleTimeVisibility()
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
        restartFocusCheckInsAfterRename()
        return true
    }

    // Clears the task and resets timing state.
    func completeCurrentTask() {
        currentTask = nil
        resetTiming()
    }

    // Clears all timing state to inactive.
    private func resetTiming() {
        stopRefreshTimer()
        alarmSoundService.stopAlarm()
        focusAlertService.stopCheckIns()
        sessionClock.reset()
        timingMode = .stopwatch
        activeElapsedTime = 0
        displayedTime = 0
        isTimingRunning = false
        isTimeVisible = true
        isTimerExpired = false
    }

    // Starts UI refresh ticks for displayed time.
    private func startRefreshTimer() {
        stopRefreshTimer()

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshTimingState()
        }

        refreshTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    // Stops any active display refresh timer.
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // Starts check-ins for the current task.
    private func startFocusCheckInsForCurrentTask() {
        guard let currentTask else {
            return
        }

        focusAlertService.startCheckIns(
            for: currentTask,
            onPause: { [weak self] in
                self?.pauseTiming()
            },
            onEndSession: { [weak self] in
                self?.completeCurrentTask()
            }
        )
    }

    // Keeps check-in alert text aligned after rename.
    private func restartFocusCheckInsAfterRename() {
        guard isTimingRunning else {
            return
        }

        startFocusCheckInsForCurrentTask()
    }

    // Recalculates displayed time from clock state.
    private func refreshTimingState(now: Date = Date()) {
        activeElapsedTime = sessionClock.elapsedTime(now: now)
        displayedTime = timingMode.displayedTime(activeElapsedTime: activeElapsedTime)
        isTimingRunning = sessionClock.isRunning
        handleTimerExpirationIfNeeded(now: now)
    }

    // Starts completion behavior once when Timer expires.
    private func handleTimerExpirationIfNeeded(now: Date) {
        guard case let .timer(duration) = timingMode else {
            return
        }

        guard !isTimerExpired, activeElapsedTime >= duration else {
            return
        }

        isTimerExpired = true
        sessionClock.pause(now: now)
        activeElapsedTime = sessionClock.elapsedTime(now: now)
        displayedTime = 0
        isTimingRunning = false
        stopRefreshTimer()
        focusAlertService.stopCheckIns()
        alarmSoundService.startAlarm()
    }

    // Validates supported focus-session timing modes.
    private static func isValidTimingMode(_ timingMode: TimingMode) -> Bool {
        switch timingMode {
        case .stopwatch:
            return true
        case let .timer(duration):
            return duration > 0
        }
    }

    // Converts seconds into display text.
    private static func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
