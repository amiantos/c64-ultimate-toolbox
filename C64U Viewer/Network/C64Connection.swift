// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import Observation

@Observable
final class C64Connection {
    var hostname: String = "c64u" {
        didSet { UserDefaults.standard.set(hostname, forKey: "c64_hostname") }
    }
    var videoPort: UInt16 = 11000
    var audioPort: UInt16 = 11001

    var isConnected = false
    let presetManager = PresetManager()

    var crtSettings = CRTSettings() {
        didSet {
            renderer.crtSettings = crtSettings
            if oldValue.renderResolution != crtSettings.renderResolution {
                UserDefaults.standard.set(crtSettings.renderResolution.rawValue, forKey: "c64_renderResolution")
            }
        }
    }

    var volume: Float = 0.2 {
        didSet {
            audioPlayer.volume = volume
            UserDefaults.standard.set(volume, forKey: "c64_volume")
        }
    }
    var balance: Float = 0.0 {
        didSet {
            audioPlayer.balance = balance
            UserDefaults.standard.set(balance, forKey: "c64_balance")
        }
    }
    var isMuted = false

    private(set) var framesPerSecond: Double = 0
    private var frameCount = 0
    private var fpsTimer: DispatchSourceTimer?

    let frameAssembler = FrameAssembler()
    let videoReceiver: UDPVideoReceiver
    let audioReceiver = UDPAudioReceiver()
    let audioPlayer = AudioPlayer()
    let renderer = MetalRenderer()
    let mediaCapture = MediaCapture()

    var isRecording: Bool { mediaCapture.isRecording }

    func selectPreset(_ id: PresetIdentifier) {
        presetManager.selectedIdentifier = id
        var settings = presetManager.settings(for: id)
        settings.renderResolution = crtSettings.renderResolution
        crtSettings = settings
        presetManager.schedulePersist()
    }

    func applySettingsChange() {
        switch presetManager.selectedIdentifier {
        case .builtIn(let preset):
            presetManager.saveOverride(for: preset, settings: crtSettings)
        case .custom(let id):
            presetManager.updateCustom(id: id, settings: crtSettings)
        }
    }

    init() {
        videoReceiver = UDPVideoReceiver(frameAssembler: frameAssembler)

        // Restore saved settings
        if let saved = UserDefaults.standard.string(forKey: "c64_hostname"), !saved.isEmpty {
            hostname = saved
        }

        // Restore saved volume and balance
        if UserDefaults.standard.object(forKey: "c64_volume") != nil {
            volume = UserDefaults.standard.float(forKey: "c64_volume")
        }
        if UserDefaults.standard.object(forKey: "c64_balance") != nil {
            balance = UserDefaults.standard.float(forKey: "c64_balance")
        }

        // Load settings from preset manager
        var settings = presetManager.settings(for: presetManager.selectedIdentifier)
        if let res = UserDefaults.standard.string(forKey: "c64_renderResolution"),
           let r = CRTRenderResolution(rawValue: res) {
            settings.renderResolution = r
        }
        crtSettings = settings

        mediaCapture.renderer = renderer
        mediaCapture.audioPlayer = audioPlayer

        frameAssembler.onFrameReady = { [weak self] rgbaData, width, height in
            guard let self else { return }
            DispatchQueue.main.async {
                self.frameCount += 1
                self.renderer.updateFrame(rgbaData: rgbaData, width: width, height: height)
            }
        }

        audioReceiver.onAudioData = { [weak self] pcmData, _ in
            self?.audioPlayer.scheduleAudio(pcmData)
        }
    }

    func connect() {
        guard !isConnected else { return }

        // Start UDP listeners
        videoReceiver.start(port: videoPort)
        audioReceiver.start(port: audioPort)
        audioPlayer.start()

        isConnected = true
        startFPSCounter()
    }

    func takeScreenshot() {
        mediaCapture.takeScreenshot()
    }

    func toggleRecording() {
        if mediaCapture.isRecording {
            mediaCapture.stopRecording()
        } else {
            let size = crtSettings.renderResolution.size
            mediaCapture.startRecording(resolution: size)
        }
    }

    func disconnect() {
        guard isConnected else { return }

        if mediaCapture.isRecording {
            mediaCapture.stopRecording()
        }

        videoReceiver.stop()
        audioReceiver.stop()
        audioPlayer.stop()
        isConnected = false
        fpsTimer?.cancel()
        fpsTimer = nil
        framesPerSecond = 0
    }

    private func startFPSCounter() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            self.framesPerSecond = Double(self.frameCount)
            self.frameCount = 0
        }
        timer.resume()
        fpsTimer = timer
    }

}
