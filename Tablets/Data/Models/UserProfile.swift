import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var appleUserId: String?
    var loginMethod: String = "guest"
    var createdAt: Date = Date()
    var hasCompletedOnboarding: Bool = false
    var displayName: String?
    var age: Int?
    var genderRawValue: String?
    var healthConditions: [String] = []
    var selectedFeatures: [String] = []
    var preferredLanguage: String = "english"

    var gender: Gender? {
        get {
            guard let genderRawValue else { return nil }
            return Gender(rawValue: genderRawValue)
        }
        set {
            genderRawValue = newValue?.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        appleUserId: String? = nil,
        loginMethod: String = "guest",
        createdAt: Date = .now,
        hasCompletedOnboarding: Bool = false,
        displayName: String? = nil,
        age: Int? = nil,
        gender: Gender? = nil,
        healthConditions: [String] = [],
        selectedFeatures: [String] = [],
        preferredLanguage: String = "english"
    ) {
        self.id = id
        self.name = name
        self.appleUserId = appleUserId
        self.loginMethod = loginMethod
        self.createdAt = createdAt
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.displayName = displayName
        self.age = age
        self.genderRawValue = gender?.rawValue
        self.healthConditions = healthConditions
        self.selectedFeatures = selectedFeatures
        self.preferredLanguage = preferredLanguage
    }
}

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male
    case female
    case preferNotToSay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .preferNotToSay: "Prefer not to say"
        }
    }
}
