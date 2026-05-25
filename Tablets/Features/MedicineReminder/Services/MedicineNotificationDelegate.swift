import Foundation
import SwiftData
import UserNotifications
import WidgetKit

@MainActor
final class MedicineNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = MedicineNotificationDelegate()

    private var modelContext: ModelContext?
    private let calendar = Calendar.current
    private let isoFormatter = ISO8601DateFormatter()

    private override init() {
        super.init()
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        debugLog("Delegate configured")
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await MainActor.run {
            handleDeliveredNotification(notification.request)
        }
        return [.banner, .sound, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            handleNotificationResponse(response)
        }
    }

    private func handleDeliveredNotification(_ request: UNNotificationRequest) {
        guard let payload = MedicineNotificationPayload(userInfo: request.content.userInfo) else {
            debugLog("Missing userInfo keys for id=\(request.identifier)")
            return
        }

        if payload.isMissedDoseFollowUp {
            debugLog("Follow-up delivered id=\(request.identifier)")
            return
        }

        debugLog("Primary reminder fired id=\(request.identifier)")
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            await self?.scheduleFollowUpIfNeeded(payload: payload)
        }
    }

    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let request = response.notification.request
        guard let payload = MedicineNotificationPayload(userInfo: request.content.userInfo) else {
            debugLog("Tapped notification missing userInfo id=\(request.identifier)")
            return
        }

        if payload.isMissedDoseFollowUp {
            debugLog("Follow-up tapped id=\(request.identifier)")
            routeToMedicineReminder(payload: payload)
        } else if handleAction(response.actionIdentifier, payload: payload) {
            debugLog("Handled notification action \(response.actionIdentifier) id=\(request.identifier)")
        } else {
            debugLog("Primary reminder tapped id=\(request.identifier)")
            routeToMedicineReminder(payload: payload)
        }
    }

    private func handleAction(_ actionIdentifier: String, payload: MedicineNotificationPayload) -> Bool {
        switch actionIdentifier {
        case RichNotificationController.takenActionIdentifier:
            saveLog(payload: payload, status: .taken)
            return true
        case RichNotificationController.snoozeActionIdentifier:
            saveLog(payload: payload, status: .snoozed)
            scheduleSnooze(payload: payload)
            return true
        case RichNotificationController.skipActionIdentifier:
            saveLog(payload: payload, status: .skipped)
            return true
        default:
            return false
        }
    }

    private func saveLog(payload: MedicineNotificationPayload, status: MedicineLogStatus) {
        guard let modelContext,
              let uuid = UUID(uuidString: payload.medicineID)
        else {
            debugLog("Cannot save action log; missing context or bad medicineID")
            return
        }

        var descriptor = FetchDescriptor<Medicine>(
            predicate: #Predicate<Medicine> { $0.id == uuid }
        )
        descriptor.fetchLimit = 1

        do {
            guard let medicine = try modelContext.fetch(descriptor).first else {
                debugLog("Cannot save action log; medicine not found")
                return
            }
            let scheduledAt = payload.scheduledTime ?? Date()
            let log = MedicineLog(
                medicine: medicine,
                scheduledTime: scheduledAt,
                takenTime: status == .taken ? Date() : nil,
                status: status
            )
            modelContext.insert(log)
            try modelContext.save()
            MissedDoseFollowUpManager(modelContext: modelContext).cancelFollowUp(
                for: payload.medicineID,
                scheduledTimeKey: payload.scheduledTimeKey,
                date: scheduledAt
            )
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            debugLog("Notification action save failed: \(error)")
        }
    }

    private func scheduleSnooze(payload: MedicineNotificationPayload) {
        guard let medicineName = fetchMedicineName(medicineID: payload.medicineID) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time for \(medicineName)"
        content.body = "Just checking in again."
        content.sound = .default
        content.categoryIdentifier = RichNotificationController.categoryIdentifier
        content.userInfo = [
            "medicineID": payload.medicineID,
            "scheduledTime": isoFormatter.string(from: Date()),
            "scheduledTimeKey": payload.scheduledTimeKey,
            "isMissedDoseFollowUp": false
        ]

        let request = UNNotificationRequest(
            identifier: "medicine_snooze_\(payload.medicineID)_\(payload.scheduledTimeKey)_\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false)
        )

        Task {
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                debugLog("Snooze scheduling failed: \(error)")
            }
        }
    }

    private func routeToMedicineReminder(payload: MedicineNotificationPayload) {
        let userInfo = [
            "medicineID": payload.medicineID,
            "scheduledTimeKey": payload.scheduledTimeKey
        ]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            NotificationCenter.default.post(
                name: VoiceNavigationNotification.openMedicineReminder,
                object: nil,
                userInfo: userInfo
            )
        }
    }

    private func scheduleFollowUpIfNeeded(payload: MedicineNotificationPayload) async {
        guard let modelContext else {
            debugLog("No modelContext; cannot check follow-up")
            return
        }

        let checkDate = payload.scheduledTime ?? .now
        let checker = MedicineDoseLogChecker(modelContext: modelContext)
        let isLogged = await checker.hasLoggedDose(
            medicineID: payload.medicineID,
            scheduledTimeKey: payload.scheduledTimeKey,
            on: checkDate
        )

        guard isLogged == false else {
            debugLog("Follow-up skipped because dose already logged for \(payload.medicineID) \(payload.scheduledTimeKey)")
            return
        }

        let medicineName = fetchMedicineName(medicineID: payload.medicineID) ?? "your medicine"
        let manager = MissedDoseFollowUpManager(modelContext: modelContext)
        await manager.scheduleFollowUp(
            for: payload.medicineID,
            scheduledTimeKey: payload.scheduledTimeKey,
            medicineName: medicineName,
            scheduledAt: checkDate
        )
    }

    private func fetchMedicineName(medicineID: String) -> String? {
        guard let uuid = UUID(uuidString: medicineID), let modelContext else { return nil }
        var descriptor = FetchDescriptor<Medicine>(
            predicate: #Predicate<Medicine> { $0.id == uuid }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first?.name
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[MedicineNotificationDelegate] \(message)")
        #endif
    }
}

struct MedicineNotificationPayload {
    let medicineID: String
    let scheduledTime: Date?
    let scheduledTimeKey: String
    let isMissedDoseFollowUp: Bool

    init?(userInfo: [AnyHashable: Any]) {
        guard let medicineID = userInfo["medicineID"] as? String,
              let scheduledTimeKey = userInfo["scheduledTimeKey"] as? String
        else {
            return nil
        }

        self.medicineID = medicineID
        self.scheduledTimeKey = scheduledTimeKey
        self.isMissedDoseFollowUp = (userInfo["isMissedDoseFollowUp"] as? Bool) ?? false

        if let scheduledTimeText = userInfo["scheduledTime"] as? String {
            self.scheduledTime = ISO8601DateFormatter().date(from: scheduledTimeText)
        } else {
            self.scheduledTime = nil
        }
    }
}

enum MedicineNotificationIdentifier {
    static func primary(medicineID: String, scheduledTimeKey: String) -> String {
        "medicine_\(medicineID)_\(scheduledTimeKey)"
    }

    static func followUp(medicineID: String, scheduledTimeKey: String) -> String {
        "medicine_followup_\(medicineID)_\(scheduledTimeKey)"
    }
}
