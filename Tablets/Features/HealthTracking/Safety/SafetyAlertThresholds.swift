import Foundation
import SwiftUI

enum HealthSafetySeverity: String, Codable, CaseIterable, Identifiable {
    case info
    case caution
    case urgent
    case emergency

    var id: String { rawValue }

    var title: String {
        switch self {
        case .info: return "Saved"
        case .caution: return "Please keep an eye on this"
        case .urgent: return "Please contact your doctor"
        case .emergency: return "Consider urgent care"
        }
    }

    var color: Color {
        switch self {
        case .info: return AppColor.medicalBlue
        case .caution: return Color.orange
        case .urgent: return AppColor.softRed
        case .emergency: return Color.red
        }
    }
}

struct HealthSafetyAlert: Identifiable, Codable, Equatable {
    let id: UUID
    let recordID: UUID
    let metricTypeRawValue: String
    let metricTitle: String
    let valueText: String
    let severity: HealthSafetySeverity
    let title: String
    let message: String
    let actionMessage: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        recordID: UUID,
        metricType: HealthRecordType,
        valueText: String,
        severity: HealthSafetySeverity,
        title: String,
        message: String,
        actionMessage: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.recordID = recordID
        self.metricTypeRawValue = metricType.rawValue
        self.metricTitle = metricType.title
        self.valueText = valueText
        self.severity = severity
        self.title = title
        self.message = message
        self.actionMessage = actionMessage
        self.createdAt = createdAt
    }

    var metricType: HealthRecordType {
        HealthRecordType(rawValue: metricTypeRawValue) ?? .heartRate
    }
}

enum SafetyAlertThresholds {
    static let medicalDisclaimer = "This is not a diagnosis. Please contact your doctor for medical advice."

    static func bloodPressure(systolic: Double, diastolic: Double) -> (HealthSafetySeverity, String, String)? {
        if systolic >= 180 || diastolic >= 120 {
            return (
                .emergency,
                "Your BP reading is very high.",
                "If you have chest pain, shortness of breath, severe headache, weakness, confusion, or feel unwell, seek urgent medical care now. Please contact your doctor."
            )
        }
        if systolic >= 160 || diastolic >= 100 {
            return (
                .urgent,
                "Your BP reading is high.",
                "Please recheck after resting and contact your doctor for guidance, especially if this is unusual for you."
            )
        }
        if systolic < 90 || diastolic < 60 {
            return (
                .caution,
                "Your BP reading is on the lower side.",
                "If you feel dizzy, faint, weak, or unwell, please contact your doctor."
            )
        }
        return nil
    }

    static func bloodSugar(value: Double, testType: SugarTestType?) -> (HealthSafetySeverity, String, String)? {
        if value < 54 {
            return (
                .emergency,
                "Your sugar reading is very low.",
                "Low sugar can become urgent. Please follow your doctor's low-sugar plan and seek urgent help if you feel confused, faint, very weak, or unwell."
            )
        }
        if value < 70 {
            return (
                .urgent,
                "Your sugar reading is low.",
                "Please follow your doctor's advice for low sugar and recheck as directed."
            )
        }
        if value >= 300 {
            return (
                .urgent,
                "Your sugar reading is very high.",
                "Please contact your doctor for guidance. Seek urgent care if you feel very unwell, dehydrated, confused, or have vomiting."
            )
        }
        if value >= 250 {
            return (
                .caution,
                "Your sugar reading is high.",
                "Please follow your diabetes care plan and contact your doctor if this keeps happening."
            )
        }
        if testType == .hba1c && value >= 9 {
            return (
                .urgent,
                "Your HbA1c entry is high.",
                "Please review this with your doctor. Long-term sugar control needs medical guidance."
            )
        }
        return nil
    }

    static func heartRate(value: Double) -> (HealthSafetySeverity, String, String)? {
        if value < 40 || value > 130 {
            return (
                .urgent,
                "Your heart rate reading needs attention.",
                "Please contact your doctor, especially if you feel chest pain, dizziness, shortness of breath, faintness, or weakness."
            )
        }
        if value < 50 || value > 120 {
            return (
                .caution,
                "Your heart rate is outside the usual resting range.",
                "Please rest, recheck, and contact your doctor if this is unusual for you or you feel unwell."
            )
        }
        return nil
    }

    static func oxygen(value: Double) -> (HealthSafetySeverity, String, String)? {
        if value < 90 {
            return (
                .emergency,
                "Your oxygen reading is low.",
                "If this reading is accurate or you feel breathless, blue-lipped, confused, weak, or unwell, seek urgent medical care now."
            )
        }
        if value < 94 {
            return (
                .urgent,
                "Your oxygen reading is below the usual range.",
                "Please recheck and contact your doctor, especially if you have breathing symptoms."
            )
        }
        return nil
    }

    static func temperature(value: Double, unit: String) -> (HealthSafetySeverity, String, String)? {
        let fahrenheit = unit.contains("C") ? (value * 9 / 5) + 32 : value
        if fahrenheit >= 103 || fahrenheit <= 95 {
            return (
                .urgent,
                "Your temperature reading needs attention.",
                "Please contact your doctor. Seek urgent care if you feel very unwell, confused, dehydrated, or have trouble breathing."
            )
        }
        if fahrenheit >= 100.4 {
            return (
                .caution,
                "Your temperature suggests a fever.",
                "Please rest, hydrate if allowed by your doctor, and contact your doctor if symptoms worsen or continue."
            )
        }
        return nil
    }

    static func weight(value: Double) -> (HealthSafetySeverity, String, String)? {
        if value <= 0 {
            return (
                .caution,
                "This weight entry looks unusual.",
                "Please check the number and edit it if needed."
            )
        }
        return nil
    }
}
