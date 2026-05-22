import Foundation
import NaturalLanguage
import SwiftData

@MainActor
protocol CustomShortcutMatching {
    func match(_ transcript: String, context: ModelContext) async -> CustomShortcutMatch?
}

struct CustomShortcutMatch {
    let shortcut: CustomVoiceShortcut
    let confidence: Double
    let needsConfirmation: Bool
}

@MainActor
final class CustomShortcutMatcher: CustomShortcutMatching {
    func match(_ transcript: String, context: ModelContext) async -> CustomShortcutMatch? {
        if CustomShortcutSafety.isDirectHealthLoggingCandidate(transcript) ||
            CustomShortcutSafety.isHealthQuestionCandidate(transcript) {
            return nil
        }

        let normalizedTranscript = CustomShortcutSafety.normalize(transcript)
        guard !normalizedTranscript.isEmpty else { return nil }

        let descriptor = FetchDescriptor<CustomVoiceShortcut>(
            predicate: #Predicate { $0.isEnabled == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let shortcuts = try? context.fetch(descriptor), !shortcuts.isEmpty else {
            return nil
        }

        var bestShortcut: CustomVoiceShortcut?
        var bestScore = 0.0

        for shortcut in shortcuts {
            let trigger = CustomShortcutSafety.normalize(shortcut.triggerPhrase)
            guard !trigger.isEmpty, !CustomShortcutSafety.isReservedTrigger(trigger) else { continue }

            let score: Double
            if normalizedTranscript == trigger {
                score = 1.0
            } else if trigger.count > 4,
                      (normalizedTranscript.contains(trigger) || trigger.contains(normalizedTranscript)) {
                score = 0.92
            } else {
                score = await embeddingSimilarity(normalizedTranscript, trigger)
            }

            if score > bestScore {
                bestScore = score
                bestShortcut = shortcut
            }
        }

        guard bestScore >= 0.78, let bestShortcut else { return nil }
        return CustomShortcutMatch(
            shortcut: bestShortcut,
            confidence: bestScore,
            needsConfirmation: bestScore < 0.88
        )
    }

    func markTriggered(_ shortcut: CustomVoiceShortcut, context: ModelContext) {
        shortcut.triggerCount += 1
        shortcut.lastTriggeredAt = .now
        try? context.save()
    }

    private func embeddingSimilarity(_ lhs: String, _ rhs: String) async -> Double {
        guard let embedding = NLEmbedding.wordEmbedding(for: .english),
              let lhsVector = averageVector(for: lhs, embedding: embedding),
              let rhsVector = averageVector(for: rhs, embedding: embedding)
        else {
            return 0
        }
        return cosine(lhsVector, rhsVector)
    }
}

private func averageVector(for text: String, embedding: NLEmbedding) -> [Double]? {
    let words = text.split(separator: " ").map(String.init)
    let vectors = words.compactMap { embedding.vector(for: $0) }
    guard !vectors.isEmpty else { return nil }

    let dimensions = vectors[0].count
    var average = Array(repeating: 0.0, count: dimensions)
    for vector in vectors where vector.count == dimensions {
        for index in 0..<dimensions {
            average[index] += vector[index]
        }
    }
    return average.map { $0 / Double(vectors.count) }
}

private func cosine(_ lhs: [Double], _ rhs: [Double]) -> Double {
    guard lhs.count == rhs.count, !lhs.isEmpty else { return 0 }
    var dot = 0.0
    var lhsMagnitude = 0.0
    var rhsMagnitude = 0.0

    for index in lhs.indices {
        dot += lhs[index] * rhs[index]
        lhsMagnitude += lhs[index] * lhs[index]
        rhsMagnitude += rhs[index] * rhs[index]
    }

    let denominator = sqrt(lhsMagnitude) * sqrt(rhsMagnitude)
    guard denominator > 0 else { return 0 }
    return dot / denominator
}
