import Foundation
import SwiftData

@Model
final class BirthPlan {
    @Attribute(.unique) var id: UUID
    var pregnancyProfileId: UUID
    var birthLocation: String?
    var birthPartner: String?
    var painManagement: [String]
    var mobilityPreferences: String?
    var deliveryPreferences: String?
    var babyAfterBirth: [String]
    var feedingPreference: String?
    var specialRequests: String?
    var doctorNotes: String?
    var lastUpdated: Date
    var createdAt: Date

    init(id: UUID = UUID(), pregnancyProfileId: UUID, birthLocation: String? = nil, birthPartner: String? = nil, painManagement: [String] = [], mobilityPreferences: String? = nil, deliveryPreferences: String? = nil, babyAfterBirth: [String] = [], feedingPreference: String? = nil, specialRequests: String? = nil, doctorNotes: String? = nil, lastUpdated: Date = .now, createdAt: Date = .now) {
        self.id = id
        self.pregnancyProfileId = pregnancyProfileId
        self.birthLocation = birthLocation
        self.birthPartner = birthPartner
        self.painManagement = painManagement
        self.mobilityPreferences = mobilityPreferences
        self.deliveryPreferences = deliveryPreferences
        self.babyAfterBirth = babyAfterBirth
        self.feedingPreference = feedingPreference
        self.specialRequests = specialRequests
        self.doctorNotes = doctorNotes
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
    }
}
