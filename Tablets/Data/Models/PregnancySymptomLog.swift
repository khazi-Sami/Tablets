import Foundation
import SwiftData

@Model
final class PregnancySymptomLog {
    @Attribute(.unique) var id: UUID
    var pregnancyProfileId: UUID
    var loggedAt: Date
    var symptoms: [String]
    var severityRawValue: String
    var moodRawValue: String
    var notes: String?
    var createdAt: Date

    var severity: SymptomSeverity {
        get { SymptomSeverity(rawValue: severityRawValue) ?? .mild }
        set { severityRawValue = newValue.rawValue }
    }

    var mood: PregnancyMood {
        get { PregnancyMood(rawValue: moodRawValue) ?? .calm }
        set { moodRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        pregnancyProfileId: UUID,
        loggedAt: Date = .now,
        symptoms: [String],
        severity: SymptomSeverity = .mild,
        mood: PregnancyMood = .calm,
        notes: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.pregnancyProfileId = pregnancyProfileId
        self.loggedAt = loggedAt
        self.symptoms = symptoms
        self.severityRawValue = severity.rawValue
        self.moodRawValue = mood.rawValue
        self.notes = notes
        self.createdAt = createdAt
    }
}

enum SymptomSeverity: String, Codable, CaseIterable, Identifiable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"

    var id: String { rawValue }
}

enum PregnancyMood: String, Codable, CaseIterable, Identifiable {
    case happy = "Happy"
    case anxious = "Anxious"
    case tired = "Tired"
    case emotional = "Emotional"
    case calm = "Calm"
    case uncomfortable = "Uncomfortable"
    case excited = "Excited"
    case worried = "Worried"

    var id: String { rawValue }
}

