import Foundation
import SwiftData

protocol HealthQueryAnswering {
    func answer(_ transcript: String, modelContext: ModelContext) async -> String?
}

@MainActor
final class HealthQueryEngine: HealthQueryAnswering {
    private let detector = HealthQueryTypeDetector()

    func answer(_ transcript: String, modelContext: ModelContext) async -> String? {
        switch detector.detect(transcript) {
        case .bpLatest:
            return bloodPressureAnswer(modelContext: modelContext, mode: .latest)
        case .bpAverage:
            return bloodPressureAnswer(modelContext: modelContext, mode: .average)
        case .bpComparison:
            return bloodPressureAnswer(modelContext: modelContext, mode: .comparison)
        case .bpRangeCheck(let systolic, let diastolic):
            return bpRangeAnswer(systolic: systolic, diastolic: diastolic, modelContext: modelContext)
        case .sugarLatest:
            return sugarAnswer(testType: nil, modelContext: modelContext, mode: .latest)
        case .sugarAverage:
            return sugarAnswer(testType: nil, modelContext: modelContext, mode: .average)
        case .sugarComparison:
            return sugarAnswer(testType: nil, modelContext: modelContext, mode: .comparison)
        case .sugarRangeCheck(let value, let testType):
            return sugarRangeAnswer(value: value, testType: testType, modelContext: modelContext)
        case .medicinePending:
            return medicinePendingAnswer(modelContext: modelContext)
        case .medicineNext:
            return medicineNextAnswer(modelContext: modelContext)
        case .medicineTakenStatus:
            return medicineTakenAnswer(modelContext: modelContext)
        case .periodLast:
            return periodAnswer(modelContext: modelContext, mode: .last)
        case .periodNext:
            return periodAnswer(modelContext: modelContext, mode: .next)
        case .periodCycle:
            return periodAnswer(modelContext: modelContext, mode: .cycle)
        case .doctorNext:
            return doctorAnswer(modelContext: modelContext)
        case .babyStatus:
            return BabyStatusEngine().getBabyStatusSummary(context: modelContext)
        case .pregnancy:
            return answerPregnancyQuery(transcript, context: modelContext)
        case .pregnancyHydrationReminder(let minutes):
            let profiles = fetch(modelContext, descriptor: FetchDescriptor<PregnancyProfile>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
            guard let profile = profiles.first(where: \.isActive) else {
                return "I don't have pregnancy information saved yet. Say Open pregnancy to set up your journey."
            }
            guard profile.hydrationRemindersEnabled != false else {
                PregnancyHydrationService().cancelAllHydrationReminders()
                return "Hydration reminders are turned off. Turn them on in Pregnancy and Planning before setting a water reminder."
            }
            let result = await PregnancyHydrationService().scheduleQuickReminder(minutes: minutes)
            switch result {
            case .scheduled:
                return "Done. I'll remind you to drink water in \(minutes) minute\(minutes == 1 ? "" : "s"). This is informational only — please follow your doctor's guidance."
            case .denied:
                return "Notifications are off. Turn them on in Settings to use hydration reminders."
            case .failed:
                return "I could not schedule that water reminder just now. Please try again."
            }
        case .pregnancySupplements:
            return pregnancySupplementAnswer(modelContext: modelContext)
        case .pregnancyNutrition:
            return pregnancyNutritionAnswer(modelContext: modelContext, query: transcript)
        case .healthSummary:
            return healthSummaryAnswer(modelContext: modelContext)
        case .unknown:
            return nil
        }
    }

    private func bloodPressureAnswer(modelContext: ModelContext, mode: QueryMode) -> String {
        let records = fetchHealthRecords(modelContext: modelContext, type: .bloodPressure)
        guard let latest = records.first else { return NoData.bp }
        let latestText = "\(Int(latest.value1)) over \(Int(latest.value2 ?? 0))"

        switch mode {
        case .latest:
            return "Based on your saved logs, your latest BP was \(latestText). \(ReferenceRange.bp(systolic: latest.value1, diastolic: latest.value2)) This is informational only. Please follow your doctor's advice."
        case .average:
            guard let average = averageBP(records.filter { $0.measuredAt >= Date.daysAgo(7) }) else {
                return "Based on your saved logs, your latest BP was \(latestText). I need more BP readings to calculate an average."
            }
            return "Based on your saved logs, your 7-day BP average is about \(average). This is informational only."
        case .comparison:
            let sevenDays = records.filter { $0.measuredAt >= Date.daysAgo(7) }
            let previous = records.filter { $0.measuredAt < Date.daysAgo(7) && $0.measuredAt >= Date.daysAgo(14) }
            return "Based on your saved logs, \(bpComparison(current: sevenDays, previous: previous)) This is informational only."
        }
    }

    private func bpRangeAnswer(systolic: Double?, diastolic: Double?, modelContext: ModelContext) -> String {
        if let systolic, let diastolic {
            return "Based on common reference ranges, \(Int(systolic)) over \(Int(diastolic)) \(ReferenceRange.bp(systolic: systolic, diastolic: diastolic).lowercased()) This is informational only. Please follow your doctor's advice."
        }
        return bloodPressureAnswer(modelContext: modelContext, mode: .latest)
    }

    private func sugarAnswer(testType: SugarTestType?, modelContext: ModelContext, mode: QueryMode) -> String {
        var records = fetchHealthRecords(modelContext: modelContext, type: .bloodSugar)
        if let testType {
            records = records.filter { $0.sugarTestType == testType }
        }
        guard let latest = records.first else { return NoData.sugar }
        let context = (testType ?? latest.sugarTestType)?.title.lowercased() ?? "sugar"

        switch mode {
        case .latest:
            return "Based on your saved logs, your latest \(context) reading was \(Int(latest.value1)) \(latest.unit). \(ReferenceRange.sugar(value: latest.value1, testType: latest.sugarTestType)) This is informational only."
        case .average:
            guard let average = averageValue(records.filter { $0.measuredAt >= Date.daysAgo(7) }) else {
                return "Based on your saved logs, your latest sugar was \(Int(latest.value1)) \(latest.unit). I need more sugar readings to calculate an average."
            }
            return "Based on your saved logs, your 7-day sugar average is about \(Int(average)) \(latest.unit). This is informational only."
        case .comparison:
            let sevenDays = records.filter { $0.measuredAt >= Date.daysAgo(7) }
            let previous = records.filter { $0.measuredAt < Date.daysAgo(7) && $0.measuredAt >= Date.daysAgo(14) }
            return "Based on your saved logs, \(valueComparison(label: "sugar", current: sevenDays, previous: previous)) This is informational only."
        }
    }

    private func sugarRangeAnswer(value: Double?, testType: SugarTestType?, modelContext: ModelContext) -> String {
        if let value {
            let context = testType?.title.lowercased() ?? "sugar"
            return "Based on common \(context) reference ranges, \(Int(value)) \(ReferenceRange.sugar(value: value, testType: testType).lowercased()) This is informational only. Please follow your doctor's advice."
        }
        return sugarAnswer(testType: testType, modelContext: modelContext, mode: .latest)
    }

    private func medicinePendingAnswer(modelContext: ModelContext) -> String {
        let medicines = fetch(modelContext, descriptor: FetchDescriptor<Medicine>(sortBy: [SortDescriptor(\.name)])).filter(\.isActive)
        guard !medicines.isEmpty else { return NoData.medicine }
        let names = medicines.prefix(3).map(\.name).joined(separator: ", ")
        return "Based on your saved list, pending medicines include \(names). Please check your reminder time before taking anything."
    }

    private func medicineNextAnswer(modelContext: ModelContext) -> String {
        let medicines = fetch(modelContext, descriptor: FetchDescriptor<Medicine>(sortBy: [SortDescriptor(\.name)])).filter(\.isActive)
        let next = medicines.flatMap { medicine in medicine.times.map { (medicine, $0) } }.sorted { $0.1 < $1.1 }.first
        guard let next else { return NoData.medicine }
        return "Based on your saved list, your next medicine time I found is \(next.0.name) at \(next.1.formatted(date: .omitted, time: .shortened)). Please check your schedule before taking anything."
    }

    private func medicineTakenAnswer(modelContext: ModelContext) -> String {
        let logs = fetch(modelContext, descriptor: FetchDescriptor<MedicineLog>(sortBy: [SortDescriptor(\.scheduledTime, order: .reverse)]))
        if let taken = logs.first(where: { $0.status == .taken && Calendar.current.isDateInToday($0.scheduledTime) }) {
            let name = taken.medicine?.name ?? "medicine"
            let time = (taken.takenTime ?? taken.scheduledTime).formatted(date: .omitted, time: .shortened)
            return "Based on your saved logs, \(name) was marked taken today at \(time). Please check your medicine list before taking anything."
        }
        return "Based on your saved logs, I do not see a medicine marked taken today yet. Please check your schedule before taking anything."
    }

    private func periodAnswer(modelContext: ModelContext, mode: PeriodMode) -> String {
        let periods = fetch(modelContext, descriptor: FetchDescriptor<PeriodRecord>(sortBy: [SortDescriptor(\.startDate, order: .reverse)]))
        let cycles = fetch(modelContext, descriptor: FetchDescriptor<PeriodCycle>(sortBy: [SortDescriptor(\.startDate, order: .reverse)]))
        let latestStart = periods.first?.startDate ?? cycles.first?.startDate
        guard let latestStart else { return NoData.period }
        let daysAgo = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: latestStart), to: Calendar.current.startOfDay(for: .now)).day ?? 0

        switch mode {
        case .last:
            return "Based on your saved logs, your last period started \(daysAgo) day\(daysAgo == 1 ? "" : "s") ago. This is informational only."
        case .next:
            let next = Calendar.current.date(byAdding: .day, value: estimatedCycleLength(periods: periods, cycles: cycles), to: latestStart)
            let text = next?.formatted(date: .abbreviated, time: .omitted) ?? "not enough data yet"
            return "Based on your saved logs, your next period estimate is \(text). This is only an estimate and not medical advice."
        case .cycle:
            return "Based on your saved logs, your estimated cycle length is about \(estimatedCycleLength(periods: periods, cycles: cycles)) days. This is only an estimate."
        }
    }

    private func doctorAnswer(modelContext: ModelContext) -> String {
        let appointments = fetch(modelContext, descriptor: FetchDescriptor<DoctorAppointment>(sortBy: [SortDescriptor(\.appointmentDate)]))
        if let upcoming = appointments.first(where: { $0.appointmentDate >= .now }) {
            let doctor = upcoming.doctorName.isEmpty ? "your doctor" : upcoming.doctorName
            return "Your next saved doctor visit is with \(doctor) on \(upcoming.appointmentDate.formatted(date: .abbreviated, time: .shortened))."
        }
        return NoData.doctor
    }

    func answerPregnancyQuery(_ query: String, context: ModelContext) -> String {
        let profiles = fetch(context, descriptor: FetchDescriptor<PregnancyProfile>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
        guard let profile = profiles.first(where: \.isActive) else {
            return "I don't have any pregnancy information saved yet. You can set up your pregnancy journey by saying Open pregnancy and I'll take you there."
        }
        let week = max(1, min(42, profile.currentWeek))
        let info = PregnancyWeekGuide.info(for: week)
        let days = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: profile.dueDate)).day ?? 0)
        return "You are in week \(week) of your pregnancy. Your baby is about the size of a \(info.fruitComparison) this week. \(info.babyDevelopment) Your due date is \(profile.dueDate.formatted(date: .abbreviated, time: .omitted)), which is \(days) days away. This is informational only — please follow your doctor's guidance throughout your pregnancy."
    }

    private func pregnancySupplementAnswer(modelContext: ModelContext) -> String {
        let profiles = fetch(modelContext, descriptor: FetchDescriptor<PregnancyProfile>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
        guard let profile = profiles.first(where: \.isActive) else {
            return "I don't have pregnancy information saved yet. Say Open pregnancy to set up your journey."
        }
        return PregnancySupplementService().suggestionResponse(for: max(1, min(42, profile.currentWeek)))
    }

    private func pregnancyNutritionAnswer(modelContext: ModelContext, query: String) -> String {
        let profiles = fetch(modelContext, descriptor: FetchDescriptor<PregnancyProfile>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
        guard let profile = profiles.first(where: \.isActive) else {
            return "I don't have pregnancy information saved yet. Say Open pregnancy to set up your journey."
        }
        return PregnancyNutritionGuide().getSuggestion(for: max(1, min(42, profile.currentWeek)), query: query)
    }

    private func healthSummaryAnswer(modelContext: ModelContext) -> String {
        let bp = fetchHealthRecords(modelContext: modelContext, type: .bloodPressure).first
        let sugar = fetchHealthRecords(modelContext: modelContext, type: .bloodSugar).first
        let medicines = fetch(modelContext, descriptor: FetchDescriptor<Medicine>()).filter(\.isActive)
        var parts: [String] = []
        if let bp { parts.append("latest BP was \(Int(bp.value1)) over \(Int(bp.value2 ?? 0))") }
        if let sugar { parts.append("latest sugar was \(Int(sugar.value1)) \(sugar.unit)") }
        if !medicines.isEmpty { parts.append("\(medicines.count) active medicine\(medicines.count == 1 ? "" : "s") saved") }
        guard !parts.isEmpty else { return NoData.general }
        return "Based on your saved logs, \(parts.joined(separator: ", ")). This is informational only. Please consult your doctor for medical advice."
    }

    private func fetchHealthRecords(modelContext: ModelContext, type: HealthRecordType) -> [HealthRecord] {
        fetch(modelContext, descriptor: FetchDescriptor<HealthRecord>(sortBy: [SortDescriptor(\.measuredAt, order: .reverse)])).filter { $0.type == type }
    }

    private func fetch<T: PersistentModel>(_ modelContext: ModelContext, descriptor: FetchDescriptor<T>) -> [T] {
        (try? modelContext.fetch(descriptor)) ?? []
    }

    private func averageBP(_ records: [HealthRecord]) -> String? {
        guard !records.isEmpty else { return nil }
        let systolic = records.map(\.value1).reduce(0, +) / Double(records.count)
        let diastolicValues = records.compactMap(\.value2)
        guard !diastolicValues.isEmpty else { return nil }
        let diastolic = diastolicValues.reduce(0, +) / Double(diastolicValues.count)
        return "\(Int(systolic.rounded())) over \(Int(diastolic.rounded()))"
    }

    private func averageValue(_ records: [HealthRecord]) -> Double? {
        guard !records.isEmpty else { return nil }
        return records.map(\.value1).reduce(0, +) / Double(records.count)
    }

    private func bpComparison(current: [HealthRecord], previous: [HealthRecord]) -> String {
        guard let currentAverage = averageValue(current), let previousAverage = averageValue(previous) else {
            return "I need more previous BP readings for a trend comparison."
        }
        return trendText(label: "BP", current: currentAverage, previous: previousAverage)
    }

    private func valueComparison(label: String, current: [HealthRecord], previous: [HealthRecord]) -> String {
        guard let currentAverage = averageValue(current), let previousAverage = averageValue(previous) else {
            return "I need more previous \(label) readings for a trend comparison."
        }
        return trendText(label: label, current: currentAverage, previous: previousAverage)
    }

    private func trendText(label: String, current: Double, previous: Double) -> String {
        let difference = current - previous
        if abs(difference) < 3 {
            return "\(label.capitalized) looks stable compared to your previous saved readings."
        }
        return "\(label.capitalized) is \(difference > 0 ? "higher" : "lower") than your previous saved readings."
    }

    private func estimatedCycleLength(periods: [PeriodRecord], cycles: [PeriodCycle]) -> Int {
        let dates = (periods.map(\.startDate) + cycles.map(\.startDate)).sorted(by: >)
        guard dates.count >= 2 else { return 28 }
        let gaps = zip(dates, dates.dropFirst()).compactMap { Calendar.current.dateComponents([.day], from: $1, to: $0).day }.filter { $0 > 10 && $0 < 60 }
        guard !gaps.isEmpty else { return 28 }
        return max(1, gaps.reduce(0, +) / gaps.count)
    }
}

private enum QueryMode {
    case latest
    case average
    case comparison
}

private enum PeriodMode {
    case last
    case next
    case cycle
}

private enum NoData {
    static let bp = "\(ResponseVariationPool().noDataFound()) You can say, 'My BP is 120 over 80' and I will save it."
    static let sugar = "\(ResponseVariationPool().noDataFound()) You can say, 'My sugar is 145 after food' and I will save it."
    static let medicine = "\(ResponseVariationPool().noDataFound()) You can add medicines first, then I can help track them."
    static let period = "\(ResponseVariationPool().noDataFound()) You can say, 'My period started today' to save one."
    static let doctor = "\(ResponseVariationPool().noDataFound()) You can add one in Doctor Visit."
    static let general = ResponseVariationPool().noDataFound()
}

private enum ReferenceRange {
    static func bp(systolic: Double, diastolic: Double?) -> String {
        guard let diastolic else { return "BP needs both numbers for a reference range. This is informational only." }
        if systolic < 90 || diastolic < 60 {
            return "appears lower than common reference ranges."
        }
        if systolic > 140 || diastolic > 90 {
            return "appears elevated compared with common reference ranges."
        }
        if systolic >= 90 && systolic <= 120 && diastolic >= 60 && diastolic <= 80 {
            return "is within a common reference range for many adults."
        }
        return "depends on context and your doctor's guidance."
    }

    static func sugar(value: Double, testType: SugarTestType?) -> String {
        switch testType {
        case .fasting:
            if value >= 70 && value <= 100 { return "is within a common fasting reference range." }
            if value > 126 { return "appears elevated compared with common fasting reference ranges." }
            return "depends on timing and context."
        case .afterMeal:
            if value < 140 { return "is within a common after-food reference range." }
            if value > 200 { return "appears elevated compared with common after-food reference ranges." }
            return "is slightly above the common after-food reference range."
        default:
            return "depends on timing and context."
        }
    }
}

private extension Date {
    static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }
}
