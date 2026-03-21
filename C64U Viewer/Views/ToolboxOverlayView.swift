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

    var body: some View {
        ZStack {
            // Dismiss background
            Color.black.opacity(0.4)
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Toolbox")
                        .font(.headline)
                    Spacer()
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                // Device Info
                if let info = connection.deviceInfo {
                    deviceInfoSection(info)
                    Divider()
                }

                if let error = connection.connectionError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                // File Runners
                fileRunnersSection
                Divider()

                // Machine Controls
                machineControlsSection
            }
            .padding(20)
            .frame(width: 360)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
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

    private func deviceInfoSection(_ info: DeviceInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Device Info")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            LabeledContent("Product", value: info.product)
            LabeledContent("Firmware", value: info.firmwareVersion)
            LabeledContent("Hostname", value: info.hostname)
        }
        .font(.caption)
    }

    private var fileRunnersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Run File")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                runnerButton("Play SID", type: .sid, extensions: ["sid"])
                runnerButton("Run PRG", type: .prg, extensions: ["prg"])
                runnerButton("Run CRT", type: .crt, extensions: ["crt"])
            }
        }
    }

    private func runnerButton(_ label: String, type: RunnerType, extensions: [String]) -> some View {
        Button(label) {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = extensions.compactMap {
                .init(filenameExtension: $0)
            }
            panel.allowsMultipleSelection = false
            if panel.runModal() == .OK, let url = panel.url,
               let data = try? Data(contentsOf: url) {
                connection.runFile(type: type, data: data)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var machineControlsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Machine Control")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Button("Menu") {
                    connection.machineAction(.menuButton)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Reset") {
                    showResetConfirm = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Reboot") {
                    showRebootConfirm = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Power Off") {
                    showPowerOffConfirm = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
            }
        }
    }
}
