//
//  FocusSession.swift
//  OnTask
//  Purpose: Source of truth for the current focus session.
//  Created by Harini Suresh on 8/18/26.
//

import Foundation
import Observation

@Observable
final class FocusSession {
    private static let menuBarTaskCharacterLimit = 20

    private(set) var currentTask: String?

    var hasCurrentTask: Bool {
        currentTask != nil
    }

    var menuBarTaskTitle: String? {
        guard let currentTask else {
            return nil
        }

        if currentTask.count <= Self.menuBarTaskCharacterLimit {
            return currentTask
        }

        let truncatedText = currentTask.prefix(Self.menuBarTaskCharacterLimit)
        return "\(truncatedText)..."
    }

    @discardableResult
    func startTask(_ taskText: String) -> Bool {
        let trimmedTask = taskText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTask.isEmpty else {
            return false
        }

        currentTask = trimmedTask
        return true
    }
}
