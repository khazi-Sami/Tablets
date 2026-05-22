import Foundation
import NaturalLanguage

protocol IntentSimilarityScoring {
    func bestMatch(for transcript: String) async -> IntentExampleMatch?
}

final class IntentSimilarityEngine: IntentSimilarityScoring {
    private struct CachedExample {
        let group: IntentExampleGroup
        let example: String
        let vector: [Double]
    }

    private var cachedExamples: [CachedExample]?
    private let embedding = NLEmbedding.wordEmbedding(for: .english)

    func bestMatch(for transcript: String) async -> IntentExampleMatch? {
        let normalized = normalize(transcript)
        guard !normalized.isEmpty, embedding != nil else { return nil }

        return await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self, let transcriptVector = self.vector(for: normalized) else { return nil }
            let examples = self.loadCachedExamples()
            guard !examples.isEmpty else { return nil }

            let best = examples
                .map { ($0, self.cosine(transcriptVector, $0.vector)) }
                .max { $0.1 < $1.1 }

            guard let best, best.1 >= 0.58 else {
                return IntentExampleMatch(intent: .unknown, confidence: best?.1 ?? 0, rawTranscript: transcript, matchedExample: best?.0.example, displayName: best?.0.group.displayName, needsConfirmation: false)
            }

            return IntentExampleMatch(
                intent: AppNavigationIntent(intentId: best.0.group.intentId),
                confidence: best.1,
                rawTranscript: transcript,
                matchedExample: best.0.example,
                displayName: best.0.group.displayName,
                needsConfirmation: best.1 < 0.72
            )
        }.value
    }

    private func loadCachedExamples() -> [CachedExample] {
        if let cachedExamples { return cachedExamples }
        guard let url = Bundle.main.url(forResource: "IntentExampleLibrary", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let groups = try? JSONDecoder().decode([IntentExampleGroup].self, from: data) else {
            return []
        }
        let cached = groups.flatMap { group in
            group.examples.compactMap { example -> CachedExample? in
                guard let vector = vector(for: normalize(example)) else { return nil }
                return CachedExample(group: group, example: example, vector: vector)
            }
        }
        cachedExamples = cached
        return cached
    }

    private func vector(for text: String) -> [Double]? {
        guard let embedding else { return nil }
        let words = text.split(separator: " ").map(String.init)
        let vectors = words.compactMap { embedding.vector(for: $0) }
        guard let first = vectors.first else { return nil }
        var sum = Array(repeating: 0.0, count: first.count)
        for vector in vectors {
            for index in vector.indices { sum[index] += vector[index] }
        }
        return sum.map { $0 / Double(vectors.count) }
    }

    private func cosine(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count else { return 0 }
        let dot = zip(a, b).map(*).reduce(0, +)
        let magA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        guard magA > 0, magB > 0 else { return 0 }
        return dot / (magA * magB)
    }

    private func normalize(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.punctuationCharacters)
            .joined(separator: " ")
            .split(separator: " ")
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
