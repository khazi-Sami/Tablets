import Combine
import Foundation
import SwiftData
import UIKit

@MainActor
final class HealthTrackingViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var selectedAddType: HealthRecordType?
    @Published var isShowingDiabetes = false
    @Published var isShowingInsights = false
    @Published var isShowingCharts = false
    @Published var isShowingAlertHistory = false

    func addQuickHeartRate(modelContext: ModelContext) {
        do {
            let metric = HealthRecord(type: .heartRate, value1: 72, unit: "bpm")
            try HealthRecordRepository(modelContext: modelContext).add(metric)
            HapticsManager.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
            HapticsManager.notification(.error)
        }
    }

    func latest(_ type: HealthRecordType, from records: [HealthRecord]) -> HealthRecord? {
        records.first { $0.type == type }
    }

    func weeklyAverage(_ type: HealthRecordType, from records: [HealthRecord]) -> Double? {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let values = records.filter { $0.type == type && $0.measuredAt >= start }.map(\.value1)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    func activeSafetyAlerts(from records: [HealthRecord]) -> [HealthSafetyAlert] {
        HealthSafetyAlerter.activeAlerts(from: records)
    }
}
