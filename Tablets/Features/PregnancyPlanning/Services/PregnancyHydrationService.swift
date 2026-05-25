import Foundation
import UserNotifications

enum PregnancyHydrationScheduleResult: Equatable {
    case scheduled
    case denied
    case failed(String)
}

struct PregnancyHydrationService {
    func scheduleHydrationReminders(for profile: PregnancyProfile) async -> PregnancyHydrationScheduleResult {
        guard await requestNotificationPermissionIfNeeded() else {
            return .denied
        }

        cancelAllHydrationReminders()
        let week = max(1, min(42, profile.currentWeek))

        for item in hydrationSchedule {
            let result = await scheduleDailyReminder(
                hour: item.hour,
                minute: item.minute,
                body: item.body + trimesterText(for: week),
                identifier: "pregnancy_hydration_\(item.hour)_\(item.minute)"
            )
            if result != .scheduled {
                cancelAllHydrationReminders()
                return result
            }
        }

        return .scheduled
    }

    func cancelAllHydrationReminders() {
        let fixedIdentifiers = hydrationSchedule.map { "pregnancy_hydration_\($0.hour)_\($0.minute)" } + ["pregnancy_hydration_nausea"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: fixedIdentifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: fixedIdentifiers)
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let quickIdentifiers = requests
                .map(\.identifier)
                .filter { $0.hasPrefix("pregnancy_hydration_quick_") }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: quickIdentifiers)
        }
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let quickIdentifiers = notifications
                .map(\.request.identifier)
                .filter { $0.hasPrefix("pregnancy_hydration_quick_") }
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: quickIdentifiers)
        }
    }

    func scheduleQuickReminder(minutes: Int) async -> PregnancyHydrationScheduleResult {
        guard await requestNotificationPermissionIfNeeded() else {
            return .denied
        }

        let safeMinutes = max(1, min(minutes, 240))
        let content = UNMutableNotificationContent()
        content.title = "Water reminder"
        content.body = "Time for a gentle hydration break. This is informational only — please follow your doctor's guidance."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(safeMinutes * 60), repeats: false)
        return await add(UNNotificationRequest(identifier: "pregnancy_hydration_quick_\(Date().timeIntervalSince1970)", content: content, trigger: trigger))
    }

    func handleSymptomLogged(_ symptoms: [String], isEnabled: Bool = true) {
        guard isEnabled else { return }
        let text = symptoms.joined(separator: " ").lowercased()
        guard text.contains("nausea") || text.contains("morning sickness") else { return }
        let content = UNMutableNotificationContent()
        content.title = "Gentle hydration check"
        content.body = "Feeling nauseous? Small sips of cold water or ginger tea may help. Please contact your doctor if nausea is severe."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
        Task {
            _ = await add(UNNotificationRequest(identifier: "pregnancy_hydration_nausea", content: content, trigger: trigger))
        }
    }

    private func scheduleDailyReminder(hour: Int, minute: Int, body: String, identifier: String) async -> PregnancyHydrationScheduleResult {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let content = UNMutableNotificationContent()
        content.title = "Hydration reminder"
        content.body = body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        return await add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    private func requestNotificationPermissionIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                debugLog("Hydration permission request failed: \(error)")
                return false
            }
        @unknown default:
            return false
        }
    }

    private func add(_ request: UNNotificationRequest) async -> PregnancyHydrationScheduleResult {
        do {
            try await UNUserNotificationCenter.current().add(request)
            return .scheduled
        } catch {
            debugLog("Hydration notification schedule failed: \(error)")
            return .failed(error.localizedDescription)
        }
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[PregnancyHydrationService] \(message)")
        #endif
    }

    private func trimesterText(for week: Int) -> String {
        if week <= 12 {
            return " Staying hydrated can help with morning sickness."
        }
        if week >= 28 {
            return " Extra hydration helps reduce swelling in late pregnancy."
        }
        return ""
    }

    private var hydrationSchedule: [(hour: Int, minute: Int, body: String)] {
        [
            (8, 0, "Good morning. Stay hydrated today. Aim for 8-10 glasses of water."),
            (10, 30, "Time for a water break. Staying hydrated helps with swelling and energy."),
            (12, 30, "Lunchtime hydration reminder. Have a glass of water with your meal."),
            (15, 0, "Afternoon water reminder. Your baby needs you hydrated."),
            (18, 0, "Evening hydration check. A few more sips before dinner."),
            (20, 30, "Last hydration reminder for today. Well done for taking care of yourself.")
        ]
    }
}
