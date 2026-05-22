import AVFoundation
import Combine
import Foundation

@MainActor
final class TTSService: ObservableObject, TTSServiceProtocol {
    @Published private(set) var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, preferredVoiceIdentifier: String = "com.apple.ttsbundle.Samantha-compact") {
        stop()
        configureAudioSessionForSpeech()
        let utterance = AVSpeechUtterance(string: text)
        let prefersSlowerVoice = UserDefaults.standard.bool(forKey: AssistantAccessibilitySettings.slowerVoiceKey)
        utterance.rate = prefersSlowerVoice ? 0.36 : 0.45
        utterance.pitchMultiplier = 1.02
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(identifier: preferredVoiceIdentifier) ?? AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    private func configureAudioSessionForSpeech() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .spokenAudio,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP, .duckOthers]
            )
            try session.setActive(true)

            if !hasExternalAudioRoute(session.currentRoute) {
                try session.overrideOutputAudioPort(.speaker)
            }
        } catch {
            #if DEBUG
            print("[TTSService] Could not configure loudspeaker route: \(error.localizedDescription)")
            #endif
        }
    }

    private func hasExternalAudioRoute(_ route: AVAudioSessionRouteDescription) -> Bool {
        route.outputs.contains { output in
            switch output.portType {
            case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE, .headphones, .usbAudio, .carAudio, .airPlay:
                return true
            default:
                return false
            }
        }
    }
}

// TTSKit adapter can be added here later if the package is available and stable.
// Keep AVSpeechSynthesizer as the no-key, offline fallback.
