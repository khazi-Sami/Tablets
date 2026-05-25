import Foundation
import SwiftData

@Model
final class BabyKickLog: Identifiable {
    @Attribute(.unique) var id: UUID
    var pregnancyProfileId: UUID
    var sessionStartedAt: Date
    var sessionEndedAt: Date?
    var kickCount: Int
    var durationMinutes: Int?
    var notes: String?
    var createdAt: Date

    init(id: UUID = UUID(), pregnancyProfileId: UUID, sessionStartedAt: Date = .now, sessionEndedAt: Date? = nil, kickCount: Int, durationMinutes: Int? = nil, notes: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.pregnancyProfileId = pregnancyProfileId
        self.sessionStartedAt = sessionStartedAt
        self.sessionEndedAt = sessionEndedAt
        self.kickCount = kickCount
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.createdAt = createdAt
    }
}
