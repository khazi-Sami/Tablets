import Foundation

enum HealthAuraManager {
    static func mood(
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        womensLogs: [WomensHealthDailyLog],
        periodCycles: [PeriodCycle]
    ) -> HealthAuraMood {
        if isInActivePeriod(periodCycles) {
            return .lavenderCycle
        }

        if hasMissedMedicineToday(medicineLogs) || hasStressIndicators(womensLogs) {
            return .attention
        }

        if latestSleepQuality(womensLogs) == .poor {
            return .restorative
        }

        if healthTrackingStreak(healthRecords: healthRecords, medicineLogs: medicineLogs) >= 3 {
            return .sunrise
        }

        return .stable
    }

    static func healthTrackingStreak(healthRecords: [HealthRecord], medicineLogs: [MedicineLog]) -> Int {
        let calendar = Calendar.current
        var streak = 0

        for offset in 0..<21 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: .now) else { continue }
            let hasHealth = healthRecords.contains { calendar.isDate($0.measuredAt, inSameDayAs: day) }
            let hasMedicine = medicineLogs.contains { calendar.isDate($0.scheduledTime, inSameDayAs: day) && $0.status == .taken }

            if hasHealth || hasMedicine {
                streak += 1
            } else if offset == 0 {
                continue
            } else {
                break
            }
        }

        return streak
    }

    private static func hasMissedMedicineToday(_ logs: [MedicineLog]) -> Bool {
        logs.contains { Calendar.current.isDateInToday($0.scheduledTime) && $0.status == .missed }
    }

    private static func hasStressIndicators(_ logs: [WomensHealthDailyLog]) -> Bool {
        guard let latest = logs.sorted(by: { $0.date > $1.date }).first else { return false }
        let stressWords = ["fatigue", "moodSwings", "headache", "dizziness", "pain"]
        return latest.symptoms.contains { symptom in
            stressWords.contains { symptom.localizedCaseInsensitiveContains($0) }
        }
    }

    private static func latestSleepQuality(_ logs: [WomensHealthDailyLog]) -> SleepQuality? {
        logs.sorted(by: { $0.date > $1.date }).first?.sleepQuality
    }

    private static func isInActivePeriod(_ cycles: [PeriodCycle]) -> Bool {
        let calendar = Calendar.current
        return cycles.contains { cycle in
            let startIsNotFuture = calendar.compare(cycle.startDate, to: .now, toGranularity: .day) != .orderedDescending

            if let endDate = cycle.endDate {
                let endIsNotPast = calendar.compare(endDate, to: .now, toGranularity: .day) != .orderedAscending
                return startIsNotFuture && endIsNotPast
            }

            guard let days = calendar.dateComponents([.day], from: cycle.startDate, to: .now).day else {
                return false
            }
            return days >= 0 && days <= 6
        }
    }
}
