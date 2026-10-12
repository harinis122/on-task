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
            SettingsView()
        }
    }
}

final class OnTaskAppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private static let reservedMenuBarTimeText = "00:00:00"
    private static let activeTaskTitleMaxWidth: CGFloat = 84
    private static let activeStatusItemHorizontalPadding: CGFloat = 24
    private static let activeStatusItemIconWidth: CGFloat = 13
    private static let activeStatusItemIconSpacing: CGFloat = 8
    private static let menuBarIconTitleSpacing = " "
    private static let menuBarSeparator = " · "

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
            _ = focusSession.displayedTimeText
            _ = focusSession.isTimeVisible
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
            let displayTaskTitle = truncatedTaskTitle(taskTitle, button: button)

            button.image = activeStatusIconImage()
            button.imagePosition = .imageLeading
            button.imageScaling = .scaleProportionallyDown
            button.attributedTitle = menuBarAttributedTitle(for: displayTaskTitle, button: button)
            button.contentTintColor = NSColor.labelColor.withAlphaComponent(0.85)
            button.layer?.cornerRadius = max(button.bounds.height / 2, 5)
            button.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.28).cgColor
            statusItem.length = activeStatusItemLength(for: displayTaskTitle, button: button)
        } else {
            button.attributedTitle = NSAttributedString(string: "")
            button.title = ""
            button.image = statusIconImage()
            button.imagePosition = .imageOnly
            button.contentTintColor = nil
            button.layer?.cornerRadius = 5
            button.layer?.backgroundColor = NSColor.clear.cgColor
            statusItem.length = 28
        }
    }

    // Combines the task title with visible Stopwatch or Timer time.
    private func menuBarAttributedTitle(for taskTitle: String, button: NSStatusBarButton) -> NSAttributedString {
        let font = button.font ?? NSFont.menuBarFont(ofSize: 0)
        let timeFont = NSFont.monospacedDigitSystemFont(ofSize: font.pointSize, weight: .regular)
        let title = NSMutableAttributedString(
            string: "\(Self.menuBarIconTitleSpacing)\(taskTitle)",
            attributes: [.font: font, .foregroundColor: NSColor.labelColor]
        )

        guard focusSession.isTimeVisible else {
            return title
        }

        title.append(
            NSAttributedString(
                string: Self.menuBarSeparator,
                attributes: [.font: font, .foregroundColor: NSColor.labelColor.withAlphaComponent(0.4)]
            )
        )
        title.append(
            NSAttributedString(
                string: focusSession.displayedTimeText,
                attributes: [.font: timeFont, .foregroundColor: NSColor.labelColor]
            )
        )

        return title
    }

    // Truncates task text by rendered width so the Timer remains fully visible.
    private func truncatedTaskTitle(_ taskTitle: String, button: NSStatusBarButton) -> String {
        let font = button.font ?? NSFont.menuBarFont(ofSize: 0)

        guard textWidth(taskTitle, font: font) > Self.activeTaskTitleMaxWidth else {
            return taskTitle
        }

        let ellipsis = "..."
        var truncatedTitle = taskTitle

        while !truncatedTitle.isEmpty {
            truncatedTitle.removeLast()

            if textWidth("\(truncatedTitle)\(ellipsis)", font: font) <= Self.activeTaskTitleMaxWidth {
                return "\(truncatedTitle)\(ellipsis)"
            }
        }

        return ellipsis
    }

    // Reserves enough menu-bar width for an hours-format time value.
    private func activeStatusItemLength(for taskTitle: String, button: NSStatusBarButton) -> CGFloat {
        let font = button.font ?? NSFont.menuBarFont(ofSize: 0)
        let timeFont = NSFont.monospacedDigitSystemFont(ofSize: font.pointSize, weight: .regular)
        let taskWidth = textWidth(taskTitle, font: font)
        let titleSpacingWidth = textWidth(Self.menuBarIconTitleSpacing, font: font)
        let iconWidth = Self.activeStatusItemIconWidth + Self.activeStatusItemIconSpacing

        guard focusSession.isTimeVisible else {
            return ceil(iconWidth + titleSpacingWidth + taskWidth + Self.activeStatusItemHorizontalPadding)
        }

        let separatorWidth = textWidth(Self.menuBarSeparator, font: font)
        let timeWidth = textWidth(Self.reservedMenuBarTimeText, font: timeFont)

        return ceil(iconWidth + titleSpacingWidth + taskWidth + separatorWidth + timeWidth + Self.activeStatusItemHorizontalPadding)
    }

    // Measures menu-bar text using its rendered font.
    private func textWidth(_ text: String, font: NSFont) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: font]).width
    }

    // Draws the active task checkmark as a single template stroke.
    private func activeStatusIconImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 13, height: 13))

        image.lockFocus()
        NSColor.black.setStroke()

        let checkPath = NSBezierPath()
        checkPath.lineWidth = 1.35
        checkPath.lineCapStyle = .round
        checkPath.lineJoinStyle = .round
        checkPath.move(to: NSPoint(x: 2.2, y: 6.8))
        checkPath.line(to: NSPoint(x: 5.2, y: 3.8))
        checkPath.line(to: NSPoint(x: 10.8, y: 9.6))
        checkPath.stroke()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    // Draws template icon for system contrast.
    private func statusIconImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))

        image.lockFocus()
        NSColor.black.setStroke()

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
        image.isTemplate = true // tells macOS to apply template-image rendering rules
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
