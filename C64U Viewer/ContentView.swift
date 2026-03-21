// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import MetalKit
import SwiftUI

struct ContentView: View {
    @State var connection: C64Connection
    @State private var showToolboxOverlay = false

    var body: some View {
        ZStack {
            Color.black

            MetalView(renderer: connection.renderer)
                .aspectRatio(CGFloat(384.0 / 272.0), contentMode: .fit)

            if !connection.isConnected {
                HomeView(connection: connection)
            }

            // Status bar overlay
            if connection.isConnected {
                VStack {
                    Spacer()
                    HStack {
                        if connection.isRecording {
                            Text("REC")
                                .font(.caption)
                                .bold()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 4))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Text("\(Int(connection.framesPerSecond)) fps")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(8)
                }

                // Clickable area for toolbox overlay (Toolbox Mode only)
                if connection.connectionMode == .toolbox && !showToolboxOverlay {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { showToolboxOverlay = true }
                }
            }

            // Toolbox overlay
            if showToolboxOverlay && connection.connectionMode == .toolbox {
                ToolboxOverlayView(connection: connection) {
                    showToolboxOverlay = false
                }
            }
        }
        .frame(minWidth: 480, minHeight: 340)
        .onChange(of: connection.isConnected) { _, isConnected in
            if !isConnected {
                showToolboxOverlay = false
            }
        }
    }
}
