import Foundation

enum HealthQueryType {
    case bpLatest
    case bpAverage
    case bpComparison
    case bpRangeCheck(systolic: Double?, diastolic: Double?)
    case sugarLatest
    case sugarAverage
    case sugarComparison
    case sugarRangeCheck(value: Double?, testType: SugarTestType?)
    case medicinePending
    case medicineNext
    case medicineTakenStatus
    case periodLast
    case periodNext
    case periodCycle
    case doctorNext
    case healthSummary
    case unknown
}

final class HealthQueryTypeDetector {
    func detect(_ transcript: String) -> HealthQueryType {
        let text = normalize(transcript)
        let numbers = extractNumbers(text)
        let hasBP = containsAny(text, ["bp", "blood pressure", "pressure", "systolic", "diastolic"])
        let hasSugar = containsAny(text, ["sugar", "blood sugar", "glucose", "diabetes"])
        let hasMedicine = containsAny(text, ["medicine", "tablet", "pill", "dose", "pending", "taken"])
        let hasPeriod = containsAny(text, ["period", "cycle", "monthly", "menstrual"])
        let hasDoctor = containsAny(text, ["doctor", "clinic", "checkup", "appointment"])
        let hasAverage = containsAny(text, ["average", "weekly", "this week", "last week"])
        let hasComparison = containsAny(text, ["compare", "compared", "better than", "yesterday", "last time", "last week", "this week"])
        let hasRangeCheck = containsAny(text, ["okay", " ok ", "normal", "high", "low"]) || text.hasPrefix("is ")

        if hasBP || looksLikeBPRange(text, numbers: numbers) {
            if hasRangeCheck || looksLikeBPRange(text, numbers: numbers) {
                return .bpRangeCheck(systolic: numbers.first, diastolic: numbers.dropFirst().first)
            }
            if hasAverage { return .bpAverage }
            if hasComparison { return .bpComparison }
            return .bpLatest
        }

        if hasSugar {
            if hasRangeCheck || !numbers.isEmpty {
                return .sugarRangeCheck(value: numbers.first, testType: sugarTestType(in: text))
            }
            if hasAverage { return .sugarAverage }
            if hasComparison { return .sugarComparison }
            return .sugarLatest
        }

        if hasMedicine {
            if containsAny(text, ["did i", "taken", "took"]) { return .medicineTakenStatus }
            if containsAny(text, ["next", "when"]) { return .medicineNext }
            if containsAny(text, ["pending", "should i take", "miss"]) { return .medicinePending }
            return .medicinePending
        }

        if hasPeriod {
            if containsAny(text, ["next", "late", "am i"]) { return .periodNext }
            if containsAny(text, ["cycle", "length"]) { return .periodCycle }
            return .periodLast
        }

        if hasDoctor {
            return .doctorNext
        }

        if containsAny(text, ["how am i doing", "how is my health", "give me summary", "health status", "what happened this week"]) {
            return .healthSummary
        }

        return .unknown
    }

    private func normalize(_ transcript: String) -> String {
        var text = transcript.lowercased()
        let replacements: [(String, String)] = [
            ("one twenty", "120"),
            ("one forty five", "145"),
            ("one forty", "140"),
            ("one fifty", "150"),
            ("one ten", "110"),
            ("one hundred and ten", "110"),
            ("one hundred ten", "110"),
            ("eighty", "80"),
            ("ninety", "90"),
            ("seventy", "70"),
            ("sixty", "60")
        ]
        replacements.forEach { text = text.replacingOccurrences(of: $0.0, with: $0.1) }
        text = text.replacingOccurrences(of: #"[^a-z0-9/\s\.]"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractNumbers(_ text: String) -> [Double] {
        guard let regex = try? NSRegularExpression(pattern: #"(?<!\w)\d+(\.\d+)?(?!\w)"#) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap {
            Range($0.range, in: text).flatMap { Double(text[$0]) }
        }
    }

    private func looksLikeBPRange(_ text: String, numbers: [Double]) -> Bool {
        numbers.count >= 2 && (text.contains(" over ") || text.contains("/") || text.contains("pressure") || text.contains("bp"))
    }

    private func sugarTestType(in text: String) -> SugarTestType? {
        if containsAny(text, ["fasting"]) { return .fasting }
        if containsAny(text, ["after food", "after meal", "post meal", "after lunch", "after dinner", "after breakfast"]) { return .afterMeal }
        if containsAny(text, ["before food", "before meal"]) { return .beforeMeal }
        if containsAny(text, ["random"]) { return .random }
        return nil
    }

    private func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains { text.contains($0) }
    }
}
