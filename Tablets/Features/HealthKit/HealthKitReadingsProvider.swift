import Foundation
import HealthKit
import Observation

@Observable
final class HealthKitReadingsProvider {
    private let service: HealthKitService
    private let calendar: Calendar

    init(service: HealthKitService, calendar: Calendar = .current) {
        self.service = service
        self.calendar = calendar
    }

    func fetchTodaySnapshot() async -> HKDailySnapshot {
        await fetchSnapshotForDate(.now)
    }

    func fetchSnapshotForDate(_ date: Date) async -> HKDailySnapshot {
        async let steps = cumulativeQuantity(.stepCount, unit: .count(), date: date)
        async let energy = cumulativeQuantity(.activeEnergyBurned, unit: .kilocalorie(), date: date)
        async let restingHR = latestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), date: date)
        async let heartRate = latestQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()), date: date)
        async let oxygen = latestQuantity(.oxygenSaturation, unit: .percent(), date: date)
        async let weight = latestQuantity(.bodyMass, unit: .gramUnit(with: .kilo), date: date)
        async let sleep = fetchSleepSummary(for: date)

        return await HKDailySnapshot(
            date: date,
            steps: steps,
            activeEnergy: energy,
            restingHeartRate: restingHR,
            latestHeartRate: heartRate,
            sleepDurationHours: sleep?.totalHours,
            oxygenSaturation: oxygen,
            weight: weight
        )
    }

    func fetchLast7DaysSnapshots() async -> [HKDailySnapshot] {
        var snapshots: [HKDailySnapshot] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            let date = calendar.date(byAdding: .day, value: -offset, to: .now) ?? .now
            snapshots.append(await fetchSnapshotForDate(date))
        }
        return snapshots
    }

    func fetchSleepSummary(for date: Date) async -> HKSleepSummary? {
        guard service.isAvailable,
              let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let interval = dayInterval(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error {
                    print("[HealthKitReadingsProvider] Sleep query failed: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]
                let seconds = (samples as? [HKCategorySample] ?? [])
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                guard seconds > 0 else {
                    continuation.resume(returning: nil)
                    return
                }
                let hours = seconds / 3600
                let quality: HKSleepSummary.SleepQuality = hours >= 7 ? .good : hours >= 5 ? .moderate : .short
                continuation.resume(returning: HKSleepSummary(date: date, totalHours: hours, quality: quality))
            }
            service.store().execute(query)
        }
    }

    private func cumulativeQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, date: Date) async -> Double? {
        guard service.isAvailable, let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        let interval = dayInterval(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error {
                    if !self.isNoDataError(error) {
                        print("[HealthKitReadingsProvider] Cumulative query failed for \(identifier.rawValue): \(error)")
                    }
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit))
            }
            service.store().execute(query)
        }
    }

    private func latestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, date: Date) async -> Double? {
        guard service.isAvailable, let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }
        let interval = dayInterval(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    print("[HealthKitReadingsProvider] Latest query failed for \(identifier.rawValue): \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                let sample = (samples as? [HKQuantitySample])?.first
                continuation.resume(returning: sample?.quantity.doubleValue(for: unit))
            }
            service.store().execute(query)
        }
    }

    private func isNoDataError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == HKError.errorDomain && nsError.code == HKError.errorNoData.rawValue
    }

    private func dayInterval(for date: Date) -> (start: Date, end: Date) {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return (start, end)
    }
}
