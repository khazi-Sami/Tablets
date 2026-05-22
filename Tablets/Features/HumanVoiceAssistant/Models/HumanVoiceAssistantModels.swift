import Foundation
import SwiftData

@Model
final class HumanAssistantConversation {
    @Attribute(.unique) var id: UUID
    var userText: String
    var assistantText: String
    var intentRawValue: String
    var confidence: Double
    var createdAt: Date

    var intent: HealthVoiceIntent {
        get { HealthVoiceIntent(rawValue: intentRawValue) ?? .unknown }
        set { intentRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        userText: String,
        assistantText: String,
        intent: HealthVoiceIntent,
        confidence: Double,
        createdAt: Date = .now
    ) {
        self.id = id
        self.userText = userText
        self.assistantText = assistantText
        self.intentRawValue = intent.rawValue
        self.confidence = min(max(confidence, 0), 1)
        self.createdAt = createdAt
    }
}

@Model
final class HumanAssistantPreference {
    @Attribute(.unique) var id: UUID
    var useBaseModelOnCapableDevices: Bool
    var prefersSpokenResponses: Bool
    var elderlyMode: Bool
    var voiceIdentifier: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        useBaseModelOnCapableDevices: Bool = true,
        prefersSpokenResponses: Bool = true,
        elderlyMode: Bool = false,
        voiceIdentifier: String = "com.apple.ttsbundle.Samantha-compact",
        createdAt: Date = .now
    ) {
        self.id = id
        self.useBaseModelOnCapableDevices = useBaseModelOnCapableDevices
        self.prefersSpokenResponses = prefersSpokenResponses
        self.elderlyMode = elderlyMode
        self.voiceIdentifier = voiceIdentifier
        self.createdAt = createdAt
    }
}

@Model
final class HumanVoiceMemory {
    @Attribute(.unique) var id: UUID
    var memoryTypeRawValue: String
    var phrase: String
    var value: String
    var count: Int
    var lastSeenAt: Date

    var memoryType: HumanVoiceMemoryType {
        get { HumanVoiceMemoryType(rawValue: memoryTypeRawValue) ?? .habit }
        set { memoryTypeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        memoryType: HumanVoiceMemoryType,
        phrase: String,
        value: String,
        count: Int = 1,
        lastSeenAt: Date = .now
    ) {
        self.id = id
        self.memoryTypeRawValue = memoryType.rawValue
        self.phrase = phrase
        self.value = value
        self.count = max(count, 0)
        self.lastSeenAt = lastSeenAt
    }
}

enum HumanVoiceMemoryType: String, Codable, CaseIterable, Identifiable {
    case habit
    case frequentMedicineTime
    case reminderResponsePattern
    case commonSymptom

    var id: String { rawValue }
}

enum HealthVoiceIntent: String, Codable, CaseIterable, Identifiable {
    case logSugar
    case logBloodPressure
    case askSugar
    case askBloodPressure
    case askMedicineTaken
    case memorySearch
    case logSymptoms
    case medicineTaken
    case pendingMedicine
    case reminderRequest
    case startPeriod
    case weeklyHealth
    case unknown

    var id: String { rawValue }
}

struct ParsedHealthCommand {
    let intent: HealthVoiceIntent
    let originalText: String
    let numbers: [Double]
    let symptoms: [String]
    let entities: [String: String]
    let confidence: Double
}

struct HealthAssistantResponse {
    let text: String
    let requiresConfirmation: Bool
    let confidence: Double
}
