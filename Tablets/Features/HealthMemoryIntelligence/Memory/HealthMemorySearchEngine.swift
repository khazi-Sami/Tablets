import Foundation

struct HealthMemorySearchEngine {
    func answer(_ command: ParsedHealthCommand, healthRecords: [HealthRecord], medicineLogs: [MedicineLog], symptomLogs: [WomensHealthDailyLog]) -> String? {
        let text = command.originalText.lowercased()

        if text.contains("last record bp") || text.contains("last recorded bp") || text.contains("when did i last record bp") {
            return lastBP(records: healthRecords)
        }

        if text.contains("headache") && (text.contains("how many") || text.contains("this month")) {
            return symptomCount("headache", logs: symptomLogs)
        }

        if text.contains("sugar trend") || text.contains("show my sugar trend") {
            return sugarTrend(records: healthRecords)
        }

        if text.contains("miss medicine") || text.contains("missed medicine") {
            return lastMissedMedicine(logs: medicineLogs)
        }

        return nil
    }

    private func lastBP(records: [HealthRecord]) -> String {
        guard let latest = records.filter({ $0.type == .bloodPressure }).sorted(by: { $0.measuredAt > $1.measuredAt }).first else {
            return "I do not see a saved BP reading yet."
        }
        return "You last recorded BP on \(latest.measuredAt.formatted(date: .abbreviated, time: .shortened)). The reading was \(latest.displayValue), based on your saved logs."
    }

    private func symptomCount(_ symptom: String, logs: [WomensHealthDailyLog]) -> String {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
        let count = logs
            .filter { $0.date >= startOfMonth }
            .filter { $0.symptoms.contains(symptom) || $0.notes.lowercased().contains(symptom) }
            .count
        return "You logged \(symptom) \(count) time\(count == 1 ? "" : "s") this month, based on your saved symptom logs. This is informational only."
    }

    private func sugarTrend(records: [HealthRecord]) -> String {
        let values = records
            .filter { $0.type == .bloodSugar }
            .sorted { $0.measuredAt > $1.measuredAt }
            .prefix(7)
            .map(\.value1)
        guard values.count >= 2 else {
            return "I need at least two saved sugar readings before I can describe a trend."
        }
        let latest = values.first ?? 0
        let average = values.reduce(0, +) / Double(values.count)
        let direction = latest <= average ? "lower than your recent average" : "higher than your recent average"
        return "Based on your saved logs, your latest sugar reading is \(direction). This is informational only."
    }

    private func lastMissedMedicine(logs: [MedicineLog]) -> String {
        guard let latest = logs.filter({ $0.status == .missed || $0.status == .skipped }).sorted(by: { $0.scheduledTime > $1.scheduledTime }).first else {
            return "I do not see a missed medicine log in your saved history."
        }
        let name = latest.medicine?.name ?? "medicine"
        return "The last missed medicine I found was \(name) on \(latest.scheduledTime.formatted(date: .abbreviated, time: .shortened)), based on your saved logs."
    }
}
