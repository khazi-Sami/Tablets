import AVFoundation
import Combine
import Foundation
#if canImport(WhisperKit)
import WhisperKit
#endif

@MainActor
protocol SpeechToTextServiceProtocol {
    var isListening: Bool { get }
    var transcript: String { get }
    var partialTranscript: String { get }
    var audioLevel: Double { get }
    var modelName: String { get }
    func startListening() async throws
    func stopListening() async throws -> String
}

@MainActor
final class WhisperKitSpeechToTextService: ObservableObject, SpeechToTextServiceProtocol {
    @Published private(set) var isListening = false
    @Published private(set) var transcript = ""
    @Published private(set) var partialTranscript = ""
    @Published private(set) var audioLevel: Double = 0
    @Published private(set) var autoStopRequested = false
    @Published private(set) var isPreparingModel = false
    var modelName: String { modelManager.selectedModelName }
    var isLocalModelAvailable: Bool {
        modelManager.isInstalled()
    }

    private let modelManager: WhisperModelManager
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var meteringTask: Task<Void, Never>?

    init(modelManager: WhisperModelManager = .shared, preferAccuracy: Bool = true) {
        self.modelManager = modelManager
        modelManager.selectBestModelForDevice(preferAccuracy: preferAccuracy)
    }

    func startListening() async throws {
        transcript = ""
        partialTranscript = ""
        autoStopRequested = false
        try await prepareModelIfNeeded()
        let url = FileManager.default.temporaryDirectory.appending(path: "human-assistant-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.record()
        audioRecorder = recorder
        recordingURL = url
        isListening = true
        startMetering()
    }

    func stopListening() async throws -> String {
        audioRecorder?.stop()
        meteringTask?.cancel()
        meteringTask = nil
        audioLevel = 0
        isListening = false

        guard let recordingURL else {
            return ""
        }

        #if canImport(WhisperKit)
        let whisperKit = try await prepareModelIfNeeded()
        let result = try await Task.detached(priority: .userInitiated) {
            try await whisperKit.transcribe(audioPath: recordingURL.path)
        }.value
        let text = result.map(\.text).joined(separator: " ")
        transcript = text
        return text
        #else
        // Build-safe fallback for environments where the package has not resolved yet.
        transcript = ""
        return ""
        #endif
    }

    #if canImport(WhisperKit)
    @discardableResult
    private func prepareModelIfNeeded() async throws -> WhisperKit {
        isPreparingModel = true
        defer { isPreparingModel = false }
        return try await modelManager.loadedModel()
    }
    #else
    private func prepareModelIfNeeded() async throws {}
    #endif

    private func startMetering() {
        meteringTask?.cancel()
        meteringTask = Task { [weak self] in
            var detector = VoiceActivityDetector()
            detector.reset()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(180))
                guard let self, let recorder = self.audioRecorder, self.isListening else { continue }
                recorder.updateMeters()
                let power = recorder.averagePower(forChannel: 0)
                let normalized = min(max((Double(power) + 55) / 55, 0), 1)
                audioLevel = normalized

                switch detector.update(audioLevel: normalized) {
                case .continueListening(let speechDetected):
                    partialTranscript = "Listening to your voice..."
                    if !speechDetected && recorder.currentTime > 2.0 {
                        partialTranscript = "I’m listening. You can speak now."
                    }
                case .stop(let reason):
                    switch reason {
                    case .silenceAfterSpeech:
                        partialTranscript = "I heard a pause. Processing now..."
                    case .noSpeechDetected:
                        partialTranscript = "I didn't hear anything. Please try again."
                    case .maximumDuration:
                        partialTranscript = "Processing your voice now..."
                    }
                    autoStopRequested = true
                    return
                }
            }
        }
    }
}

enum WhisperKitSpeechToTextError: LocalizedError {
    case localModelMissing(String)

    var errorDescription: String? {
        switch self {
        case .localModelMissing(let modelName):
            return "The local Whisper model \(modelName) is not installed yet."
        }
    }
}
