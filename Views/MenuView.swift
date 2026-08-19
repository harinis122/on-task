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
        VStack(spacing: 8) {
            Text("Current task")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(currentTask)
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func startTask() {
        guard focusSession.startTask(taskText) else {
            return
        }

        taskText = ""
    }
}
