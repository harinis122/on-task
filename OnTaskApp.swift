//
//  OnTaskApp.swift
//  OnTask
//  Purpose: App entry point; creates the menu-bar app and connects MenuView.
//  Created by Harini Suresh on 8/18/26.
//

import AppKit
import Observation
import SwiftUI

@main
struct OnTaskApp: App {
    @NSApplicationDelegateAdaptor(OnTaskAppDelegate.self) private var appDelegate

    // Provides the required SwiftUI scene without windows.
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class OnTaskAppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let focusSession = FocusSession()
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?

    // Configures the menu-bar app after launch.
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        configurePopover()
        configureStatusItem()
        observeSystemColorChanges()
        observeStateChanges()
        updateStatusItem()
    }

    // Closes the popover when focus moves away.
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        true
    }

    // Creates the SwiftUI menu popover content.
    private func configurePopover() {
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: MenuView(focusSession: focusSession)
        )
    }

    // Creates the native menu-bar item.
    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.wantsLayer = true
        statusItem.button?.layer?.cornerRadius = 5
        statusItem.button?.layer?.masksToBounds = true
        self.statusItem = statusItem
    }

    // Refreshes accent colors after system changes.
    private func observeSystemColorChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemColorsDidChange),
            name: NSColor.systemColorsDidChangeNotification,
            object: nil
        )
    }

    // Re-renders status item when observed state changes.
    private func observeStateChanges() {
        withObservationTracking {
            _ = focusSession.menuBarTaskTitle
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.updateStatusItem()
                self?.observeStateChanges()
            }
        }
    }

    // Applies native icon or task text display.
    private func updateStatusItem() {
        guard let statusItem, let button = statusItem.button else {
            return
        }

        if let taskTitle = focusSession.menuBarTaskTitle {
            button.image = nil
            button.title = taskTitle
            button.contentTintColor = nil
            button.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.28).cgColor
            statusItem.length = NSStatusItem.variableLength
        } else {
            button.title = ""
            button.image = statusIconImage(color: .controlAccentColor)
            button.contentTintColor = nil
            button.layer?.backgroundColor = NSColor.clear.cgColor
            statusItem.length = 28
        }
    }

    // Draws checked icon using system accent color.
    private func statusIconImage(color: NSColor) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))

        image.lockFocus()
        color.setStroke()

        let boxPath = NSBezierPath(roundedRect: NSRect(x: 2.5, y: 2.5, width: 13, height: 13), xRadius: 2.5, yRadius: 2.5)
        boxPath.lineWidth = 1.7
        boxPath.stroke()

        let checkPath = NSBezierPath()
        checkPath.lineWidth = 1.9
        checkPath.lineCapStyle = .round
        checkPath.lineJoinStyle = .round
        checkPath.move(to: NSPoint(x: 5.2, y: 9.1))
        checkPath.line(to: NSPoint(x: 8, y: 6.4))
        checkPath.line(to: NSPoint(x: 12.8, y: 11.5))
        checkPath.stroke()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    // Refreshes status item after accent changes.
    @objc private func systemColorsDidChange() {
        updateStatusItem()
    }

    // Opens or closes the SwiftUI menu popover.
    @objc private func togglePopover() {
        guard let button = statusItem?.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
