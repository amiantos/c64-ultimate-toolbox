// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
internal import UniformTypeIdentifiers

struct ToolboxOverlayView: View {
    @Bindable var connection: C64Connection
    let onDismiss: () -> Void

    @State private var showResetConfirm = false
    @State private var showRebootConfirm = false
    @State private var showPowerOffConfirm = false

    private let tileColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .onTapGesture { onDismiss() }

            ScrollView {
                VStack(spacing: 16) {
                    header
                    statusArea
                    deviceInfoTile
                    audioSection
                    presetSection
                    controlGrid
                }
                .padding(20)
            }
            .frame(width: 400)
            .frame(maxHeight: 560)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 20)
        }
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
        .confirmationDialog("Reset Machine?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { connection.machineAction(.reset) }
        }
        .confirmationDialog("Reboot Machine?", isPresented: $showRebootConfirm) {
            Button("Reboot", role: .destructive) { connection.machineAction(.reboot) }
        }
        .confirmationDialog("Power Off Machine?", isPresented: $showPowerOffConfirm) {
            Button("Power Off", role: .destructive) { connection.machineAction(.powerOff) }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Toolbox")
                .font(.title3)
                .fontWeight(.semibold)
            Spacer()
            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Status

    @ViewBuilder
    private var statusArea: some View {
        if connection.isWaitingForReboot {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Waiting for device to restart...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
        } else if let error = connection.connectionError {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Device Info

    @ViewBuilder
    private var deviceInfoTile: some View {
        if let info = connection.deviceInfo {
            HStack(spacing: 12) {
                Image(systemName: "desktopcomputer")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.product)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("v\(info.firmwareVersion) · \(info.hostname)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Audio

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Audio")
            VStack(spacing: 6) {
                SliderRow(label: "Volume", value: Binding(
                    get: { connection.volume },
                    set: {
                        connection.volume = $0
                        connection.isMuted = false
                    }
                ), range: 0...1)
                SliderRow(label: "Balance", value: $connection.balance, range: -1...1)
            }
            .padding(12)
            .background(.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Preset

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("CRT Preset")
            HStack(spacing: 12) {
                Image(systemName: "tv")
                    .font(.title2)
                    .foregroundStyle(.indigo)
                    .frame(width: 36)
                Picker("Preset", selection: Binding(
                    get: { connection.presetManager.selectedIdentifier },
                    set: { connection.selectPreset($0) }
                )) {
                    ForEach(CRTPreset.allCases) { preset in
                        let modified = connection.presetManager.isModified(preset)
                        Text(modified ? "\(preset.rawValue) *" : preset.rawValue)
                            .tag(PresetIdentifier.builtIn(preset))
                    }
                    if !connection.presetManager.customPresets.isEmpty {
                        Divider()
                        ForEach(connection.presetManager.customPresets) { custom in
                            Text(custom.name)
                                .tag(PresetIdentifier.custom(custom.id))
                        }
                    }
                }
                .labelsHidden()
                Spacer()
                Button("Customize") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(12)
            .background(.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Control Grid

    private var controlGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Controls")
            LazyVGrid(columns: tileColumns, spacing: 10) {
                if connection.streamsActive {
                    controlTile("Stop Streams", icon: "stop.circle.fill", color: .red) {
                        connection.stopStreams()
                    }
                } else {
                    controlTile("Start Streams", icon: "play.circle.fill", color: .green) {
                        connection.startStreams()
                    }
                }

                controlTile("Run File", icon: "doc.fill.badge.plus", color: .blue) {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = ["sid", "prg", "crt"].compactMap {
                        .init(filenameExtension: $0)
                    }
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url,
                       let data = try? Data(contentsOf: url) {
                        let ext = url.pathExtension.lowercased()
                        let type: RunnerType = switch ext {
                        case "sid": .sid
                        case "crt": .crt
                        default: .prg
                        }
                        connection.runFile(type: type, data: data)
                    }
                }

                controlTile("Menu", icon: "line.3.horizontal", color: .purple) {
                    connection.machineAction(.menuButton)
                }

                controlTile("Reset", icon: "arrow.counterclockwise", color: .orange) {
                    showResetConfirm = true
                }

                controlTile("Reboot", icon: "arrow.trianglehead.2.clockwise", color: .orange) {
                    showRebootConfirm = true
                }

                controlTile("Power Off", icon: "power", color: .red) {
                    showPowerOffConfirm = true
                }
            }
        }
    }

    // MARK: - Components

    private func controlTile(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
    }
}

#Preview("With Device Info") {
    let connection = C64Connection()
    connection.deviceInfo = DeviceInfo(
        product: "C64 Ultimate",
        firmwareVersion: "3.14",
        fpgaVersion: "121",
        coreVersion: "1.47",
        hostname: "C64-Ultimate-3258D7",
        uniqueId: "25A73F"
    )
    connection.streamsActive = true
    return ToolboxOverlayView(connection: connection) {}
        .frame(width: 768, height: 544)
}

#Preview("No Device Info") {
    let connection = C64Connection()
    connection.connectionError = "Connection timed out"
    return ToolboxOverlayView(connection: connection) {}
        .frame(width: 768, height: 544)
}

#Preview("Rebooting") {
    let connection = C64Connection()
    connection.isWaitingForReboot = true
    return ToolboxOverlayView(connection: connection) {}
        .frame(width: 768, height: 544)
}
