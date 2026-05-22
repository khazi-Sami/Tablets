import Foundation
import SwiftData

@Model
final class PeriodCycle {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date?
    var flowLevelRawValue: String
    var painLevel: Int
    var moodRawValue: String
    var symptoms: [String]
    var notes: String
    var createdAt: Date

    var flowLevel: WomensFlowLevel {
        get { WomensFlowLevel(rawValue: flowLevelRawValue) ?? .medium }
        set { flowLevelRawValue = newValue.rawValue }
    }

    var mood: WomensMood {
        get { WomensMood(rawValue: moodRawValue) ?? .calm }
        set { moodRawValue = newValue.rawValue }
    }

    var durationDays: Int? {
        guard let endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day.map { max($0 + 1, 1) }
    }

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        flowLevel: WomensFlowLevel = .medium,
        painLevel: Int = 0,
        mood: WomensMood = .calm,
        symptoms: [String] = [],
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.flowLevelRawValue = flowLevel.rawValue
        self.painLevel = min(max(painLevel, 0), 10)
        self.moodRawValue = mood.rawValue
        self.symptoms = symptoms
        self.notes = notes
        self.createdAt = createdAt
    }
}

enum WomensFlowLevel: String, Codable, CaseIterable, Identifiable {
    case light
    case medium
    case heavy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        }
    }
}

enum WomensMood: String, Codable, CaseIterable, Identifiable {
    case calm
    case happy
    case tired
    case sensitive
    case anxious
    case irritated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm: return "Calm"
        case .happy: return "Happy"
        case .tired: return "Tired"
        case .sensitive: return "Sensitive"
        case .anxious: return "Anxious"
        case .irritated: return "Irritated"
        }
    }
}

enum WomensHealthSymptom: String, Codable, CaseIterable, Identifiable {
    case cramps
    case headache
    case backPain
    case breastTenderness
    case acne
    case bloating
    case fatigue
    case moodSwings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cramps: return "Cramps"
        case .headache: return "Headache"
        case .backPain: return "Back pain"
        case .breastTenderness: return "Breast tenderness"
        case .acne: return "Acne"
        case .bloating: return "Bloating"
        case .fatigue: return "Fatigue"
        case .moodSwings: return "Mood swings"
        }
    }
}
