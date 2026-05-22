import Foundation
import SwiftData

protocol MedicineVoiceQueryAnswering {
    func answer(_ transcript: String, modelContext: ModelContext) async -> MedicineVoiceQueryResult?
}

struct MedicineVoiceQueryResult {
    let response: String
    let shouldNavigateToWidget: Bool
    let handledAction: Bool
}

@MainActor
struct MedicineVoiceQueryEngine: MedicineVoiceQueryAnswering {
    private let detector = MedicineVoiceQueryTypeDetector()
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func answer(_ transcript: String, modelContext: ModelContext) async -> MedicineVoiceQueryResult? {
        let queryType = detector.detect(transcript)
        if case .unknown = queryType {
            return nil
        }

        let medicines = fetchActiveMedicines(modelContext: modelContext)
        let todayDoses = buildTodayDoses(medicines: medicines, logs: fetchTodayLogs(modelContext: modelContext))
        let weekly = buildWeeklyAdherence(medicines: medicines, modelContext: modelContext)

        switch queryType {
        case .todayRoutine:
            return MedicineVoiceQueryResult(
                response: todayRoutineResponse(doses: todayDoses, medicineCount: medicines.count),
                shouldNavigateToWidget: asksToShow(transcript),
                handledAction: false
            )
        case .weeklyAdherence:
            return MedicineVoiceQueryResult(
                response: weeklyAdherenceResponse(weekly),
                shouldNavigateToWidget: false,
                handledAction: false
            )
        case .pending:
            return MedicineVoiceQueryResult(
                response: pendingResponse(transcript: transcript, doses: todayDoses),
                shouldNavigateToWidget: false,
                handledAction: false
            )
        case .nextMedicine:
            return MedicineVoiceQueryResult(
                response: nextMedicineResponse(doses: todayDoses),
                shouldNavigateToWidget: false,
                handledAction: false
            )
        case .overdue:
            return MedicineVoiceQueryResult(
                response: overdueResponse(doses: todayDoses),
                shouldNavigateToWidget: false,
                handledAction: false
            )
        case .lowStock:
            return MedicineVoiceQueryResult(
                response: lowStockResponse(medicines: medicines),
                shouldNavigateToWidget: false,
                handledAction: false
            )
        case .markNextTaken:
            return await markNextTaken(doses: todayDoses, modelContext: modelContext)
        case .markSpecificTaken(let medicineName):
            return await markSpecificTaken(medicineName: medicineName, transcript: transcript, medicines: medicines, doses: todayDoses, modelContext: modelContext)
        case .unknown:
            return nil
        }
    }

    private func todayRoutineResponse(doses: [TodayMedicineDose], medicineCount: Int) -> String {
        guard medicineCount > 0 else {
            return "No medicines are added yet. Add your first medicine to start a daily routine."
        }
        guard !doses.isEmpty else {
            return "No medicines are scheduled for today. Take it easy."
        }

        let taken = doses.filter { $0.status == .taken }.count
        let pending = doses.filter { $0.status == .pending }.count
        let overdue = doses.filter { $0.status == .overdue }.count
        return "You have \(doses.count) medicine dose\(doses.count == 1 ? "" : "s") scheduled today. \(taken) taken, \(pending) pending, and \(overdue) overdue. Every logged dose helps your routine."
    }

    private func weeklyAdherenceResponse(_ adherence: WeeklyMedicineAdherence) -> String {
        guard adherence.totalCount > 0 else {
            return "I do not see scheduled medicine doses for this week yet. Start adding medicines to see your routine."
        }
        let missedText = adherence.missedCount > 0 ? " \(adherence.missedCount) dose\(adherence.missedCount == 1 ? "" : "s") still need attention." : ""
        return "You took \(adherence.takenCount) of \(adherence.totalCount) scheduled medicines this week.\(missedText) Keep going."
    }

    private func pendingResponse(transcript: String, doses: [TodayMedicineDose]) -> String {
        if transcript.lowercased().contains("did i take") {
            let targetDoses = filteredByDayPartIfNeeded(doses: doses, transcript: transcript)
            let taken = targetDoses.filter { $0.status == .taken }
            if !taken.isEmpty {
                let names = taken.prefix(2).map(\.medicineName).joined(separator: ", ")
                return "Yes, \(names) \(taken.count == 1 ? "is" : "are") logged as taken today."
            }
            let waiting = targetDoses.filter { $0.status == .pending || $0.status == .overdue }
            if let next = waiting.first {
                return "\(next.medicineName) is not logged as taken yet. It was scheduled at \(formatTime(next.scheduledTime))."
            }
            return "I do not see a matching tablet scheduled for that time today."
        }

        let pending = doses.filter { $0.status == .pending || $0.status == .overdue }
        guard !pending.isEmpty else {
            return "No pending medicines are showing for today."
        }
        let next = pending.sorted { $0.scheduledTime < $1.scheduledTime }.first
        let nextText = next.map { " The next one is \($0.medicineName) at \(formatTime($0.scheduledTime))." } ?? ""
        return "You have \(pending.count) pending medicine\(pending.count == 1 ? "" : "s") today.\(nextText)"
    }

    private func nextMedicineResponse(doses: [TodayMedicineDose]) -> String {
        guard let next = doses.first(where: { $0.status == .pending || $0.status == .overdue }) else {
            if doses.isEmpty {
                return "No medicines are scheduled for today."
            }
            return "All scheduled medicines are logged for today."
        }
        return "Your next medicine is \(next.medicineName) \(next.dosage) at \(formatTime(next.scheduledTime))."
    }

    private func overdueResponse(doses: [TodayMedicineDose]) -> String {
        let overdue = doses.filter { $0.status == .overdue }
        guard !overdue.isEmpty else {
            return "No overdue medicines are showing for today."
        }
        let names = overdue.prefix(3).map { "\($0.medicineName), scheduled at \(formatTime($0.scheduledTime))" }.joined(separator: "; ")
        return "You have \(overdue.count) overdue medicine\(overdue.count == 1 ? "" : "s"): \(names)."
    }

    private func lowStockResponse(medicines: [Medicine]) -> String {
        let lowStock = medicines
            .filter { $0.stockCount <= $0.lowStockAlertCount }
            .sorted { $0.stockCount == $1.stockCount ? $0.name < $1.name : $0.stockCount < $1.stockCount }

        guard !lowStock.isEmpty else {
            return "No low stock medicines are showing right now."
        }
        let summary = lowStock.prefix(3).map { "\($0.name) has \($0.stockCount) left" }.joined(separator: "; ")
        return summary + "."
    }

    private func markNextTaken(doses: [TodayMedicineDose], modelContext: ModelContext) async -> MedicineVoiceQueryResult {
        guard let dose = doses.first(where: { $0.status == .pending || $0.status == .overdue }) else {
            return MedicineVoiceQueryResult(response: "I do not see a pending medicine dose to mark as taken.", shouldNavigateToWidget: false, handledAction: false)
        }
        return await saveTakenLog(for: dose, modelContext: modelContext)
    }

    private func markSpecificTaken(
        medicineName: String?,
        transcript: String,
        medicines: [Medicine],
        doses: [TodayMedicineDose],
        modelContext: ModelContext
    ) async -> MedicineVoiceQueryResult {
        let matches = matchingMedicines(named: medicineName, transcript: transcript, medicines: medicines)
        guard !matches.isEmpty else {
            return MedicineVoiceQueryResult(response: "I could not find that medicine in your active list.", shouldNavigateToWidget: false, handledAction: false)
        }
        guard matches.count == 1, let medicine = matches.first else {
            return MedicineVoiceQueryResult(response: "I found more than one matching medicine. Which one did you mean?", shouldNavigateToWidget: false, handledAction: false)
        }
        let medicineDoses = doses.filter { $0.medicineId == medicine.id }
        if medicineDoses.contains(where: { $0.status == .taken }) &&
            !medicineDoses.contains(where: { $0.status == .pending || $0.status == .overdue || $0.status == .notLogged }) {
            return MedicineVoiceQueryResult(response: "\(medicine.name) is already logged as taken today.", shouldNavigateToWidget: false, handledAction: false)
        }
        guard let dose = medicineDoses.first(where: { $0.status == .pending || $0.status == .overdue || $0.status == .notLogged }) else {
            return MedicineVoiceQueryResult(response: "\(medicine.name) is not scheduled for today.", shouldNavigateToWidget: false, handledAction: false)
        }
        return await saveTakenLog(for: dose, modelContext: modelContext)
    }

    private func saveTakenLog(for dose: TodayMedicineDose, modelContext: ModelContext) async -> MedicineVoiceQueryResult {
        guard let medicine = fetchMedicine(id: dose.medicineId, modelContext: modelContext) else {
            return MedicineVoiceQueryResult(response: "I could not find that medicine in your active list.", shouldNavigateToWidget: false, handledAction: false)
        }
        guard !alreadyTaken(dose: dose, modelContext: modelContext) else {
            return MedicineVoiceQueryResult(response: "\(dose.medicineName) is already logged as taken today.", shouldNavigateToWidget: false, handledAction: false)
        }

        let log = MedicineLog(medicine: medicine, scheduledTime: dose.scheduledTime, takenTime: .now, status: .taken)
        modelContext.insert(log)
        do {
            try modelContext.save()
            NotificationCenter.default.post(name: .healthDataDidUpdate, object: nil)
            return MedicineVoiceQueryResult(response: "Done. I marked \(medicine.name) as taken.", shouldNavigateToWidget: false, handledAction: true)
        } catch {
            modelContext.delete(log)
            print("[MedicineVoiceQueryEngine] Could not save taken medicine log: \(error)")
            return MedicineVoiceQueryResult(response: "I could not save that medicine dose just now. Please try again.", shouldNavigateToWidget: false, handledAction: false)
        }
    }

    private func alreadyTaken(dose: TodayMedicineDose, modelContext: ModelContext) -> Bool {
        let start = calendar.startOfDay(for: dose.scheduledTime)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? dose.scheduledTime
        let logs = fetchLogs(from: start, to: end, modelContext: modelContext)
        return logs.contains { log in
            log.status == .taken &&
            log.medicine?.id == dose.medicineId &&
            calendar.isDate(log.scheduledTime, equalTo: dose.scheduledTime, toGranularity: .minute)
        }
    }

    private func buildTodayDoses(medicines: [Medicine], logs: [MedicineLog]) -> [TodayMedicineDose] {
        let today = calendar.startOfDay(for: .now)
        return medicines
            .filter { isMedicineScheduled($0, on: today) }
            .flatMap { medicine in
                medicine.times.map { time in
                    let scheduledTime = timeOnDay(time, day: today)
                    let log = bestMatchingLog(for: medicine, scheduledTime: scheduledTime, logs: logs)
                    return buildDose(medicine: medicine, scheduledTime: scheduledTime, log: log)
                }
            }
            .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    private func buildDose(medicine: Medicine, scheduledTime: Date, log: MedicineLog?) -> TodayMedicineDose {
        let status: MedicineDoseStatus
        if let log {
            switch log.status {
            case .taken: status = .taken
            case .skipped: status = .skipped
            case .snoozed: status = .snoozed
            case .missed: status = scheduledTime < .now ? .overdue : .notLogged
            }
        } else {
            status = scheduledTime < .now ? .overdue : .pending
        }

        return TodayMedicineDose(
            id: "\(medicine.id.uuidString)-\(Int(scheduledTime.timeIntervalSince1970))",
            medicineId: medicine.id,
            medicineName: medicine.name,
            dosage: medicine.dosage,
            medicineType: medicine.medicineType,
            scheduledTime: scheduledTime,
            status: status,
            actualTakenTime: log?.takenTime,
            stockCount: medicine.stockCount,
            isLowStock: medicine.stockCount <= medicine.lowStockAlertCount,
            minutesUntilDue: max(0, calendar.dateComponents([.minute], from: .now, to: scheduledTime).minute ?? 0),
            minutesOverdue: max(0, calendar.dateComponents([.minute], from: scheduledTime, to: .now).minute ?? 0),
            adaptiveInsight: nil
        )
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
        var bestScore = -1.0

        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { continue }
            let doseKeys = scheduledDoseKeys(medicines: medicines, day: day)
            guard !doseKeys.isEmpty else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let dayLogs = logs.filter { $0.scheduledTime >= dayStart && $0.scheduledTime < dayEnd }
            let dayTaken = doseKeys.filter { key in
                dayLogs.contains { log in
                    log.status == .taken &&
                    log.medicine?.id == key.medicineId &&
                    calendar.isDate(log.scheduledTime, equalTo: key.scheduledTime, toGranularity: .minute)
                }
            }.count
            let dayMissed = doseKeys.filter { key in
                let matched = dayLogs.first { log in
                    log.medicine?.id == key.medicineId &&
                    calendar.isDate(log.scheduledTime, equalTo: key.scheduledTime, toGranularity: .minute)
                }
                if matched?.status == .skipped || matched?.status == .missed { return true }
                return key.scheduledTime < .now && matched == nil
            }.count
            totalCount += doseKeys.count
            takenCount += dayTaken
            missedCount += dayMissed

            let score = Double(dayTaken) / Double(doseKeys.count)
            if score > bestScore {
                bestScore = score
                bestDayName = weekdayName(for: day)
            }
        }

        return WeeklyMedicineAdherence(
            takenCount: takenCount,
            totalCount: totalCount,
            missedCount: missedCount,
            percent: totalCount > 0 ? Double(takenCount) / Double(totalCount) : 0,
            bestDayName: bestDayName
        )
    }

    private func fetchActiveMedicines(modelContext: ModelContext) -> [Medicine] {
        fetch(FetchDescriptor<Medicine>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.name)]
        ), modelContext: modelContext)
    }

    private func fetchMedicine(id: UUID, modelContext: ModelContext) -> Medicine? {
        var descriptor = FetchDescriptor<Medicine>(predicate: #Predicate<Medicine> { $0.id == id })
        descriptor.fetchLimit = 1
        return fetch(descriptor, modelContext: modelContext).first
    }

    private func fetchTodayLogs(modelContext: ModelContext) -> [MedicineLog] {
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? .now
        return fetchLogs(from: start, to: end, modelContext: modelContext)
    }

    private func fetchLogs(from start: Date, to end: Date, modelContext: ModelContext) -> [MedicineLog] {
        fetch(FetchDescriptor<MedicineLog>(
            predicate: #Predicate<MedicineLog> { log in
                log.scheduledTime >= start && log.scheduledTime < end
            },
            sortBy: [SortDescriptor(\.scheduledTime)]
        ), modelContext: modelContext)
    }

    private func fetch<T>(_ descriptor: FetchDescriptor<T>, modelContext: ModelContext) -> [T] where T: PersistentModel {
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("[MedicineVoiceQueryEngine] Fetch failed for \(T.self): \(error)")
            return []
        }
    }

    private func bestMatchingLog(for medicine: Medicine, scheduledTime: Date, logs: [MedicineLog]) -> MedicineLog? {
        let matches = logs.filter {
            $0.medicine?.id == medicine.id &&
            calendar.isDate($0.scheduledTime, equalTo: scheduledTime, toGranularity: .minute)
        }
        if let taken = matches.first(where: { $0.status == .taken }) { return taken }
        if let snoozed = matches.first(where: { $0.status == .snoozed }) { return snoozed }
        if let skipped = matches.first(where: { $0.status == .skipped }) { return skipped }
        return matches.first
    }

    private func scheduledDoseKeys(medicines: [Medicine], day: Date) -> [(medicineId: UUID, scheduledTime: Date)] {
        medicines
            .filter { isMedicineScheduled($0, on: day) }
            .flatMap { medicine in medicine.times.map { (medicine.id, timeOnDay($0, day: day)) } }
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

    private func filteredByDayPartIfNeeded(doses: [TodayMedicineDose], transcript: String) -> [TodayMedicineDose] {
        let text = transcript.lowercased()
        if text.contains("morning") || text.contains("subah") {
            return doses.filter { calendar.component(.hour, from: $0.scheduledTime) < 12 }
        }
        if text.contains("afternoon") || text.contains("dopahar") {
            return doses.filter {
                let hour = calendar.component(.hour, from: $0.scheduledTime)
                return hour >= 12 && hour < 17
            }
        }
        if text.contains("evening") || text.contains("sham") || text.contains("night") || text.contains("raat") {
            return doses.filter { calendar.component(.hour, from: $0.scheduledTime) >= 17 }
        }
        return doses
    }

    private func matchingMedicines(named medicineName: String?, transcript: String, medicines: [Medicine]) -> [Medicine] {
        let text = normalized(transcript)
        let candidate = normalized(medicineName ?? "")
        let searchable = candidate.isEmpty ? text : candidate
        let matches = medicines.filter { medicine in
            let name = normalized(medicine.name)
            return searchable.contains(name) || name.contains(searchable) || similarity(name, searchable) >= 0.72
        }
        return matches.isEmpty && text.contains("bp tablet")
            ? medicines.filter { normalized($0.name).contains("bp") || normalized($0.name).contains("pressure") }
            : matches
    }

    private func asksToShow(_ transcript: String) -> Bool {
        let text = transcript.lowercased()
        return text.contains("show") || text.contains("open") || text.contains("dikhao")
    }

    private func formatTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func weekdayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func normalized(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
            .split(separator: " ")
            .joined(separator: " ")
    }

    private func similarity(_ lhs: String, _ rhs: String) -> Double {
        guard !lhs.isEmpty, !rhs.isEmpty else { return 0 }
        let distance = levenshtein(lhs, rhs)
        return 1.0 - Double(distance) / Double(max(lhs.count, rhs.count))
    }

    private func levenshtein(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs)
        let b = Array(rhs)
        var row = Array(0...b.count)
        for (i, left) in a.enumerated() {
            var previous = row[0]
            row[0] = i + 1
            for (j, right) in b.enumerated() {
                let old = row[j + 1]
                row[j + 1] = left == right ? previous : min(previous, row[j], row[j + 1]) + 1
                previous = old
            }
        }
        return row[b.count]
    }
}
