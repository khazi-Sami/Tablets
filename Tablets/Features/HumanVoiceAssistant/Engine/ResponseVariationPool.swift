import Foundation

struct ResponseVariationPool {
    private let safetyDisclaimer = "This is informational only — please consult your doctor."

    func bpSaved(systolic: Int, diastolic: Int, comparison: String) -> String {
        fill(random([
            "Got it. I've saved your blood pressure as {systolic} over {diastolic}. {comparison}",
            "Done. Your BP of {systolic} over {diastolic} is now in your log. {comparison}",
            "Saved. Blood pressure {systolic} over {diastolic} recorded. {comparison}",
            "I've noted your BP as {systolic} over {diastolic}. {comparison}"
        ]), values: ["systolic": "\(systolic)", "diastolic": "\(diastolic)", "comparison": comparison])
    }

    func sugarSaved(value: Int, context: String, comparison: String) -> String {
        fill(random([
            "Got it. I've saved your {context} sugar as {value}. {comparison}",
            "Done. Your sugar reading of {value} has been logged. {comparison}",
            "Saved. {value} recorded as your {context} sugar level. {comparison}",
            "I've noted your {context} sugar as {value}. {comparison}"
        ]), values: ["value": "\(value)", "context": context, "comparison": comparison])
    }

    func symptomSaved(symptoms: String) -> String {
        fill(random([
            "I've saved {symptoms} in your health log. If anything worsens, please contact a doctor.",
            "Got it. I've recorded {symptoms} in your symptom log. Please consult your doctor if needed.",
            "Noted. {symptoms} saved in your log. Please seek medical advice if symptoms persist.",
            "I've logged {symptoms} for you. Please consult a doctor if these symptoms continue."
        ]), values: ["symptoms": symptoms])
    }

    func medicineTaken(medicine: String) -> String {
        fill(random([
            "Got it. I've marked your {medicine} as taken.",
            "Done. Your {medicine} dose has been logged.",
            "Noted. I've recorded that you took your {medicine}.",
            "Saved. {medicine} marked as taken for today."
        ]), values: ["medicine": medicine])
    }

    func noDataFound() -> String {
        random([
            "I don't have enough saved data to answer that yet. Try logging more readings.",
            "There are no records for that yet. Start logging and I'll be able to help.",
            "I couldn't find data for that. The more you log, the better I can answer.",
            "No saved records found for that. Please log some readings first."
        ])
    }

    func navigation(_ templates: [String]) -> String {
        random(templates)
    }

    func safeComparison() -> String {
        random([
            "Based on your recent logs, this looks stable.",
            "Compared to your last reading, this is similar.",
            "Your readings have been consistent recently.",
            "Based on your saved data, no significant change.",
            "I'll note this alongside your recent readings.",
            safetyDisclaimer
        ])
    }

    func withSafety(_ text: String) -> String {
        text.contains("informational only") || text.contains("consult your doctor") ? text : "\(text) \(safetyDisclaimer)"
    }

    private func random(_ templates: [String]) -> String {
        templates[Int.random(in: 0..<templates.count)]
    }

    private func fill(_ template: String, values: [String: String]) -> String {
        values.reduce(template) { partial, pair in
            partial.replacingOccurrences(of: "{\(pair.key)}", with: pair.value)
        }
    }
}
