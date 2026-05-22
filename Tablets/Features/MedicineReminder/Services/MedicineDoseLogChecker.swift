import Foundation
import SwiftData

@MainActor
struct MedicineDoseLogChecker {
    private let modelContext: ModelContext
    private let calendar: Calendar

    init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.modelContext = modelContext
        self.calendar = calendar
    }

    func hasLoggedDose(
        medicineID: String,
        scheduledTimeKey: String,
        on date: Date
    ) async -> Bool {
        guard let uuid = UUID(uuidString: medicineID),
              let dayEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))
        else {
            debugLog("Could not parse medicineID=\(medicineID)")
            return false
        }

        let dayStart = calendar.startOfDay(for: date)
        let descriptor = FetchDescriptor<MedicineLog>(
            predicate: #Predicate<MedicineLog> { log in
                log.scheduledTime >= dayStart && log.scheduledTime < dayEnd
            },
            sortBy: [SortDescriptor(\.scheduledTime)]
        )

        do {
            let logs = try modelContext.fetch(descriptor)
            return logs.contains { log in
                guard log.medicine?.id == uuid,
                      log.status == .taken || log.status == .skipped || log.status == .snoozed
                else {
                    return false
                }
                return AdaptiveReminderTimeKey.key(from: log.scheduledTime, calendar: calendar) == scheduledTimeKey
            }
        } catch {
            debugLog("Log check failed: \(error)")
            return false
        }
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[MedicineDoseLogChecker] \(message)")
        #endif
    }
}
