import Foundation
import NaturalLanguage

struct HealthIntentParser {
    func parse(_ text: String) -> ParsedHealthCommand {
        let normalized = normalizeNumberWords(in: text.lowercased())
        let numbers = extractNumbers(normalized)
        let symptoms = extractSymptoms(normalized)
        let entities = extractEntities(normalized)

        let intent: HealthVoiceIntent
        let confidence: Double

        if normalized.contains("when did i") || normalized.contains("how many") || normalized.contains("show my sugar trend") {
            intent = .memorySearch
            confidence = 0.82
        } else if normalized.contains("did i take") || normalized.contains("have i taken") {
            intent = .askMedicineTaken
            confidence = 0.83
        } else if normalized.contains("start") && normalized.contains("period") {
            intent = .startPeriod
            confidence = 0.84
        } else if (normalized.contains("sugar") || normalized.contains("glucose")) && (normalized.contains("how") || normalized.contains("compare") || normalized.contains("compared")) {
            intent = .askSugar
            confidence = 0.80
        } else if normalized.contains("sugar") || normalized.contains("glucose") {
            intent = .logSugar
            confidence = numbers.isEmpty ? 0.45 : 0.88
        } else if normalized.contains("bp") || normalized.contains("blood pressure") {
            intent = numbers.count >= 2 ? .logBloodPressure : .askBloodPressure
            confidence = numbers.count >= 2 ? 0.9 : 0.78
        } else if normalized.contains("how is my bp") {
            intent = .askBloodPressure
            confidence = 0.82
        } else if !symptoms.isEmpty || normalized.contains("symptom") {
            intent = .logSymptoms
            confidence = symptoms.isEmpty ? 0.52 : 0.86
        } else if normalized.contains("i took") || normalized.contains("taken") {
            intent = .medicineTaken
            confidence = 0.78
        } else if normalized.contains("pending") || normalized.contains("medicine left") || normalized.contains("what medicine") {
            intent = .pendingMedicine
            confidence = 0.80
        } else if normalized.contains("remind me") {
            intent = .reminderRequest
            confidence = entities["time"] == nil ? 0.58 : 0.82
        } else if normalized.contains("this week") || normalized.contains("health") {
            intent = .weeklyHealth
            confidence = 0.72
        } else {
            intent = .unknown
            confidence = 0.30
        }

        return ParsedHealthCommand(intent: intent, originalText: text, numbers: numbers, symptoms: symptoms, entities: entities, confidence: confidence)
    }

    private func extractNumbers(_ text: String) -> [Double] {
        let pattern = #"(?<!\w)\d+(\.\d+)?(?!\w)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap {
            Range($0.range, in: text).flatMap { Double(text[$0]) }
        }
    }

    private func extractSymptoms(_ text: String) -> [String] {
        ["headache", "dizziness", "fatigue", "tired", "tiredness", "cramps", "back pain", "bloating", "nausea", "pain"].filter {
            text.contains($0)
        }
    }

    private func extractEntities(_ text: String) -> [String: String] {
        var entities: [String: String] = [:]
        if text.contains("after food") || text.contains("after meal") {
            entities["sugarTestType"] = SugarTestType.afterMeal.rawValue
        } else if text.contains("after lunch") || text.contains("after dinner") || text.contains("after breakfast") {
            entities["sugarTestType"] = SugarTestType.afterMeal.rawValue
            entities["mealContext"] = text.contains("lunch") ? "lunch" : text.contains("dinner") ? "dinner" : "breakfast"
        } else if text.contains("before food") || text.contains("before meal") {
            entities["sugarTestType"] = SugarTestType.beforeMeal.rawValue
        } else if text.contains("fasting") {
            entities["sugarTestType"] = SugarTestType.fasting.rawValue
        }
        if text.contains("diabetes tablet") {
            entities["medicineHint"] = "diabetes"
        } else if text.contains("night tablet") {
            entities["medicineHint"] = "night"
        }
        if let time = firstMatch(text, pattern: #"(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)"#) {
            entities["time"] = time
        }
        return entities
    }

    private func normalizeNumberWords(in text: String) -> String {
        var normalized = text
        let phrases: [(String, String)] = [
            ("one twenty", "120"),
            ("one thirty", "130"),
            ("one forty five", "145"),
            ("one forty", "140"),
            ("one fifty", "150"),
            ("eighty", "80"),
            ("ninety", "90"),
            ("seventy", "70"),
            ("sixty", "60"),
            ("one ten", "110"),
            ("one hundred ten", "110"),
            ("one hundred and ten", "110")
        ]

        for (phrase, value) in phrases {
            normalized = normalized.replacingOccurrences(of: phrase, with: value)
        }

        let smallNumbers: [String: String] = [
            "zero": "0", "one": "1", "two": "2", "three": "3", "four": "4",
            "five": "5", "six": "6", "seven": "7", "eight": "8", "nine": "9",
            "ten": "10"
        ]
        for (word, value) in smallNumbers {
            normalized = normalized.replacingOccurrences(of: " \(word) ", with: " \(value) ")
        }

        return normalized
    }

    private func firstMatch(_ text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), let swiftRange = Range(match.range, in: text) else { return nil }
        return String(text[swiftRange])
    }
}
