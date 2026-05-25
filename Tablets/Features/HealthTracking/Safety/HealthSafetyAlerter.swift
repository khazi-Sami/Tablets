import Foundation
import SwiftData

@MainActor
enum HealthSafetyAlerter {
    static func alert(for record: HealthRecord) -> HealthSafetyAlert? {
        let result: (HealthSafetySeverity, String, String)?
        switch record.type {
        case .bloodPressure:
            guard let diastolic = record.value2 else { return nil }
            result = SafetyAlertThresholds.bloodPressure(systolic: record.value1, diastolic: diastolic)
        case .bloodSugar:
            result = SafetyAlertThresholds.bloodSugar(value: record.value1, testType: record.sugarTestType)
        case .heartRate:
            result = SafetyAlertThresholds.heartRate(value: record.value1)
        case .oxygen:
            result = SafetyAlertThresholds.oxygen(value: record.value1)
        case .weight:
            result = SafetyAlertThresholds.weight(value: record.value1)
        case .temperature:
            result = SafetyAlertThresholds.temperature(value: record.value1, unit: record.unit)
        }

        guard let result else { return nil }

        return HealthSafetyAlert(
            recordID: record.id,
            metricType: record.type,
            valueText: record.displayValue,
            severity: result.0,
            title: result.1,
            message: "\(result.2) \(SafetyAlertThresholds.medicalDisclaimer)",
            actionMessage: "Recheck if you can, and contact your doctor."
        )
    }

    static func activeAlerts(from records: [HealthRecord], limit: Int = 3) -> [HealthSafetyAlert] {
        records.compactMap(alert(for:)).prefix(limit).map { $0 }
    }

    static func recordIfNeeded(_ alert: HealthSafetyAlert?) {
        guard let alert else { return }
        HealthSafetyAlertHistoryStore.shared.append(alert)
    }
}

final class HealthSafetyAlertHistoryStore {
    static let shared = HealthSafetyAlertHistoryStore()

    private let key = "health_safety_alert_history_v1"
    private let maxItems = 50

    private init() {}

    func append(_ alert: HealthSafetyAlert) {
        var alerts = all()
        guard !alerts.contains(where: { $0.recordID == alert.recordID && $0.metricTypeRawValue == alert.metricTypeRawValue }) else {
            return
        }
        alerts.insert(alert, at: 0)
        alerts = Array(alerts.prefix(maxItems))
        save(alerts)
    }

    func all() -> [HealthSafetyAlert] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([HealthSafetyAlert].self, from: data)) ?? []
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func save(_ alerts: [HealthSafetyAlert]) {
        guard let data = try? JSONEncoder().encode(alerts) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
