import Foundation
import Observation
import SwiftData

struct DailyAdherencePoint: Identifiable {
    let id = UUID()
    let date: Date
    let adherence: Double
}

struct VoiceChip: Identifiable {
    let id = UUID()
    let label: String
    let phrase: String
}

struct DashboardMedicineSummary: Identifiable {
    let id: UUID
    let name: String
    let stockCount: Int
}

struct DashboardPendingMedicine {
    let medicineID: UUID
    let name: String
    let dosage: String
    let scheduledAt: Date
}

@Observable
@MainActor
final class DashboardDataProvider {
    private let modelContext: ModelContext
    private let calendar: Calendar

    private(set) var todayMedicineLogs: [MedicineLog] = []
    private(set) var lowStockMedicines: [DashboardMedicineSummary] = []
    private(set) var latestBP: HealthRecord?
    private(set) var latestSugar: HealthRecord?
    private(set) var latestHeartRate: HealthRecord?
    private(set) var latestOxygen: HealthRecord?
    private(set) var latestWeight: HealthRecord?
    private(set) var latestTemperature: HealthRecord?
    private(set) var bpLast7Days: [HealthRecord] = []
    private(set) var sugarLast7Days: [HealthRecord] = []
    private(set) var weightLast7Days: [HealthRecord] = []
    private(set) var medicineAdherenceLast7Days: [DailyAdherencePoint] = []
    private(set) var latestPeriodCycle: PeriodCycle?
    private(set) var estimatedNextPeriodDate: Date?
    private(set) var recentPeriodSymptoms: [String] = []
    private(set) var activeFamilyMembers: [FamilyMember] = []
    private(set) var pendingFamilyMedicineLogs: [MedicineLog] = []
    private(set) var pendingFamilyMedicineLogsUnavailable = false
    private(set) var nextDoctorAppointment: DoctorAppointment?
    private(set) var activeMedicineCount = 0
    private(set) var nextPendingMedicine: DashboardPendingMedicine?
    private(set) var lastRefreshedAt: Date?
    private(set) var todaySnapshot: HKDailySnapshot?
    private(set) var wellnessInsights: [WellnessInsight] = []
    private(set) var readinessSignal: ReadinessSignal?
    private(set) var isRecoveryDay = false
    private(set) var healthKitLastSyncAt: Date?

    private let healthKitService = HealthKitService()

    init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.modelContext = modelContext
        self.calendar = calendar
    }

    var takenCountToday: Int {
        todayMedicineLogs.filter { $0.status == .taken }.count
    }

    var pendingCountToday: Int {
        todayMedicineLogs.filter { $0.status != .taken && $0.status != .skipped }.count
    }

    var missedCountToday: Int {
        todayMedicineLogs.filter { $0.status == .missed }.count
    }

    var medicineProgressToday: Double {
        guard !todayMedicineLogs.isEmpty else { return 0 }
        return Double(takenCountToday) / Double(todayMedicineLogs.count)
    }

    var currentCycleDay: Int? {
        guard let startDate = latestPeriodCycle?.startDate else { return nil }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: .now)).day ?? 0
        return max(days + 1, 1)
    }

    var hasFamilyMembers: Bool {
        !activeFamilyMembers.isEmpty
    }

    var voiceChips: [VoiceChip] {
        var chips: [VoiceChip] = []
        if latestBP == nil { chips.append(VoiceChip(label: "Log BP", phrase: "Record my BP")) }
        if latestSugar == nil { chips.append(VoiceChip(label: "Log sugar", phrase: "My sugar is")) }
        if pendingCountToday > 0 { chips.append(VoiceChip(label: "Pending medicines", phrase: "What medicine is pending?")) }
        if nextDoctorAppointment != nil { chips.append(VoiceChip(label: "Doctor visit", phrase: "Open doctor visit")) }
        chips.append(VoiceChip(label: "Health summary", phrase: "How is my health today?"))
        return Array(chips.prefix(4))
    }

    func refresh() async {
        DebugStartupLogger.log("DashboardDataProvider.refresh started")
        let activeMedicines = fetchActiveMedicines()
        activeMedicineCount = activeMedicines.count
        todayMedicineLogs = fetchTodayMedicineLogs()
        lowStockMedicines = lowStockSummaries(from: activeMedicines)
        nextPendingMedicine = buildNextPendingMedicine(medicines: activeMedicines, logs: todayMedicineLogs)
        latestBP = fetchLatestHealthRecord(type: .bloodPressure)
        latestSugar = fetchLatestHealthRecord(type: .bloodSugar)
        latestHeartRate = fetchLatestHealthRecord(type: .heartRate)
        latestOxygen = fetchLatestHealthRecord(type: .oxygen)
        latestWeight = fetchLatestHealthRecord(type: .weight)
        latestTemperature = fetchLatestHealthRecord(type: .temperature)
        bpLast7Days = fetchHealthRecords(type: .bloodPressure, days: 7)
        sugarLast7Days = fetchHealthRecords(type: .bloodSugar, days: 7)
        weightLast7Days = fetchHealthRecords(type: .weight, days: 7)
        medicineAdherenceLast7Days = fetchAdherencePoints()
        latestPeriodCycle = fetchLatestPeriodCycle()
        estimatedNextPeriodDate = fetchEstimatedNextPeriodDate()
        recentPeriodSymptoms = fetchRecentPeriodSymptoms()
        activeFamilyMembers = fetchActiveFamilyMembers()
        pendingFamilyMedicineLogs = fetchPendingFamilyMedicineLogs()
        nextDoctorAppointment = fetchNextDoctorAppointment()
        await refreshHealthKitDataIfNeeded()
        lastRefreshedAt = .now
        DebugStartupLogger.log("DashboardDataProvider.refresh finished activeMedicines=\(activeMedicineCount) todayLogs=\(todayMedicineLogs.count) healthRecords bp=\(latestBP != nil) sugar=\(latestSugar != nil) healthKitInsights=\(wellnessInsights.count)")
    }

    private func fetchActiveMedicines() -> [Medicine] {
        let descriptor = FetchDescriptor<Medicine>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.name)]
        )
        return fetch(descriptor, fallback: [])
    }

    private func fetchTodayMedicineLogs() -> [MedicineLog] {
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? .now
        let descriptor = FetchDescriptor<MedicineLog>(
            predicate: #Predicate<MedicineLog> { log in
                log.scheduledTime >= start && log.scheduledTime < end
            },
            sortBy: [SortDescriptor(\.scheduledTime)]
        )
        return fetch(descriptor, fallback: [])
    }

    private func lowStockSummaries(from medicines: [Medicine]) -> [DashboardMedicineSummary] {
        medicines
            .filter { $0.stockCount <= $0.lowStockAlertCount }
            .sorted { $0.stockCount == $1.stockCount ? $0.name < $1.name : $0.stockCount < $1.stockCount }
            .map { DashboardMedicineSummary(id: $0.id, name: $0.name, stockCount: $0.stockCount) }
    }

    private func buildNextPendingMedicine(medicines: [Medicine], logs: [MedicineLog]) -> DashboardPendingMedicine? {
        let today = calendar.startOfDay(for: .now)
        return medicines
            .filter { isMedicineScheduled($0, on: today) }
            .flatMap { medicine in
                medicine.times.map { time -> DashboardPendingMedicine? in
                    let scheduledAt = timeOnDay(time, day: today)
                    guard scheduledAt > .now else { return nil }
                    let matchedLog = matchingLog(for: medicine.id, scheduledAt: scheduledAt, logs: logs)
                    if matchedLog?.status == .taken || matchedLog?.status == .skipped {
                        return nil
                    }
                    return DashboardPendingMedicine(
                        medicineID: medicine.id,
                        name: medicine.name,
                        dosage: medicine.dosage,
                        scheduledAt: scheduledAt
                    )
                }
            }
            .compactMap { $0 }
            .sorted { $0.scheduledAt < $1.scheduledAt }
            .first
    }

    private func matchingLog(for medicineID: UUID, scheduledAt: Date, logs: [MedicineLog]) -> MedicineLog? {
        logs.first { log in
            calendar.isDate(log.scheduledTime, equalTo: scheduledAt, toGranularity: .minute)
        }
    }

    private func fetchLatestHealthRecord(type: HealthRecordType) -> HealthRecord? {
        var descriptor = FetchDescriptor<HealthRecord>(
            predicate: #Predicate<HealthRecord> { $0.typeRawValue == type.rawValue },
            sortBy: [SortDescriptor(\.measuredAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return fetch(descriptor, fallback: []).first
    }

    private func fetchHealthRecords(type: HealthRecordType, days: Int) -> [HealthRecord] {
        let start = calendar.date(byAdding: .day, value: -days, to: .now) ?? .now
        let descriptor = FetchDescriptor<HealthRecord>(
            predicate: #Predicate<HealthRecord> { record in
                record.typeRawValue == type.rawValue && record.measuredAt >= start
            },
            sortBy: [SortDescriptor(\.measuredAt)]
        )
        return fetch(descriptor, fallback: [])
    }

    private func fetchAdherencePoints() -> [DailyAdherencePoint] {
        (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -6 + offset, to: .now) else { return nil }
            let start = calendar.startOfDay(for: day)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? day
            let takenStatus = MedicineLogStatus.taken.rawValue
            let descriptor = FetchDescriptor<MedicineLog>(
                predicate: #Predicate<MedicineLog> { log in
                    log.scheduledTime >= start && log.scheduledTime < end
                }
            )
            let logs = fetch(descriptor, fallback: [])
            let takenCount = logs.filter { $0.statusRawValue == takenStatus }.count
            let adherence = logs.isEmpty ? 0 : Double(takenCount) / Double(logs.count)
            return DailyAdherencePoint(date: start, adherence: adherence)
        }
    }

    private func fetchLatestPeriodCycle() -> PeriodCycle? {
        var descriptor = FetchDescriptor<PeriodCycle>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        descriptor.fetchLimit = 1
        return fetch(descriptor, fallback: []).first
    }

    private func fetchEstimatedNextPeriodDate() -> Date? {
        guard let startDate = latestPeriodCycle?.startDate ?? fetchLatestPeriodCycle()?.startDate else { return nil }
        var settingsDescriptor = FetchDescriptor<CyclePredictionSettings>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        settingsDescriptor.fetchLimit = 1
        let settings = fetch(settingsDescriptor, fallback: []).first
        let cycleLength = settings?.averageCycleLengthDays ?? 28
        return calendar.date(byAdding: .day, value: cycleLength, to: startDate)
    }

    private func fetchRecentPeriodSymptoms() -> [String] {
        let start = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        let descriptor = FetchDescriptor<WomensHealthDailyLog>(
            predicate: #Predicate<WomensHealthDailyLog> { $0.date >= start },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let logs = fetch(descriptor, fallback: [])
        return Array(logs.flatMap(\.symptoms).prefix(3))
    }

    private func fetchActiveFamilyMembers() -> [FamilyMember] {
        let descriptor = FetchDescriptor<FamilyMember>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return fetch(descriptor, fallback: [])
    }

    private func fetchPendingFamilyMedicineLogs() -> [MedicineLog] {
        pendingFamilyMedicineLogsUnavailable = false
        // Avoid traversing Medicine relationships from dashboard refresh. SwiftData can
        // invalidate a related Medicine after delete, and reading it here can fatal.
        return []
    }

    private func fetchNextDoctorAppointment() -> DoctorAppointment? {
        let now = Date.now
        var descriptor = FetchDescriptor<DoctorAppointment>(
            predicate: #Predicate<DoctorAppointment> { $0.appointmentDate >= now },
            sortBy: [SortDescriptor(\.appointmentDate)]
        )
        descriptor.fetchLimit = 1
        return fetch(descriptor, fallback: []).first
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

    private func fetch<T>(_ descriptor: FetchDescriptor<T>, fallback: [T]) -> [T] where T: PersistentModel {
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("[DashboardDataProvider] Fetch failed for \(T.self): \(error)")
            return fallback
        }
    }

    private func refreshHealthKitDataIfNeeded() async {
        healthKitService.refreshAuthorizationStatus()
        DebugStartupLogger.log("DashboardDataProvider HealthKit check available=\(healthKitService.isAvailable) enabled=\(UserHealthProfile.healthKitEnabled) authorized=\(healthKitService.isAuthorized)")
        guard healthKitService.isAvailable, UserHealthProfile.healthKitEnabled, healthKitService.isAuthorized else {
            todaySnapshot = nil
            wellnessInsights = []
            readinessSignal = nil
            isRecoveryDay = false
            healthKitLastSyncAt = nil
            return
        }

        let readingsProvider = HealthKitReadingsProvider(service: healthKitService)
        let insightEngine = WellnessInsightEngine(readingsProvider: readingsProvider, modelContext: modelContext)
        todaySnapshot = await readingsProvider.fetchTodaySnapshot()
        healthKitLastSyncAt = .now
        wellnessInsights = await insightEngine.generateTodayInsights()
        readinessSignal = wellnessInsights.compactMap { insight -> ReadinessSignal? in
            guard insight.category == .recoveryMode else { return nil }
            return ReadinessSignal(date: insight.date, level: .low, reason: insight.message)
        }.first
        isRecoveryDay = wellnessInsights.contains { $0.category == .recoveryMode }
    }
}
