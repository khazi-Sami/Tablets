import Foundation
import SwiftData

@Model
final class PregnancyWeightLog {
    @Attribute(.unique) var id: UUID
    var pregnancyProfileId: UUID
    var weight: Double
    var unitRawValue: String
    var loggedAt: Date
    var weekNumber: Int
    var notes: String?
    var createdAt: Date

    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRawValue) ?? .kg }
        set { unitRawValue = newValue.rawValue }
    }

    init(id: UUID = UUID(), pregnancyProfileId: UUID, weight: Double, unit: WeightUnit = .kg, loggedAt: Date = .now, weekNumber: Int, notes: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.pregnancyProfileId = pregnancyProfileId
        self.weight = weight
        self.unitRawValue = unit.rawValue
        self.loggedAt = loggedAt
        self.weekNumber = weekNumber
        self.notes = notes
        self.createdAt = createdAt
    }
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg = "kg"
    case lbs = "lbs"

    var id: String { rawValue }
}

