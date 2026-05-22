import Combine
import SwiftData
import SwiftUI

@MainActor
final class AmbientIntelligenceViewModel: ObservableObject {
    private let habitEngine = HabitLearningEngine()
    private let analyzer = HealthRoutineAnalyzer()
    private let reminderEngine = AmbientAdaptiveReminderEngine()

    func state(
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        womensLogs: [WomensHealthDailyLog],
        periodCycles: [PeriodCycle],
        interactions: [AmbientInteractionMemory],
        environment: AmbientEnvironmentContext
    ) -> AmbientIntelligenceState {
        let signals = habitEngine.learnSignals(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            interactions: interactions
        )

        return analyzer.state(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            periodCycles: periodCycles,
            habitSignals: signals,
            environment: environment
        )
    }

    func reminderRecommendation(
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        womensLogs: [WomensHealthDailyLog],
        interactions: [AmbientInteractionMemory],
        elderlyMode: Bool
    ) -> String {
        let signals = habitEngine.learnSignals(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            interactions: interactions
        )
        return reminderEngine.recommendation(from: signals, elderlyMode: elderlyMode)
    }
}

enum AmbientIntelligenceBuilder {
    static func state(
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        womensLogs: [WomensHealthDailyLog],
        periodCycles: [PeriodCycle],
        interactions: [AmbientInteractionMemory],
        environment: AmbientEnvironmentContext
    ) -> AmbientIntelligenceState {
        let signals = HabitLearningEngine().learnSignals(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            interactions: interactions
        )
        return HealthRoutineAnalyzer().state(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            periodCycles: periodCycles,
            habitSignals: signals,
            environment: environment
        )
    }

    static func reminderRecommendation(
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        womensLogs: [WomensHealthDailyLog],
        interactions: [AmbientInteractionMemory],
        elderlyMode: Bool
    ) -> String {
        let signals = HabitLearningEngine().learnSignals(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            interactions: interactions
        )
        return AmbientAdaptiveReminderEngine().recommendation(from: signals, elderlyMode: elderlyMode)
    }
}
