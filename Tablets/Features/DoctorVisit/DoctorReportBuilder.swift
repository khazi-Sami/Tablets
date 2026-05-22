import Foundation

@MainActor
struct DoctorReportBuilder {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func build(
        range: DoctorReportRange,
        customStart: Date,
        customEnd: Date,
        medicines: [Medicine],
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        womensLogs: [WomensHealthDailyLog],
        periodCycles: [PeriodCycle],
        appointments: [DoctorAppointment],
        notes: String
    ) async -> DoctorReportData {
        let endDate = range == .custom ? customEnd : .now
        let startDate: Date
        switch range {
        case .sevenDays:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .thirtyDays:
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        case .custom:
            startDate = customStart
        }

        let logs = medicineLogs.filter { $0.scheduledTime >= startDate && $0.scheduledTime <= endDate }
        let records = healthRecords.filter { $0.measuredAt >= startDate && $0.measuredAt <= endDate }
        let womens = womensLogs.filter { $0.date >= startDate && $0.date <= endDate }
        let cycles = periodCycles.filter { $0.startDate <= endDate && ($0.endDate ?? .now) >= startDate }
        let visitNotes = appointments.filter { $0.appointmentDate >= startDate && $0.appointmentDate <= endDate }

        return DoctorReportData(
            startDate: startDate,
            endDate: endDate,
            patientName: UserHealthProfile.userName,
            patientAge: appointments.first?.patientAge ?? 0,
            medicines: medicines.filter(\.isActive),
            medicineLogs: logs,
            healthRecords: records,
            symptoms: symptomFrequency(womens),
            periodSummary: UserHealthProfile.showWomensHealthCard ? periodSummary(cycles) : nil,
            appointments: visitNotes.isEmpty ? appointments.prefix(3).map { $0 } : visitNotes,
            notes: notes,
            appleHealthSummary: await appleHealthSummary()
        )
    }

    private func symptomFrequency(_ logs: [WomensHealthDailyLog]) -> [(String, Int)] {
        let all = logs.flatMap(\.symptoms) + logs.flatMap { log in
            log.notes
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0.count < 40 }
        }
        return Dictionary(grouping: all, by: { $0 })
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }

    private func periodSummary(_ cycles: [PeriodCycle]) -> String? {
        guard let latest = cycles.sorted(by: { $0.startDate > $1.startDate }).first else { return nil }
        let end = latest.endDate?.mediumDateText ?? "ongoing"
        return "Latest period started \(latest.startDate.mediumDateText), end: \(end), flow: \(latest.flowLevel.title), pain: \(latest.painLevel)/10."
    }

    private func appleHealthSummary() async -> DoctorReportAppleHealthSummary? {
        let service = HealthKitService()
        service.refreshAuthorizationStatus()
        guard service.isAvailable, UserHealthProfile.healthKitEnabled, service.isAuthorized else { return nil }

        let provider = HealthKitReadingsProvider(service: service)
        let snapshots = await provider.fetchLast7DaysSnapshots()
        let today = await provider.fetchTodaySnapshot()
        return DoctorReportAppleHealthSummary(
            averageSteps: average(snapshots.compactMap(\.steps)),
            averageSleepHours: average(snapshots.compactMap(\.sleepDurationHours)),
            latestHeartRate: today.latestHeartRate,
            restingHeartRate: today.restingHeartRate
        )
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
