import Foundation
import HealthKit
import Observation
import SwiftData

@Observable
final class WellnessInsightEngine {
    private let readingsProvider: HealthKitReadingsProvider
    private let modelContext: ModelContext
    private let calendar: Calendar

    init(readingsProvider: HealthKitReadingsProvider, modelContext: ModelContext, calendar: Calendar = .current) {
        self.readingsProvider = readingsProvider
        self.modelContext = modelContext
        self.calendar = calendar
    }

    func generateTodayInsights() async -> [WellnessInsight] {
        let today = await readingsProvider.fetchTodaySnapshot()
        let baselineHR = await computeUserBaseline14Day(type: .restingHeartRate)
        var insights: [WellnessInsight] = []

        if let readiness = readinessSignal(snapshot: today, baselineHR: baselineHR), readiness.level != .unknown {
            insights.append(WellnessInsight(date: .now, message: readiness.reason, category: readiness.level == .low ? .recoveryMode : .general))
        }

        if let steps = today.steps,
           steps > 6000,
           let latestSugar = fetchHealthRecords(type: .bloodSugar, days: 1).first,
           let averageSugar = average(fetchHealthRecords(type: .bloodSugar, days: 14).map(\.value1)),
           fetchHealthRecords(type: .bloodSugar, days: 14).count >= 5,
           latestSugar.value1 < averageSugar {
            insights.append(safeInsight("On active days like today, your sugar logs tend to be lower based on your saved records.", category: .activity))
        }

        if let sleep = today.sleepDurationHours,
           sleep < 6.0,
           let latestBP = fetchHealthRecords(type: .bloodPressure, days: 1).first,
           let averageBP = average(fetchHealthRecords(type: .bloodPressure, days: 14).map(\.value1)),
           fetchHealthRecords(type: .bloodPressure, days: 14).count >= 5,
           latestBP.value1 > averageBP {
            insights.append(safeInsight("Your BP logs tend to be slightly higher after shorter sleep nights based on your saved records.", category: .sleep))
        }

        if UserHealthProfile.showWomensHealthCard,
           let cycleDay = currentCycleDay(),
           (1...3).contains(cycleDay),
           let sleep = today.sleepDurationHours,
           sleep < 6.5 {
            insights.append(safeInsight("Sleep is often shorter in the first days of a cycle based on your saved logs.", category: .sleep))
        }

        return Array(insights.prefix(3))
    }

    func computeUserBaseline14Day(type: HKQuantityTypeIdentifier) async -> Double? {
        guard type == .restingHeartRate || type == .heartRate else { return nil }
        var values: [Double] = []
        for offset in 1...14 {
            let date = calendar.date(byAdding: .day, value: -offset, to: .now) ?? .now
            let snapshot = await readingsProvider.fetchSnapshotForDate(date)
            if type == .restingHeartRate, let value = snapshot.restingHeartRate {
                values.append(value)
            } else if type == .heartRate, let value = snapshot.latestHeartRate {
                values.append(value)
            }
        }
        guard values.count >= 3 else { return nil }
        return average(values)
    }

    private func readinessSignal(snapshot: HKDailySnapshot, baselineHR: Double?) -> ReadinessSignal? {
        guard let sleep = snapshot.sleepDurationHours,
              let restingHR = snapshot.restingHeartRate,
              let baselineHR else {
            return ReadinessSignal(date: .now, level: .unknown, reason: "")
        }

        if sleep < 5.0 && restingHR > baselineHR * 1.2 {
            return ReadinessSignal(date: .now, level: .low, reason: "Recovery day — your body signals suggest taking it easy today based on your saved records.")
        }

        if sleep >= 7.0, restingHR < baselineHR, (snapshot.steps ?? 0) > 3000 {
            return ReadinessSignal(date: .now, level: .good, reason: "You look well-rested today based on your saved records for sleep and heart rate. Informational only.")
        }

        if sleep < 5.0 || restingHR > baselineHR * 1.15 {
            return ReadinessSignal(date: .now, level: .low, reason: "Your body signals suggest more rest today based on your saved records from last night's sleep. Informational only.")
        }

        return ReadinessSignal(date: .now, level: .moderate, reason: "Your wellness signals look moderate today based on your saved records. Informational only.")
    }

    private func fetchHealthRecords(type: HealthRecordType, days: Int) -> [HealthRecord] {
        let start = calendar.date(byAdding: .day, value: -days, to: .now) ?? .now
        let rawValue = type.rawValue
        let descriptor = FetchDescriptor<HealthRecord>(
            predicate: #Predicate<HealthRecord> { record in
                record.typeRawValue == rawValue && record.measuredAt >= start
            },
            sortBy: [SortDescriptor(\.measuredAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("[WellnessInsightEngine] Fetch failed for \(type.rawValue): \(error)")
            return []
        }
    }

    private func currentCycleDay() -> Int? {
        var descriptor = FetchDescriptor<PeriodCycle>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        descriptor.fetchLimit = 1
        do {
            guard let cycle = try modelContext.fetch(descriptor).first else { return nil }
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: cycle.startDate), to: calendar.startOfDay(for: .now)).day ?? 0
            return max(days + 1, 1)
        } catch {
            print("[WellnessInsightEngine] Cycle fetch failed: \(error)")
            return nil
        }
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func safeInsight(_ message: String, category: WellnessInsight.InsightCategory) -> WellnessInsight {
        WellnessInsight(date: .now, message: safeMessage(message), category: category)
    }

    private func safeMessage(_ message: String) -> String {
        var safe = message
        ["You are healthy", "You are fine", "Normal", "Nothing to worry about", "Everything is good", "No need to worry", "This is normal"].forEach {
            safe = safe.replacingOccurrences(of: $0, with: "Informational only", options: [.caseInsensitive])
        }
        if !safe.localizedCaseInsensitiveContains("based on your saved records") &&
            !safe.localizedCaseInsensitiveContains("based on your logs") &&
            !safe.localizedCaseInsensitiveContains("informational only") {
            safe += " Informational only."
        }
        return safe
    }
}
