//
//  MenuView.swift
//  OnTask
//  Purpose: Main menu-bar UI.
//  Created by Harini Suresh on 8/18/26.
//

import AppKit
import SwiftUI

struct OutlineButtonStyle: ButtonStyle {
    let isPrimary: Bool

    // Stores whether the button should appear primary (macOS accent color).
    init(isPrimary: Bool = false) {
        self.isPrimary = isPrimary
    }

    // Builds an adaptive rounded button appearance.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: isPrimary ? .semibold : .regular))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(isPrimary ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isPrimary ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Color.primary.opacity(isPrimary ? 0 : 0.18), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.65 : 1.0)
    }
}

struct MenuView: View {
    let focusSession: FocusSession

    @State private var taskText = ""
    @State private var selectedTimingOption = StartTimingOption.stopwatch
    @State private var timerMinutesText = "\(TimingMode.defaultTimerMinutes)"
    @State private var isRenamingTask = false
    @State private var renameText = ""

    // Displays task controls and quit access.
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let currentTask = focusSession.currentTask {
                currentTaskView(currentTask)
            } else {
                noTaskView
            }

            if focusSession.hasCurrentTask {
                Divider()
                    .opacity(0.45)

                timeVisibilityToggle
            }

            Divider()
                .opacity(0.45)

            Button("Quit OnTask") {
                requestQuit()
            }
            .buttonStyle(OutlineButtonStyle())
            .keyboardShortcut("q")
        }
        .padding(10)
        .frame(width: 224)
        .foregroundStyle(Color.primary)
    }

    // Shows the empty-state task creation form.
    private var noTaskView: some View {
        VStack(spacing: 10) {
            Text("What's your current task?")
                .font(.headline)

            TextField("e.g. Finish report", text: $taskText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
                .onSubmit(startTask)

            timingModePicker

            if selectedTimingOption == .timer {
                timerDurationInput
            }

            Button("Start Task", action: startTask)
                .buttonStyle(OutlineButtonStyle(isPrimary: true))
                .disabled(!canStartTask)
        }
        .frame(maxWidth: .infinity)
    }

    // Shows Stopwatch and Timer start options.
    private var timingModePicker: some View {
        Picker("Timing mode", selection: $selectedTimingOption) {
            ForEach(StartTimingOption.allCases) { option in
                Text(option.title)
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    // Shows the Timer duration text input.
    private var timerDurationInput: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("How many minutes?")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("25", text: $timerMinutesText)
                .textFieldStyle(.roundedBorder)
                .onSubmit(startTask)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Reports whether current start input is valid.
    private var canStartTask: Bool {
        let hasTaskText = !taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        guard hasTaskText else {
            return false
        }

        if selectedTimingOption == .timer {
            return selectedTimingMode != nil
        }

        return true
    }

    // Converts start selection into model timing mode.
    private var selectedTimingMode: TimingMode? {
        switch selectedTimingOption {
        case .stopwatch:
            return .stopwatch
        case .timer:
            return TimingMode.timer(minutesText: timerMinutesText)
        }
    }

    // Chooses active display or rename editor.
    private func currentTaskView(_ currentTask: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if isRenamingTask {
                renameTaskView
            } else {
                activeTaskView(currentTask)
            }
        }
    }

    // Displays task, time, and session controls.
    private func activeTaskView(_ currentTask: String) -> some View {
        VStack(spacing: 8) {
            Text(currentTask)
                .font(.system(size: 14, weight: .bold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            timeDisplay

            if focusSession.isTimerExpired {
                timerExpiredLabel
            } else if focusSession.isTimingRunning {
                Button {
                    focusSession.pauseTiming()
                } label: {
                    Label("Pause", systemImage: "pause")
                }
                .buttonStyle(OutlineButtonStyle(isPrimary: true))
            } else {
                Button {
                    focusSession.resumeTiming()
                } label: {
                    Label("Resume", systemImage: "play")
                }
                .buttonStyle(OutlineButtonStyle(isPrimary: true))
            }

            Button {
                focusSession.restartTiming()
            } label: {
                Label("Restart", systemImage: "arrow.clockwise")
            }
            .buttonStyle(OutlineButtonStyle())

            Button {
                beginRename(currentTask)
            } label: {
                Label("Rename task", systemImage: "pencil")
            }
            .buttonStyle(OutlineButtonStyle())

            Button {
                focusSession.completeCurrentTask()
                cancelRename()
            } label: {
                Label("Done", systemImage: "checkmark")
            }
            .buttonStyle(OutlineButtonStyle())
        }
        .frame(maxWidth: .infinity)
    }

    // Shows elapsed/remaining time or hidden indicator.
    private var timeDisplay: some View {
        Group {
            if focusSession.isTimeVisible {
                Text(focusSession.displayedTimeText)
                    .font(.system(size: 22, weight: .regular, design: .monospaced))
            } else {
                Image(systemName: "eye.slash")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Time hidden")
            }
        }
        .frame(height: 27)
    }

    // Shows Timer expiration status.
    private var timerExpiredLabel: some View {
        Label("Timer complete", systemImage: "bell")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
    }

    // Shows switch for time visibility.
    private var timeVisibilityToggle: some View {
        HStack {
            Text("Show time")
                .font(.system(size: 15, weight: .regular))

            Spacer()

            Toggle("", isOn: timeVisibilityBinding)
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.9)
                .tint(Color(nsColor: .controlAccentColor))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, -2)
    }

    // Bridges toggle changes to FocusSession behavior.
    private var timeVisibilityBinding: Binding<Bool> {
        Binding(
            get: {
                focusSession.isTimeVisible
            },
            set: { isVisible in
                guard focusSession.isTimeVisible != isVisible else {
                    return
                }

                focusSession.toggleTimeVisibility()
            }
        )
    }

    // Shows controls for editing the task name.
    private var renameTaskView: some View {
        VStack(spacing: 8) {
            TextField("Current task", text: $renameText)
                .textFieldStyle(.roundedBorder)
                .onSubmit(saveRename)

            HStack(spacing: 8) {
                Button("Save") {
                    saveRename()
                }
                .buttonStyle(OutlineButtonStyle(isPrimary: true))
                .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Cancel") {
                    cancelRename()
                }
                .buttonStyle(OutlineButtonStyle())
            }
        }
    }

    // Starts a validated task through FocusSession.
    private func startTask() {
        guard let selectedTimingMode else {
            return
        }

        guard focusSession.startTask(taskText, timingMode: selectedTimingMode) else {
            return
        }

        taskText = ""
        selectedTimingOption = .stopwatch
        timerMinutesText = "\(TimingMode.defaultTimerMinutes)"
    }

    // Enters rename mode with current text.
    private func beginRename(_ currentTask: String) {
        renameText = currentTask
        isRenamingTask = true
    }

    // Saves a valid renamed task value.
    private func saveRename() {
        guard focusSession.renameTask(renameText) else {
            return
        }

        cancelRename()
    }

    // Exits rename mode without session changes.
    private func cancelRename() {
        renameText = ""
        isRenamingTask = false
    }

    // Confirms destructive quit when a task exists.
    private func requestQuit() {
        guard focusSession.requiresQuitConfirmation else {
            terminateApp()
            return
        }

        let alert = NSAlert()
        alert.messageText = "Quit OnTask?"
        alert.informativeText = "Quitting will discard your current task and timing state. This in-memory session cannot be restored."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")
        alert.buttons.first?.keyEquivalent = ""
        alert.buttons.last?.keyEquivalent = "\u{1b}"

        if alert.runModal() == .alertFirstButtonReturn {
            terminateApp()
        }
    }

    // Terminates OnTask through the shared application.
    private func terminateApp() {
        NSApplication.shared.terminate(nil)
    }
}

private extension MenuView {
    enum StartTimingOption: String, CaseIterable, Identifiable {
        case stopwatch
        case timer

        // Uses the raw value as stable identity.
        var id: String {
            rawValue
        }

        // Provides display text for the picker.
        var title: String {
            switch self {
            case .stopwatch:
                return "Stopwatch"
            case .timer:
                return "Timer"
            }
        }
    }
}
