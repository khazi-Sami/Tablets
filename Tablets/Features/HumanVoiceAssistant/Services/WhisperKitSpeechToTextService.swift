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
    @Published private(set) var isTranscribing = false
    #if DEBUG
    @Published private(set) var lastDebugRecordingURL: URL?
    #endif
    var modelName: String { modelManager.selectedModelName }
    private let minimumValidRecordingDuration: TimeInterval = 0.7
    private let minimumValidRecordingSize = 50 * 1_024
    var isLocalModelAvailable: Bool {
        modelManager.isInstalled()
    }

    private let modelManager: WhisperModelManager
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var meteringTask: Task<Void, Never>?
    private var recordingStartedAt: Date?
    private var powerSamples: [Double] = []
    private var peakPower: Double = 0
    #if DEBUG
    private var debugAudioPlayer: AVAudioPlayer?
    #endif

    init(modelManager: WhisperModelManager? = nil, preferAccuracy: Bool = true) {
        self.modelManager = modelManager ?? .shared
        self.modelManager.selectBestModelForDevice(preferAccuracy: preferAccuracy)
    }

    func startListening() async throws {
        guard !isListening, !isTranscribing else {
            debugLog("Start ignored. isListening=\(isListening), isTranscribing=\(isTranscribing)")
            throw WhisperKitSpeechToTextError.sessionAlreadyRunning
        }
        transcript = ""
        partialTranscript = ""
        autoStopRequested = false
        powerSamples = []
        peakPower = 0
        try await prepareModelIfNeeded()
        try configureAudioSessionForRecording()

        let url = FileManager.default.temporaryDirectory.appending(path: "human-assistant-\(UUID().uuidString).wav")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()

        guard recorder.record() else {
            throw WhisperKitSpeechToTextError.recordingDidNotStart
        }

        audioRecorder = recorder
        recordingURL = url
        recordingStartedAt = .now
        isListening = true
        logRecordingDiagnostics(prefix: "Recording started", url: url)
        startMetering()
    }

    func stopListening() async throws -> String {
        guard !isTranscribing else {
            debugLog("Stop ignored because transcription is already running")
            throw WhisperKitSpeechToTextError.sessionAlreadyRunning
        }
        audioRecorder?.stop()
        let recordedDuration = recordingStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        meteringTask?.cancel()
        meteringTask = nil
        audioLevel = 0
        isListening = false
        recordingStartedAt = nil

        guard let recordingURL else {
            return ""
        }

        defer {
            try? FileManager.default.removeItem(at: recordingURL)
            self.recordingURL = nil
            self.audioRecorder = nil
            self.isTranscribing = false
        }

        if recordedDuration < 0.5 {
            throw WhisperKitSpeechToTextError.noUsableAudio
        }

        let metadata = try validateRecording(at: recordingURL)
        try preserveLastRecordingForDebug(from: recordingURL)

        #if canImport(WhisperKit)
        let whisperKit = try await prepareModelIfNeeded()
        isTranscribing = true
        let transcriptionStartedAt = Date()
        debugLog("Transcription starting")
        debugLog("Whisper model ready: \(modelManager.isReady)")
        debugLog("WhisperKit instance loaded: \(modelManager.isModelLoaded)")
        debugLog("Whisper audioPath: \(recordingURL.path)")
        let result = try await Task.detached(priority: .userInitiated) {
            try await whisperKit.transcribe(audioPath: recordingURL.path)
        }.value
        let transcriptionDuration = Date().timeIntervalSince(transcriptionStartedAt)
        let text = result.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        debugLog("Transcription finished in \(String(format: "%.2f", transcriptionDuration)) seconds")
        debugLog("Returned transcript: \(text.isEmpty ? "<empty>" : text)")
        debugLog("Transcript character count: \(text.count)")
        if text.isEmpty {
            #if DEBUG
            print("[WhisperKitSpeechToTextService] Empty transcript from valid audio. Duration: \(metadata.duration)s, size: \(metadata.fileSize) bytes")
            #endif
            throw WhisperKitSpeechToTextError.emptyTranscript
        }
        transcript = text
        return text
        #else
        // Build-safe fallback for environments where the package has not resolved yet.
        transcript = ""
        return ""
        #endif
    }

    #if DEBUG
    func playLastRecordingForDebug() {
        guard let lastDebugRecordingURL else {
            debugLog("No debug recording available to play")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
            try session.setActive(true)
            if !hasExternalAudioRoute(session.currentRoute) {
                try session.overrideOutputAudioPort(.speaker)
            }
            let player = try AVAudioPlayer(contentsOf: lastDebugRecordingURL)
            debugAudioPlayer = player
            player.prepareToPlay()
            player.play()
            debugLog("Playing last recording: \(lastDebugRecordingURL.path)")
        } catch {
            debugLog("Could not play last recording: \(error.localizedDescription)")
        }
    }
    #endif

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

    private func configureAudioSessionForRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
        )
        try session.setPreferredSampleRate(16_000)
        try? session.setPreferredInputNumberOfChannels(1)
        try session.setPreferredIOBufferDuration(0.02)
        try session.setActive(true)

        guard session.isInputAvailable else {
            throw WhisperKitSpeechToTextError.microphoneUnavailable
        }

        logAudioSessionState(prefix: "Recording session configured")
    }

    private func validateRecording(at url: URL) throws -> RecordingMetadata {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw WhisperKitSpeechToTextError.noUsableAudio
        }

        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        let fileSize = values.fileSize ?? 0
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let duration = Double(audioFile.length) / max(format.sampleRate, 1)
        let averagePower = powerSamples.isEmpty ? 0 : powerSamples.reduce(0, +) / Double(powerSamples.count)
        let metadata = RecordingMetadata(
            fileSize: fileSize,
            duration: duration,
            sampleRate: format.sampleRate,
            channelCount: format.channelCount,
            frameCount: audioFile.length,
            averagePower: averagePower,
            peakPower: peakPower
        )

        #if DEBUG
        print("[WhisperKitSpeechToTextService] Recorded audio path: \(url.path)")
        print("[WhisperKitSpeechToTextService] Recorded audio size: \(metadata.fileSize) bytes")
        print("[WhisperKitSpeechToTextService] Recorded audio duration: \(String(format: "%.2f", metadata.duration)) seconds")
        print("[WhisperKitSpeechToTextService] Recorded audio sample rate: \(metadata.sampleRate)")
        print("[WhisperKitSpeechToTextService] Recorded audio channels: \(metadata.channelCount)")
        print("[WhisperKitSpeechToTextService] Recorded audio frames: \(metadata.frameCount)")
        print("[WhisperKitSpeechToTextService] Recorded audio average level: \(String(format: "%.3f", metadata.averagePower))")
        print("[WhisperKitSpeechToTextService] Recorded audio peak level: \(String(format: "%.3f", metadata.peakPower))")
        logRecordingDiagnostics(prefix: "Recording validation", url: url)
        #endif

        guard metadata.fileSize > minimumValidRecordingSize,
              metadata.duration >= minimumValidRecordingDuration,
              metadata.channelCount >= 1,
              metadata.frameCount > 0
        else {
            throw WhisperKitSpeechToTextError.noUsableAudio
        }

        guard metadata.peakPower >= 0.08 || metadata.averagePower >= 0.025 else {
            throw WhisperKitSpeechToTextError.lowAudio
        }

        return metadata
    }

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
                powerSamples.append(normalized)
                peakPower = max(peakPower, normalized)
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

    private func logAudioSessionState(prefix: String) {
        #if DEBUG
        let session = AVAudioSession.sharedInstance()
        let inputs = session.currentRoute.inputs.map { "\($0.portName):\($0.portType.rawValue)" }.joined(separator: ", ")
        let outputs = session.currentRoute.outputs.map { "\($0.portName):\($0.portType.rawValue)" }.joined(separator: ", ")
        print("[WhisperKitSpeechToTextService] \(prefix)")
        print("[WhisperKitSpeechToTextService] Input available: \(session.isInputAvailable)")
        print("[WhisperKitSpeechToTextService] Current inputs: \(inputs.isEmpty ? "none" : inputs)")
        print("[WhisperKitSpeechToTextService] Current outputs: \(outputs.isEmpty ? "none" : outputs)")
        print("[WhisperKitSpeechToTextService] Session sample rate: \(session.sampleRate)")
        print("[WhisperKitSpeechToTextService] IO buffer duration: \(session.ioBufferDuration)")
        #endif
    }

    private func logRecordingDiagnostics(prefix: String, url: URL?) {
        #if DEBUG
        debugLog(prefix)
        if let url {
            debugLog("Audio file path: \(url.path)")
            let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            debugLog("Audio file size: \(fileSize) bytes")
        }
        logAudioSessionState(prefix: "\(prefix) session")
        debugLog("Whisper model ready: \(modelManager.isReady)")
        debugLog("WhisperKit instance loaded: \(modelManager.isModelLoaded)")
        debugLog("Active model path: \(modelManager.activeModelPath ?? "none")")
        #endif
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[WhisperKitSpeechToTextService] \(message)")
        #endif
    }

    private func preserveLastRecordingForDebug(from url: URL) throws {
        #if DEBUG
        let debugURL = FileManager.default.temporaryDirectory.appending(path: "last-human-assistant-recording.wav")
        if FileManager.default.fileExists(atPath: debugURL.path) {
            try? FileManager.default.removeItem(at: debugURL)
        }
        try FileManager.default.copyItem(at: url, to: debugURL)
        lastDebugRecordingURL = debugURL
        debugLog("Debug playback copy: \(debugURL.path)")
        #endif
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

private struct RecordingMetadata {
    let fileSize: Int
    let duration: TimeInterval
    let sampleRate: Double
    let channelCount: AVAudioChannelCount
    let frameCount: AVAudioFramePosition
    let averagePower: Double
    let peakPower: Double
}

enum WhisperKitSpeechToTextError: LocalizedError {
    case localModelMissing(String)
    case recordingDidNotStart
    case noUsableAudio
    case lowAudio
    case microphoneUnavailable
    case emptyTranscript
    case sessionAlreadyRunning

    var errorDescription: String? {
        switch self {
        case .localModelMissing(let modelName):
            return "The local Whisper model \(modelName) is not installed yet."
        case .recordingDidNotStart:
            return "I could not start the microphone recording."
        case .noUsableAudio:
            return "I couldn't hear clearly. Please try again."
        case .lowAudio:
            return "I heard very low audio. Please speak closer to the phone."
        case .microphoneUnavailable:
            return "Microphone is not available."
        case .emptyTranscript:
            return "I heard audio, but couldn't understand it clearly. Please try again."
        case .sessionAlreadyRunning:
            return "Voice assistant is already listening or processing."
        }
    }
}
