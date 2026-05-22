import Foundation

struct PrescriptionParserService {
    func parse(_ text: String) -> [PrescriptionMedicineDraft] {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let candidateLines = lines.filter { line in
            line.range(of: #"\d+\s*(mg|ml|mcg|g|iu|tablet|tab|capsule|cap)"#, options: [.regularExpression, .caseInsensitive]) != nil
                || line.localizedCaseInsensitiveContains("tablet")
                || line.localizedCaseInsensitiveContains("syrup")
                || line.localizedCaseInsensitiveContains("cap")
        }

        let drafts = candidateLines.map(makeDraft(from:))
        return drafts.isEmpty ? [PrescriptionMedicineDraft.empty] : drafts
    }

    private func makeDraft(from line: String) -> PrescriptionMedicineDraft {
        let dosage = firstMatch(in: line, pattern: #"\d+(\.\d+)?\s*(mg|ml|mcg|g|iu|tablet|tab|capsule|cap)"#) ?? ""
        let instruction = instruction(from: line)
        let duration = firstMatch(in: line, pattern: #"(\d+\s*(days|day|weeks|week|months|month))"#) ?? ""
        let timing = timing(from: line)
        let name = medicineName(from: line, removing: [dosage, duration, timing])
        let confidence: PrescriptionMedicineDraft.Confidence = name.isEmpty || dosage.isEmpty ? .unclear : timing.isEmpty ? .needsReview : .high

        return PrescriptionMedicineDraft(
            name: name,
            dosage: dosage,
            timing: timing,
            instruction: instruction,
            duration: duration,
            notes: line,
            confidence: confidence
        )
    }

    private func medicineName(from line: String, removing fragments: [String]) -> String {
        var value = line
        fragments.filter { !$0.isEmpty }.forEach {
            value = value.replacingOccurrences(of: $0, with: "", options: [.caseInsensitive])
        }
        ["after food", "before food", "with food", "empty stomach", "morning", "night", "daily", "twice", "once"].forEach {
            value = value.replacingOccurrences(of: $0, with: "", options: [.caseInsensitive])
        }
        return value.trimmingCharacters(in: CharacterSet(charactersIn: "-:• ").union(.whitespacesAndNewlines))
    }

    private func instruction(from line: String) -> MedicineInstruction {
        if line.localizedCaseInsensitiveContains("before food") { return .beforeFood }
        if line.localizedCaseInsensitiveContains("with food") { return .withFood }
        if line.localizedCaseInsensitiveContains("empty stomach") { return .emptyStomach }
        return .afterFood
    }

    private func timing(from line: String) -> String {
        var parts: [String] = []
        if line.localizedCaseInsensitiveContains("morning") { parts.append("Morning") }
        if line.localizedCaseInsensitiveContains("afternoon") { parts.append("Afternoon") }
        if line.localizedCaseInsensitiveContains("evening") { parts.append("Evening") }
        if line.localizedCaseInsensitiveContains("night") { parts.append("Night") }
        if line.localizedCaseInsensitiveContains("twice") { parts.append("Twice daily") }
        if line.localizedCaseInsensitiveContains("once") { parts.append("Once daily") }
        return parts.joined(separator: ", ")
    }

    private func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let swiftRange = Range(match.range, in: text) else {
            return nil
        }
        return String(text[swiftRange])
    }
}
