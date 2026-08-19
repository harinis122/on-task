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
    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuView()
        } label: {
            Image(systemName: "smallcircle.filled.circle")
                .accessibilityLabel("OnTask")
        }
        .menuBarExtraStyle(.window)
    }
}
