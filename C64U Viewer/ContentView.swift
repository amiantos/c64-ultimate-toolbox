// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import MetalKit
import SwiftUI

struct ContentView: View {
    @State var connection: C64Connection
    @State private var showCRTSettings = false
    @State private var showAudioSettings = false
    @State private var showResetConfirm = false
    @State private var showRebootConfirm = false
    @State private var showPowerOffConfirm = false
    @State private var showKeyboardInfo = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var toolbarManager: ToolbarManager?

    private var keyboardActive: Bool {
        connection.keyboardForwarder?.isEnabled == true
    }

    private var isToolbox: Bool {
        connection.connectionMode == .toolbox
    }

    var body: some View {
        ZStack {
            if !connection.isConnected {
                Color.black
                MetalView(renderer: connection.renderer)
                    .aspectRatio(CGFloat(384.0 / 272.0), contentMode: .fit)
                HomeView(connection: connection)
            } else if isToolbox {
                toolboxView
            } else {
                viewerView
            }

            // Settings modals
            if showCRTSettings {
                settingsOverlay {
                    CRTSettingsOverlayView(
                        connection: connection,
                        onDismiss: { showCRTSettings = false }
                    )
                }
            }

            if showAudioSettings {
                settingsOverlay {
                    AudioSettingsOverlayView(
                        connection: connection,
                        onDismiss: { showAudioSettings = false }
                    )
                }
            }
        }
        .frame(minWidth: 480, minHeight: 340)
        .focusable(keyboardActive)
        .onKeyPress(phases: .down) { press in
            guard keyboardActive, let forwarder = connection.keyboardForwarder else {
                return .ignored
            }

            switch press.key {
            case .return, .init("\r"):
                forwarder.sendKey(0x0D)
                return .handled
            case .delete:
                forwarder.sendKey(0x14)
                return .handled
            case .escape:
                forwarder.sendKey(0x03)
                return .handled
            case .upArrow:
                forwarder.sendKey(0x91)
                return .handled
            case .downArrow:
                forwarder.sendKey(0x11)
                return .handled
            case .leftArrow:
                forwarder.sendKey(0x9D)
                return .handled
            case .rightArrow:
                forwarder.sendKey(0x1D)
                return .handled
            case .home:
                forwarder.sendKey(press.modifiers.contains(.shift) ? 0x93 : 0x13)
                return .handled
            default:
                break
            }

            let chars = press.characters
            if !chars.isEmpty {
                forwarder.handleKeyPress(chars)
                return .handled
            }

            return .ignored
        }
        .onChange(of: connection.isConnected) { _, isConnected in
            if !isConnected {
                showCRTSettings = false
                showAudioSettings = false
            }
        }
        .onChange(of: connection.isRecording) { _, isRecording in
            if let window = NSApplication.shared.windows.first {
                if isRecording {
                    window.styleMask.remove(.resizable)
                } else {
                    window.styleMask.insert(.resizable)
                }
            }
        }
    }

    // MARK: - Toolbox View

    private var toolboxView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ControlSidebarView(connection: connection)
        } detail: {
            videoArea
                .inspector(isPresented: inspectorPresented) {
                    inspectorContent
                        .inspectorColumnWidth(min: 280, ideal: 350, max: 500)
                }
        }
        .onAppear { setupToolbar() }
        .onDisappear { teardownToolbar() }
        .confirmationDialog("Reset Machine?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { connection.machineAction(.reset) }
        }
        .confirmationDialog("Reboot Machine?", isPresented: $showRebootConfirm) {
            Button("Reboot", role: .destructive) { connection.machineAction(.reboot) }
        }
        .confirmationDialog("Power Off Machine?", isPresented: $showPowerOffConfirm) {
            Button("Power Off", role: .destructive) { connection.machineAction(.powerOff) }
        }
        .alert("Keyboard Forwarding", isPresented: $showKeyboardInfo) {
            Button("Enable") {
                UserDefaults.standard.set(true, forKey: "c64_keyboard_info_shown")
                connection.keyboardForwarder?.isEnabled = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Keyboard input is forwarded to the C64 via the KERNAL keyboard buffer. This works with BASIC and programs that read input through the KERNAL, but does not work in the Ultimate menu or with most games that read the keyboard hardware directly.")
        }
    }

    // MARK: - Inspector

    private var inspectorPresented: Binding<Bool> {
        Binding(
            get: { connection.activeToolPanel != nil },
            set: { if !$0 { connection.activeToolPanel = nil } }
        )
    }

    @ViewBuilder
    private var inspectorContent: some View {
        switch connection.activeToolPanel {
        case .basicScratchpad:
            BASICScratchpadPanelView(connection: connection)
        case .none:
            EmptyView()
        }
    }

    // MARK: - Toolbar Setup

    private func setupToolbar() {
        let manager = ToolbarManager(connection: connection)
        manager.onShowCRTSettings = { showCRTSettings = true }
        manager.onShowAudioSettings = { showAudioSettings = true }
        manager.onShowResetConfirm = { showResetConfirm = true }
        manager.onShowRebootConfirm = { showRebootConfirm = true }
        manager.onShowPowerOffConfirm = { showPowerOffConfirm = true }
        manager.onShowKeyboardInfo = { showKeyboardInfo = true }
        toolbarManager = manager

        if let window = NSApplication.shared.windows.first {
            manager.configureToolbar(for: window)
        }
    }

    private func teardownToolbar() {
        if let window = NSApplication.shared.windows.first {
            toolbarManager?.removeToolbar(from: window)
        }
        toolbarManager = nil
    }

    // MARK: - Viewer View (clean, no sidebar)

    private var viewerView: some View {
        videoArea
    }

    // MARK: - Video Area

    private var videoArea: some View {
        ZStack {
            Color.black

            MetalView(renderer: connection.renderer)
                .aspectRatio(CGFloat(384.0 / 272.0), contentMode: .fit)

            VStack(spacing: 0) {
                Spacer()

                if keyboardActive, let forwarder = connection.keyboardForwarder {
                    C64KeyStripView(forwarder: forwarder, connection: connection)
                }

                StatusBarView(connection: connection, keyboardActive: keyboardActive)
            }
            .allowsHitTesting(keyboardActive)
        }
    }

    // MARK: - Settings Overlay Wrapper

    private func settingsOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .onTapGesture {
                    showCRTSettings = false
                    showAudioSettings = false
                }
            content()
        }
        .onKeyPress(.escape) {
            showCRTSettings = false
            showAudioSettings = false
            return .handled
        }
    }

}
