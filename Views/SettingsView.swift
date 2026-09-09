//
//  SettingsView.swift
//  OnTask
//
//  Created by Harini Suresh on 9/8/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("focusCheckInsEnabled") private var focusCheckInsEnabled = true
    @AppStorage("focusCheckInIntervalMinutes") private var focusCheckInIntervalMinutes = 15

    private let checkInIntervals = [5, 10, 15, 20, 30, 45, 60]

    // Displays persistent app preference controls.
    var body: some View {
        Form {
            Section("Focus Check-Ins") {
                Toggle("Enable focus check-ins", isOn: $focusCheckInsEnabled)

                Picker("Remind me every", selection: $focusCheckInIntervalMinutes) {
                    ForEach(checkInIntervals, id: \.self) { minutes in
                        Text("\(minutes) minutes")
                            .tag(minutes)
                    }
                }
                .disabled(!focusCheckInsEnabled)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 360)
    }
}
