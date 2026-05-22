import Foundation

struct HabitLearningEngine {
    func learnSignals(
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        womensLogs: [WomensHealthDailyLog],
        interactions: [AmbientInteractionMemory]
    ) -> [AmbientHabitSignal] {
        var signals: [AmbientHabitSignal] = []

        if let hour = mostCommonHour(medicineLogs.map(\.scheduledTime)) {
            signals.append(AmbientHabitSignal(signalType: .medicine, hourOfDay: hour, eventCount: medicineLogs.count, confidence: confidence(for: medicineLogs.count), note: "Common medicine time"))
        }

        if let hour = mostCommonHour(healthRecords.filter { $0.type == .bloodPressure }.map(\.measuredAt)) {
            signals.append(AmbientHabitSignal(signalType: .bloodPressure, hourOfDay: hour, eventCount: healthRecords.count, confidence: confidence(for: healthRecords.count), note: "BP logging pattern"))
        }

        if let hour = mostCommonHour(womensLogs.map(\.date)) {
            signals.append(AmbientHabitSignal(signalType: .sleep, hourOfDay: hour, eventCount: womensLogs.count, confidence: confidence(for: womensLogs.count), note: "Wellness log timing"))
        }

        if let interaction = interactions.max(by: { $0.count < $1.count }) {
            signals.append(AmbientHabitSignal(signalType: .assistant, hourOfDay: interaction.hourOfDay, eventCount: interaction.count, confidence: confidence(for: interaction.count), note: "Preferred interaction period"))
        }

        return signals
    }

    private func mostCommonHour(_ dates: [Date]) -> Int? {
        let hours = Dictionary(grouping: dates) { Calendar.current.component(.hour, from: $0) }
        return hours.max(by: { $0.value.count < $1.value.count })?.key
    }

    private func confidence(for count: Int) -> Double {
        min(Double(count) / 10.0, 1)
    }
}

