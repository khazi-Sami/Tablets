import Foundation
import SwiftData
import SwiftUI

@Model
final class DailyHealthCheckIn {
    @Attribute(.unique) var id: UUID
    var date: Date
    var moodRawValue: String
    var stressLevel: Int
    var energyLevel: Int
    var sleepQualityRawValue: String
    var symptoms: [String]
    var notes: String
    var createdAt: Date

    var mood: JourneyMood {
        get { JourneyMood(rawValue: moodRawValue) ?? .calm }
        set { moodRawValue = newValue.rawValue }
    }

    var sleepQuality: SleepQuality {
        get { SleepQuality(rawValue: sleepQualityRawValue) ?? .okay }
        set { sleepQualityRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        date: Date = .now,
        mood: JourneyMood = .calm,
        stressLevel: Int = 3,
        energyLevel: Int = 6,
        sleepQuality: SleepQuality = .okay,
        symptoms: [String] = [],
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.moodRawValue = mood.rawValue
        self.stressLevel = min(max(stressLevel, 0), 10)
        self.energyLevel = min(max(energyLevel, 0), 10)
        self.sleepQualityRawValue = sleepQuality.rawValue
        self.symptoms = symptoms
        self.notes = notes
        self.createdAt = createdAt
    }
}

@Model
final class WellnessMemory {
    @Attribute(.unique) var id: UUID
    var habitName: String
    var categoryRawValue: String
    var preferredHour: Int
    var consistencyScore: Double
    var lastObservedAt: Date
    var notes: String

    var category: WellnessMemoryCategory {
        get { WellnessMemoryCategory(rawValue: categoryRawValue) ?? .medicine }
        set { categoryRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        habitName: String,
        category: WellnessMemoryCategory,
        preferredHour: Int = 8,
        consistencyScore: Double = 0,
        lastObservedAt: Date = .now,
        notes: String = ""
    ) {
        self.id = id
        self.habitName = habitName
        self.categoryRawValue = category.rawValue
        self.preferredHour = min(max(preferredHour, 0), 23)
        self.consistencyScore = min(max(consistencyScore, 0), 1)
        self.lastObservedAt = lastObservedAt
        self.notes = notes
    }
}

enum WellnessMemoryCategory: String, Codable, CaseIterable, Identifiable {
    case medicine
    case bloodPressure
    case sugar
    case hydration
    case sleep
    case symptoms

    var id: String { rawValue }
}

enum JourneyMood: String, Codable, CaseIterable, Identifiable {
    case calm
    case hopeful
    case tired
    case stressed
    case energetic
    case healing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: return "Calm"
        case .hopeful: return "Hopeful"
        case .tired: return "Tired"
        case .stressed: return "Stressed"
        case .energetic: return "Energetic"
        case .healing: return "Healing"
        }
    }

    var symbol: String {
        switch self {
        case .calm: return "leaf.fill"
        case .hopeful: return "sunrise.fill"
        case .tired: return "moon.zzz.fill"
        case .stressed: return "wind"
        case .energetic: return "bolt.heart.fill"
        case .healing: return "heart.circle.fill"
        }
    }
}

enum EmotionalWellnessMode: String {
    case calm
    case energetic
    case recovery
    case focus
    case healing

    var title: String {
        switch self {
        case .calm: return "Calm mode"
        case .energetic: return "Energetic mode"
        case .recovery: return "Recovery mode"
        case .focus: return "Focus mode"
        case .healing: return "Healing mode"
        }
    }
}

struct JourneyFeedItem: Identifiable {
    enum Kind {
        case medicine
        case bloodPressure
        case sugar
        case mood
        case symptom
        case period
        case sleep
        case water
        case streak
        case encouragement
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let subtitle: String
    let date: Date
    let symbol: String
    let color: Color
}

struct HealthStreakSummary {
    let medicine: Int
    let bloodPressure: Int
    let hydration: Int
    let sleep: Int
    let symptoms: Int

    var best: Int {
        [medicine, bloodPressure, hydration, sleep, symptoms].max() ?? 0
    }
}
