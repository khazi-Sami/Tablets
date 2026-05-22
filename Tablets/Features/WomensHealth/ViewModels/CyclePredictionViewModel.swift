import Combine
import Foundation

@MainActor
final class CyclePredictionViewModel: ObservableObject {
    func prediction(from cycles: [PeriodCycle], settings: CyclePredictionSettings? = nil) -> CyclePredictionSummary {
        let sortedCycles = cycles.sorted { $0.startDate > $1.startDate }
        let averageCycleLength = estimatedCycleLength(from: sortedCycles, fallback: settings?.averageCycleLengthDays ?? 28)
        let averageDuration = estimatedPeriodDuration(from: sortedCycles, fallback: settings?.averagePeriodDurationDays ?? 5)
        let latestStart = sortedCycles.first?.startDate ?? .now
        let nextPeriod = Calendar.current.date(byAdding: .day, value: averageCycleLength, to: latestStart) ?? .now
        let ovulation = Calendar.current.date(byAdding: .day, value: -14, to: nextPeriod) ?? nextPeriod
        let fertileStart = Calendar.current.date(byAdding: .day, value: -5, to: ovulation) ?? ovulation
        let fertileEnd = Calendar.current.date(byAdding: .day, value: 1, to: ovulation) ?? ovulation

        return CyclePredictionSummary(
            nextPeriodDate: nextPeriod,
            averageCycleLengthDays: averageCycleLength,
            averagePeriodDurationDays: averageDuration,
            fertileWindowStart: fertileStart,
            fertileWindowEnd: fertileEnd,
            ovulationDate: ovulation
        )
    }

    func currentCycleDay(from cycles: [PeriodCycle]) -> Int {
        guard let latest = cycles.sorted(by: { $0.startDate > $1.startDate }).first else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: latest.startDate, to: .now).day ?? 0
        return max(days + 1, 1)
    }

    private func estimatedCycleLength(from cycles: [PeriodCycle], fallback: Int) -> Int {
        guard cycles.count > 1 else { return fallback }

        let sortedAscending = cycles.sorted { $0.startDate < $1.startDate }
        let lengths = zip(sortedAscending, sortedAscending.dropFirst()).compactMap { previous, next in
            Calendar.current.dateComponents([.day], from: previous.startDate, to: next.startDate).day
        }.filter { $0 >= 18 && $0 <= 45 }

        guard !lengths.isEmpty else { return fallback }
        return Int((Double(lengths.reduce(0, +)) / Double(lengths.count)).rounded())
    }

    private func estimatedPeriodDuration(from cycles: [PeriodCycle], fallback: Int) -> Int {
        let durations = cycles.compactMap(\.durationDays).filter { $0 >= 1 && $0 <= 10 }
        guard !durations.isEmpty else { return fallback }
        return Int((Double(durations.reduce(0, +)) / Double(durations.count)).rounded())
    }
}

struct CyclePredictionSummary {
    let nextPeriodDate: Date
    let averageCycleLengthDays: Int
    let averagePeriodDurationDays: Int
    let fertileWindowStart: Date
    let fertileWindowEnd: Date
    let ovulationDate: Date
}
