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

    var body: some View {
        VStack(spacing: 12) {
            if let currentTask = focusSession.currentTask {
                currentTaskView(currentTask)
            } else {
                noTaskView
            }

            Divider()

            Button("Quit OnTask") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 260)
    }

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

    private func startTask() {
        guard focusSession.startTask(taskText) else {
            return
        }

        taskText = ""
    }

    private func beginRename(_ currentTask: String) {
        renameText = currentTask
        isRenamingTask = true
    }

    private func saveRename() {
        guard focusSession.renameTask(renameText) else {
            return
        }

        cancelRename()
    }

    private func cancelRename() {
        renameText = ""
        isRenamingTask = false
    }
}
