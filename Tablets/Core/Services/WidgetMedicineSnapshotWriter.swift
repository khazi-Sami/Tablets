import Foundation
import SwiftData
import WidgetKit

@MainActor
enum WidgetMedicineSnapshotWriter {
    private static let snapshotFileName = "medicine_widget_snapshot.json"
    private static let calendar = Calendar.current

    static func writeAndReload(context: ModelContext, now: Date = .now) {
        writeSnapshot(context: context, now: now)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func writeSnapshot(context: ModelContext, now: Date = .now) {
        do {
            let snapshot = try makeSnapshot(context: context, now: now)
            try save(snapshot: snapshot)
        } catch {
            #if DEBUG
            print("[WidgetMedicineSnapshotWriter] Failed to write snapshot: \(error)")
            #endif
        }
    }

    static func writeSafeModeAndReload(message: String = "Open BanyAI to refresh your health data.") {
        writeSystemSnapshot(message: message)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func writeSignedOutAndReload() {
        writeSystemSnapshot(message: HealthAppIntegrityChecker.signedOutWidgetMessage)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func isCurrentSnapshotValid(activeMedicineIDs: Set<String>) -> Bool {
        guard let snapshot = try? loadSnapshot() else {
            return activeMedicineIDs.isEmpty
        }
        guard snapshot.errorMessage == nil else {
            return activeMedicineIDs.isEmpty
        }
        guard Set(snapshot.activeMedicineIDs) == activeMedicineIDs else { return false }
        if let nextMedicineID = snapshot.nextMedicineID {
            return activeMedicineIDs.contains(nextMedicineID)
        }
        return true
    }

    static func clearAndReload() {
        do {
            let url = try snapshotURL()
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            #if DEBUG
            print("[WidgetMedicineSnapshotWriter] Failed to clear snapshot: \(error)")
            #endif
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func makeSnapshot(context: ModelContext, now: Date) throws -> WidgetMedicineSnapshot {
        guard try hasActiveProfile(context: context) else {
            return emptySnapshot(now: now, hasAnyMedicines: false, message: HealthAppIntegrityChecker.safeModeMessage)
        }

        let medicines = try fetchActiveMedicines(context: context)
            .filter(HealthAppIntegrityChecker.isValidMedicine)
        let activeMedicineIDs = medicines.map { $0.id.uuidString }
        guard medicines.isEmpty == false else {
            return emptySnapshot(now: now, hasAnyMedicines: false, message: nil)
        }

        let todayDoses = todayDoses(for: medicines, now: now)
        guard todayDoses.isEmpty == false else {
            return emptySnapshot(now: now, hasAnyMedicines: true, message: nil, activeMedicineIDs: activeMedicineIDs)
        }

        let dayRange = dayRange(containing: now)
        let logs = try fetchLogs(context: context, start: dayRange.start, end: dayRange.end)
        let doseStates = todayDoses.map { dose in
            DoseState(dose: dose, status: status(for: dose, logs: logs, now: now))
        }

        let taken = doseStates.filter { $0.status == .taken }.count
        let skipped = doseStates.filter { $0.status == .skipped || $0.status == .snoozed }.count
        let pendingStates = doseStates.filter { $0.status == .pending || $0.status == .overdue }
        let pending = pendingStates.count
        let adherence = todayDoses.isEmpty ? 0 : (Double(taken) / Double(todayDoses.count)) * 100
        let next = pendingStates.sorted { $0.dose.scheduledAt < $1.dose.scheduledAt }.first
        let upcoming = pendingStates
            .sorted { $0.dose.scheduledAt < $1.dose.scheduledAt }
            .prefix(3)
            .map {
                WidgetMedicineSnapshotUpcoming(
                    time: timeText($0.dose.scheduledAt),
                    name: shortened($0.dose.medicine.name),
                    status: $0.status.rawValue,
                    medicineID: $0.dose.medicine.id.uuidString
                )
            }

        return WidgetMedicineSnapshot(
            generatedAt: now,
            takenCount: taken,
            pendingCount: pending,
            skippedCount: skipped,
            adherencePercent: adherence,
            adherenceTrend: nil,
            nextMedicineName: next?.dose.medicine.name,
            nextMedicineDosage: next?.dose.medicine.dosage,
            nextMedicineInstruction: next?.dose.medicine.instruction.title,
            nextMedicineID: next?.dose.medicine.id.uuidString,
            timeRemaining: next.map { relativeText(to: $0.dose.scheduledAt, now: now) },
            isOverdue: next?.status == .overdue,
            upcomingMedicines: Array(upcoming),
            adaptiveInsight: nil,
            hasAnyMedicines: true,
            hasMedicinesDueToday: true,
            errorMessage: nil,
            activeMedicineIDs: activeMedicineIDs
        )
    }

    private static func hasActiveProfile(context: ModelContext) throws -> Bool {
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        return profiles.contains { profile in
            profile.hasCompletedOnboarding &&
            !profile.loginMethod.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private static func fetchActiveMedicines(context: ModelContext) throws -> [Medicine] {
        let descriptor = FetchDescriptor<Medicine>(
            predicate: #Predicate<Medicine> { $0.isActive == true },
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    private static func fetchLogs(context: ModelContext, start: Date, end: Date) throws -> [MedicineLog] {
        let descriptor = FetchDescriptor<MedicineLog>(
            predicate: #Predicate<MedicineLog> { log in
                log.scheduledTime >= start && log.scheduledTime < end
            },
            sortBy: [SortDescriptor(\.scheduledTime)]
        )
        return try context.fetch(descriptor)
    }

    private static func todayDoses(for medicines: [Medicine], now: Date) -> [Dose] {
        medicines.flatMap { medicine in
            medicine.times.map { time in
                Dose(medicine: medicine, scheduledAt: sameDayTime(time, day: now))
            }
        }
        .sorted { $0.scheduledAt < $1.scheduledAt }
    }

    private static func sameDayTime(_ time: Date, day: Date) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        return calendar.date(from: components) ?? time
    }

    private static func status(for dose: Dose, logs: [MedicineLog], now: Date) -> DoseStatus {
        let key = timeKey(dose.scheduledAt)
        if let log = logs.first(where: { timeKey($0.scheduledTime) == key && $0.medicine?.id == dose.medicine.id }) {
            switch log.status {
            case .taken: return .taken
            case .skipped: return .skipped
            case .snoozed: return .snoozed
            case .missed: return .overdue
            }
        }
        return dose.scheduledAt < now ? .overdue : .pending
    }

    private static func emptySnapshot(
        now: Date,
        hasAnyMedicines: Bool,
        message: String?,
        activeMedicineIDs: [String] = []
    ) -> WidgetMedicineSnapshot {
        WidgetMedicineSnapshot(
            generatedAt: now,
            takenCount: 0,
            pendingCount: 0,
            skippedCount: 0,
            adherencePercent: 0,
            adherenceTrend: nil,
            nextMedicineName: nil,
            nextMedicineDosage: nil,
            nextMedicineInstruction: nil,
            nextMedicineID: nil,
            timeRemaining: nil,
            isOverdue: false,
            upcomingMedicines: [],
            adaptiveInsight: nil,
            hasAnyMedicines: hasAnyMedicines,
            hasMedicinesDueToday: false,
            errorMessage: message,
            activeMedicineIDs: activeMedicineIDs
        )
    }

    private static func writeSystemSnapshot(message: String) {
        do {
            try save(snapshot: emptySnapshot(now: .now, hasAnyMedicines: false, message: message))
        } catch {
            #if DEBUG
            print("[WidgetMedicineSnapshotWriter] Failed to write system snapshot: \(error)")
            #endif
        }
    }

    private static func save(snapshot: WidgetMedicineSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: try snapshotURL(), options: [.atomic])
    }

    private static func loadSnapshot() throws -> WidgetMedicineSnapshot {
        let data = try Data(contentsOf: try snapshotURL())
        return try JSONDecoder().decode(WidgetMedicineSnapshot.self, from: data)
    }

    private static func snapshotURL() throws -> URL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppPreferenceKeys.appGroupID) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return containerURL.appendingPathComponent(snapshotFileName)
    }

    private static func dayRange(containing date: Date) -> (start: Date, end: Date) {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return (start, end)
    }

    private static func relativeText(to date: Date, now: Date) -> String {
        let minutes = Int(date.timeIntervalSince(now) / 60)
        if minutes < 0 {
            return "\(abs(minutes)) min overdue"
        }
        if minutes < 60 {
            return "Due in \(max(minutes, 1)) min"
        }
        return "Due in \(minutes / 60) hr"
    }

    private static func timeText(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private static func timeKey(_ date: Date) -> String {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d%02d", components.hour ?? 0, components.minute ?? 0)
    }

    private static func shortened(_ name: String) -> String {
        name.count > 12 ? String(name.prefix(11)) + "..." : name
    }
}

private struct WidgetMedicineSnapshot: Codable {
    let generatedAt: Date
    let takenCount: Int
    let pendingCount: Int
    let skippedCount: Int
    let adherencePercent: Double
    let adherenceTrend: String?
    let nextMedicineName: String?
    let nextMedicineDosage: String?
    let nextMedicineInstruction: String?
    let nextMedicineID: String?
    let timeRemaining: String?
    let isOverdue: Bool
    let upcomingMedicines: [WidgetMedicineSnapshotUpcoming]
    let adaptiveInsight: String?
    let hasAnyMedicines: Bool
    let hasMedicinesDueToday: Bool
    let errorMessage: String?
    let activeMedicineIDs: [String]
}

private struct WidgetMedicineSnapshotUpcoming: Codable {
    let time: String
    let name: String
    let status: String
    let medicineID: String?
}

private struct Dose {
    let medicine: Medicine
    let scheduledAt: Date
}

private struct DoseState {
    let dose: Dose
    let status: DoseStatus
}

private enum DoseStatus: String {
    case taken
    case pending
    case overdue
    case skipped
    case snoozed
}
