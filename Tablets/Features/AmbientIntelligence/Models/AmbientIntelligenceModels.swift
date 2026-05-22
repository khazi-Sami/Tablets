import Foundation
import SwiftData
import SwiftUI

@Model
final class AmbientHabitSignal {
    @Attribute(.unique) var id: UUID
    var signalTypeRawValue: String
    var hourOfDay: Int
    var eventCount: Int
    var averageResponseDelayMinutes: Double
    var confidence: Double
    var lastUpdatedAt: Date
    var note: String

    var signalType: AmbientHabitSignalType {
        get { AmbientHabitSignalType(rawValue: signalTypeRawValue) ?? .medicine }
        set { signalTypeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        signalType: AmbientHabitSignalType,
        hourOfDay: Int,
        eventCount: Int = 1,
        averageResponseDelayMinutes: Double = 0,
        confidence: Double = 0.2,
        lastUpdatedAt: Date = .now,
        note: String = ""
    ) {
        self.id = id
        self.signalTypeRawValue = signalType.rawValue
        self.hourOfDay = min(max(hourOfDay, 0), 23)
        self.eventCount = max(eventCount, 0)
        self.averageResponseDelayMinutes = max(averageResponseDelayMinutes, 0)
        self.confidence = min(max(confidence, 0), 1)
        self.lastUpdatedAt = lastUpdatedAt
        self.note = note
    }
}

@Model
final class AmbientInteractionMemory {
    @Attribute(.unique) var id: UUID
    var screenName: String
    var interactionType: String
    var hourOfDay: Int
    var count: Int
    var lastSeenAt: Date

    init(
        id: UUID = UUID(),
        screenName: String,
        interactionType: String,
        hourOfDay: Int = Calendar.current.component(.hour, from: .now),
        count: Int = 1,
        lastSeenAt: Date = .now
    ) {
        self.id = id
        self.screenName = screenName
        self.interactionType = interactionType
        self.hourOfDay = min(max(hourOfDay, 0), 23)
        self.count = max(count, 0)
        self.lastSeenAt = lastSeenAt
    }
}

enum AmbientHabitSignalType: String, Codable, CaseIterable, Identifiable {
    case medicine
    case bloodPressure
    case sugar
    case hydration
    case sleep
    case symptoms
    case assistant

    var id: String { rawValue }
}

enum AmbientTimeMode: String {
    case morning
    case afternoon
    case night
}

enum AmbientEmotionalMode: String {
    case calm
    case focused
    case healing
    case celebratory
    case simplified
}

struct AmbientIntelligenceState {
    let timeMode: AmbientTimeMode
    let emotionalMode: AmbientEmotionalMode
    let assistantTone: String
    let dashboardPriority: [AmbientDashboardPriority]
    let observations: [String]
    let elderlyModeSuggested: Bool
    let animationSpeed: Double
    let brightness: Double
}

enum AmbientDashboardPriority: String, Identifiable {
    case overdueMedicine
    case nextMedicine
    case healthLogging
    case hydration
    case womensHealth
    case healthJourney

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overdueMedicine: return "Overdue medicine"
        case .nextMedicine: return "Next medicine"
        case .healthLogging: return "Health logging"
        case .hydration: return "Hydration"
        case .womensHealth: return "Women’s health"
        case .healthJourney: return "Health journey"
        }
    }

    var symbol: String {
        switch self {
        case .overdueMedicine: return "bell.badge.fill"
        case .nextMedicine: return "pills.fill"
        case .healthLogging: return "heart.text.square.fill"
        case .hydration: return "drop.fill"
        case .womensHealth: return "heart.circle.fill"
        case .healthJourney: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .overdueMedicine: return AppColor.softRed
        case .nextMedicine: return AppColor.medicalBlue
        case .healthLogging: return AppColor.mintGreenDeep
        case .hydration: return AppColor.medicalBlue
        case .womensHealth: return AppColor.lavenderDeep
        case .healthJourney: return AppColor.mintGreenDeep
        }
    }
}
