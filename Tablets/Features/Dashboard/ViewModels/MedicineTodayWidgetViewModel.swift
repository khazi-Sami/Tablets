import Foundation
import Observation
import SwiftData

enum MedicineDoseStatus: String {
    case taken
    case pending
    case overdue
    case skipped
    case snoozed
    case notLogged
}

struct TodayMedicineDose: Identifiable {
    let id: String
    let medicineId: UUID
    let medicineName: String
    let dosage: String
    let medicineType: MedicineType
    let scheduledTime: Date
    let status: MedicineDoseStatus
    let actualTakenTime: Date?
    let stockCount: Int?
    let isLowStock: Bool
    let minutesUntilDue: Int
    let minutesOverdue: Int
    let adaptiveInsight: String?
}

struct WeeklyMedicineAdherence {
    let takenCount: Int
    let totalCount: Int
    let missedCount: Int
    let percent: Double
    let bestDayName: String?

    static let empty = WeeklyMedicineAdherence(
        takenCount: 0,
        totalCount: 0,
        missedCount: 0,
        percent: 0,
        bestDayName: nil
    )
}

struct LowStockMedicineSummary: Identifiable {
    let id: UUID
    let name: String
    let stockCount: Int
}

@MainActor
@Observable
final class MedicineTodayWidgetViewModel {
    private(set) var activeMedicineCount = 0
    private(set) var todayDoses: [TodayMedicineDose] = []
    private(set) var weeklyAdherence = WeeklyMedicineAdherence.empty
    private(set) var lowStockMedicines: [LowStockMedicineSummary] = []
    private(set) var nextPendingDose: TodayMedicineDose?
    private(set) var overdueCount = 0
    private(set) var missedSkippedTodayCount = 0
    private(set) var isLoading = false
    private(set) var isSavingDoseID: String?
    private(set) var errorMessage: String?
    private(set) var lastRefreshAt: Date?

    private var refreshTask: Task<Void, Never>?
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    var hasActiveMedicines: Bool {
        activeMedicineCount > 0
    }

    var hasScheduledDosesToday: Bool {
        !todayDoses.isEmpty
    }

    var allDosesTakenToday: Bool {
        !todayDoses.isEmpty && todayDoses.allSatisfy { $0.status == .taken || $0.status == .skipped }
    }

    func refresh(modelContext: ModelContext) async {
        isLoading = true
        defer {
            isLoading = false
            lastRefreshAt = .now
        }

        let medicines = fetchActiveMedicines(modelContext: modelContext)
        activeMedicineCount = medicines.count
        lowStockMedicines = medicines
            .filter { $0.stockCount <= $0.lowStockAlertCount }
            .sorted { $0.stockCount == $1.stockCount ? $0.name < $1.name : $0.stockCount < $1.stockCount }
            .map { LowStockMedicineSummary(id: $0.id, name: $0.name, stockCount: $0.stockCount) }

        let todayLogs = fetchLogs(
            from: calendar.startOfDay(for: .now),
            to: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? .now,
            modelContext: modelContext
        )
        let adaptivePatterns = await adaptivePatterns(for: medicines, modelContext: modelContext)

        todayDoses = buildTodayDoses(medicines: medicines, logs: todayLogs, adaptivePatterns: adaptivePatterns)
        nextPendingDose = todayDoses.first { $0.status == .pending || $0.status == .overdue }
        overdueCount = todayDoses.filter { $0.status == .overdue }.count
        missedSkippedTodayCount = todayDoses.filter { $0.status == .skipped || $0.status == .overdue }.count
        weeklyAdherence = buildWeeklyAdherence(medicines: medicines, modelContext: modelContext)
    }

    func startAutoRefresh(modelContext: ModelContext) {
        stopAutoRefresh()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                guard !Task.isCancelled else { return }
                await self?.refresh(modelContext: modelContext)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func markTaken(_ dose: TodayMedicineDose, modelContext: ModelContext) async {
        guard isSavingDoseID == nil else { return }
        isSavingDoseID = dose.id
        errorMessage = nil
        defer { isSavingDoseID = nil }

        guard let medicine = fetchMedicine(id: dose.medicineId, modelContext: modelContext) else {
            errorMessage = "Could not find that medicine. Please try again."
            return
        }

        let log = MedicineLog(
            medicine: medicine,
            scheduledTime: dose.scheduledTime,
            takenTime: .now,
            status: .taken
        )
        modelContext.insert(log)

        do {
            try modelContext.save()
            NotificationCenter.default.post(name: .healthDataDidUpdate, object: nil)
            await refresh(modelContext: modelContext)
        } catch {
            modelContext.delete(log)
            errorMessage = "Could not save that dose. Please try again."
            print("[MedicineTodayWidgetViewModel] Could not mark dose taken: \(error)")
        }
    }

    private func fetchActiveMedicines(modelContext: ModelContext) -> [Medicine] {
        let descriptor = FetchDescriptor<Medicine>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.name)]
        )
        return fetch(descriptor, modelContext: modelContext)
    }

    private func fetchMedicine(id: UUID, modelContext: ModelContext) -> Medicine? {
        var descriptor = FetchDescriptor<Medicine>(
            predicate: #Predicate<Medicine> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return fetch(descriptor, modelContext: modelContext).first
    }

    private func fetchLogs(from start: Date, to end: Date, modelContext: ModelContext) -> [MedicineLog] {
        let descriptor = FetchDescriptor<MedicineLog>(
            predicate: #Predicate<MedicineLog> { log in
                log.scheduledTime >= start && log.scheduledTime < end
            },
            sortBy: [SortDescriptor(\.scheduledTime)]
        )
        return fetch(descriptor, modelContext: modelContext)
    }

    private func fetch<T>(_ descriptor: FetchDescriptor<T>, modelContext: ModelContext) -> [T] where T: PersistentModel {
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("[MedicineTodayWidgetViewModel] Fetch failed for \(T.self): \(error)")
            return []
        }
    }

    private func buildTodayDoses(
        medicines: [Medicine],
        logs: [MedicineLog],
        adaptivePatterns: [UUID: [MedicineTakePattern]]
    ) -> [TodayMedicineDose] {
        let today = calendar.startOfDay(for: .now)
        return medicines
            .filter { isMedicineScheduled($0, on: today) }
            .flatMap { medicine in
                medicine.times.map { time in
                    let scheduledTime = timeOnDay(time, day: today)
                    let matchingLog = bestMatchingLog(for: medicine, scheduledTime: scheduledTime, logs: logs)
                    return buildDose(
                        medicine: medicine,
                        scheduledTime: scheduledTime,
                        log: matchingLog,
                        pattern: adaptivePattern(for: scheduledTime, patterns: adaptivePatterns[medicine.id] ?? [])
                    )
                }
            }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    private func buildDose(
        medicine: Medicine,
        scheduledTime: Date,
        log: MedicineLog?,
        pattern: MedicineTakePattern?
    ) -> TodayMedicineDose {
        let status = doseStatus(scheduledTime: scheduledTime, log: log)
        let minutesUntil = max(0, calendar.dateComponents([.minute], from: .now, to: scheduledTime).minute ?? 0)
        let minutesLate = max(0, calendar.dateComponents([.minute], from: scheduledTime, to: .now).minute ?? 0)
        let id = "\(medicine.id.uuidString)-\(Int(scheduledTime.timeIntervalSince1970))"

        return TodayMedicineDose(
            id: id,
            medicineId: medicine.id,
            medicineName: medicine.name,
            dosage: medicine.dosage,
            medicineType: medicine.medicineType,
            scheduledTime: scheduledTime,
            status: status,
            actualTakenTime: log?.takenTime,
            stockCount: medicine.stockCount,
            isLowStock: medicine.stockCount <= medicine.lowStockAlertCount,
            minutesUntilDue: minutesUntil,
            minutesOverdue: minutesLate,
            adaptiveInsight: adaptiveInsight(for: pattern, scheduledTime: scheduledTime)
        )
    }

    private func adaptivePatterns(for medicines: [Medicine], modelContext: ModelContext) async -> [UUID: [MedicineTakePattern]] {
        let engine = AdaptiveReminderEngine(modelContext: modelContext)
        var result: [UUID: [MedicineTakePattern]] = [:]
        for medicine in medicines {
            result[medicine.id] = await engine.analyzePatterns(for: medicine)
        }
        return result
    }

    private func adaptivePattern(for scheduledTime: Date, patterns: [MedicineTakePattern]) -> MedicineTakePattern? {
        let key = AdaptiveReminderTimeKey.key(from: scheduledTime, calendar: calendar)
        return patterns.first {
            $0.sampleCount >= 5 &&
            AdaptiveReminderPreferenceStore().isEnabled(medicineID: $0.medicineID, scheduledTime: $0.scheduledTime) &&
            AdaptiveReminderTimeKey.key(from: $0.scheduledTime) == key
        }
    }

    private func adaptiveInsight(for pattern: MedicineTakePattern?, scheduledTime: Date) -> String? {
        guard let pattern else { return nil }
        let minutes = abs(pattern.averageActualMinuteOffset)
        if minutes == 0 {
            return "You usually take this close to the reminder time."
        }
        guard let learnedTime = calendar.date(byAdding: .minute, value: pattern.averageActualMinuteOffset, to: scheduledTime) else {
            return nil
        }
        return "Your body clock says: \(learnedTime.formatted(date: .omitted, time: .shortened))."
    }

    private func doseStatus(scheduledTime: Date, log: MedicineLog?) -> MedicineDoseStatus {
        guard let log else {
            return scheduledTime < .now ? .overdue : .pending
        }

        switch log.status {
        case .taken:
            return .taken
        case .skipped:
            return .skipped
        case .snoozed:
            return .snoozed
        case .missed:
            return scheduledTime < .now ? .overdue : .notLogged
        }
    }

    private func bestMatchingLog(for medicine: Medicine, scheduledTime: Date, logs: [MedicineLog]) -> MedicineLog? {
        let matches = logs.filter { log in
            guard log.medicine?.id == medicine.id else { return false }
            return calendar.isDate(log.scheduledTime, equalTo: scheduledTime, toGranularity: .minute)
        }

        if let taken = matches.first(where: { $0.status == .taken }) { return taken }
        if let snoozed = matches.first(where: { $0.status == .snoozed }) { return snoozed }
        if let skipped = matches.first(where: { $0.status == .skipped }) { return skipped }
        return matches.first
    }

    private func buildWeeklyAdherence(medicines: [Medicine], modelContext: ModelContext) -> WeeklyMedicineAdherence {
        let today = calendar.startOfDay(for: .now)
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
            return .empty
        }

        let logs = fetchLogs(from: weekStart, to: tomorrow, modelContext: modelContext)
        var takenCount = 0
        var totalCount = 0
        var missedCount = 0
        var bestDayName: String?
        var bestDayScore = -1.0

        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            let dayDoses = scheduledDoseKeys(medicines: medicines, day: day)
            guard !dayDoses.isEmpty else { continue }

            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let dayLogs = logs.filter { $0.scheduledTime >= dayStart && $0.scheduledTime < dayEnd }
            let dayTaken = dayDoses.filter { key in
                dayLogs.contains { log in
                    log.status == .taken &&
                    log.medicine?.id == key.medicineId &&
                    calendar.isDate(log.scheduledTime, equalTo: key.scheduledTime, toGranularity: .minute)
                }
            }.count
            let dayMissed = dayDoses.filter { key in
                let matched = dayLogs.first { log in
                    log.medicine?.id == key.medicineId &&
                    calendar.isDate(log.scheduledTime, equalTo: key.scheduledTime, toGranularity: .minute)
                }
                if matched?.status == .skipped || matched?.status == .missed { return true }
                return key.scheduledTime < .now && matched == nil
            }.count

            totalCount += dayDoses.count
            takenCount += dayTaken
            missedCount += dayMissed

            let score = Double(dayTaken) / Double(dayDoses.count)
            if score > bestDayScore {
                bestDayScore = score
                bestDayName = weekdayName(for: day)
            }
        }

        let percent = totalCount > 0 ? Double(takenCount) / Double(totalCount) : 0
        return WeeklyMedicineAdherence(
            takenCount: takenCount,
            totalCount: totalCount,
            missedCount: missedCount,
            percent: percent,
            bestDayName: bestDayName
        )
    }

    private func scheduledDoseKeys(medicines: [Medicine], day: Date) -> [(medicineId: UUID, scheduledTime: Date)] {
        medicines
            .filter { isMedicineScheduled($0, on: day) }
            .flatMap { medicine in
                medicine.times.map { (medicine.id, timeOnDay($0, day: day)) }
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
            // TODO: Custom frequency needs recurrence metadata beyond MedicineFrequencyType.
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

    private func weekdayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}
