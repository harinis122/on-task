//
//  OnTaskApp.swift
//  OnTask
//  Purpose: App entry point; creates the menu-bar app and connects MenuView.
//  Created by Harini Suresh on 8/18/26.
//

import AppKit
import SwiftUI

@main
struct OnTaskApp: App {
    @State private var focusSession = FocusSession()

    // Configures OnTask as a menu-bar accessory app.
    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    // Builds the menu-bar scene and task label.
    var body: some Scene {
        MenuBarExtra {
            MenuView(focusSession: focusSession)
        } label: {
            if let taskTitle = focusSession.menuBarTaskTitle {
                Text(taskTitle)
            } else {
                Image(systemName: "smallcircle.filled.circle")
                    .accessibilityLabel("OnTask")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
