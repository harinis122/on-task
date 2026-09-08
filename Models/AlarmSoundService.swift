//
//  AlarmSoundService.swift
//  OnTask
//  Purpose: Plays and stops Timer completion alarm sounds.
//  Created by Harini Suresh on 9/8/26.
//

import AppKit
import Foundation

protocol AlarmSoundPlaying: AnyObject {
    // Starts repeating alarm playback.
    func startAlarm()

    // Stops any active alarm playback.
    func stopAlarm()
}

final class AlarmSoundService: AlarmSoundPlaying {
    private var alarmTimer: Timer?

    // Reports whether alarm playback is active.
    var isAlarmPlaying: Bool {
        alarmTimer != nil
    }

    // Starts repeating native alarm playback.
    func startAlarm() {
        guard alarmTimer == nil else {
            return
        }

        playAlarmSound()

        let timer = Timer(timeInterval: 1.5, repeats: true) { _ in
            Self.playSystemBeep()
        }

        alarmTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    // Stops any active alarm playback.
    func stopAlarm() {
        alarmTimer?.invalidate()
        alarmTimer = nil
    }

    // Ensures alarm playback ends when released.
    deinit {
        stopAlarm()
    }

    // Plays one immediate alarm sound tick.
    private func playAlarmSound() {
        Self.playSystemBeep()
    }

    // Uses the standard macOS alert sound.
    private static func playSystemBeep() {
        NSSound(named: "Basso")?.play()
    }
}
