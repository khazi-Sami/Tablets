import Foundation
import SwiftData

@Model
final class PregnancyMoodLog {
    @Attribute(.unique) var id: UUID
    var pregnancyProfileId: UUID
    var moodRawValue: String
    var emotions: [String]
    var energyLevel: Int
    var note: String?
    var loggedAt: Date
    var weekNumber: Int
    var createdAt: Date

    var mood: PregnancyMood {
        get { PregnancyMood(rawValue: moodRawValue) ?? .calm }
        set { moodRawValue = newValue.rawValue }
    }

    init(id: UUID = UUID(), pregnancyProfileId: UUID, mood: PregnancyMood, emotions: [String] = [], energyLevel: Int = 3, note: String? = nil, loggedAt: Date = .now, weekNumber: Int, createdAt: Date = .now) {
        self.id = id
        self.pregnancyProfileId = pregnancyProfileId
        self.moodRawValue = mood.rawValue
        self.emotions = emotions
        self.energyLevel = energyLevel
        self.note = note
        self.loggedAt = loggedAt
        self.weekNumber = weekNumber
        self.createdAt = createdAt
    }
}
