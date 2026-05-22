import Foundation

struct HealthContextEngine {
    func responsePrefix(for tone: AssistantTone, date: Date = .now) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        if hour >= 21 || hour < 6 {
            return "Gently,"
        }

        switch tone {
        case .calm:
            return "Taking it calmly,"
        case .encouraging:
            return "Nice,"
        case .supportive:
            return "I’m with you."
        case .balanced:
            return ""
        }
    }

    func tone(medicineLogs: [MedicineLog], symptomCount: Int, interactions: [AssistantInteractionMemory]) -> AssistantTone {
        let recentMisses = medicineLogs.filter { $0.status == .missed || $0.status == .skipped }.count
        if symptomCount >= 2 || recentMisses > 0 {
            return .supportive
        }

        let commonHour = mostCommonHour(from: interactions)
        let currentHour = Calendar.current.component(.hour, from: .now)
        if let commonHour, abs(commonHour - currentHour) <= 1 {
            return .encouraging
        }

        return currentHour >= 21 || currentHour < 6 ? .calm : .balanced
    }

    private func mostCommonHour(from interactions: [AssistantInteractionMemory]) -> Int? {
        Dictionary(grouping: interactions, by: \.interactionHour)
            .max { $0.value.count < $1.value.count }?
            .key
    }
}
