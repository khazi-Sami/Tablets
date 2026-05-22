import Foundation
import NaturalLanguage

struct CustomShortcutSafety {
    static let reservedPhraseMessage = "This phrase is too general and may conflict with health commands. Please make it more specific."
    static let conflictWarningMessage = "This sounds similar to an existing voice command. It may not work reliably."

    private static let reservedHealthTerms = [
        "bp", "blood pressure", "pressure", "sugar", "glucose", "diabetes",
        "temperature", "oxygen", "weight", "pulse", "heart rate",
        "medicine", "tablet", "pill", "dose", "taken", "pending", "missed",
        "period", "cycle", "menstrual", "women health", "ladies health", "health"
    ]

    private static let reservedQuestionPhrases = [
        "how is", "what is", "when was", "when is", "did i", "should i",
        "compare", "am i"
    ]

    private static let healthQuestionStarts = [
        "how", "what", "when", "is", "was", "did", "should", "compare", "am i"
    ]

    private static let healthQuestionTerms = [
        "bp", "blood pressure", "sugar", "glucose", "diabetes", "medicine",
        "tablet", "period", "doctor", "health"
    ]

    private static let metricTerms = [
        "bp", "blood pressure", "pressure", "sugar", "glucose", "diabetes",
        "temperature", "oxygen", "weight", "pulse", "heart rate"
    ]

    static let safeNavigationIntentIds: Set<String> = [
        "openDashboard", "openMedicines", "openAddMedicine", "openHealthTracking",
        "openSugarTracking", "openSugarLog", "openBPTracking", "openBPLog",
        "openPeriods", "openAddPeriodLog", "openCyclePrediction", "openDoctorVisit",
        "openPrescriptionScanner", "openFamilyCare", "openProfile", "openHealthMemory",
        "openMedicineReminder", "openDailyCheckIn", "openSettings", "openHealthJourney",
        "openMore"
    ]

    static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .components(separatedBy: CharacterSet.punctuationCharacters)
            .joined(separator: " ")
            .split(separator: " ")
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isReservedTrigger(_ trigger: String) -> Bool {
        let normalized = normalize(trigger)
        guard !normalized.isEmpty else { return false }

        if reservedHealthTerms.contains(normalized) || reservedQuestionPhrases.contains(normalized) {
            return true
        }

        if normalized.split(separator: " ").count <= 3 {
            if reservedHealthTerms.contains(where: { normalized == "my \($0)" || normalized == "open \($0)" }) {
                return true
            }
            if reservedQuestionPhrases.contains(where: { normalized.hasPrefix($0) }),
               containsAny(normalized, reservedHealthTerms) {
                return true
            }
        }

        return false
    }

    static func isDirectHealthLoggingCandidate(_ transcript: String) -> Bool {
        let normalized = normalize(transcript)
        return containsAny(normalized, metricTerms) && containsNumericValue(normalized)
    }

    static func isHealthQuestionCandidate(_ transcript: String) -> Bool {
        let normalized = normalize(transcript)
        guard containsAny(normalized, healthQuestionTerms) else { return false }
        return healthQuestionStarts.contains { start in
            normalized == start || normalized.hasPrefix("\(start) ")
        }
    }

    static func conflictsWithBuiltInCommand(_ phrase: String) -> Bool {
        let normalizedPhrase = normalize(phrase)
        guard !normalizedPhrase.isEmpty else { return false }
        return builtInExamples().contains { example in
            let normalizedExample = normalize(example)
            guard !normalizedExample.isEmpty else { return false }
            if normalizedPhrase == normalizedExample { return true }
            if normalizedPhrase.count > 4, normalizedExample.contains(normalizedPhrase) { return true }
            if normalizedExample.count > 4, normalizedPhrase.contains(normalizedExample) { return true }
            return similarity(normalizedPhrase, normalizedExample) > 0.80
        }
    }

    private static func containsNumericValue(_ text: String) -> Bool {
        if text.range(of: #"\d+(\.\d+)?"#, options: .regularExpression) != nil {
            return true
        }
        let numberWords = [
            "zero", "one", "two", "three", "four", "five", "six", "seven",
            "eight", "nine", "ten", "twenty", "thirty", "forty", "fifty",
            "sixty", "seventy", "eighty", "ninety", "hundred", "ek", "do",
            "teen", "char", "paanch", "saat", "aath", "nau", "sau", "assi",
            "nabbe"
        ]
        return containsAny(text, numberWords)
    }

    private static func builtInExamples() -> [String] {
        guard let url = Bundle.main.url(forResource: "IntentExampleLibrary", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let groups = try? JSONDecoder().decode([IntentExampleGroup].self, from: data)
        else {
            return []
        }
        return groups.flatMap(\.examples)
    }

    private static func similarity(_ lhs: String, _ rhs: String) -> Double {
        if let embedding = NLEmbedding.wordEmbedding(for: .english),
           let lhsVector = averageVector(for: lhs, embedding: embedding),
           let rhsVector = averageVector(for: rhs, embedding: embedding) {
            return cosine(lhsVector, rhsVector)
        }

        let lhsTokens = Set(lhs.split(separator: " ").map(String.init))
        let rhsTokens = Set(rhs.split(separator: " ").map(String.init))
        guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else { return 0 }
        let intersection = lhsTokens.intersection(rhsTokens).count
        let union = lhsTokens.union(rhsTokens).count
        return Double(intersection) / Double(union)
    }

    private static func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains { text.contains($0) }
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
