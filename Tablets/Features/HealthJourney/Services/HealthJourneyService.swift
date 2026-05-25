import Foundation
import SwiftUI

struct HealthJourneyService {
    func feed(
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        womensLogs: [WomensHealthDailyLog],
        periodCycles: [PeriodCycle],
        checkIns: [DailyHealthCheckIn]
    ) -> [JourneyFeedItem] {
        var items: [JourneyFeedItem] = []

        items += medicineLogs.prefix(8).map {
            JourneyFeedItem(
                kind: .medicine,
                title: $0.status == .taken ? "Medicine taken" : "Medicine \($0.status.title.lowercased())",
                subtitle: $0.medicine?.name ?? "Medicine reminder",
                date: $0.scheduledTime,
                symbol: $0.status == .taken ? "checkmark.circle.fill" : "bell.badge.fill",
                color: $0.status == .taken ? AppColor.mintGreenDeep : AppColor.softRed
            )
        }

        items += healthRecords.prefix(12).map { record in
            JourneyFeedItem(
                kind: record.type == .bloodPressure ? .bloodPressure : record.type == .bloodSugar ? .sugar : .encouragement,
                title: "\(record.type.title) logged",
                subtitle: record.displayValue,
                date: record.measuredAt,
                symbol: record.type.icon,
                color: record.type == .bloodSugar ? AppColor.lavenderDeep : AppColor.medicalBlue
            )
        }

        items += womensLogs.prefix(8).flatMap { log -> [JourneyFeedItem] in
            var generated: [JourneyFeedItem] = [
                JourneyFeedItem(
                    kind: .sleep,
                    title: "Sleep check-in",
                    subtitle: log.sleepQuality.title,
                    date: log.date,
                    symbol: "moon.zzz.fill",
                    color: AppColor.lavenderDeep
                )
            ]

            if log.waterIntakeCups > 0 {
                generated.append(
                    JourneyFeedItem(
                        kind: .water,
                        title: "Hydration logged",
                        subtitle: "\(log.waterIntakeCups) cups",
                        date: log.date,
                        symbol: "drop.fill",
                        color: AppColor.medicalBlue
                    )
                )
            }

            if !log.symptoms.isEmpty {
                generated.append(
                    JourneyFeedItem(
                        kind: .symptom,
                        title: "Symptoms noted",
                        subtitle: log.symptoms.prefix(3).joined(separator: ", "),
                        date: log.date,
                        symbol: "heart.text.square.fill",
                        color: AppColor.softRed
                    )
                )
            }

            return generated
        }

        items += periodCycles.prefix(4).map {
            JourneyFeedItem(
                kind: .period,
                title: "Period update",
                subtitle: "\($0.flowLevel.title) flow • pain \($0.painLevel)/10",
                date: $0.startDate,
                symbol: "calendar.badge.clock",
                color: AppColor.lavenderDeep
            )
        }

        items += checkIns.prefix(8).map {
            JourneyFeedItem(
                kind: .mood,
                title: "Daily check-in",
                subtitle: "\($0.mood.title) • energy \($0.energyLevel)/10",
                date: $0.date,
                symbol: $0.mood.symbol,
                color: AppColor.mintGreenDeep
            )
        }

        items.append(
            JourneyFeedItem(
                kind: .encouragement,
                title: "You are building steady care habits",
                subtitle: "Your journey is made of small caring moments.",
                date: .now,
                symbol: "sparkles",
                color: AppColor.medicalBlue
            )
        )

        return items.sorted { $0.date > $1.date }
    }

    func streaks(
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        womensLogs: [WomensHealthDailyLog],
        checkIns: [DailyHealthCheckIn]
    ) -> HealthStreakSummary {
        HealthStreakSummary(
            medicine: streak { day in
                medicineLogs.contains { Calendar.current.isDate($0.scheduledTime, inSameDayAs: day) && $0.status == .taken }
            },
            bloodPressure: streak { day in
                healthRecords.contains { Calendar.current.isDate($0.measuredAt, inSameDayAs: day) && $0.type == .bloodPressure }
            },
            hydration: streak { day in
                womensLogs.contains { Calendar.current.isDate($0.date, inSameDayAs: day) && $0.waterIntakeCups > 0 }
            },
            sleep: streak { day in
                womensLogs.contains { Calendar.current.isDate($0.date, inSameDayAs: day) && [.good, .excellent].contains($0.sleepQuality) }
            },
            symptoms: streak { day in
                !checkIns.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }.isEmpty
                    || womensLogs.contains { Calendar.current.isDate($0.date, inSameDayAs: day) && !$0.symptoms.isEmpty }
            }
        )
    }

    func mode(
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        womensLogs: [WomensHealthDailyLog],
        periodCycles: [PeriodCycle]
    ) -> EmotionalWellnessMode {
        let aura = HealthAuraManager.mood(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            periodCycles: periodCycles
        )

        switch aura {
        case .sunrise: return .energetic
        case .lavenderCycle: return .healing
        case .attention: return .focus
        case .restorative: return .recovery
        case .stable: return .calm
        }
    }

    func insights(streaks: HealthStreakSummary, feed: [JourneyFeedItem]) -> [String] {
        var insights = ["You're building a steady care routine, one gentle check-in at a time."]

        if streaks.medicine >= 3 {
            insights.append("Your medicine tracking is becoming consistent based on your saved logs.")
        }
        if streaks.bloodPressure >= 2 {
            insights.append("Your BP tracking rhythm is improving this week.")
        }
        if streaks.hydration >= 2 {
            insights.append("Your hydration tracking improved based on recent entries.")
        }
        if feed.contains(where: { $0.kind == .symptom }) {
            insights.append("You logged symptoms regularly, which can help you notice patterns.")
        }

        return insights
    }

    private func streak(hasEntry: (Date) -> Bool) -> Int {
        let calendar = Calendar.current
        var count = 0

        for offset in 0..<30 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: .now) else { continue }
            if hasEntry(day) {
                count += 1
            } else if offset == 0 {
                continue
            } else {
                break
            }
        }

        return count
    }
}
