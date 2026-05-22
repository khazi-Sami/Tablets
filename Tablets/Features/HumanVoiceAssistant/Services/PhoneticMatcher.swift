import Foundation

struct PhoneticMatchResult {
    let intent: AppNavigationIntent
    let confidence: Double
    let matchedTerm: String?
}

struct PhoneticMatcher {
    private let intentTerms: [(AppNavigationIntent, [String])] = [
        (.openBPTracking, ["pressure", "blood pressure", "bp", "fresher", "tension"]),
        (.openBPLog, ["record pressure", "record bp", "add pressure", "enter bp"]),
        (.openSugarTracking, ["glucose", "gluco", "sugar", "diabetes", "diabetic"]),
        (.openSugarLog, ["record sugar", "log glucose", "add sugar", "enter sugar"]),
        (.openMedicines, ["medicine", "medcine", "tablet", "tablat", "pill", "goli"]),
        (.openAddMedicine, ["add medicine", "new tablet", "add tablet", "new pill"]),
        (.openPeriods, ["period", "peroid", "paired", "cycle", "women", "ladies"]),
        (.openPrescriptionScanner, ["prescription", "scanner", "scan", "doctor slip"]),
        (.openDoctorVisit, ["doctor", "appointment", "clinic", "checkup"]),
        (.openHealthJourney, ["journey", "progress", "timeline", "wellness"]),
        (.openSettings, ["settings", "preference", "options"])
    ]

    func match(_ transcript: String) -> PhoneticMatchResult? {
        let words = tokenize(transcript)
        guard !words.isEmpty else { return nil }
        let wordCodes = Set(words.map(code))
        var best: PhoneticMatchResult?

        for (intent, terms) in intentTerms {
            for term in terms {
                let termCodes = Set(tokenize(term).map(code))
                guard !termCodes.isEmpty else { continue }
                let overlap = Double(wordCodes.intersection(termCodes).count)
                let confidence = overlap / Double(termCodes.count)
                if confidence > (best?.confidence ?? 0) {
                    best = PhoneticMatchResult(intent: intent, confidence: confidence, matchedTerm: term)
                }
            }
        }

        guard let best, best.confidence > 0.60 else { return nil }
        return best
    }

    private func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .replacingOccurrences(of: #"[^a-z0-9\s]"#, with: " ", options: .regularExpression)
            .split(separator: " ")
            .map(String.init)
    }

    // Compact Soundex-style phonetic code. It is intentionally small and local.
    private func code(_ word: String) -> String {
        let alias = [
            "fresher": "pressure",
            "glucos": "glucose",
            "gluco": "glucose",
            "medcine": "medicine",
            "peroid": "period",
            "paired": "period",
            "tablat": "tablet"
        ][word] ?? word
        let word = alias
        guard let first = word.first else { return "" }
        let mapped = word.dropFirst().map { char -> Character in
            switch char {
            case "b", "f", "p", "v": return "1"
            case "c", "g", "j", "k", "q", "s", "x", "z": return "2"
            case "d", "t": return "3"
            case "l": return "4"
            case "m", "n": return "5"
            case "r": return "6"
            default: return "0"
            }
        }
        var result = String(first)
        var previous: Character?
        for char in mapped where char != "0" {
            if char != previous {
                result.append(char)
            }
            previous = char
        }
        return result.padding(toLength: 4, withPad: "0", startingAt: 0).prefix(4).description
    }
}
