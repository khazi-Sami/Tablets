import Foundation

protocol SemanticIntentRouting {
    func route(_ transcript: String) async -> RouteResult
}

final class SemanticIntentRouter: SemanticIntentRouting {
    private let similarityEngine: IntentSimilarityScoring
    private let fallback = IntentRouterFallback()

    init(similarityEngine: IntentSimilarityScoring = IntentSimilarityEngine()) {
        self.similarityEngine = similarityEngine
    }

    func route(_ transcript: String) async -> RouteResult {
        let normalized = normalize(transcript)
        if shouldHardGateHealthQuestion(normalized) || containsDirectHealthValues(normalized) || looksLikeSavedHealthQuestion(normalized) {
            return RouteResult(intent: .unknown, confidence: 0, rawTranscript: transcript, matchedExample: nil, needsConfirmation: false)
        }

        if let match = await similarityEngine.bestMatch(for: transcript), match.intent != .unknown {
            return RouteResult(intent: match.intent, confidence: match.confidence, rawTranscript: transcript, matchedExample: match.matchedExample, needsConfirmation: match.needsConfirmation)
        }

        let fallbackResult = fallback.route(transcript)
        return fallbackResult.confidence >= 0.58 ? fallbackResult : RouteResult(intent: .unknown, confidence: fallbackResult.confidence, rawTranscript: transcript, matchedExample: nil, needsConfirmation: false)
    }

    private func normalize(_ transcript: String) -> String {
        transcript
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9\s]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func shouldHardGateHealthQuestion(_ text: String) -> Bool {
        let questionStarts = ["how", "what", "when", "is", "was", "did", "should", "compare", "am i"]
        let navigationPhrases = ["open", "take me to", "go to", "show me the page", "navigate to"]
        let startsWithQuestion = questionStarts.contains { text == $0 || text.hasPrefix("\($0) ") }
        let hasClearNavigation = navigationPhrases.contains { text.contains($0) }
        return startsWithQuestion && !hasClearNavigation
    }

    private func containsDirectHealthValues(_ transcript: String) -> Bool {
        let text = transcript.lowercased()
        let hasNumber = text.range(of: #"(?<!\w)\d+(\.\d+)?(?!\w)"#, options: .regularExpression) != nil
        let hasHealthTerm = ["bp", "blood pressure", "sugar", "glucose", "temperature", "oxygen", "weight"].contains { text.contains($0) }
        return hasNumber && hasHealthTerm
    }

    private func looksLikeSavedHealthQuestion(_ transcript: String) -> Bool {
        let text = transcript.lowercased()
        let questionTerms = ["how is", "what", "when", "average", "last", "pending", "did i", "summary", "compared", "compare"]
        let healthTerms = ["bp", "blood pressure", "sugar", "glucose", "medicine", "tablet", "period", "doctor", "health"]
        return questionTerms.contains { text.contains($0) } && healthTerms.contains { text.contains($0) }
    }
}
