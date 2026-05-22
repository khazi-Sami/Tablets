import Foundation

struct VoiceActivityDetector {
    let speechThreshold: Double = 0.16
    let silenceTimeout: TimeInterval = 1.5
    let noSpeechTimeout: TimeInterval = 5.0
    let maximumDuration: TimeInterval = 12.0
    let startupGracePeriod: TimeInterval = 0.5
    let minimumAudioBeforeAutoStop: TimeInterval = 0.7

    private(set) var speechStarted = false
    private(set) var startedAt = Date()
    private(set) var lastSpeechAt = Date()

    mutating func reset(now: Date = .now) {
        speechStarted = false
        startedAt = now
        lastSpeechAt = now
    }

    mutating func update(audioLevel: Double, now: Date = .now) -> VoiceActivityDecision {
        let elapsed = now.timeIntervalSince(startedAt)

        if audioLevel > speechThreshold {
            speechStarted = true
            lastSpeechAt = now
            return .continueListening(speechDetected: true)
        }

        if elapsed < startupGracePeriod {
            return .continueListening(speechDetected: speechStarted)
        }

        if elapsed >= maximumDuration {
            return .stop(reason: .maximumDuration)
        }

        if !speechStarted && elapsed >= noSpeechTimeout {
            return .stop(reason: .noSpeechDetected)
        }

        if speechStarted && elapsed >= minimumAudioBeforeAutoStop && now.timeIntervalSince(lastSpeechAt) >= silenceTimeout {
            return .stop(reason: .silenceAfterSpeech)
        }

        return .continueListening(speechDetected: speechStarted)
    }
}

enum VoiceActivityDecision {
    case continueListening(speechDetected: Bool)
    case stop(reason: VoiceActivityStopReason)
}

enum VoiceActivityStopReason {
    case silenceAfterSpeech
    case noSpeechDetected
    case maximumDuration
}
