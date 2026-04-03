// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import AppKit

// MARK: - Memory Region Presets

struct MemoryPreset {
    let name: String
    let address: Int
    let description: String
}

private let memoryPresets: [MemoryPreset] = [
    MemoryPreset(name: "Zero Page", address: 0x0000, description: "Processor variables"),
    MemoryPreset(name: "Screen", address: 0x0400, description: "40×25 text display"),
    MemoryPreset(name: "BASIC", address: 0x0801, description: "BASIC program area"),
    MemoryPreset(name: "Color RAM", address: 0xD800, description: "Character colors"),
    MemoryPreset(name: "VIC-II", address: 0xD000, description: "Graphics chip"),
    MemoryPreset(name: "SID", address: 0xD400, description: "Sound chip"),
    MemoryPreset(name: "CIA 1", address: 0xDC00, description: "Keyboard/Joystick I/O"),
]

// MARK: - Memory Browser View Controller

final class MemoryBrowserViewController: NSViewController {
    let connection: C64Connection
    private let hexView = HexDumpView()
    private var addressField: NSTextField!
    private var statusLabel: NSTextField!
    private var autoRefreshButton: NSButton!
    private var editModeButton: NSButton!
    private var writeButton: NSButton!
    private var revertButton: NSButton!

    private var currentAddress: Int = 0x0000
    private let pageSize = 256
    private var memoryData = Data()
    private var originalData = Data()
    private var refreshTimer: DispatchSourceTimer?
    private var isEditing = false

    init(connection: C64Connection) {
        self.connection = connection
        super.init(nibName: nil, bundle: nil)
        self.title = "Memory Browser"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        let container = BackgroundView()
        container.backgroundColor = .controlBackgroundColor

        // Top bar: address field + go button + presets
        let addressLabel = NSTextField(labelWithString: "$")
        addressLabel.font = .monospacedSystemFont(ofSize: 12, weight: .medium)

        addressField = NSTextField()
        addressField.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        addressField.placeholderString = "0000"
        addressField.stringValue = "0000"
        addressField.widthAnchor.constraint(equalToConstant: 50).isActive = true
        addressField.target = self
        addressField.action = #selector(goToAddress)

        let goButton = NSButton(title: "Go", target: self, action: #selector(goToAddress))
        goButton.bezelStyle = .rounded
        goButton.controlSize = .small

        let presetMenu = NSPopUpButton(frame: .zero, pullsDown: true)
        presetMenu.addItem(withTitle: "Jump to…")
        for preset in memoryPresets {
            presetMenu.addItem(withTitle: "\(preset.name) ($\(String(format: "%04X", preset.address)))")
        }
        presetMenu.target = self
        presetMenu.action = #selector(presetSelected(_:))
        presetMenu.controlSize = .small

        // Navigation buttons
        let prevButton = NSButton(title: "◀", target: self, action: #selector(prevPage))
        prevButton.bezelStyle = .rounded
        prevButton.controlSize = .small
        let nextButton = NSButton(title: "▶", target: self, action: #selector(nextPage))
        nextButton.bezelStyle = .rounded
        nextButton.controlSize = .small

        let topRow = NSStackView(views: [prevButton, addressLabel, addressField, goButton, presetMenu, nextButton])
        topRow.orientation = .horizontal
        topRow.spacing = 4
        topRow.translatesAutoresizingMaskIntoConstraints = false

        // Hex dump view
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = hexView
        hexView.onByteEdited = { [weak self] offset, value in
            self?.byteEdited(at: offset, value: value)
        }

        // Bottom bar
        autoRefreshButton = NSButton(checkboxWithTitle: "Auto-refresh", target: self, action: #selector(toggleAutoRefresh))
        autoRefreshButton.controlSize = .small

        editModeButton = NSButton(checkboxWithTitle: "Edit", target: self, action: #selector(toggleEditMode))
        editModeButton.controlSize = .small

        writeButton = NSButton(title: "Write", target: self, action: #selector(writeChanges))
        writeButton.bezelStyle = .rounded
        writeButton.controlSize = .small
        writeButton.isHidden = true

        revertButton = NSButton(title: "Revert", target: self, action: #selector(revertChanges))
        revertButton.bezelStyle = .rounded
        revertButton.controlSize = .small
        revertButton.isHidden = true

        statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = .systemFont(ofSize: 10)
        statusLabel.textColor = .secondaryLabelColor

        let bottomRow = NSStackView(views: [autoRefreshButton, editModeButton, writeButton, revertButton, NSView(), statusLabel])
        bottomRow.orientation = .horizontal
        bottomRow.spacing = 8
        bottomRow.edgeInsets = NSEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        bottomRow.translatesAutoresizingMaskIntoConstraints = false

        let topSeparator = NSBox()
        topSeparator.boxType = .separator
        topSeparator.translatesAutoresizingMaskIntoConstraints = false

        let bottomSeparator = NSBox()
        bottomSeparator.boxType = .separator
        bottomSeparator.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(topRow)
        container.addSubview(topSeparator)
        container.addSubview(scrollView)
        container.addSubview(bottomSeparator)
        container.addSubview(bottomRow)

        NSLayoutConstraint.activate([
            topRow.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor, constant: 4),
            topRow.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            topSeparator.topAnchor.constraint(equalTo: topRow.bottomAnchor, constant: 4),
            topSeparator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            topSeparator.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: topSeparator.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomSeparator.topAnchor),

            bottomSeparator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomSeparator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomSeparator.bottomAnchor.constraint(equalTo: bottomRow.topAnchor),

            bottomRow.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bottomRow.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomRow.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bottomRow.heightAnchor.constraint(equalToConstant: 28),
        ])

        self.view = container

        loadMemory(at: currentAddress)
    }

    // MARK: - Memory Operations

    private func loadMemory(at address: Int) {
        guard let client = connection.apiClient else { return }
        currentAddress = min(address, 0xFFFF)
        let readLength = min(pageSize, 0x10000 - currentAddress)

        addressField.stringValue = String(format: "%04X", currentAddress)
        statusLabel.stringValue = "Loading $\(String(format: "%04X", currentAddress))…"

        Task {
            do {
                let data = try await client.readMem(address: currentAddress, length: readLength)
                memoryData = data
                originalData = data
                hexView.update(address: currentAddress, data: data, editMode: isEditing)
                statusLabel.stringValue = "\(data.count) bytes at $\(String(format: "%04X", currentAddress))"
            } catch {
                statusLabel.stringValue = "Error: \(error.localizedDescription)"
            }
        }
    }

    private func byteEdited(at offset: Int, value: UInt8) {
        guard offset < memoryData.count else { return }
        memoryData[offset] = value
        let hasChanges = memoryData != originalData
        writeButton.isHidden = !hasChanges
        revertButton.isHidden = !hasChanges
    }

    // MARK: - Actions

    @objc private func goToAddress() {
        let hex = addressField.stringValue.trimmingCharacters(in: .whitespaces)
        guard let addr = UInt16(hex, radix: 16) else { return }
        loadMemory(at: Int(addr))
    }

    @objc private func presetSelected(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem - 1 // -1 for "Jump to…" title
        guard index >= 0, index < memoryPresets.count else { return }
        let preset = memoryPresets[index]
        loadMemory(at: preset.address)
        sender.selectItem(at: 0) // Reset to "Jump to…"
    }

    @objc private func prevPage() {
        let newAddr = max(0, currentAddress - pageSize)
        loadMemory(at: newAddr)
    }

    @objc private func nextPage() {
        let newAddr = min(0xFFFF, currentAddress + pageSize)
        loadMemory(at: newAddr)
    }

    @objc private func toggleAutoRefresh() {
        if autoRefreshButton.state == .on {
            let timer = DispatchSource.makeTimerSource(queue: .main)
            timer.schedule(deadline: .now() + 0.25, repeating: 0.25)
            timer.setEventHandler { [weak self] in
                guard let self, !self.isEditing else { return }
                self.loadMemory(at: self.currentAddress)
            }
            timer.resume()
            refreshTimer = timer
        } else {
            refreshTimer?.cancel()
            refreshTimer = nil
        }
    }

    @objc private func toggleEditMode() {
        isEditing = editModeButton.state == .on
        hexView.update(address: currentAddress, data: memoryData, editMode: isEditing)
        if !isEditing {
            revertChanges()
        }
    }

    @objc private func writeChanges() {
        guard let client = connection.apiClient, memoryData != originalData else { return }
        statusLabel.stringValue = "Writing…"

        // Find changed byte ranges and write them individually
        Task {
            do {
                var writtenCount = 0
                for i in 0..<memoryData.count {
                    if i < originalData.count && memoryData[i] != originalData[i] {
                        let addr = currentAddress + i
                        let dataHex = String(format: "%02X", memoryData[i])
                        // Use PUT with data= parameter for single byte writes (works for I/O registers)
                        try await client.writeMemHex(address: addr, dataHex: dataHex)
                        writtenCount += 1
                    }
                }
                originalData = memoryData
                writeButton.isHidden = true
                revertButton.isHidden = true
                hexView.clearModified()
                statusLabel.stringValue = "Written \(writtenCount) byte\(writtenCount == 1 ? "" : "s")"
            } catch {
                statusLabel.stringValue = "Write error: \(error.localizedDescription)"
            }
        }
    }

    @objc private func revertChanges() {
        memoryData = originalData
        hexView.update(address: currentAddress, data: memoryData, editMode: isEditing)
        writeButton.isHidden = true
        revertButton.isHidden = true
    }

    deinit {
        refreshTimer?.cancel()
    }
}

// MARK: - Hex Dump View

final class HexDumpView: NSView {
    private let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    private var baseAddress: Int = 0
    private var data = Data()
    private var originalData = Data()
    private var editMode = false
    private var selectedByte: Int? = nil
    private var editingHighNibble = true  // true = entering high nibble, false = low nibble
    var onByteEdited: ((Int, UInt8) -> Void)?

    private let bytesPerRow = 16
    private let rowHeight: CGFloat = 16
    private let addressWidth: CGFloat = 55
    private let byteWidth: CGFloat = 22
    private let charWidth: CGFloat = 9

    override var isFlipped: Bool { true }

    func clearModified() {
        originalData = data
        needsDisplay = true
    }

    func update(address: Int, data: Data, editMode: Bool) {
        let addressChanged = address != self.baseAddress
        self.baseAddress = address
        self.data = data
        if !editMode || addressChanged || self.originalData.count != data.count {
            self.originalData = data
        }
        self.editMode = editMode
        self.selectedByte = nil

        let rows = CGFloat((data.count + bytesPerRow - 1) / bytesPerRow)
        let height = max(rows * rowHeight + 4, 100)
        let width = addressWidth + CGFloat(bytesPerRow) * byteWidth + 12 + CGFloat(bytesPerRow) * charWidth + 20
        frame = NSRect(x: 0, y: 0, width: superview?.bounds.width ?? width, height: height)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard !data.isEmpty else { return }

        let rows = (data.count + bytesPerRow - 1) / bytesPerRow
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor]
        let addrAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.systemYellow]
        let modifiedAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.systemRed]
        let charAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.secondaryLabelColor]

        for row in 0..<rows {
            let y = CGFloat(row) * rowHeight + 2
            let rowAddr = baseAddress + row * bytesPerRow

            // Address
            let addrStr = String(format: "%04X:", rowAddr)
            addrStr.draw(at: NSPoint(x: 4, y: y), withAttributes: addrAttrs)

            // Hex bytes
            for col in 0..<bytesPerRow {
                let offset = row * bytesPerRow + col
                guard offset < data.count else { break }

                let byte = data[offset]
                let x = addressWidth + CGFloat(col) * byteWidth + (col >= 8 ? 6 : 0)
                let hexStr = String(format: "%02X", byte)

                let isModified = offset < originalData.count && byte != originalData[offset]
                let isSelected = selectedByte == offset && editMode

                if isSelected {
                    NSColor.systemBlue.withAlphaComponent(0.3).setFill()
                    NSRect(x: x - 1, y: y, width: byteWidth, height: rowHeight).fill()
                }

                hexStr.draw(at: NSPoint(x: x, y: y), withAttributes: isModified ? modifiedAttrs : attrs)
            }

            // PETSCII character representation
            let charX = addressWidth + CGFloat(bytesPerRow) * byteWidth + 12
            var charStr = ""
            for col in 0..<bytesPerRow {
                let offset = row * bytesPerRow + col
                guard offset < data.count else { break }
                let byte = data[offset]
                charStr += petsciiToChar(byte)
            }
            charStr.draw(at: NSPoint(x: charX, y: y), withAttributes: charAttrs)
        }
    }

    /// Convert a byte to a displayable character.
    /// Handles both PETSCII screen codes and standard ASCII ranges.
    private func petsciiToChar(_ byte: UInt8) -> String {
        switch byte {
        case 0x00: return "·"           // null
        case 0x01...0x1A:               // Screen codes: A-Z
            return String(UnicodeScalar(byte - 1 + 65))  // → A-Z
        case 0x20: return " "           // space
        case 0x21...0x3F:               // !"#$%... digits, punctuation
            return String(UnicodeScalar(byte))
        case 0x30...0x39:               // 0-9 (overlap handled above)
            return String(UnicodeScalar(byte))
        case 0x40...0x5A:               // PETSCII uppercase (same as screen codes with offset)
            return String(UnicodeScalar(byte))
        case 0x41...0x5A:               // A-Z in PETSCII
            return String(UnicodeScalar(byte))
        case 0x61...0x7A:               // a-z in PETSCII (shifted)
            return String(UnicodeScalar(byte))
        case 0xC1...0xDA:               // PETSCII shifted uppercase A-Z
            return String(UnicodeScalar(byte - 0xC1 + 65))
        default:
            // Standard printable ASCII fallback
            if byte >= 0x20 && byte <= 0x7E {
                return String(UnicodeScalar(byte))
            }
            return "·"
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard editMode else { return }
        let point = convert(event.locationInWindow, from: nil)
        let row = Int((point.y - 2) / rowHeight)
        let xInHex = point.x - addressWidth

        if xInHex >= 0 {
            var col = Int(xInHex / byteWidth)
            // Account for the gap between byte 7 and 8
            if xInHex > CGFloat(8) * byteWidth + 6 {
                col = Int((xInHex - 6) / byteWidth)
            }
            if col >= 0 && col < bytesPerRow {
                let offset = row * bytesPerRow + col
                if offset < data.count {
                    selectedByte = offset
                    editingHighNibble = true
                    needsDisplay = true
                    window?.makeFirstResponder(self)
                }
            }
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard editMode, let selected = selectedByte, selected < data.count else {
            super.keyDown(with: event)
            return
        }

        let chars = event.characters?.uppercased() ?? ""
        for char in chars {
            if let nibble = UInt8(String(char), radix: 16) {
                if editingHighNibble {
                    // Replace high nibble, keep low nibble
                    data[selected] = (nibble << 4) | (data[selected] & 0x0F)
                    editingHighNibble = false
                    onByteEdited?(selected, data[selected])
                } else {
                    // Replace low nibble, keep high nibble
                    data[selected] = (data[selected] & 0xF0) | nibble
                    editingHighNibble = true
                    onByteEdited?(selected, data[selected])
                    // Move to next byte after entering both nibbles
                    if selected + 1 < data.count {
                        selectedByte = selected + 1
                    }
                }
                needsDisplay = true
                return
            }
        }

        // Arrow key navigation
        switch event.keyCode {
        case 123: // Left
            if selected > 0 { selectedByte = selected - 1; needsDisplay = true }
        case 124: // Right
            if selected + 1 < data.count { selectedByte = selected + 1; needsDisplay = true }
        case 126: // Up
            if selected >= bytesPerRow { selectedByte = selected - bytesPerRow; needsDisplay = true }
        case 125: // Down
            if selected + bytesPerRow < data.count { selectedByte = selected + bytesPerRow; needsDisplay = true }
        default:
            super.keyDown(with: event)
        }
    }
}
