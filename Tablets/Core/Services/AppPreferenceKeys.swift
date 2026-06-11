import Foundation

enum AppPreferenceKeys {
    static let appGroupID = "group.com.samisiddiqui.BanyAI"
    static let sharedDefaults = UserDefaults(suiteName: appGroupID) ?? .standard

    static let theme = "settings_theme"
    static let textSize = "settings_textSize"
    static let boldText = "settings_boldText"
    static let reduceAnimations = "settings_reduceAnimations"
    static let voiceLanguage = "settings_voiceLanguage"
    static let voiceSpeed = "settings_voiceSpeed"
    static let autoListenAfterResponse = "settings_autoListenAfterResponse"
    static let appLockEnabled = "appLockEnabled"
    static let hasSeenQuickStartGuide = "hasSeenQuickStartGuide"
    static let completedSession = "tablets_has_completed_session"

    static var hasCompletedSession: Bool {
        standardOrSharedBool(forKey: completedSession)
    }

    static func setCompletedSession(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: completedSession)
        sharedDefaults.set(value, forKey: completedSession)
        UserDefaults.standard.synchronize()
        sharedDefaults.synchronize()
    }

    static func clearCompletedSession() {
        UserDefaults.standard.removeObject(forKey: completedSession)
        sharedDefaults.removeObject(forKey: completedSession)
        UserDefaults.standard.synchronize()
        sharedDefaults.synchronize()
    }

    private static func standardOrSharedBool(forKey key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key) || sharedDefaults.bool(forKey: key)
    }
}

enum AppThemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum AppTextSizePreference: String, CaseIterable, Identifiable {
    case standard
    case large
    case extraLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
}

enum VoiceLanguagePreference: String, CaseIterable, Identifiable {
    case english

    var id: String { rawValue }

    var title: String {
        switch self {
        case .english: return "English"
        }
    }
}

enum VoiceSpeedPreference: String, CaseIterable, Identifiable {
    case slow
    case normal
    case fast

    var id: String { rawValue }

    var title: String {
        switch self {
        case .slow: return "Slow"
        case .normal: return "Normal"
        case .fast: return "Fast"
        }
    }

    var speechRate: Float {
        switch self {
        case .slow: return 0.36
        case .normal: return 0.45
        case .fast: return 0.53
        }
    }
}
