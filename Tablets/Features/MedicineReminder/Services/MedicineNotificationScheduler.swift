import Foundation
import UserNotifications

@MainActor
struct MedicineNotificationScheduler {
    struct PendingMedicineNotification: Identifiable {
        let id: String
        let medicineName: String
        let title: String
        let body: String
        let triggerType: String
        let fireDate: Date?
        let repeats: Bool
        let medicineID: String
        let scheduledTime: String
        let scheduledTimeKey: String
        let sound: String
        let authorizationStatus: String
    }

    private let notificationCenter: UNUserNotificationCenter
    private let calendar: Calendar

    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        calendar: Calendar = .current
    ) {
        self.notificationCenter = notificationCenter
        self.calendar = calendar
    }

    func requestPermissionIfNeeded() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        debugLog("Authorization status before scheduling: \(authorizationStatusText(settings.authorizationStatus))")
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                debugLog("Permission request failed: \(error)")
                return false
            }
        @unknown default:
            return false
        }
    }

    #if DEBUG
    func authorizationStatusDescription() async -> String {
        let settings = await notificationCenter.notificationSettings()
        return authorizationStatusText(settings.authorizationStatus)
    }

    func scheduleTestNotificationIn10Seconds() async -> Bool {
        guard await requestPermissionIfNeeded() else {
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = "Tablets Test Reminder"
        content.body = "This is a test medicine reminder."
        content.sound = .default
        content.userInfo = [
            "isDebugTestNotification": true
        ]

        let request = UNNotificationRequest(
            identifier: "tablets_test_reminder_\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        )

        do {
            try await notificationCenter.add(request)
            debugLog("Scheduled 10-second test notification id=\(request.identifier)")
            return true
        } catch {
            debugLog("Test notification failed: \(error)")
            return false
        }
    }
    #endif

    func scheduleNotifications(for medicine: Medicine) async -> Bool {
        guard medicine.isActive else {
            await cancelNotifications(for: medicine)
            return true
        }

        let hasPermission = await requestPermissionIfNeeded()
        guard hasPermission else {
            debugLog("Notifications not authorized for \(medicine.name)")
            return false
        }

        await cancelNotifications(for: medicine)
        let times = medicine.times.isEmpty ? [Date()] : medicine.times
        var didScheduleAll = true

        for time in times {
            do {
                try await notificationCenter.add(request(for: medicine, time: time))
                debugLog("Scheduled \(MedicineNotificationIdentifier.primary(medicineID: medicine.id.uuidString, scheduledTimeKey: scheduledTimeKey(from: time)))")
            } catch {
                didScheduleAll = false
                debugLog("Schedule failed for \(medicine.name): \(error)")
            }
        }

        return didScheduleAll
    }

    func rescheduleNotifications(for medicine: Medicine) async -> Bool {
        await scheduleNotifications(for: medicine)
    }

    func cancelNotifications(for medicine: Medicine) async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let matchingIdentifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.contains(medicine.id.uuidString) }

        guard !matchingIdentifiers.isEmpty else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: matchingIdentifiers)
        debugLog("Cancelled \(matchingIdentifiers.count) notifications for \(medicine.name)")
    }

    #if DEBUG
    func pendingMedicineNotifications() async -> [PendingMedicineNotification] {
        let requests = await notificationCenter.pendingNotificationRequests()
        let settings = await notificationCenter.notificationSettings()
        let status = authorizationStatusText(settings.authorizationStatus)
        return requests
            .map { request in
                PendingMedicineNotification(
                    id: request.identifier,
                    medicineName: request.content.title.replacingOccurrences(of: "Time for ", with: ""),
                    title: request.content.title,
                    body: request.content.body,
                    triggerType: triggerType(for: request.trigger),
                    fireDate: nextFireDate(for: request.trigger),
                    repeats: (request.trigger as? UNCalendarNotificationTrigger)?.repeats ?? (request.trigger as? UNTimeIntervalNotificationTrigger)?.repeats ?? false,
                    medicineID: request.content.userInfo["medicineID"] as? String ?? "-",
                    scheduledTime: request.content.userInfo["scheduledTime"] as? String ?? "-",
                    scheduledTimeKey: request.content.userInfo["scheduledTimeKey"] as? String ?? "-",
                    sound: request.content.sound == nil ? "None" : "Set",
                    authorizationStatus: status
                )
            }
            .sorted { ($0.fireDate ?? .distantFuture) < ($1.fireDate ?? .distantFuture) }
    }
    #endif

    private func request(for medicine: Medicine, time: Date) -> UNNotificationRequest {
        let medicineID = medicine.id.uuidString
        let timeKey = scheduledTimeKey(from: time)
        let scheduledDate = nextScheduledDate(for: medicine, time: time)

        let content = UNMutableNotificationContent()
        content.title = "Time for \(medicine.name)"
        content.body = bodyText(for: medicine)
        content.sound = .default
        content.categoryIdentifier = "MEDICINE_REMINDER"
        content.userInfo = [
            "medicineID": medicineID,
            "scheduledTime": ISO8601DateFormatter().string(from: scheduledDate),
            "scheduledTimeKey": timeKey,
            "isMissedDoseFollowUp": false
        ]

        let trigger = trigger(for: medicine, scheduledDate: scheduledDate)
        return UNNotificationRequest(
            identifier: MedicineNotificationIdentifier.primary(medicineID: medicineID, scheduledTimeKey: timeKey),
            content: content,
            trigger: trigger
        )
    }

    private func bodyText(for medicine: Medicine) -> String {
        let instruction = medicine.instruction.title
        guard !medicine.dosage.isEmpty else { return instruction }
        return "\(medicine.dosage) • \(instruction)"
    }

    private func trigger(for medicine: Medicine, scheduledDate: Date) -> UNNotificationTrigger {
        let timeInterval = scheduledDate.timeIntervalSinceNow
        if timeInterval > 0, timeInterval <= 120 {
            debugLog("Using near-future time interval trigger: \(timeInterval)s")
            return UNTimeIntervalNotificationTrigger(timeInterval: max(timeInterval, 5), repeats: false)
        }

        var components = calendar.dateComponents([.hour, .minute], from: scheduledDate)

        switch medicine.frequencyType {
        case .daily:
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case .weekly:
            components.weekday = calendar.component(.weekday, from: scheduledDate)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case .alternateDays, .custom:
            // The current model stores the frequency label but not a full recurrence rule.
            // Schedule the next safe reminder now; a future scheduler can roll this forward.
            components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
    }

    private func nextScheduledDate(for medicine: Medicine, time: Date) -> Date {
        let base = max(medicine.startDate, .now)
        var components = calendar.dateComponents([.year, .month, .day], from: base)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        let candidate = calendar.date(from: components) ?? time

        guard candidate <= .now else { return candidate }

        switch medicine.frequencyType {
        case .daily, .custom:
            return calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        case .alternateDays:
            return calendar.date(byAdding: .day, value: 2, to: candidate) ?? candidate
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: candidate) ?? candidate
        }
    }

    private func scheduledTimeKey(from date: Date) -> String {
        AdaptiveReminderTimeKey.key(from: date, calendar: calendar)
    }

    private func nextFireDate(for trigger: UNNotificationTrigger?) -> Date? {
        if let calendarTrigger = trigger as? UNCalendarNotificationTrigger {
            return calendarTrigger.nextTriggerDate()
        }
        if let intervalTrigger = trigger as? UNTimeIntervalNotificationTrigger {
            return Date().addingTimeInterval(intervalTrigger.timeInterval)
        }
        return nil
    }

    private func triggerType(for trigger: UNNotificationTrigger?) -> String {
        switch trigger {
        case is UNCalendarNotificationTrigger:
            return "Calendar"
        case is UNTimeIntervalNotificationTrigger:
            return "Time interval"
        default:
            return "Unknown"
        }
    }

    private func authorizationStatusText(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not determined"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[MedicineNotificationScheduler] \(message)")
        #endif
    }
}
