//
//  FocusAlertService.swift
//  OnTask
//  Purpose: Schedules and presents focus check-in alerts.
//  Created by Harini Suresh on 9/8/26.
//

import AppKit
import Foundation
import SwiftUI

protocol FocusAlertScheduling: AnyObject {
    // Starts repeating check-ins for the active task.
    func startCheckIns(for task: String)

    // Cancels any scheduled or visible check-ins.
    func stopCheckIns()
}

final class FocusAlertService: FocusAlertScheduling {
    private static let enabledKey = "focusCheckInsEnabled"
    private static let intervalKey = "focusCheckInIntervalMinutes"
    private static let defaultIntervalMinutes = 15
    private static let allowedIntervals = [5, 10, 15, 20, 30, 45, 60]

    private let userDefaults: UserDefaults
    private var activeTask: String?
    private var alertPanel: NSPanel?
    private var checkInTimer: Timer?
    private var settingsObserver: NSObjectProtocol?

    // Creates alert scheduling with persisted settings.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        observeSettingsChanges()
    }

    // Starts repeating check-ins when settings allow them.
    func startCheckIns(for task: String) {
        stopCheckIns()
        activeTask = task

        guard areCheckInsEnabled else {
            return
        }

        scheduleNextCheckIn()
    }

    // Cancels scheduled check-ins and visible alerts.
    func stopCheckIns() {
        activeTask = nil
        checkInTimer?.invalidate()
        checkInTimer = nil
        closeCheckInPanel()
    }

    // Cleans up timers, observers, and panels.
    deinit {
        if let settingsObserver {
            NotificationCenter.default.removeObserver(settingsObserver)
        }

        stopCheckIns()
    }

    // Reads whether focus check-ins are enabled.
    private var areCheckInsEnabled: Bool {
        userDefaults.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    // Reads and normalizes the persisted interval.
    private var checkInIntervalMinutes: Int {
        let storedInterval = userDefaults.integer(forKey: Self.intervalKey)

        guard Self.allowedIntervals.contains(storedInterval) else {
            return Self.defaultIntervalMinutes
        }

        return storedInterval
    }

    // Watches Settings changes during active sessions.
    private func observeSettingsChanges() {
        settingsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSettingsChange()
        }
    }

    // Reschedules or stops after preference changes.
    private func handleSettingsChange() {
        guard activeTask != nil else {
            return
        }

        guard areCheckInsEnabled else {
            cancelScheduledAndVisibleCheckIn()
            return
        }

        guard alertPanel == nil else {
            return
        }

        scheduleNextCheckIn()
    }

    // Cancels current alert UI without ending tracking.
    private func cancelScheduledAndVisibleCheckIn() {
        checkInTimer?.invalidate()
        checkInTimer = nil
        closeCheckInPanel()
    }

    // Schedules the next in-app check-in alert.
    private func scheduleNextCheckIn() {
        checkInTimer?.invalidate()
        checkInTimer = nil

        guard let activeTask, areCheckInsEnabled else {
            return
        }

        let interval = TimeInterval(checkInIntervalMinutes * 60)
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            self?.showCheckInPanel(for: activeTask)
        }

        checkInTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    // Shows one custom check-in panel.
    private func showCheckInPanel(for task: String) {
        checkInTimer = nil

        guard activeTask == task, alertPanel == nil else {
            return
        }

        let contentView = FocusCheckInAlertView(task: task) { [weak self] in
            self?.handleCheckInAcknowledgement()
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 168),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.title = "Focus Check-In"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: contentView)
        panel.center()

        alertPanel = panel
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    // Handles the user's still-on-task response.
    private func handleCheckInAcknowledgement() {
        closeCheckInPanel()
        scheduleNextCheckIn()
    }

    // Closes the current custom check-in panel.
    private func closeCheckInPanel() {
        alertPanel?.close()
        alertPanel = nil
    }
}

private struct FocusCheckInAlertView: View {
    let task: String
    let onConfirm: () -> Void

    // Displays the custom still-on-task prompt.
    var body: some View {
        VStack(spacing: 14) {
            Text("Still on task?")
                .font(.headline)

            Text("You're currently focusing on \"\(task)\".")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Yes", action: onConfirm)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
        .padding(22)
        .frame(width: 320)
        .background(.regularMaterial)
    }
}
