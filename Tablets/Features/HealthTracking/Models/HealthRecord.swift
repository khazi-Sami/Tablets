import Foundation
import SwiftData

@Model
final class HealthRecord {
    @Attribute(.unique) var id: UUID
    var typeRawValue: String
    var value1: Double
    var value2: Double?
    var unit: String
    var measuredAt: Date
    var notes: String
    var mood: String
    var symptoms: [String]
    var sugarTestTypeRawValue: String?
    var createdAt: Date

    var type: HealthRecordType {
        get { HealthRecordType(rawValue: typeRawValue) ?? .heartRate }
        set { typeRawValue = newValue.rawValue }
    }

    var sugarTestType: SugarTestType? {
        get { sugarTestTypeRawValue.flatMap(SugarTestType.init(rawValue:)) }
        set { sugarTestTypeRawValue = newValue?.rawValue }
    }

    var recordedAt: Date {
        get { measuredAt }
        set { measuredAt = newValue }
    }

    var displayValue: String {
        if let value2 {
            return "\(formatted(value1))/\(formatted(value2)) \(unit)"
        }

        return "\(formatted(value1)) \(unit)"
    }

    init(
        id: UUID = UUID(),
        type: HealthRecordType,
        value1: Double,
        value2: Double? = nil,
        unit: String,
        measuredAt: Date = .now,
        notes: String = "",
        mood: String = "",
        symptoms: [String] = [],
        sugarTestType: SugarTestType? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.typeRawValue = type.rawValue
        self.value1 = value1
        self.value2 = value2
        self.unit = unit
        self.measuredAt = measuredAt
        self.notes = notes
        self.mood = mood
        self.symptoms = symptoms
        self.sugarTestTypeRawValue = sugarTestType?.rawValue
        self.createdAt = createdAt
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

enum HealthRecordType: String, Codable, CaseIterable, Identifiable {
    case bloodPressure
    case bloodSugar
    case heartRate
    case oxygen
    case weight
    case temperature

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bloodPressure:
            return "Blood Pressure"
        case .bloodSugar:
            return "Blood Sugar"
        case .heartRate:
            return "Heart Rate"
        case .oxygen:
            return "Oxygen"
        case .weight:
            return "Weight"
        case .temperature:
            return "Temperature"
        }
    }

    var unit: String {
        switch self {
        case .bloodPressure: return "mmHg"
        case .bloodSugar: return "mg/dL"
        case .heartRate: return "bpm"
        case .oxygen: return "%"
        case .weight: return "kg"
        case .temperature: return "°F"
        }
    }

    var icon: String {
        switch self {
        case .bloodPressure: return "heart.text.square.fill"
        case .bloodSugar: return "drop.fill"
        case .heartRate: return "waveform.path.ecg"
        case .oxygen: return "lungs.fill"
        case .weight: return "scalemass.fill"
        case .temperature: return "thermometer.medium"
        }
    }
}

enum SugarTestType: String, Codable, CaseIterable, Identifiable {
    case fasting
    case afterMeal
    case random
    case beforeMeal
    case hba1c

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fasting: return "Fasting"
        case .afterMeal: return "After meal"
        case .random: return "Random"
        case .beforeMeal: return "Before meal"
        case .hba1c: return "HbA1c"
        }
    }
}

enum BPStatus: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case elevated
    case high
    case critical

    var id: String { rawValue }
}

enum SugarStatus: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case prediabetes
    case high
    case critical

    var id: String { rawValue }
}
