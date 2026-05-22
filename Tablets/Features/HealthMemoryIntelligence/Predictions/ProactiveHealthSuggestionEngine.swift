import Foundation

struct ProactiveHealthSuggestionEngine {
    func suggestions(
        medicines: [Medicine],
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        habits: [UserHealthHabit]
    ) -> [HealthInsightCard] {
        var cards: [HealthInsightCard] = []

        if let pending = pendingEveningMedicine(medicines: medicines, logs: medicineLogs) {
            cards.append(HealthInsightCard(title: "Medicine reminder", message: "\(pending) may be pending based on your saved reminders.", icon: "pills.fill", tint: "blue"))
        }

        if !hasLoggedToday(.bloodSugar, records: healthRecords) {
            cards.append(HealthInsightCard(title: "Sugar log", message: "You have not logged sugar today, based on your saved logs.", icon: "drop.fill", tint: "mint"))
        }

        if let bpHabit = habits.first(where: { $0.habitType == .bpLogging }) {
            cards.append(HealthInsightCard(title: "BP habit", message: bpHabit.detail, icon: "heart.text.square.fill", tint: "lavender"))
        }

        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let recentLogDays = Set(healthRecords.filter { $0.measuredAt >= weekAgo }.map { Calendar.current.startOfDay(for: $0.measuredAt) })
        if recentLogDays.count >= 4 {
            cards.append(HealthInsightCard(title: "Consistency", message: "You tracked your health consistently this week, based on your saved logs.", icon: "sparkles", tint: "mint"))
        }

        return Array(cards.prefix(4))
    }

    private func hasLoggedToday(_ type: HealthRecordType, records: [HealthRecord]) -> Bool {
        records.contains { $0.type == type && Calendar.current.isDateInToday($0.measuredAt) }
    }

    private func pendingEveningMedicine(medicines: [Medicine], logs: [MedicineLog]) -> String? {
        let currentHour = Calendar.current.component(.hour, from: .now)
        guard currentHour >= 17 else { return nil }

        for medicine in medicines where medicine.isActive {
            let hasEveningTime = medicine.times.contains { Calendar.current.component(.hour, from: $0) >= 17 }
            guard hasEveningTime else { continue }
            let takenToday = logs.contains {
                $0.medicine?.id == medicine.id && $0.status == .taken && Calendar.current.isDateInToday($0.scheduledTime)
            }
            if !takenToday { return medicine.name }
        }

        return nil
    }
}
