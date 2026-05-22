import Foundation
import SwiftData

@Model
final class PeriodRecord {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date?
    var flowLevelRawValue: String
    var symptoms: [String]
    var moodRawValue: String
    var notes: String

    var flowLevel: PeriodFlowLevel {
        get { PeriodFlowLevel(rawValue: flowLevelRawValue) ?? .medium }
        set { flowLevelRawValue = newValue.rawValue }
    }

    var mood: PeriodMood {
        get { PeriodMood(rawValue: moodRawValue) ?? .okay }
        set { moodRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        flowLevel: PeriodFlowLevel = .medium,
        symptoms: [String] = [],
        mood: PeriodMood = .okay,
        notes: String = ""
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.flowLevelRawValue = flowLevel.rawValue
        self.symptoms = symptoms
        self.moodRawValue = mood.rawValue
        self.notes = notes
    }
}

enum PeriodFlowLevel: String, Codable, CaseIterable, Identifiable {
    case light
    case medium
    case heavy
    case spotting

    var id: String { rawValue }
}

enum PeriodMood: String, Codable, CaseIterable, Identifiable {
    case happy
    case okay
    case tired
    case anxious
    case sad
    case irritated

    var id: String { rawValue }
}
