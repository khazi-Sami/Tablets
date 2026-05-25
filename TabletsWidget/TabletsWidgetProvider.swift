import Foundation
import SwiftData
import WidgetKit

struct TabletsWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MedicineWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (MedicineWidgetEntry) -> Void) {
        completion(WidgetMedicineDataSource.loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MedicineWidgetEntry>) -> Void) {
        let entry = WidgetMedicineDataSource.loadEntry()
        let nextUpdate = WidgetMedicineDataSource.nextUpdateDate(for: entry)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

enum WidgetMedicineDataSource {
    private static let appGroupID = "group.com.developer.apple.Tablets"
    private static let calendar = Calendar.current

    static func loadEntry(now: Date = .now) -> MedicineWidgetEntry {
        do {
            let context = try makeContext()
            let medicines = try fetchActiveMedicines(context: context)
            guard medicines.isEmpty == false else {
                return emptyEntry(now: now, hasAnyMedicines: false, message: nil)
            }

            let todayDoses = todayDoses(for: medicines, now: now)
            guard todayDoses.isEmpty == false else {
                return emptyEntry(now: now, hasAnyMedicines: true, message: nil)
            }

            let dayRange = dayRange(containing: now)
            let logs = try fetchLogs(context: context, start: dayRange.start, end: dayRange.end)
            let doseStates = todayDoses.map { dose -> DoseState in
                let status = status(for: dose, logs: logs)
                return DoseState(dose: dose, status: status)
            }

            let taken = doseStates.filter { $0.status == .taken }.count
            let skipped = doseStates.filter { $0.status == .skipped || $0.status == .snoozed }.count
            let pendingStates = doseStates.filter { $0.status == .pending || $0.status == .overdue }
            let pending = pendingStates.count
            let adherence = todayDoses.isEmpty ? 0 : (Double(taken) / Double(todayDoses.count)) * 100
            let next = pendingStates.sorted { $0.dose.scheduledAt < $1.dose.scheduledAt }.first
            let upcoming = doseStates
                .filter { $0.status == .pending || $0.status == .overdue }
                .sorted { $0.dose.scheduledAt < $1.dose.scheduledAt }
                .prefix(3)
                .map { UpcomingMedicine(time: timeText($0.dose.scheduledAt), name: shortened($0.dose.medicine.name), status: $0.status.rawValue) }

            return MedicineWidgetEntry(
                date: now,
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
                adaptiveInsight: adaptiveInsight(for: next),
                hasAnyMedicines: true,
                hasMedicinesDueToday: true,
                errorMessage: nil
            )
        } catch {
            return MedicineWidgetEntry(
                date: now,
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
                hasAnyMedicines: false,
                hasMedicinesDueToday: false,
                errorMessage: "Unable to load medicines"
            )
        }
    }

    static func nextUpdateDate(for entry: MedicineWidgetEntry, now: Date = .now) -> Date {
        if entry.pendingCount > 0 {
            return calendar.date(byAdding: .minute, value: 5, to: now) ?? now.addingTimeInterval(300)
        }

        var tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now.addingTimeInterval(86_400)
        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 8
        components.minute = 0
        tomorrow = calendar.date(from: components) ?? tomorrow
        return tomorrow
    }

    private static func makeContext() throws -> ModelContext {
        let schema = Schema([Medicine.self, MedicineLog.self])
        let configuration = ModelConfiguration(
            "TabletsModelV10",
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupID)
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
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

    private static func status(for dose: Dose, logs: [MedicineLog]) -> DoseStatus {
        let key = timeKey(dose.scheduledAt)
        if let log = logs.first(where: { log in
            guard log.medicine?.id == dose.medicine.id else { return false }
            return timeKey(log.scheduledTime) == key
        }) {
            switch log.status {
            case .taken: return .taken
            case .skipped: return .skipped
            case .snoozed: return .snoozed
            case .missed: return .overdue
            }
        }
        return dose.scheduledAt < Date() ? .overdue : .pending
    }

    private static func emptyEntry(now: Date, hasAnyMedicines: Bool, message: String?) -> MedicineWidgetEntry {
        MedicineWidgetEntry(
            date: now,
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
            errorMessage: message
        )
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

    private static func adaptiveInsight(for state: DoseState?) -> String? {
        guard state != nil else { return nil }
        return nil
    }
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
