import Foundation
import SwiftData

@MainActor
struct SwiftDataHealthMemoryService {
    let modelContext: ModelContext

    func remember(_ command: ParsedHealthCommand) {
        let memory = HumanVoiceMemory(
            memoryType: memoryType(for: command.intent),
            phrase: command.originalText,
            value: command.entities.values.first ?? command.numbers.first.map { String($0) } ?? "",
            count: 1
        )
        modelContext.insert(memory)
        try? modelContext.save()
    }

    private func memoryType(for intent: HealthVoiceIntent) -> HumanVoiceMemoryType {
        switch intent {
        case .medicineTaken, .pendingMedicine, .reminderRequest:
            return .frequentMedicineTime
        case .logSymptoms:
            return .commonSymptom
        default:
            return .habit
        }
    }
}
