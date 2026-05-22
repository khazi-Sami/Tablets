import Foundation

struct HKDailySnapshot {
    let date: Date
    let steps: Double?
    let activeEnergy: Double?
    let restingHeartRate: Double?
    let latestHeartRate: Double?
    let sleepDurationHours: Double?
    let oxygenSaturation: Double?
    let weight: Double?
}

struct HKSleepSummary {
    let date: Date
    let totalHours: Double
    let quality: SleepQuality

    enum SleepQuality {
        case short
        case moderate
        case good
        case unknown
    }
}

struct WellnessInsight: Identifiable {
    let id = UUID()
    let date: Date
    let message: String
    let category: InsightCategory

    enum InsightCategory {
        case activity
        case sleep
        case heartRate
        case medicineCorrelation
        case recoveryMode
        case general
    }
}

struct ReadinessSignal {
    let date: Date
    let level: ReadinessLevel
    let reason: String

    enum ReadinessLevel {
        case low
        case moderate
        case good
        case unknown
    }
}
