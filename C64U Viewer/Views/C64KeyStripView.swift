// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct C64KeyStripView: View {
    let forwarder: C64KeyboardForwarder

    private let topRow: [SpecialKey] = [
        .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8
    ]

    private let bottomRow: [SpecialKey] = [
        .runStop, .home, .clr, .inst, .instDel,
        .cursorUp, .cursorDown, .cursorLeft, .cursorRight,
        .pound, .upArrow, .leftArrow, .shiftReturn
    ]

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(topRow) { key in
                    keyButton(key)
                }
            }
            HStack(spacing: 4) {
                ForEach(bottomRow) { key in
                    keyButton(key)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }

    private func keyButton(_ key: SpecialKey) -> some View {
        Button {
            forwarder.handleSpecialKey(key)
        } label: {
            Text(key.rawValue)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}
