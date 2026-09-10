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
    func startCheckIns(
        for task: String,
        onPause: @escaping () -> Void,
        onEndSession: @escaping () -> Void
    )

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
    private var pauseAction: (() -> Void)?
    private var endSessionAction: (() -> Void)?
    private var settingsObserver: NSObjectProtocol?

    // Creates alert scheduling with persisted settings.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        observeSettingsChanges()
    }

    // Starts repeating check-ins when settings allow them.
    func startCheckIns(
        for task: String,
        onPause: @escaping () -> Void,
        onEndSession: @escaping () -> Void
    ) {
        stopCheckIns()
        activeTask = task
        pauseAction = onPause
        endSessionAction = onEndSession

        guard areCheckInsEnabled else {
            return
        }

        scheduleNextCheckIn()
    }

    // Cancels scheduled check-ins and visible alerts.
    func stopCheckIns() {
        activeTask = nil
        pauseAction = nil
        endSessionAction = nil
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
        } onPause: { [weak self] in
            self?.handlePauseRequest()
        } onEndSession: { [weak self] in
            self?.handleEndSessionRequest()
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 220),
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

    // Reuses the focus session's pause behavior.
    private func handlePauseRequest() {
        let pauseAction = pauseAction
        closeCheckInPanel()
        pauseAction?()
    }

    // Reuses the focus session's end behavior.
    private func handleEndSessionRequest() {
        let endSessionAction = endSessionAction
        closeCheckInPanel()
        endSessionAction?()
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
    let onPause: () -> Void
    let onEndSession: () -> Void

    // Displays the custom still-on-task prompt.
    var body: some View {
        VStack(spacing: 10) {
            Text("Still on task?")
                .font(.system(size: 21, weight: .bold))

            taskSentence
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                Button(action: onConfirm) {
                    Label("Yes, still on it", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryCheckInButtonStyle())
                .keyboardShortcut(.defaultAction)

                Button(action: onConfirm) {
                    Label("Drifted — refocusing now", systemImage: "scope")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(OutlinedCheckInButtonStyle())
            }

            Divider()

            HStack(spacing: 14) {
                Button("Pause", action: onPause)
                    .buttonStyle(SecondaryCheckInButtonStyle())

                Button("End session", action: onEndSession)
                    .buttonStyle(SecondaryCheckInButtonStyle())
            }
        }
        .padding(14)
        .frame(width: 280)
        .background(.regularMaterial)
    }

    // Builds the sentence with styled task text.
    private var taskSentence: Text {
        Text("You've been focusing on ")
            .foregroundStyle(.secondary)
        + Text(task)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
        + Text("!")
            .foregroundStyle(.secondary)
    }
}

private struct PrimaryCheckInButtonStyle: ButtonStyle {
    // Builds the filled primary check-in action.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.white)
            .padding(.vertical, 9)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor)
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

private struct OutlinedCheckInButtonStyle: ButtonStyle {
    // Builds the quieter outlined check-in action.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.primary)
            .padding(.vertical, 9)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.42))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.32), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.68 : 1)
    }
}

private struct SecondaryCheckInButtonStyle: ButtonStyle {
    // Builds compact muted secondary alert actions.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(Color.secondary.opacity(0.28), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
