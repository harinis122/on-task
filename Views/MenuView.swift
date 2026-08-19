//
//  MenuView.swift
//  OnTask
//  Purpose: Main menu-bar UI for the current MVP milestone.
//  Created by Harini Suresh on 8/18/26.
//

import AppKit
import SwiftUI

struct MenuView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("No current task")
                .font(.headline)

            Text("OnTask is running from the menu bar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            Button("Quit OnTask") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 240)
    }
}
