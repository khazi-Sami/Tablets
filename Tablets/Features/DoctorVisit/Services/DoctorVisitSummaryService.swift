import Foundation

struct DoctorVisitSummaryService {
    func makeSummary(
        range: DoctorReportRange,
        customStart: Date,
        customEnd: Date,
        medicines: [Medicine],
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        womensLogs: [WomensHealthDailyLog],
        periodCycles: [PeriodCycle],
        notes: String
    ) -> DoctorVisitSummary {
        let endDate = range == .custom ? customEnd : Date()
        let startDate: Date
        switch range {
        case .sevenDays:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .thirtyDays:
            startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        case .custom:
            startDate = customStart
        }

        let logs = medicineLogs.filter { $0.scheduledTime >= startDate && $0.scheduledTime <= endDate }
        let records = healthRecords.filter { $0.measuredAt >= startDate && $0.measuredAt <= endDate }
        let womens = womensLogs.filter { $0.date >= startDate && $0.date <= endDate }
        let periods = periodCycles.filter { $0.startDate <= endDate && ($0.endDate ?? .now) >= startDate }

        return DoctorVisitSummary(
            startDate: startDate,
            endDate: endDate,
            medicines: medicines.filter(\.isActive),
            medicineTakenCount: logs.filter { $0.status == .taken }.count,
            medicineMissedCount: logs.filter { $0.status == .missed || $0.status == .skipped }.count,
            averageBP: averageBP(records),
            averageSugar: average(records.filter { $0.type == .bloodSugar }.map(\.value1), unit: "mg/dL"),
            highestSugar: extreme(records.filter { $0.type == .bloodSugar }.map(\.value1), isHigh: true, unit: "mg/dL"),
            lowestSugar: extreme(records.filter { $0.type == .bloodSugar }.map(\.value1), isHigh: false, unit: "mg/dL"),
            symptomFrequency: symptomFrequency(womens),
            periodSummary: periodSummary(periods),
            notes: notes
        )
    }

    private func averageBP(_ records: [HealthRecord]) -> String {
        let bp = records.filter { $0.type == .bloodPressure && $0.value2 != nil }
        guard !bp.isEmpty else { return "No BP logs" }
        let systolic = bp.map(\.value1).reduce(0, +) / Double(bp.count)
        let diastolic = bp.compactMap(\.value2).reduce(0, +) / Double(bp.count)
        return "\(Int(systolic.rounded()))/\(Int(diastolic.rounded())) mmHg"
    }

    private func average(_ values: [Double], unit: String) -> String {
        guard !values.isEmpty else { return "No logs" }
        return "\(Int((values.reduce(0, +) / Double(values.count)).rounded())) \(unit)"
    }

    private func extreme(_ values: [Double], isHigh: Bool, unit: String) -> String {
        guard let value = isHigh ? values.max() : values.min() else { return "No logs" }
        return "\(Int(value.rounded())) \(unit)"
    }

    private func symptomFrequency(_ logs: [WomensHealthDailyLog]) -> [(String, Int)] {
        let symptoms = logs.flatMap(\.symptoms)
        let grouped = Dictionary(grouping: symptoms, by: { $0 })
        return grouped.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }

    private func periodSummary(_ cycles: [PeriodCycle]) -> String {
        guard let latest = cycles.sorted(by: { $0.startDate > $1.startDate }).first else {
            return "No period logs in this range"
        }
        let end = latest.endDate?.mediumDateText ?? "ongoing"
        return "Latest period started \(latest.startDate.mediumDateText), end: \(end), flow: \(latest.flowLevel.title), pain: \(latest.painLevel)/10"
    }
}
