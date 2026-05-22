import Foundation

enum UserProfileGender: String, CaseIterable, Identifiable {
    case male
    case female
    case other
    case preferNotToSay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

enum UserHealthProfile {
    static let userNameKey = "profile_userName"
    static let genderKey = "profile_gender"
    static let womenHealthEnabledKey = "profile_womenHealthEnabled"
    static let elderlyModeKey = "profile_elderlyMode"
    static let highContrastKey = "profile_highContrast"
    static let healthKitEnabledKey = "profile_healthKitEnabled"
    static let healthKitWriteEnabledKey = "profile_healthKitWriteEnabled"

    static var userName: String {
        get { UserDefaults.standard.string(forKey: userNameKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: userNameKey) }
    }

    static var gender: UserProfileGender {
        get {
            let rawValue = UserDefaults.standard.string(forKey: genderKey) ?? UserProfileGender.preferNotToSay.rawValue
            return UserProfileGender(rawValue: rawValue) ?? .preferNotToSay
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: genderKey) }
    }

    static var womenHealthEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: womenHealthEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: womenHealthEnabledKey) }
    }

    static var elderlyMode: Bool {
        get { UserDefaults.standard.bool(forKey: elderlyModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: elderlyModeKey) }
    }

    static var highContrast: Bool {
        get { UserDefaults.standard.bool(forKey: highContrastKey) }
        set { UserDefaults.standard.set(newValue, forKey: highContrastKey) }
    }

    static var healthKitEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: healthKitEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: healthKitEnabledKey) }
    }

    static var healthKitWriteEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: healthKitWriteEnabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: healthKitWriteEnabledKey) }
    }

    static var showWomensHealthCard: Bool {
        gender == .female || womenHealthEnabled
    }
}
