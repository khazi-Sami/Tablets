import Foundation

enum MedicineVoiceQueryType {
    case todayRoutine
    case weeklyAdherence
    case pending
    case nextMedicine
    case overdue
    case lowStock
    case markNextTaken
    case markSpecificTaken(medicineName: String?)
    case unknown
}

struct MedicineVoiceQueryTypeDetector {
    func detect(_ transcript: String) -> MedicineVoiceQueryType {
        let text = normalize(transcript)
        let markTakenIntent = isMarkTaken(text)
        guard containsMedicineTerm(text) || markTakenIntent else { return .unknown }

        if markTakenIntent {
            if containsAny(text, ["next", "pending", "due", "now"]) {
                return .markNextTaken
            }
            return .markSpecificTaken(medicineName: extractedMedicineName(from: text))
        }

        if containsAny(text, [
            "low stock", "stock", "pills left", "tablets left",
            "which tablets are low", "any low", "medicine stock"
        ]) {
            return .lowStock
        }

        if containsAny(text, [
            "overdue", "missed tablet today", "missed medicine today",
            "did i miss any medicine", "did i miss medicines", "late medicine"
        ]) {
            return .overdue
        }

        if containsAny(text, [
            "next medicine", "next tablet", "next dose",
            "which medicine now", "which tablet now",
            "what tablet should i take now", "what medicine should i take now",
            "kaunsa tablet", "kaunsi dawa"
        ]) {
            return .nextMedicine
        }

        if containsAny(text, [
            "pending", "pending tablet", "pending medicine",
            "tablet pending", "tablet pending hai kya",
            "goli pending", "dawa pending", "how many medicines are pending",
            "what medicine is pending", "any pending tablets", "did i take"
        ]) {
            return .pending
        }

        if containsAny(text, [
            "this week", "weekly", "adherence", "routine this week",
            "how many medicines did i take", "did i miss medicines this week",
            "tablet routine this week", "medicine routine this week"
        ]) {
            return .weeklyAdherence
        }

        if containsAny(text, [
            "medicine routine", "tablet routine", "dose routine",
            "medicine schedule", "tablet schedule", "goli schedule",
            "dawa routine", "today medicine list", "what tablets today",
            "what medicine should i take today", "what medicines today"
        ]) {
            return .todayRoutine
        }

        return .unknown
    }

    private func normalize(_ transcript: String) -> String {
        transcript
            .lowercased()
            .replacingOccurrences(of: "what's", with: "what is")
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func containsMedicineTerm(_ text: String) -> Bool {
        containsAny(text, [
            "medicine", "medicines", "tablet", "tablets", "pill", "pills",
            "dose", "doses", "dawa", "dawai", "goli", "goliyan", "medication"
        ])
    }

    private func isMarkTaken(_ text: String) -> Bool {
        containsAny(text, [
            "mark", "i took", "i have taken", "taken", "took",
            "kha li", "kha liya", "li", "liya"
        ]) && containsAny(text, [
            "taken", "took", "mark", "kha", "li", "liya"
        ])
    }

    private func extractedMedicineName(from text: String) -> String? {
        var cleaned = text
        let removable = [
            "mark", "as taken", "taken", "i took my", "i took", "i have taken",
            "my", "medicine", "tablet", "pill", "dose", "dawa", "goli",
            "kha liya", "kha li", "liya", "li"
        ]
        removable.forEach {
            cleaned = cleaned.replacingOccurrences(of: $0, with: " ")
        }
        let name = cleaned
            .split(separator: " ")
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }

    private func containsAny(_ text: String, _ phrases: [String]) -> Bool {
        phrases.contains { text.contains($0) }
    }
}
