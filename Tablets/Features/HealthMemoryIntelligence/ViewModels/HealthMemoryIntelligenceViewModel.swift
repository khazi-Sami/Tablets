import Foundation
import Combine
import SwiftData
import SwiftUI

@MainActor
final class HealthMemoryIntelligenceViewModel: ObservableObject {
    @Published var tone: AssistantTone = .balanced
    @Published var cards: [HealthInsightCard] = []
    @Published var assistantMessage = "I’ll keep insights gentle and based only on your saved logs."

    func refresh(
        medicines: [Medicine],
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        habits: [UserHealthHabit],
        interactions: [AssistantInteractionMemory],
        symptomLogs: [WomensHealthDailyLog]
    ) {
        tone = HealthContextEngine().tone(
            medicineLogs: Array(medicineLogs.prefix(14)),
            symptomCount: symptomLogs.prefix(7).reduce(0) { $0 + $1.symptoms.count },
            interactions: interactions
        )
        cards = ProactiveHealthSuggestionEngine().suggestions(
            medicines: medicines,
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            habits: habits
        )
        assistantMessage = cards.first?.message ?? "As you keep logging, I’ll notice helpful patterns without sending anything online."
    }
}
