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

                stopwatchVisibilityToggle
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

            Button("Start Task", action: startTask)
                .buttonStyle(OutlineButtonStyle(isPrimary: true))
                .disabled(taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .frame(maxWidth: .infinity)
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

    // Displays task, timer, and session controls.
    private func activeTaskView(_ currentTask: String) -> some View {
        VStack(spacing: 8) {
            Text(currentTask)
                .font(.system(size: 14, weight: .bold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            stopwatchDisplay

            if focusSession.isStopwatchRunning {
                Button {
                    focusSession.pauseStopwatch()
                } label: {
                    Label("Pause", systemImage: "pause")
                }
                .buttonStyle(OutlineButtonStyle(isPrimary: true))
            } else {
                Button {
                    focusSession.resumeStopwatch()
                } label: {
                    Label("Resume", systemImage: "play")
                }
                .buttonStyle(OutlineButtonStyle(isPrimary: true))
            }

            Button {
                focusSession.restartStopwatch()
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

    // Shows elapsed time or hidden indicator.
    private var stopwatchDisplay: some View {
        Group {
            if focusSession.isStopwatchVisible {
                Text(focusSession.elapsedTimeText)
                    .font(.system(size: 22, weight: .regular, design: .monospaced))
            } else {
                Image(systemName: "eye.slash")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Stopwatch hidden")
            }
        }
        .frame(height: 27)
    }

    // Shows switch for stopwatch visibility.
    private var stopwatchVisibilityToggle: some View {
        HStack {
            Text("Show stopwatch")
                .font(.system(size: 15, weight: .regular))

            Spacer()

            Toggle("", isOn: stopwatchVisibilityBinding)
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.9)
                .tint(Color(nsColor: .controlAccentColor))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, -2)
    }

    // Bridges toggle changes to FocusSession behavior.
    private var stopwatchVisibilityBinding: Binding<Bool> {
        Binding(
            get: {
                focusSession.isStopwatchVisible
            },
            set: { isVisible in
                guard focusSession.isStopwatchVisible != isVisible else {
                    return
                }

                focusSession.toggleStopwatchVisibility()
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
        guard focusSession.startTask(taskText) else {
            return
        }

        taskText = ""
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
        alert.informativeText = "Quitting will discard your current task and stopwatch state. This in-memory session cannot be restored."
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
