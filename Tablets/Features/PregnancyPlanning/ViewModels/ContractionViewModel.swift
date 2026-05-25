import Combine
import Foundation
import SwiftData
import UIKit

@MainActor
final class ContractionViewModel: ObservableObject {
    @Published var contractions: [ContractionLog] = []
    @Published var isContrationActive = false
    @Published var currentStart: Date?
    @Published var currentDurationSeconds = 0
    @Published var elapsedTimer: Timer?
    @Published var lastContractionEnd: Date?
    @Published var averageDuration = 0
    @Published var averageInterval = 0
    @Published var pattern: ContractionPattern = .irregular

    enum ContractionPattern {
        case irregular
        case regular511
        case callDoctor
    }

    func startContraction() {
        currentStart = .now
        currentDurationSeconds = 0
        isContrationActive = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.currentDurationSeconds += 1
            }
        }
    }

    func stopContraction(intensity: ContractionIntensity, context: ModelContext, profileId: UUID) {
        guard let start = currentStart else { return }
        elapsedTimer?.invalidate()
        let end = Date()
        let duration = max(1, Int(end.timeIntervalSince(start)))
        let interval = lastContractionEnd.map { max(0, Int(start.timeIntervalSince($0))) }
        let log = ContractionLog(pregnancyProfileId: profileId, startedAt: start, endedAt: end, durationSeconds: duration, intervalSeconds: interval, intensity: intensity)
        context.insert(log)
        try? context.save()
        lastContractionEnd = end
        isContrationActive = false
        currentStart = nil
        currentDurationSeconds = 0
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        loadHistory(context: context, profileId: profileId)
    }

    func loadHistory(context: ModelContext, profileId: UUID) {
        let descriptor = FetchDescriptor<ContractionLog>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        contractions = ((try? context.fetch(descriptor)) ?? []).filter { $0.pregnancyProfileId == profileId }
        averageDuration = average(contractions.compactMap(\.durationSeconds))
        averageInterval = average(contractions.compactMap(\.intervalSeconds))
        analyzePattern()
    }

    func analyzePattern() {
        let recent = Array(contractions.prefix(12))
        guard recent.count >= 3 else {
            pattern = .irregular
            return
        }
        let regular = recent.prefix(3).allSatisfy { ($0.durationSeconds ?? 0) >= 60 && ($0.intervalSeconds ?? Int.max) <= 300 }
        if regular {
            pattern = .callDoctor
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        } else if averageInterval > 0 && averageInterval <= 600 {
            pattern = .regular511
        } else {
            pattern = .irregular
        }
    }

    func clearHistory(context: ModelContext) {
        contractions.forEach { context.delete($0) }
        try? context.save()
        contractions = []
        averageDuration = 0
        averageInterval = 0
        pattern = .irregular
    }

    private func average(_ values: [Int]) -> Int {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / values.count
    }
}
