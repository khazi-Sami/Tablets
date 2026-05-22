import Foundation
import SwiftData

struct MedicineTakePattern: Identifiable {
    var id: String { "\(String(describing: medicineID))-\(AdaptiveReminderTimeKey.key(from: scheduledTime))" }
    let medicineID: PersistentIdentifier
    let medicineName: String
    let scheduledTime: DateComponents
    let averageActualMinuteOffset: Int
    let sampleCount: Int
    let confidenceLevel: PatternConfidence
    let lastComputedAt: Date
}

enum PatternConfidence: String, CaseIterable {
    case insufficient
    case low
    case moderate
    case high

    static func level(for sampleCount: Int) -> PatternConfidence {
        switch sampleCount {
        case ..<5: return .insufficient
        case 5..<10: return .low
        case 10..<20: return .moderate
        default: return .high
        }
    }

    var title: String {
        switch self {
        case .insufficient: return "Insufficient"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
}

struct AdaptiveShift: Identifiable {
    let id = UUID()
    let medicineID: PersistentIdentifier
    let medicineName: String
    let originalTime: Date
    let shiftedTime: Date
    let shiftMinutes: Int
    let appliedAt: Date
}

struct MissedDoseFollowUp: Identifiable {
    var id: String { notificationID }
    let notificationID: String
    let medicineID: PersistentIdentifier?
    let medicineName: String
    let scheduledAt: Date
    let followUpFireAt: Date
    var isCancelled: Bool
}

struct AdaptiveReminderConfig {
    var followUpDelayMinutes: Int = 20
    var maxFollowUpsPerDose: Int = 2
    var analysisWindowDays: Int = 30
    var minShiftMinutes: Int = 5
    var maxShiftMinutes: Int = 90
    var minimumSamplesForShift: Int = 5
}

enum AdaptiveReminderTimeKey {
    static func key(from components: DateComponents) -> String {
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return String(format: "%02d%02d", hour, minute)
    }

    static func key(from date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return key(from: components)
    }
}
