import Foundation
import SwiftData

@Model
final class PregnancyNote {
    @Attribute(.unique) var id: UUID
    var pregnancyProfileId: UUID
    var text: String
    var categoryRawValue: String
    var loggedAt: Date
    var weekNumber: Int
    var createdAt: Date

    var category: NoteCategory {
        get { NoteCategory(rawValue: categoryRawValue) ?? .general }
        set { categoryRawValue = newValue.rawValue }
    }

    init(id: UUID = UUID(), pregnancyProfileId: UUID, text: String, category: NoteCategory = .general, loggedAt: Date = .now, weekNumber: Int, createdAt: Date = .now) {
        self.id = id
        self.pregnancyProfileId = pregnancyProfileId
        self.text = text
        self.categoryRawValue = category.rawValue
        self.loggedAt = loggedAt
        self.weekNumber = weekNumber
        self.createdAt = createdAt
    }
}

enum NoteCategory: String, Codable, CaseIterable, Identifiable {
    case general = "General"
    case forDoctor = "For Doctor"
    case reminder = "Reminder"
    case question = "Question"
    case feeling = "Feeling"

    var id: String { rawValue }
}
