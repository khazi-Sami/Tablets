import Foundation
import SwiftData

@Model
final class UserHealthHabit {
    @Attribute(.unique) var id: UUID
    var habitTypeRawValue: String
    var title: String
    var detail: String
    var preferredHour: Int?
    var confidence: Double
    var lastUpdatedAt: Date

    var habitType: UserHealthHabitType {
        get { UserHealthHabitType(rawValue: habitTypeRawValue) ?? .interaction }
        set { habitTypeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        habitType: UserHealthHabitType,
        title: String,
        detail: String,
        preferredHour: Int? = nil,
        confidence: Double = 0.5,
        lastUpdatedAt: Date = .now
    ) {
        self.id = id
        self.habitTypeRawValue = habitType.rawValue
        self.title = title
        self.detail = detail
        self.preferredHour = preferredHour
        self.confidence = min(max(confidence, 0), 1)
        self.lastUpdatedAt = lastUpdatedAt
    }
}

@Model
final class HealthPatternMemory {
    @Attribute(.unique) var id: UUID
    var patternTypeRawValue: String
    var label: String
    var summary: String
    var occurrences: Int
    var firstSeenAt: Date
    var lastSeenAt: Date

    var patternType: HealthPatternType {
        get { HealthPatternType(rawValue: patternTypeRawValue) ?? .symptom }
        set { patternTypeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        patternType: HealthPatternType,
        label: String,
        summary: String,
        occurrences: Int = 1,
        firstSeenAt: Date = .now,
        lastSeenAt: Date = .now
    ) {
        self.id = id
        self.patternTypeRawValue = patternType.rawValue
        self.label = label
        self.summary = summary
        self.occurrences = max(occurrences, 0)
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
    }
}

@Model
final class AssistantInteractionMemory {
    @Attribute(.unique) var id: UUID
    var phrase: String
    var intentRawValue: String
    var responseToneRawValue: String
    var interactionHour: Int
    var responseDelaySeconds: Double
    var createdAt: Date

    var intent: HealthVoiceIntent {
        get { HealthVoiceIntent(rawValue: intentRawValue) ?? .unknown }
        set { intentRawValue = newValue.rawValue }
    }

    var responseTone: AssistantTone {
        get { AssistantTone(rawValue: responseToneRawValue) ?? .balanced }
        set { responseToneRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        phrase: String,
        intent: HealthVoiceIntent,
        responseTone: AssistantTone = .balanced,
        interactionHour: Int = Calendar.current.component(.hour, from: .now),
        responseDelaySeconds: Double = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.phrase = phrase
        self.intentRawValue = intent.rawValue
        self.responseToneRawValue = responseTone.rawValue
        self.interactionHour = interactionHour
        self.responseDelaySeconds = max(responseDelaySeconds, 0)
        self.createdAt = createdAt
    }
}

@Model
final class ReminderBehaviorMemory {
    @Attribute(.unique) var id: UUID
    var medicineName: String
    var scheduledHour: Int
    var averageDelayMinutes: Double
    var snoozeCount: Int
    var missedCount: Int
    var takenCount: Int
    var lastUpdatedAt: Date

    init(
        id: UUID = UUID(),
        medicineName: String,
        scheduledHour: Int,
        averageDelayMinutes: Double = 0,
        snoozeCount: Int = 0,
        missedCount: Int = 0,
        takenCount: Int = 0,
        lastUpdatedAt: Date = .now
    ) {
        self.id = id
        self.medicineName = medicineName
        self.scheduledHour = scheduledHour
        self.averageDelayMinutes = max(averageDelayMinutes, 0)
        self.snoozeCount = max(snoozeCount, 0)
        self.missedCount = max(missedCount, 0)
        self.takenCount = max(takenCount, 0)
        self.lastUpdatedAt = lastUpdatedAt
    }
}

enum UserHealthHabitType: String, Codable, CaseIterable, Identifiable {
    case medicineTiming
    case bpLogging
    case sugarLogging
    case interaction
    case sleep
    case assistantPersonality

    var id: String { rawValue }
}

enum HealthPatternType: String, Codable, CaseIterable, Identifiable {
    case symptom
    case streak
    case trend
    case phrase

    var id: String { rawValue }
}

enum AssistantTone: String, Codable, CaseIterable, Identifiable {
    case calm
    case encouraging
    case supportive
    case balanced

    var id: String { rawValue }
}

struct HealthInsightCard: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let tint: String
}
