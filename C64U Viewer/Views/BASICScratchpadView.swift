// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI
internal import UniformTypeIdentifiers

struct BASICScratchpadView: View {
    @Bindable var connection: C64Connection
    let onBack: () -> Void
    let onDismiss: () -> Void

    @State private var basicCode: String = BASICSamples.helloWorld
    @State private var errorMessage: String?
    @State private var isUploading = false
    @State private var showSuccess = false
    @State private var showSpecialCodes = false

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

            BASICEditorView(text: $basicCode)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 20)

            if showSpecialCodes {
                specialCodesReference
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }

            statusBar
                .padding(.horizontal, 20)
                .padding(.top, 8)

            toolbar
                .padding(20)
        }
        .frame(width: 600)
        .frame(maxHeight: 700)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 20)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { onBack() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)

            Spacer()

            Text("BASIC Scratchpad")
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

    // MARK: - Status Bar

    @ViewBuilder
    private var statusBar: some View {
        HStack {
            if let error = errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if showSuccess {
                Label("Program uploaded successfully!", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                let lineCount = basicCode.split(separator: "\n", omittingEmptySubsequences: true).count
                Text("\(lineCount) line\(lineCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                showSpecialCodes.toggle()
            } label: {
                Label(showSpecialCodes ? "Hide Codes" : "Special Codes",
                      systemImage: "character.bubble")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Menu {
                Menu("Samples") {
                    ForEach(BASICSamples.all, id: \.name) { sample in
                        Button(sample.name) {
                            basicCode = sample.code
                            errorMessage = nil
                            showSuccess = false
                        }
                    }
                }
                Divider()
                Button("Open...") { openFile() }
                Button("Save As...") { saveFile() }
            } label: {
                Label("File", systemImage: "doc")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Spacer()

            Button {
                uploadProgram()
            } label: {
                if isUploading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Upload", systemImage: "arrow.up.circle.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(basicCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUploading)
        }
    }

    // MARK: - Special Codes Reference

    private var specialCodesReference: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Special Codes")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(BASICTokenizer.specialCodes, id: \.1) { code, _ in
                    Text(code)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.pink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(10)
        .background(.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
        .frame(maxHeight: 120)
    }

    // MARK: - Actions

    private func uploadProgram() {
        guard let client = connection.apiClient else { return }
        let code = basicCode

        errorMessage = nil
        showSuccess = false
        isUploading = true

        Task {
            do {
                let (data, endAddr) = try BASICTokenizer.tokenize(program: code)

                // Write tokenized program to $0801
                try await client.writeMem(address: 0x0801, data: data)

                // Update BASIC variable pointer at $002D/$002E
                let ptrData = Data([UInt8(endAddr & 0xFF), UInt8(endAddr >> 8)])
                try await client.writeMem(address: 0x002D, data: ptrData)

                // Type "RUN" + RETURN into the keyboard buffer to auto-run
                let runBytes: [UInt8] = [0x52, 0x55, 0x4E, 0x0D] // R, U, N, RETURN
                try await client.writeMem(address: 0x0277, data: Data(runBytes))
                try await client.writeMem(address: 0x00C6, data: Data([UInt8(runBytes.count)]))

                // Dismiss overlay so user can see the program running
                onDismiss()
            } catch {
                errorMessage = error.localizedDescription
                showSuccess = false
            }
            isUploading = false
        }
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "bas"),
            UTType.plainText,
        ].compactMap { $0 }
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url,
           let content = try? String(contentsOf: url, encoding: .utf8) {
            basicCode = content
            errorMessage = nil
            showSuccess = false
        }
    }

    private func saveFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "bas") ?? .plainText]
        panel.nameFieldStringValue = "program.bas"
        if panel.runModal() == .OK, let url = panel.url {
            try? basicCode.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
