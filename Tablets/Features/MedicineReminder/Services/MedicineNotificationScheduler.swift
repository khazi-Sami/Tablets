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
        configureMedicineNotificationCategory()
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
        content.title = "BanyAI Test Reminder"
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
        guard medicine.isActive, HealthAppIntegrityChecker.isValidMedicine(medicine) else {
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
        await cancelNotifications(forMedicineID: medicine.id.uuidString, medicineName: medicine.name)
    }

    func cancelNotifications(forMedicineID medicineID: String, medicineName: String? = nil) async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let matchingIdentifiers = pendingRequests
            .filter { request in
                notificationMedicineID(from: request) == medicineID ||
                request.identifier.contains(medicineID)
            }
            .map(\.identifier)

        guard !matchingIdentifiers.isEmpty else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: matchingIdentifiers)
        debugLog("Cancelled \(matchingIdentifiers.count) notifications for \(medicineName ?? medicineID)")
    }

    func cancelAllMedicineNotifications() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let matchingIdentifiers = pendingRequests
            .filter(isMedicineNotification)
            .map(\.identifier)

        guard !matchingIdentifiers.isEmpty else {
            debugLog("No medicine notifications to cancel")
            return
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: matchingIdentifiers)
        debugLog("Cancelled all medicine notifications: \(matchingIdentifiers.count)")
    }

    func cleanupOrphanedMedicineNotifications(activeMedicineIDs: Set<String>) async -> Int {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let orphanIdentifiers = pendingRequests.compactMap { request -> String? in
            guard isMedicineNotification(request) else { return nil }
            guard let medicineID = notificationMedicineID(from: request) else {
                return request.identifier
            }
            return activeMedicineIDs.contains(medicineID) ? nil : request.identifier
        }

        debugLog("Orphan notifications found: \(orphanIdentifiers.count)")
        guard orphanIdentifiers.isEmpty == false else {
            return 0
        }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: orphanIdentifiers)
        debugLog("Orphan notifications removed: \(orphanIdentifiers.joined(separator: ", "))")
        return orphanIdentifiers.count
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
        let text = notificationText(for: medicine, scheduledDate: scheduledDate)
        content.title = text.title
        content.body = text.body
        content.sound = .default
        content.categoryIdentifier = RichNotificationController.categoryIdentifier
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

    private func notificationText(for medicine: Medicine, scheduledDate: Date) -> (title: String, body: String) {
        let displayName = medicineDisplayName(medicine)
        let hour = calendar.component(.hour, from: scheduledDate)
        let title: String
        if hour < 12 {
            title = "Good morning!"
        } else if hour < 17 {
            title = "Medicine reminder"
        } else {
            title = "Evening medicine"
        }

        let body: String
        if hour < 12 {
            body = "🌅 Good morning! Time for \(displayName)."
        } else if hour < 17 {
            body = "☀️ Medicine reminder: \(displayName)."
        } else {
            body = "🌙 Time for your evening medicine."
        }

        if medicine.stockCount > 0, medicine.stockCount <= medicine.lowStockAlertCount {
            return (title, "⚠️ \(medicine.name) is running low. Only \(medicine.stockCount) tablets left.")
        }
        return (title, body)
    }

    private func medicineDisplayName(_ medicine: Medicine) -> String {
        let dosage = medicine.dosage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !dosage.isEmpty else { return medicine.name }
        return "\(medicine.name) \(dosage)"
    }

    private func configureMedicineNotificationCategory() {
        let taken = UNNotificationAction(
            identifier: RichNotificationController.takenActionIdentifier,
            title: "Taken",
            options: [.foreground, .authenticationRequired]
        )
        let snooze = UNNotificationAction(
            identifier: RichNotificationController.snoozeActionIdentifier,
            title: "Snooze 10 min",
            options: [.foreground]
        )
        let openApp = UNNotificationAction(
            identifier: RichNotificationController.openAppActionIdentifier,
            title: "Open App",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: RichNotificationController.categoryIdentifier,
            actions: [taken, snooze, openApp],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        notificationCenter.setNotificationCategories([category])
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

    private func isMedicineNotification(_ request: UNNotificationRequest) -> Bool {
        request.identifier.hasPrefix("medicine_") ||
        request.identifier.hasPrefix("medicine_followup_") ||
        request.identifier.hasPrefix("medicine_snooze_") ||
        request.content.userInfo["medicineID"] != nil
    }

    private func notificationMedicineID(from request: UNNotificationRequest) -> String? {
        if let medicineID = request.content.userInfo["medicineID"] as? String {
            return medicineID
        }

        let identifier = request.identifier
        if identifier.hasPrefix("medicine_followup_") {
            let remainder = identifier.dropFirst("medicine_followup_".count)
            return remainder.split(separator: "_").first.map(String.init)
        }
        if identifier.hasPrefix("medicine_snooze_") {
            let remainder = identifier.dropFirst("medicine_snooze_".count)
            return remainder.split(separator: "_").first.map(String.init)
        }
        if identifier.hasPrefix("medicine_") {
            let remainder = identifier.dropFirst("medicine_".count)
            return remainder.split(separator: "_").first.map(String.init)
        }
        return nil
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
