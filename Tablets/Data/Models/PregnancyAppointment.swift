import Foundation
import SwiftData

@Model
final class PregnancyAppointment {
    @Attribute(.unique) var id: UUID
    var pregnancyProfileId: UUID
    var title: String
    var scheduledAt: Date
    var location: String?
    var doctorName: String?
    var notes: String?
    var isCompleted: Bool
    var createdAt: Date

    init(id: UUID = UUID(), pregnancyProfileId: UUID, title: String, scheduledAt: Date, location: String? = nil, doctorName: String? = nil, notes: String? = nil, isCompleted: Bool = false, createdAt: Date = .now) {
        self.id = id
        self.pregnancyProfileId = pregnancyProfileId
        self.title = title
        self.scheduledAt = scheduledAt
        self.location = location
        self.doctorName = doctorName
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

