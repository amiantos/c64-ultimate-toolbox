// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import AppKit
internal import UniformTypeIdentifiers

extension NSToolbarItem.Identifier {
    static let startStopStreams = NSToolbarItem.Identifier("startStopStreams")
    static let runFile = NSToolbarItem.Identifier("runFile")
    static let keyboard = NSToolbarItem.Identifier("keyboard")
    static let crtFilter = NSToolbarItem.Identifier("crtFilter")
    static let audioSettings = NSToolbarItem.Identifier("audioSettings")
    static let resetMachine = NSToolbarItem.Identifier("resetMachine")
    static let rebootMachine = NSToolbarItem.Identifier("rebootMachine")
    static let powerOff = NSToolbarItem.Identifier("powerOff")
    static let menuButton = NSToolbarItem.Identifier("menuButton")
}

@MainActor
final class ToolbarManager: NSObject, NSToolbarDelegate {
    let connection: C64Connection
    var onShowCRTSettings: (() -> Void)?
    var onShowAudioSettings: (() -> Void)?
    var onShowResetConfirm: (() -> Void)?
    var onShowRebootConfirm: (() -> Void)?
    var onShowPowerOffConfirm: (() -> Void)?
    var onShowKeyboardInfo: (() -> Void)?

    private static let keyboardInfoShownKey = "c64_keyboard_info_shown"

    init(connection: C64Connection) {
        self.connection = connection
        super.init()
    }

    func configureToolbar(for window: NSWindow) {
        let toolbar = NSToolbar(identifier: "ToolboxToolbar")
        toolbar.displayMode = .iconOnly
        toolbar.delegate = self
        window.toolbar = toolbar
    }

    func removeToolbar(from window: NSWindow) {
        window.toolbar = nil
    }

    // MARK: - NSToolbarDelegate

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            .toggleSidebar,
            .flexibleSpace,
            .startStopStreams, .runFile, .keyboard, .crtFilter, .audioSettings,
            .flexibleSpace,
            .resetMachine, .rebootMachine, .powerOff, .menuButton,
        ]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .startStopStreams:
            if connection.streamsActive {
                return makeItem(itemIdentifier, label: "Stop Streams", icon: "stop.circle.fill", action: #selector(stopStreams))
            } else {
                return makeItem(itemIdentifier, label: "Start Streams", icon: "play.circle.fill", action: #selector(startStreams))
            }
        case .runFile:
            return makeItem(itemIdentifier, label: "Run File", icon: "doc.fill.badge.plus", action: #selector(runFileTapped))
        case .keyboard:
            let isEnabled = connection.keyboardForwarder?.isEnabled == true
            return makeItem(itemIdentifier, label: "Keyboard", icon: isEnabled ? "keyboard.fill" : "keyboard", action: #selector(toggleKeyboard))
        case .crtFilter:
            return makeItem(itemIdentifier, label: "CRT Filter", icon: "tv", action: #selector(showCRT))
        case .audioSettings:
            return makeItem(itemIdentifier, label: "Audio", icon: "speaker.wave.2.fill", action: #selector(showAudio))
        case .resetMachine:
            return makeItem(itemIdentifier, label: "Reset", icon: "arrow.counterclockwise", action: #selector(resetTapped))
        case .rebootMachine:
            return makeItem(itemIdentifier, label: "Reboot", icon: "arrow.trianglehead.2.clockwise", action: #selector(rebootTapped))
        case .powerOff:
            return makeItem(itemIdentifier, label: "Power Off", icon: "power", action: #selector(powerOffTapped))
        case .menuButton:
            return makeItem(itemIdentifier, label: "Menu", icon: "line.3.horizontal", action: #selector(menuTapped))
        default:
            return nil
        }
    }

    // MARK: - Item Factory

    private func makeItem(_ identifier: NSToolbarItem.Identifier, label: String, icon: String, action: Selector) -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = label
        item.toolTip = label
        item.target = self
        item.action = action
        item.isBordered = true

        if let image = NSImage(systemSymbolName: icon, accessibilityDescription: label) {
            item.image = image
        }

        return item
    }

    // MARK: - Actions

    @objc private func startStreams() {
        connection.startStreams()
        refreshToolbar()
    }

    @objc private func stopStreams() {
        connection.stopStreams()
        refreshToolbar()
    }

    @objc private func runFileTapped() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = ["sid", "prg", "crt"].compactMap {
            UTType(filenameExtension: $0)
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

    @objc private func toggleKeyboard() {
        guard let forwarder = connection.keyboardForwarder else { return }
        if forwarder.isEnabled {
            forwarder.isEnabled = false
        } else if UserDefaults.standard.bool(forKey: Self.keyboardInfoShownKey) {
            forwarder.isEnabled = true
        } else {
            onShowKeyboardInfo?()
        }
        refreshToolbar()
    }

    @objc private func showCRT() {
        onShowCRTSettings?()
    }

    @objc private func showAudio() {
        onShowAudioSettings?()
    }

    @objc private func resetTapped() {
        onShowResetConfirm?()
    }

    @objc private func rebootTapped() {
        onShowRebootConfirm?()
    }

    @objc private func powerOffTapped() {
        onShowPowerOffConfirm?()
    }

    @objc private func menuTapped() {
        connection.machineAction(.menuButton)
    }

    // MARK: - Refresh

    func refreshToolbar() {
        guard let window = NSApplication.shared.windows.first,
              let toolbar = window.toolbar else { return }

        // Remove and re-insert dynamic items to update their state
        let dynamicIdentifiers: [NSToolbarItem.Identifier] = [.startStopStreams, .keyboard]
        for identifier in dynamicIdentifiers {
            if let index = toolbar.items.firstIndex(where: { $0.itemIdentifier == identifier }) {
                toolbar.removeItem(at: index)
                toolbar.insertItem(withItemIdentifier: identifier, at: index)
            }
        }
    }
}
