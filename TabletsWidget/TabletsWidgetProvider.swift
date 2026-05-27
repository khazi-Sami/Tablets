import Foundation
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
    private static let snapshotFileName = "medicine_widget_snapshot.json"
    private static let calendar = Calendar.current

    static func loadEntry(now: Date = .now) -> MedicineWidgetEntry {
        guard let snapshot = loadSnapshot() else {
            return emptyEntry(now: now, hasAnyMedicines: false, message: nil)
        }

        return MedicineWidgetEntry(
            date: now,
            takenCount: snapshot.takenCount,
            pendingCount: snapshot.pendingCount,
            skippedCount: snapshot.skippedCount,
            adherencePercent: snapshot.adherencePercent,
            adherenceTrend: snapshot.adherenceTrend,
            nextMedicineName: snapshot.nextMedicineName,
            nextMedicineDosage: snapshot.nextMedicineDosage,
            nextMedicineInstruction: snapshot.nextMedicineInstruction,
            nextMedicineID: snapshot.nextMedicineID,
            timeRemaining: snapshot.timeRemaining,
            isOverdue: snapshot.isOverdue,
            upcomingMedicines: snapshot.upcomingMedicines.map {
                UpcomingMedicine(time: $0.time, name: $0.name, status: $0.status)
            },
            adaptiveInsight: snapshot.adaptiveInsight,
            hasAnyMedicines: snapshot.hasAnyMedicines,
            hasMedicinesDueToday: snapshot.hasMedicinesDueToday,
            errorMessage: snapshot.errorMessage
        )
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

    private static func loadSnapshot() -> WidgetMedicineSnapshot? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }

        let url = containerURL.appendingPathComponent(snapshotFileName)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        return try? JSONDecoder().decode(WidgetMedicineSnapshot.self, from: data)
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
}

private struct WidgetMedicineSnapshotUpcoming: Codable {
    let time: String
    let name: String
    let status: String
}
