import Foundation
import SwiftData

@Model
final class PregnancyMilestone {
    @Attribute(.unique) var id: UUID
    var pregnancyProfileId: UUID
    var weekNumber: Int
    var title: String
    var milestoneDescription: String
    var isPersonal: Bool
    var achievedAt: Date?
    var createdAt: Date

    init(id: UUID = UUID(), pregnancyProfileId: UUID, weekNumber: Int, title: String, description: String, isPersonal: Bool = false, achievedAt: Date? = nil, createdAt: Date = .now) {
        self.id = id
        self.pregnancyProfileId = pregnancyProfileId
        self.weekNumber = weekNumber
        self.title = title
        self.milestoneDescription = description
        self.isPersonal = isPersonal
        self.achievedAt = achievedAt
        self.createdAt = createdAt
    }
}

