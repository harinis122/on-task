//
//  TimingMode.swift
//  OnTask
//  Purpose: Describes how active session time is displayed.
//  Created by Harini Suresh on 9/8/26.
//

import Foundation

enum TimingMode: Equatable {
    case stopwatch
    case timer(duration: TimeInterval)

    static let defaultTimerMinutes = 25

    // Creates a Timer mode from validated minute text.
    static func timer(minutesText: String) -> TimingMode? {
        let trimmedText = minutesText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let minutes = Int(trimmedText), minutes > 0 else {
            return nil
        }

        return .timer(duration: TimeInterval(minutes * 60))
    }

    // Reports whether this mode counts downward.
    var isTimer: Bool {
        if case .timer = self {
            return true
        }

        return false
    }

    // Provides the configured Timer duration when present.
    var timerDuration: TimeInterval? {
        if case let .timer(duration) = self {
            return duration
        }

        return nil
    }

    // Converts active elapsed time into visible time.
    func displayedTime(activeElapsedTime: TimeInterval) -> TimeInterval {
        switch self {
        case .stopwatch:
            return activeElapsedTime
        case let .timer(duration):
            return max(duration - activeElapsedTime, 0)
        }
    }
}
