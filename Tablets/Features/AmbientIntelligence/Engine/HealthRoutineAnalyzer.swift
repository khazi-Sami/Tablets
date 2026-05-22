import Foundation
import SwiftUI

struct HealthRoutineAnalyzer {
    func state(
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        womensLogs: [WomensHealthDailyLog],
        periodCycles: [PeriodCycle],
        habitSignals: [AmbientHabitSignal],
        environment: AmbientEnvironmentContext
    ) -> AmbientIntelligenceState {
        let timeMode = timeMode(for: Date())
        let emotionalMode = emotionalMode(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            periodCycles: periodCycles
        )
        let priorities = dashboardPriority(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            periodCycles: periodCycles
        )
        let observations = observations(
            healthRecords: healthRecords,
            habitSignals: habitSignals,
            womensLogs: womensLogs
        )

        return AmbientIntelligenceState(
            timeMode: timeMode,
            emotionalMode: environment.prefersReducedMotion ? .simplified : emotionalMode,
            assistantTone: assistantTone(timeMode: timeMode, emotionalMode: emotionalMode),
            dashboardPriority: priorities,
            observations: observations,
            elderlyModeSuggested: environment.accessibilityCategory.isAccessibilityCategory,
            animationSpeed: environment.prefersReducedMotion || environment.lowPowerModeEnabled ? 0 : timeMode == .night ? 0.55 : 1,
            brightness: timeMode == .night || environment.lowPowerModeEnabled ? 0.72 : 1
        )
    }

    private func timeMode(for date: Date) -> AmbientTimeMode {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return .morning
        case 12..<19: return .afternoon
        default: return .night
        }
    }

    private func emotionalMode(medicineLogs: [MedicineLog], healthRecords: [HealthRecord], womensLogs: [WomensHealthDailyLog], periodCycles: [PeriodCycle]) -> AmbientEmotionalMode {
        if HealthAuraManager.mood(medicineLogs: medicineLogs, healthRecords: healthRecords, womensLogs: womensLogs, periodCycles: periodCycles) == .sunrise {
            return .celebratory
        }
        if medicineLogs.contains(where: { Calendar.current.isDateInToday($0.scheduledTime) && $0.status == .missed }) {
            return .focused
        }
        if womensLogs.first?.sleepQuality == .poor || !(womensLogs.first?.symptoms.isEmpty ?? true) {
            return .healing
        }
        return .calm
    }

    private func dashboardPriority(medicineLogs: [MedicineLog], healthRecords: [HealthRecord], womensLogs: [WomensHealthDailyLog], periodCycles: [PeriodCycle]) -> [AmbientDashboardPriority] {
        var priorities: [AmbientDashboardPriority] = []
        if medicineLogs.contains(where: { Calendar.current.isDateInToday($0.scheduledTime) && $0.status == .missed }) {
            priorities.append(.overdueMedicine)
        }
        priorities.append(.nextMedicine)
        if !healthRecords.contains(where: { Calendar.current.isDateInToday($0.measuredAt) }) {
            priorities.append(.healthLogging)
        }
        if womensLogs.first?.waterIntakeCups ?? 0 < 5 {
            priorities.append(.hydration)
        }
        if periodCycles.contains(where: { $0.endDate == nil }) {
            priorities.append(.womensHealth)
        }
        priorities.append(.healthJourney)
        return Array(priorities.prefix(4))
    }

    private func observations(healthRecords: [HealthRecord], habitSignals: [AmbientHabitSignal], womensLogs: [WomensHealthDailyLog]) -> [String] {
        var observations = ["Based on your logs, small consistent check-ins are shaping your routine."]
        if let medicine = habitSignals.first(where: { $0.signalType == .medicine }) {
            observations.append("Evening reminders may work best around \(formattedHour(medicine.hourOfDay)).")
        }
        if let bp = habitSignals.first(where: { $0.signalType == .bloodPressure }) {
            observations.append("You usually log BP around \(formattedHour(bp.hourOfDay)) based on saved entries.")
        }
        let recent = healthRecords.filter { $0.measuredAt > (Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now) }
        if recent.count >= 3 {
            observations.append("You seem more consistent this week based on your health logs.")
        }
        if womensLogs.first?.sleepQuality == .poor {
            observations.append("Tonight, the app can keep things softer and simpler based on your sleep check-in.")
        }
        return observations
    }

    private func assistantTone(timeMode: AmbientTimeMode, emotionalMode: AmbientEmotionalMode) -> String {
        switch (timeMode, emotionalMode) {
        case (.night, _): return "calm, brief, low energy"
        case (_, .healing): return "soft, reassuring, simple"
        case (.morning, .celebratory): return "warm, energetic, encouraging"
        default: return "warm, clear, supportive"
        }
    }

    private func formattedHour(_ hour: Int) -> String {
        let suffix = hour >= 12 ? "PM" : "AM"
        let value = hour % 12 == 0 ? 12 : hour % 12
        return "\(value) \(suffix)"
    }
}
