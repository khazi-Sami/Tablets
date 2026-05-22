import Foundation
import SwiftData

@Model
final class WomensHealthDailyLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var symptoms: [String]
    var dischargeNotes: String
    var medicationTaken: String
    var waterIntakeCups: Int
    var sleepQualityRawValue: String
    var notes: String
    var createdAt: Date

    var sleepQuality: SleepQuality {
        get { SleepQuality(rawValue: sleepQualityRawValue) ?? .okay }
        set { sleepQualityRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        date: Date = .now,
        symptoms: [WomensHealthSymptom] = [],
        dischargeNotes: String = "",
        medicationTaken: String = "",
        waterIntakeCups: Int = 0,
        sleepQuality: SleepQuality = .okay,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.symptoms = symptoms.map(\.rawValue)
        self.dischargeNotes = dischargeNotes
        self.medicationTaken = medicationTaken
        self.waterIntakeCups = max(waterIntakeCups, 0)
        self.sleepQualityRawValue = sleepQuality.rawValue
        self.notes = notes
        self.createdAt = createdAt
    }
}

enum SleepQuality: String, Codable, CaseIterable, Identifiable {
    case poor
    case okay
    case good
    case excellent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .poor: return "Poor"
        case .okay: return "Okay"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
}
