import Foundation

@MainActor
protocol TTSServiceProtocol {
    var isSpeaking: Bool { get }
    func speak(_ text: String, preferredVoiceIdentifier: String)
    func stop()
}
