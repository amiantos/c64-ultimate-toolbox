// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

@main
struct C64U_ViewerApp: App {
    @State private var connection = C64Connection()
    @State private var showingSaveAsAlert = false
    @State private var menuPresetName = ""

    var body: some Scene {
        WindowGroup {
            ContentView(connection: connection)
                .alert("Save As New Preset", isPresented: $showingSaveAsAlert) {
                    TextField("Preset Name", text: $menuPresetName)
                    Button("Save") {
                        guard !menuPresetName.isEmpty else { return }
                        let id = connection.presetManager.saveAsCustom(
                            name: menuPresetName,
                            settings: connection.crtSettings
                        )
                        connection.presetManager.selectedIdentifier = .custom(id)
                        menuPresetName = ""
                    }
                    Button("Cancel", role: .cancel) { menuPresetName = "" }
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 768, height: 544)
        .commands {
            CommandMenu("Stream") {
                Button("Disconnect") {
                    connection.disconnect()
                }
                .keyboardShortcut("d", modifiers: .command)
                .disabled(!connection.isConnected)

                Divider()

                Button("Volume Up") {
                    connection.volume = min(1.0, connection.volume + 0.1)
                    connection.isMuted = false
                }
                .keyboardShortcut(.upArrow, modifiers: .command)

                Button("Volume Down") {
                    connection.volume = max(0.0, connection.volume - 0.1)
                    connection.isMuted = false
                }
                .keyboardShortcut(.downArrow, modifiers: .command)

                Button(connection.isMuted ? "Unmute" : "Mute") {
                    connection.isMuted.toggle()
                    connection.audioPlayer.volume = connection.isMuted ? 0.0 : connection.volume
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }

            CommandMenu("Capture") {
                Button("Take Screenshot") {
                    connection.takeScreenshot()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(!connection.isConnected)

                Button(connection.isRecording ? "Stop Recording" : "Start Recording") {
                    connection.toggleRecording()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!connection.isConnected)
            }

            CommandMenu("Preset") {
                ForEach(CRTPreset.allCases) { preset in
                    let isSelected = connection.presetManager.selectedIdentifier == .builtIn(preset)
                    let modified = connection.presetManager.isModified(preset)
                    Button {
                        connection.selectPreset(.builtIn(preset))
                    } label: {
                        let name = modified ? "\(preset.rawValue) *" : preset.rawValue
                        if isSelected {
                            Text("\(name)  ✓")
                        } else {
                            Text(name)
                        }
                    }
                }

                Divider()

                ForEach(connection.presetManager.customPresets) { custom in
                    let isSelected = connection.presetManager.selectedIdentifier == .custom(custom.id)
                    Button {
                        connection.selectPreset(.custom(custom.id))
                    } label: {
                        if isSelected {
                            Text("\(custom.name)  ✓")
                        } else {
                            Text(custom.name)
                        }
                    }
                }

                Divider()

                Button("Save As New Preset...") {
                    showingSaveAsAlert = true
                }

                if case .builtIn(let preset) = connection.presetManager.selectedIdentifier,
                   connection.presetManager.isModified(preset) {
                    Button("Reset to Default") {
                        connection.presetManager.resetBuiltIn(preset)
                        connection.selectPreset(.builtIn(preset))
                    }
                }

                if case .custom(let id) = connection.presetManager.selectedIdentifier {
                    Button("Delete Preset") {
                        connection.presetManager.deleteCustom(id: id)
                        connection.crtSettings = connection.presetManager.settings(
                            for: connection.presetManager.selectedIdentifier
                        )
                    }
                }
            }
        }
    }
}
