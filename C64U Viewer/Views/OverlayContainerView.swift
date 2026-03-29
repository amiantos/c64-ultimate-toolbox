// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import SwiftUI

struct OverlayContainerView: View {
    @Bindable var connection: C64Connection
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(connection.overlayMode == .crtSettings ? 0.0 : 0.4)
                .onTapGesture { onDismiss() }
                .animation(.easeInOut(duration: 0.2), value: connection.overlayMode)

            switch connection.overlayMode {
            case .controls:
                ControlsOverlayView(
                    connection: connection,
                    onCustomize: { connection.overlayMode = .crtSettings },
                    onAudio: { connection.overlayMode = .audio },
                    onBasicScratchpad: { connection.overlayMode = .basicScratchpad },
                    onDismiss: onDismiss
                )
            case .crtSettings:
                CRTSettingsOverlayView(
                    connection: connection,
                    onBack: { connection.overlayMode = .controls },
                    onDismiss: onDismiss
                )
            case .audio:
                AudioSettingsOverlayView(
                    connection: connection,
                    onBack: { connection.overlayMode = .controls },
                    onDismiss: onDismiss
                )
            case .basicScratchpad:
                BASICScratchpadView(
                    connection: connection,
                    onBack: { connection.overlayMode = .controls },
                    onDismiss: onDismiss
                )
            }
        }
        .onKeyPress(.escape) {
            if connection.overlayMode != .controls {
                connection.overlayMode = .controls
            } else {
                onDismiss()
            }
            return .handled
        }
    }
}
