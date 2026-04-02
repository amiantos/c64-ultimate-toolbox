// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain name at https://mozilla.org/MPL/2.0/.

import AppKit

final class KeyStripView: NSView {
    private weak var forwarder: C64KeyboardForwarder?
    var onMenuButton: (() -> Void)?
    private var keyButtons: [NSButton] = []
    private var menuButton: NSButton!

    init(forwarder: C64KeyboardForwarder) {
        self.forwarder = forwarder
        super.init(frame: .zero)
        setupViews()
        applyOverlaySettings()
        NotificationCenter.default.addObserver(self, selector: #selector(settingsChanged), name: .keyboardOverlaySettingsChanged, object: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupViews() {
        wantsLayer = true

        let topRow = NSStackView()
        topRow.orientation = .horizontal
        topRow.spacing = 2
        topRow.translatesAutoresizingMaskIntoConstraints = false

        // F1-F8
        for key in [SpecialKey.f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8] {
            let btn = makeKeyButton(key)
            topRow.addArrangedSubview(btn)
            keyButtons.append(btn)
        }

        let bottomRow = NSStackView()
        bottomRow.orientation = .horizontal
        bottomRow.spacing = 2
        bottomRow.translatesAutoresizingMaskIntoConstraints = false

        // Menu button
        menuButton = NSButton(title: "MENU", target: self, action: #selector(menuTapped))
        menuButton.font = .monospacedSystemFont(ofSize: 9, weight: .medium)
        menuButton.bezelStyle = .toolbar
        menuButton.bezelColor = NSColor.black.withAlphaComponent(0.6)
        bottomRow.addArrangedSubview(menuButton)

        // Special keys
        for key in [SpecialKey.runStop, .home, .clr, .inst, .instDel,
                    .cursorUp, .cursorDown, .cursorLeft, .cursorRight,
                    .pound, .upArrow, .leftArrow, .shiftReturn] {
            let btn = makeKeyButton(key)
            bottomRow.addArrangedSubview(btn)
            keyButtons.append(btn)
        }

        let stack = NSStackView(views: [topRow, bottomRow])
        stack.orientation = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.edgeInsets = NSEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    private func makeKeyButton(_ key: SpecialKey) -> NSButton {
        let button = NSButton(title: key.rawValue, target: self, action: #selector(keyTapped(_:)))
        button.font = .monospacedSystemFont(ofSize: 9, weight: .medium)
        button.bezelStyle = .toolbar
        button.tag = Int(key.petscii)
        button.bezelColor = NSColor.black.withAlphaComponent(0.6)
        return button
    }

    // MARK: - Overlay Settings

    @objc private func settingsChanged() {
        applyOverlaySettings()
    }

    private func applyOverlaySettings() {
        let defaults = UserDefaults.standard
        let bgOpacity = defaults.object(forKey: "keyboard_overlay_bg_opacity") as? CGFloat ?? 0.0
        let buttonOpacity = defaults.object(forKey: "keyboard_overlay_button_opacity") as? CGFloat ?? 1.0
        let tintIndex = defaults.integer(forKey: "keyboard_overlay_tint")

        layer?.backgroundColor = NSColor.black.withAlphaComponent(bgOpacity).cgColor

        let tintColor: NSColor = switch tintIndex {
        case 1: .systemGreen
        case 2: .systemOrange
        default: .white
        }

        for button in keyButtons {
            button.alphaValue = buttonOpacity
            button.contentTintColor = tintColor
            let attrTitle = NSAttributedString(string: button.title, attributes: [
                .foregroundColor: tintColor,
                .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .medium),
            ])
            button.attributedTitle = attrTitle
        }

        menuButton.alphaValue = buttonOpacity
        menuButton.contentTintColor = tintColor
        menuButton.attributedTitle = NSAttributedString(string: menuButton.title, attributes: [
            .foregroundColor: tintColor,
            .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .medium),
        ])
    }

    // MARK: - Actions

    @objc private func keyTapped(_ sender: NSButton) {
        forwarder?.sendKey(UInt8(sender.tag))
    }

    @objc private func menuTapped() {
        onMenuButton?()
    }
}
