import Foundation
import SwiftData

struct DashboardInsightCardModel: Identifiable {
    enum Kind {
        case medicines
        case bloodPressure
        case sugar
        case period
        case pregnancy
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let summary: String
    let icon: String
}

struct DashboardUpcomingMedicineItem: Identifiable {
    let id = UUID()
    let medicineID: UUID
    let name: String
    let dosage: String
    let scheduledAt: Date
}

struct DashboardInsightEngine {
    private let calendar: Calendar
    private let relativeFormatter = RelativeDateTimeFormatter()

    init(calendar: Calendar = .current) {
        self.calendar = calendar
        relativeFormatter.unitsStyle = .full
    }

    func morningGreeting(name: String?) -> String {
        let trimmedName = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let hour = calendar.component(.hour, from: .now)
        let baseGreeting: String

        switch hour {
        case 5..<12:
            baseGreeting = "Good morning"
        case 12..<17:
            baseGreeting = "Good afternoon"
        case 17..<22:
            baseGreeting = "Good evening"
        default:
            baseGreeting = "Good night"
        }

        guard trimmedName.isEmpty == false else { return baseGreeting }
        return "\(baseGreeting), \(trimmedName)"
    }

    func medicinesSummary(context: ModelContext) -> String {
        let medicines = fetchActiveMedicines(context: context)
        let dosesToday = scheduledDoses(for: medicines, on: .now)
        let logs = fetchTodayMedicineLogs(context: context)
        let takenCount = logs.filter { $0.status == .taken }.count

        guard dosesToday.isEmpty == false else {
            return logs.isEmpty ? "Add medicines to build your routine." : "No medicines logged yet today"
        }

        if takenCount >= dosesToday.count {
            return "All medicines taken today"
        }

        if takenCount == 0 {
            return "No medicines logged yet today"
        }

        return "\(takenCount) of \(dosesToday.count) medicines taken today"
    }

    func bpSummary(context: ModelContext) -> String? {
        guard let record = latestHealthRecord(type: .bloodPressure, context: context) else { return nil }
        let relative = relativeFormatter.localizedString(for: record.measuredAt, relativeTo: .now)
        return "Last BP: \(Int(record.value1))/\(Int(record.value2 ?? 0)) - \(relative)"
    }

    func sugarSummary(context: ModelContext) -> String? {
        guard let record = latestHealthRecord(type: .bloodSugar, context: context) else { return nil }
        let relative = relativeFormatter.localizedString(for: record.measuredAt, relativeTo: .now)
        let prefix: String
        if let testType = record.sugarTestType?.title {
            prefix = "\(testType) sugar"
        } else {
            prefix = "Last sugar"
        }
        return "\(prefix): \(Int(record.value1)) \(record.unit) - \(relative)"
    }

    func periodSummary(context: ModelContext) -> String? {
        guard UserHealthProfile.showWomensHealthCard else { return nil }

        var cycleDescriptor = FetchDescriptor<PeriodCycle>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        cycleDescriptor.fetchLimit = 1
        let latestCycle = fetch(cycleDescriptor, context: context).first

        var symptomDescriptor = FetchDescriptor<WomensHealthDailyLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        symptomDescriptor.fetchLimit = 1
        let latestLog = fetch(symptomDescriptor, context: context).first

        if let latestCycle {
            let day = max((calendar.dateComponents([.day], from: calendar.startOfDay(for: latestCycle.startDate), to: calendar.startOfDay(for: .now)).day ?? 0) + 1, 1)
            if let latestLog, latestLog.symptoms.isEmpty == false {
                return "Cycle day \(day) - based on your logs, recent note: \(latestLog.symptoms.prefix(2).joined(separator: ", "))"
            }
            return "Cycle day \(day) - keep tracking to build your cycle view"
        }

        if let latestLog {
            return "Recent women's health log from \(latestLog.date.formatted(date: .abbreviated, time: .omitted))"
        }

        return "Add a period log to build your cycle view"
    }

    func pregnancySummary(context: ModelContext) -> String? {
        guard let profile = activePregnancyProfile(context: context) else { return nil }
        let weekInfo = PregnancyWeekGuide.info(for: profile.currentWeek)
        let daysUntilDue = max(calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: calendar.startOfDay(for: profile.dueDate)).day ?? 0, 0)
        return "Week \(profile.currentWeek) - your baby is about the size of a \(weekInfo.fruitComparison). \(daysUntilDue) days until your due date."
    }

    func upcomingMedicines(context: ModelContext) -> [DashboardUpcomingMedicineItem] {
        let medicines = fetchActiveMedicines(context: context)
        let logs = fetchTodayMedicineLogs(context: context)
        let now = Date()
        let windowEnd = calendar.date(byAdding: .hour, value: 2, to: now) ?? now

        return scheduledDoses(for: medicines, on: now)
            .filter { $0.scheduledAt >= now && $0.scheduledAt <= windowEnd }
            .filter { dose in
                matchingLog(for: dose.medicineID, scheduledAt: dose.scheduledAt, logs: logs)?.status != .taken
            }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .prefix(4)
            .map {
                DashboardUpcomingMedicineItem(
                    medicineID: $0.medicineID,
                    name: $0.name,
                    dosage: $0.dosage,
                    scheduledAt: $0.scheduledAt
                )
            }
    }

    func voiceSuggestion(profile: UserProfile?, context: ModelContext) -> String {
        let showsPregnancy = activePregnancyProfile(context: context) != nil
        let showsWomensHealth = UserHealthProfile.showWomensHealthCard
        let hasBP = latestHealthRecord(type: .bloodPressure, context: context) != nil
        let hasSugar = latestHealthRecord(type: .bloodSugar, context: context) != nil

        var suggestions = [
            "Try: 'What medicine is pending'",
            "Try: 'How is my BP this week'",
            "Try: 'How is my sugar today'"
        ]

        if showsPregnancy {
            suggestions.append("Try: 'How is baby doing'")
        }
        if showsWomensHealth {
            suggestions.append("Try: 'When is my next period'")
        }
        if hasBP == false {
            suggestions.append("Try: 'My BP is 120 over 80'")
        }
        if hasSugar == false {
            suggestions.append("Try: 'My sugar is 110 fasting'")
        }

        let nameSeed = Int((profile?.displayName ?? profile?.name ?? UserHealthProfile.userName).unicodeScalars.map(\.value).reduce(0, +))
        let daySeed = calendar.ordinality(of: .day, in: .year, for: .now) ?? 0
        let index = suggestions.isEmpty ? 0 : abs(nameSeed + daySeed) % suggestions.count
        return suggestions[index]
    }

    func activeUserProfile(context: ModelContext) -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return fetch(descriptor, context: context).first
    }

    private func activePregnancyProfile(context: ModelContext) -> PregnancyProfile? {
        let descriptor = FetchDescriptor<PregnancyProfile>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return fetch(descriptor, context: context).first
    }

    private func fetchActiveMedicines(context: ModelContext) -> [Medicine] {
        let descriptor = FetchDescriptor<Medicine>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.name)]
        )
        return fetch(descriptor, context: context)
    }

    private func fetchTodayMedicineLogs(context: ModelContext) -> [MedicineLog] {
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let descriptor = FetchDescriptor<MedicineLog>(
            predicate: #Predicate<MedicineLog> { log in
                log.scheduledTime >= start && log.scheduledTime < end
            },
            sortBy: [SortDescriptor(\.scheduledTime)]
        )
        return fetch(descriptor, context: context)
    }

    private func latestHealthRecord(type: HealthRecordType, context: ModelContext) -> HealthRecord? {
        var descriptor = FetchDescriptor<HealthRecord>(
            predicate: #Predicate<HealthRecord> { $0.typeRawValue == type.rawValue },
            sortBy: [SortDescriptor(\.measuredAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return fetch(descriptor, context: context).first
    }

    private func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>, context: ModelContext) -> [T] {
        do {
            return try context.fetch(descriptor)
        } catch {
            #if DEBUG
            print("[DashboardInsightEngine] Fetch failed for \(T.self): \(error)")
            #endif
            return []
        }
    }

    private func scheduledDoses(for medicines: [Medicine], on day: Date) -> [DashboardPendingMedicine] {
        let dayStart = calendar.startOfDay(for: day)
        return medicines
            .filter { isMedicineScheduled($0, on: dayStart) }
            .flatMap { medicine in
                medicine.times.map {
                    DashboardPendingMedicine(
                        medicineID: medicine.id,
                        name: medicine.name,
                        dosage: medicine.dosage,
                        scheduledAt: timeOnDay($0, day: dayStart)
                    )
                }
            }
    }

    private func isMedicineScheduled(_ medicine: Medicine, on day: Date) -> Bool {
        let dayStart = calendar.startOfDay(for: day)
        let startDay = calendar.startOfDay(for: medicine.startDate)
        if dayStart < startDay { return false }
        if let endDate = medicine.endDate, dayStart > calendar.startOfDay(for: endDate) { return false }

        switch medicine.frequencyType {
        case .daily:
            return true
        case .alternateDays:
            let days = calendar.dateComponents([.day], from: startDay, to: dayStart).day ?? 0
            return days >= 0 && days.isMultiple(of: 2)
        case .weekly:
            return calendar.component(.weekday, from: dayStart) == calendar.component(.weekday, from: startDay)
        case .custom:
            return true
        }
    }

    private func timeOnDay(_ time: Date, day: Date) -> Date {
        let components = calendar.dateComponents([.hour, .minute, .second], from: time)
        return calendar.date(
            bySettingHour: components.hour ?? 9,
            minute: components.minute ?? 0,
            second: components.second ?? 0,
            of: calendar.startOfDay(for: day)
        ) ?? day
    }

    private func matchingLog(for medicineID: UUID, scheduledAt: Date, logs: [MedicineLog]) -> MedicineLog? {
        logs.first { log in
            guard log.medicine?.id == medicineID else { return false }
            return calendar.isDate(log.scheduledTime, equalTo: scheduledAt, toGranularity: .minute)
        }
    }
}
