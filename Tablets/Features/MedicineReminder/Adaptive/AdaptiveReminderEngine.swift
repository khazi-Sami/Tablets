import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class AdaptiveReminderEngine {
    private let modelContext: ModelContext
    private let config: AdaptiveReminderConfig
    private let calendar: Calendar

    init(
        modelContext: ModelContext,
        config: AdaptiveReminderConfig? = nil,
        calendar: Calendar = .current
    ) {
        self.modelContext = modelContext
        self.config = config ?? AdaptiveReminderConfig()
        self.calendar = calendar
    }

    func analyzePatternsForAllMedicines() async -> [MedicineTakePattern] {
        let descriptor = FetchDescriptor<Medicine>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.name)]
        )
        guard let medicines = try? modelContext.fetch(descriptor) else {
            return []
        }

        var patterns: [MedicineTakePattern] = []
        for medicine in medicines {
            patterns.append(contentsOf: await analyzePatterns(for: medicine))
        }
        return patterns
    }

    func analyzePattern(for medicine: Medicine) async -> MedicineTakePattern? {
        guard let originalTime = medicine.times.sorted().first else { return nil }
        return await analyzePattern(for: medicine, scheduledTime: originalTime)
    }

    func analyzePatterns(for medicine: Medicine) async -> [MedicineTakePattern] {
        var patterns: [MedicineTakePattern] = []
        for scheduledTime in medicine.times.sorted() {
            if let pattern = await analyzePattern(for: medicine, scheduledTime: scheduledTime) {
                patterns.append(pattern)
            }
        }
        return patterns
    }

    func analyzePattern(for medicine: Medicine, scheduledTime: Date) async -> MedicineTakePattern? {
        guard let windowStart = calendar.date(
            byAdding: .day,
            value: -config.analysisWindowDays,
            to: .now
        ) else { return nil }

        let medicineID = medicine.id
        let takenStatus = MedicineLogStatus.taken.rawValue
        let descriptor = FetchDescriptor<MedicineLog>(
            predicate: #Predicate<MedicineLog> { log in
                log.statusRawValue == takenStatus &&
                log.takenTime != nil &&
                log.scheduledTime >= windowStart &&
                log.medicine?.id == medicineID
            },
            sortBy: [SortDescriptor(\.scheduledTime, order: .reverse)]
        )

        guard let logs = try? modelContext.fetch(descriptor),
              logs.count >= config.minimumSamplesForShift
        else {
            return nil
        }

        let scheduledComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        let matchingLogs = logs.filter { log in
            calendar.component(.hour, from: log.scheduledTime) == (scheduledComponents.hour ?? 0) &&
            calendar.component(.minute, from: log.scheduledTime) == (scheduledComponents.minute ?? 0)
        }

        guard matchingLogs.count >= config.minimumSamplesForShift else { return nil }

        let offsets = matchingLogs.compactMap { log -> Int? in
            guard let takenTime = log.takenTime else { return nil }
            let minutes = differenceInMinutes(from: log.scheduledTime, to: takenTime)
            return min(max(minutes, -180), 180)
        }

        guard offsets.count >= config.minimumSamplesForShift else { return nil }

        var averageOffset = trimmedMeanOffset(from: offsets)
        if abs(averageOffset) < config.minShiftMinutes {
            averageOffset = 0
        }
        averageOffset = min(max(averageOffset, -config.maxShiftMinutes), config.maxShiftMinutes)

        return MedicineTakePattern(
            medicineID: medicine.persistentModelID,
            medicineName: medicine.name,
            scheduledTime: scheduledComponents,
            averageActualMinuteOffset: averageOffset,
            sampleCount: offsets.count,
            confidenceLevel: PatternConfidence.level(for: offsets.count),
            lastComputedAt: .now
        )
    }

    private func differenceInMinutes(from scheduledAt: Date, to takenAt: Date) -> Int {
        Int((takenAt.timeIntervalSince(scheduledAt) / 60).rounded())
    }

    private func trimmedMeanOffset(from offsets: [Int]) -> Int {
        let sorted = offsets.sorted()
        let trimCount = Int(Double(sorted.count) * 0.10)
        let upperBound = max(trimCount, sorted.count - trimCount)
        let trimmed = Array(sorted[trimCount..<upperBound])
        let values = trimmed.isEmpty ? sorted : trimmed
        let total = values.reduce(0, +)
        return Int((Double(total) / Double(values.count)).rounded())
    }
}
