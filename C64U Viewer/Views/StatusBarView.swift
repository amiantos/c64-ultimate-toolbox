// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import AppKit

final class StatusBarView: NSView {
    private let recBadge = NSTextField(labelWithString: "REC")
    private let kbBadge = NSTextField(labelWithString: "KB")

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        wantsLayer = true

        recBadge.font = .systemFont(ofSize: 10, weight: .bold)
        recBadge.textColor = .white
        recBadge.wantsLayer = true
        recBadge.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.8).cgColor
        recBadge.layer?.cornerRadius = 3
        recBadge.alignment = .center
        recBadge.translatesAutoresizingMaskIntoConstraints = false
        recBadge.isHidden = true

        kbBadge.font = .systemFont(ofSize: 10, weight: .bold)
        kbBadge.textColor = .white
        kbBadge.wantsLayer = true
        kbBadge.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.8).cgColor
        kbBadge.layer?.cornerRadius = 3
        kbBadge.alignment = .center
        kbBadge.translatesAutoresizingMaskIntoConstraints = false
        kbBadge.isHidden = true

        addSubview(recBadge)
        addSubview(kbBadge)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 24),
            recBadge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            recBadge.centerYAnchor.constraint(equalTo: centerYAnchor),
            recBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 30),
            kbBadge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            kbBadge.centerYAnchor.constraint(equalTo: centerYAnchor),
            kbBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),
        ])
    }

    func update(isRecording: Bool, isKeyboardActive: Bool) {
        recBadge.isHidden = !isRecording
        kbBadge.isHidden = !isKeyboardActive
    }
}
