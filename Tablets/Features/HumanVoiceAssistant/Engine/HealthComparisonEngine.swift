import Foundation

struct HealthComparisonEngine {
    func sugarComparison(value: Double, testType: SugarTestType, records: [HealthRecord]) -> String {
        let previous = records
            .filter { $0.type == .bloodSugar && $0.sugarTestType == testType }
            .sorted { $0.measuredAt > $1.measuredAt }
            .first

        guard let previous else {
            return "I do not see a previous \(testType.title.lowercased()) sugar log to compare yet."
        }

        if value < previous.value1 {
            return "Based on your recent logs, this is slightly lower than your previous \(testType.title.lowercased()) reading."
        }
        if value > previous.value1 {
            return "Based on your recent logs, this is higher than your previous \(testType.title.lowercased()) reading."
        }
        return "Based on your recent logs, this is similar to your previous \(testType.title.lowercased()) reading."
    }

    func latestSugarComparison(records: [HealthRecord]) -> String {
        let sugarRecords = records
            .filter { $0.type == .bloodSugar }
            .sorted { $0.measuredAt > $1.measuredAt }

        guard let latest = sugarRecords.first else {
            return "I do not see a saved sugar reading yet."
        }

        guard let previous = sugarRecords.dropFirst().first else {
            return "Your most recent sugar reading was \(Int(latest.value1)) \(latest.unit). I need more saved readings for comparison. This is informational only."
        }

        let direction: String
        if latest.value1 < previous.value1 {
            direction = "slightly lower than"
        } else if latest.value1 > previous.value1 {
            direction = "higher than"
        } else {
            direction = "similar to"
        }

        return "Your most recent sugar reading was \(Int(latest.value1)) \(latest.unit). Based on your saved logs, it is \(direction) your previous reading. This is informational only."
    }

    func bpComparison(records: [HealthRecord]) -> String {
        let bp = records
            .filter { $0.type == .bloodPressure && $0.value2 != nil }
            .sorted { $0.measuredAt > $1.measuredAt }

        guard let latest = bp.first else {
            return "I do not see a BP reading saved yet."
        }

        guard bp.count > 1 else {
            return "Your most recent BP reading was \(Int(latest.value1)) over \(Int(latest.value2 ?? 0)). I need more saved readings for comparison."
        }

        return "Your most recent BP reading was \(Int(latest.value1)) over \(Int(latest.value2 ?? 0)). Based on your saved logs, it looks stable compared to your previous readings."
    }

    func weeklySummary(records: [HealthRecord]) -> String {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let recent = records.filter { $0.measuredAt >= weekAgo }
        let bpCount = recent.filter { $0.type == .bloodPressure }.count
        let sugarCount = recent.filter { $0.type == .bloodSugar }.count
        return "Based on your saved logs this week, you recorded \(bpCount) BP readings and \(sugarCount) sugar readings. This is informational only."
    }
}
