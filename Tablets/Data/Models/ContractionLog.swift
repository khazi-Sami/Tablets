import Foundation
import SwiftData

@Model
final class ContractionLog {
    @Attribute(.unique) var id: UUID
    var pregnancyProfileId: UUID
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int?
    var intervalSeconds: Int?
    var intensityRawValue: String
    var notes: String?
    var createdAt: Date

    var intensity: ContractionIntensity {
        get { ContractionIntensity(rawValue: intensityRawValue) ?? .mild }
        set { intensityRawValue = newValue.rawValue }
    }

    init(id: UUID = UUID(), pregnancyProfileId: UUID, startedAt: Date, endedAt: Date? = nil, durationSeconds: Int? = nil, intervalSeconds: Int? = nil, intensity: ContractionIntensity = .mild, notes: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.pregnancyProfileId = pregnancyProfileId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.intervalSeconds = intervalSeconds
        self.intensityRawValue = intensity.rawValue
        self.notes = notes
        self.createdAt = createdAt
    }
}

enum ContractionIntensity: String, Codable, CaseIterable, Identifiable {
    case mild = "Mild"
    case moderate = "Moderate"
    case strong = "Strong"

    var id: String { rawValue }
}
