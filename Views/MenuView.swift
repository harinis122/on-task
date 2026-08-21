//
//  MenuView.swift
//  OnTask
//  Purpose: Main menu-bar UI for the current MVP milestone.
//  Created by Harini Suresh on 8/18/26.
//

import AppKit
import SwiftUI

struct MenuView: View {
    let focusSession: FocusSession

    @State private var taskText = ""
    @State private var isRenamingTask = false
    @State private var renameText = ""

    // Displays task controls and quit access.
    var body: some View {
        VStack(spacing: 12) {
            if let currentTask = focusSession.currentTask {
                currentTaskView(currentTask)
            } else {
                noTaskView
            }

            Divider()

            Button("Quit OnTask") {
                requestQuit()
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 260)
    }

    // Shows the empty-state task creation form.
    private var noTaskView: some View {
        VStack(spacing: 10) {
            Text("What are you doing?")
                .font(.headline)

            TextField("Current task", text: $taskText)
                .textFieldStyle(.roundedBorder)
                .onSubmit(startTask)

            Button("Start Task", action: startTask)
                .disabled(taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // Chooses active display or rename editor.
    private func currentTaskView(_ currentTask: String) -> some View {
        VStack(spacing: 10) {
            Text("Current task")
                .font(.caption)
                .foregroundStyle(.secondary)

            if isRenamingTask {
                renameTaskView
            } else {
                activeTaskView(currentTask)
            }
        }
    }

    // Displays task, timer, and session controls.
    private func activeTaskView(_ currentTask: String) -> some View {
        VStack(spacing: 10) {
            Text(currentTask)
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(focusSession.elapsedTimeText)
                .font(.system(.title2, design: .monospaced))

            if focusSession.isStopwatchRunning {
                Button("Pause") {
                    focusSession.pauseStopwatch()
                }
            } else {
                Button("Resume") {
                    focusSession.resumeStopwatch()
                }
            }

            Button("Restart") {
                focusSession.restartStopwatch()
            }

            Button("Rename task") {
                beginRename(currentTask)
            }

            Button("Done") {
                focusSession.completeCurrentTask()
                cancelRename()
            }
        }
    }

    // Shows controls for editing the task name.
    private var renameTaskView: some View {
        VStack(spacing: 10) {
            TextField("Current task", text: $renameText)
                .textFieldStyle(.roundedBorder)
                .onSubmit(saveRename)

            HStack(spacing: 8) {
                Button("Save") {
                    saveRename()
                }
                .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Cancel") {
                    cancelRename()
                }
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
