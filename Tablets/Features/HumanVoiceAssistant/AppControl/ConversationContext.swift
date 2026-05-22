import Combine
import Foundation

enum HealthTopic: String {
    case bp
    case sugar
    case period
    case medicine
    case health
}

struct ConversationTurn {
    let transcript: String
    let intent: String
    let response: String
    let timestamp: Date
}

@MainActor
final class ConversationContext: ObservableObject {
    @Published private(set) var recentTurns: [ConversationTurn] = []
    @Published var activeTopic: HealthTopic?
    @Published var lastIntent: AppNavigationIntent?
    @Published var lastHealthQuery: HealthQueryType?

    func resolve(_ transcript: String) -> String {
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let activeTopic else { return text }
        let normalized = text.lowercased()

        if containsAny(normalized, ["what about last week", "last week", "what about yesterday", "yesterday"]) && !containsTopic(normalized) {
            return "\(topicPhrase(activeTopic)) \(normalized)"
        }

        if containsAny(normalized, ["is that", "that okay", "is it", "is this", "what about that", "what about it"]) && !containsTopic(normalized) {
            return normalized.replacingOccurrences(of: "that", with: topicPhrase(activeTopic))
                .replacingOccurrences(of: "it", with: topicPhrase(activeTopic))
                .replacingOccurrences(of: "this", with: topicPhrase(activeTopic))
        }

        if containsAny(normalized, ["show me that", "open that", "show that screen", "show me that screen"]) {
            switch activeTopic {
            case .bp: return "open bp tracking"
            case .sugar: return "open sugar tracking"
            case .period: return "open period tracker"
            case .medicine: return "open medicines"
            case .health: return "open health tracking"
            }
        }

        return text
    }

    func update(transcript: String, intent: String, response: String) {
        recentTurns.append(ConversationTurn(transcript: transcript, intent: intent, response: response, timestamp: .now))
        if recentTurns.count > 5 {
            recentTurns.removeFirst(recentTurns.count - 5)
        }
        updateTopic(from: transcript, intent: intent)
    }

    func clear() {
        recentTurns.removeAll()
        activeTopic = nil
        lastIntent = nil
        lastHealthQuery = nil
    }

    private func updateTopic(from transcript: String, intent: String) {
        let text = transcript.lowercased()
        if containsAny(text, ["bp", "blood pressure", "pressure", "tension"]) || intent.contains("BloodPressure") {
            activeTopic = .bp
        } else if containsAny(text, ["sugar", "glucose", "diabetes"]) || intent.contains("Sugar") {
            activeTopic = .sugar
        } else if containsAny(text, ["period", "cycle", "women", "ladies"]) || intent.contains("Period") {
            activeTopic = .period
        } else if containsAny(text, ["medicine", "tablet", "pill", "dose", "goli"]) || intent.contains("Medicine") {
            activeTopic = .medicine
        } else if containsAny(text, ["health", "summary", "overall"]) {
            activeTopic = .health
        }
    }

    private func containsTopic(_ text: String) -> Bool {
        containsAny(text, ["bp", "blood pressure", "pressure", "tension", "sugar", "glucose", "diabetes", "period", "cycle", "medicine", "tablet", "pill", "health"])
    }

    private func topicPhrase(_ topic: HealthTopic) -> String {
        switch topic {
        case .bp: return "my bp"
        case .sugar: return "my sugar"
        case .period: return "my period"
        case .medicine: return "my medicine"
        case .health: return "my health"
        }
    }

    private func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains { text.contains($0) }
    }
}
