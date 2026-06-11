import Foundation
import Observation
import SwiftData
import UserNotifications

@Observable
@MainActor
final class MissedDoseFollowUpManager {
    private let modelContext: ModelContext
    private let config: AdaptiveReminderConfig
    private let notificationCenter: UNUserNotificationCenter
    private let defaults: UserDefaults
    private let calendar: Calendar
    private(set) var activeFollowUps: [MissedDoseFollowUp] = []

    init(
        modelContext: ModelContext,
        config: AdaptiveReminderConfig? = nil,
        notificationCenter: UNUserNotificationCenter = .current(),
        defaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.modelContext = modelContext
        self.config = config ?? AdaptiveReminderConfig()
        self.notificationCenter = notificationCenter
        self.defaults = defaults
        self.calendar = calendar
    }

    func scheduleFollowUp(for medicine: Medicine, scheduledAt: Date) async {
        await scheduleFollowUp(
            for: medicine.id.uuidString,
            scheduledTimeKey: AdaptiveReminderTimeKey.key(from: scheduledAt, calendar: calendar),
            medicineName: medicine.name,
            scheduledAt: scheduledAt,
            persistentMedicineID: medicine.persistentModelID
        )
    }

    func scheduleFollowUp(
        for medicineID: String,
        scheduledTimeKey: String,
        medicineName: String,
        scheduledAt: Date
    ) async {
        await scheduleFollowUp(
            for: medicineID,
            scheduledTimeKey: scheduledTimeKey,
            medicineName: medicineName,
            scheduledAt: scheduledAt,
            persistentMedicineID: nil
        )
    }

    private func scheduleFollowUp(
        for medicineID: String,
        scheduledTimeKey: String,
        medicineName: String,
        scheduledAt: Date,
        persistentMedicineID: PersistentIdentifier?
    ) async {
        guard isFollowUpPending(medicineID: medicineID, scheduledTimeKey: scheduledTimeKey, date: scheduledAt) == false else {
            debugLog("Follow-up skipped; already pending for \(medicineID) \(scheduledTimeKey)")
            return
        }

        guard activeFollowUps(for: medicineID, scheduledTimeKey: scheduledTimeKey, date: scheduledAt).count < config.maxFollowUpsPerDose else {
            return
        }

        guard let followUpTime = calendar.date(
            byAdding: .minute,
            value: config.followUpDelayMinutes,
            to: scheduledAt
        ), followUpTime > .now else {
            return
        }

        let identifier = followUpIdentifier(medicineID: medicineID, scheduledTimeKey: scheduledTimeKey)
        let content = UNMutableNotificationContent()
        content.title = "Quick medicine check"
        content.body = "💙 Just checking in — did you take \(medicineName)?"
        content.categoryIdentifier = RichNotificationController.categoryIdentifier
        content.sound = .default
        content.userInfo = [
            "medicineID": medicineID,
            "scheduledTime": ISO8601DateFormatter().string(from: scheduledAt),
            "scheduledTimeKey": scheduledTimeKey,
            "isMissedDoseFollowUp": true
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(followUpTime.timeIntervalSinceNow, 1),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
            setFollowUpPending(true, medicineID: medicineID, scheduledTimeKey: scheduledTimeKey, date: scheduledAt)
            debugLog("Follow-up scheduled id=\(identifier)")
            activeFollowUps.append(
                MissedDoseFollowUp(
                    notificationID: identifier,
                    medicineID: persistentMedicineID,
                    medicineName: medicineName,
                    scheduledAt: scheduledAt,
                    followUpFireAt: followUpTime,
                    isCancelled: false
                )
            )
        } catch {
            debugLog("Follow-up schedule failed: \(error)")
            return
        }
    }

    func cancelFollowUp(for medicine: Medicine, scheduledAt: Date) {
        cancelFollowUp(
            for: medicine.id.uuidString,
            scheduledTimeKey: AdaptiveReminderTimeKey.key(from: scheduledAt, calendar: calendar),
            date: scheduledAt
        )
    }

    func cancelFollowUp(for medicineID: String, scheduledTimeKey: String, date: Date) {
        let identifier = followUpIdentifier(medicineID: medicineID, scheduledTimeKey: scheduledTimeKey)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        setFollowUpPending(false, medicineID: medicineID, scheduledTimeKey: scheduledTimeKey, date: date)
        debugLog("Follow-up cancelled id=\(identifier)")
        for index in activeFollowUps.indices where activeFollowUps[index].notificationID == identifier {
            activeFollowUps[index].isCancelled = true
        }
    }

    func cancelAllFollowUps(for medicine: Medicine) async {
        await cancelAllFollowUps(for: medicine.id.uuidString)
    }

    func cancelAllFollowUps(for medicineID: String) async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let matchingIdentifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.contains(medicineID) && $0.hasPrefix("medicine_followup_") }

        guard !matchingIdentifiers.isEmpty else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: matchingIdentifiers)
        clearPendingKeys(for: medicineID)
        debugLog("All follow-ups cancelled for \(medicineID)")
        for index in activeFollowUps.indices where activeFollowUps[index].notificationID.contains(medicineID) {
            activeFollowUps[index].isCancelled = true
        }
    }

    func isFollowUpPending(medicineID: String, scheduledTimeKey: String, date: Date) -> Bool {
        defaults.bool(forKey: pendingKey(medicineID: medicineID, scheduledTimeKey: scheduledTimeKey, date: date))
    }

    private func activeFollowUps(for medicineID: String, scheduledTimeKey: String, date: Date) -> [MissedDoseFollowUp] {
        let identifierPrefix = followUpIdentifier(medicineID: medicineID, scheduledTimeKey: scheduledTimeKey)
        return activeFollowUps.filter { $0.notificationID == identifierPrefix }
    }

    private func followUpIdentifier(medicineID: String, scheduledTimeKey: String) -> String {
        MedicineNotificationIdentifier.followUp(medicineID: medicineID, scheduledTimeKey: scheduledTimeKey)
    }

    private func pendingKey(medicineID: String, scheduledTimeKey: String, date: Date) -> String {
        let day = calendar.startOfDay(for: date).formatted(.iso8601.year().month().day())
        return "medicine_followup_pending_\(medicineID)_\(scheduledTimeKey)_\(day)"
    }

    private func setFollowUpPending(_ isPending: Bool, medicineID: String, scheduledTimeKey: String, date: Date) {
        let key = pendingKey(medicineID: medicineID, scheduledTimeKey: scheduledTimeKey, date: date)
        if isPending {
            defaults.set(true, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private func clearPendingKeys(for medicineID: String) {
        let prefix = "medicine_followup_pending_\(medicineID)_"
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[MissedDoseFollowUpManager] \(message)")
        #endif
    }
}
