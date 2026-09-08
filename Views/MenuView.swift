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
    
    // Timer Duration

    private enum TimerPreset: String, CaseIterable, Identifiable {
        case fifteenMinutes
        case thirtyMinutes
        case fortyFiveMinutes
        case oneHour
        case custom

        var id: Self { self }

        var title: String {
            switch self {
            case .fifteenMinutes:
                return "15m"
            case .thirtyMinutes:
                return "30m"
            case .fortyFiveMinutes:
                return "45m"
            case .oneHour:
                return "1h"
            case .custom:
                return "Custom"
            }
        }

        var duration: TimeInterval? {
            switch self {
            case .fifteenMinutes:
                return 15 * 60
            case .thirtyMinutes:
                return 30 * 60
            case .fortyFiveMinutes:
                return 45 * 60
            case .oneHour:
                return 60 * 60
            case .custom:
                return nil
            }
        }
    }

    @State private var selectedTimerPreset: TimerPreset = .thirtyMinutes

    @State private var customHours = 0
    @State private var customMinutes = 0
    @State private var customSeconds = 0


    // Timer UI

    private var timerDurationInput: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Duration")
                .font(.headline)

            // First row
            HStack(spacing: 12) {
                timerPresetButton(.fifteenMinutes)
                timerPresetButton(.thirtyMinutes)
                timerPresetButton(.fortyFiveMinutes)
            }

            // Second row
            HStack(spacing: 12) {
                timerPresetButton(.oneHour)
                timerPresetButton(.custom)

                Spacer()
            }

            // Only show custom controls when Custom is selected
            if selectedTimerPreset == .custom {
                customDurationPicker
                    .padding(.top, 4)
            }
        }
    }


    // Preset Button
    private func timerPresetButton(_ preset: TimerPreset) -> some View {
        Button {
            selectedTimerPreset = preset
        } label: {
            Text(preset.title)
                .font(.system(size: 14))
                .frame(minWidth: 25)
                .padding(.horizontal, 15)
                .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    selectedTimerPreset == preset
                        ? Color.primary.opacity(0.10)
                        : Color.clear
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    selectedTimerPreset == preset
                        ? Color.primary.opacity(0.55)
                        : Color.secondary.opacity(0.35),
                    lineWidth: 1
                )
        )
    }


    private var customDurationPicker: some View {
        HStack(spacing: 4) {
            durationPickerColumn(
                label: "hr",
                selection: $customHours,
                range: 0..<24
            )

            durationPickerColumn(
                label: "min",
                selection: $customMinutes,
                range: 0..<60
            )

            durationPickerColumn(
                label: "sec",
                selection: $customSeconds,
                range: 0..<60
            )
        }
        .pickerStyle(.menu)
    }

    private func durationPickerColumn(
        label: String,
        selection: Binding<Int>,
        range: Range<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Picker("", selection: selection) {
                ForEach(range, id: \.self) { value in
                    Text("\(value)")
                        .tag(value)
                }
            }
            .labelsHidden()

            Text(label)
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(.secondary)
                .padding(.leading, 11)
        }
    }


    // Selected Duration
    private var selectedTimerDuration: TimeInterval? {
        if let presetDuration = selectedTimerPreset.duration {
            return presetDuration
        }

        let totalSeconds =
            customHours * 3600 +
            customMinutes * 60 +
            customSeconds

        guard totalSeconds > 0 else {
            return nil
        }

        return TimeInterval(totalSeconds)
    }


    // Timing Mode

    private var selectedTimingMode: TimingMode? {
        switch selectedTimingOption {
        case .stopwatch:
            return .stopwatch

        case .timer:
            guard let duration = selectedTimerDuration else {
                return nil
            }

            return .timer(duration: duration)
        }
    }


    // Validation

    private var canStartTask: Bool {
        let hasTaskText =
            !taskText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty

        guard hasTaskText else {
            return false
        }

        if selectedTimingOption == .timer {
            return selectedTimerDuration != nil
        }

        return true
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
