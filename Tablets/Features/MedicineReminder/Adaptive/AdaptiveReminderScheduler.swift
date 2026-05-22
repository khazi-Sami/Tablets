import Foundation
import Observation
import SwiftData
import UserNotifications

@Observable
@MainActor
final class AdaptiveReminderScheduler {
    private let engine: AdaptiveReminderEngine
    private let modelContext: ModelContext
    private let config: AdaptiveReminderConfig
    private let notificationCenter: UNUserNotificationCenter
    private let calendar: Calendar

    init(
        engine: AdaptiveReminderEngine,
        modelContext: ModelContext,
        config: AdaptiveReminderConfig? = nil,
        notificationCenter: UNUserNotificationCenter = .current(),
        calendar: Calendar = .current
    ) {
        self.engine = engine
        self.modelContext = modelContext
        self.config = config ?? AdaptiveReminderConfig()
        self.notificationCenter = notificationCenter
        self.calendar = calendar
    }

    func applyAdaptiveShifts() async -> [AdaptiveShift] {
        let patterns = await engine.analyzePatternsForAllMedicines()
        var applied: [AdaptiveShift] = []

        for pattern in patterns where pattern.confidenceLevel != .insufficient {
            let shiftMinutes = pattern.averageActualMinuteOffset
            guard abs(shiftMinutes) >= config.minShiftMinutes,
                  let originalTime = nextDate(from: pattern.scheduledTime),
                  let shiftedCandidate = calendar.date(byAdding: .minute, value: shiftMinutes, to: originalTime)
            else {
                continue
            }

            let shiftedTime = futureSafeDate(for: shiftedCandidate)
            await rescheduleNotification(
                medicineID: pattern.medicineID,
                from: originalTime,
                to: shiftedTime
            )
            applied.append(
                AdaptiveShift(
                    medicineID: pattern.medicineID,
                    medicineName: pattern.medicineName,
                    originalTime: originalTime,
                    shiftedTime: shiftedTime,
                    shiftMinutes: shiftMinutes,
                    appliedAt: .now
                )
            )
        }

        return applied
    }

    func rescheduleNotification(
        medicineID: PersistentIdentifier,
        from originalTime: Date,
        to shiftedTime: Date
    ) async {
        let medicineIDText = String(describing: medicineID)
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let matchingRequests = pendingRequests.filter { $0.identifier.contains(medicineIDText) }

        for request in matchingRequests {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [request.identifier])

            let content = mutableContent(from: request.content)
            let components = calendar.dateComponents([.hour, .minute], from: futureSafeDate(for: shiftedTime))
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let newRequest = UNNotificationRequest(
                identifier: request.identifier,
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(newRequest)
            } catch {
                continue
            }
        }
    }

    func adaptiveIdentifier(for medicineID: PersistentIdentifier, scheduledTime: DateComponents) -> String {
        "adaptive_\(String(describing: medicineID))_\(AdaptiveReminderTimeKey.key(from: scheduledTime))"
    }

    func adaptiveIdentifier(for medicineID: PersistentIdentifier, scheduledTime: Date) -> String {
        adaptiveIdentifier(
            for: medicineID,
            scheduledTime: calendar.dateComponents([.hour, .minute], from: scheduledTime)
        )
    }

    func originalIdentifier(for medicineID: PersistentIdentifier, scheduledTime: DateComponents) -> String {
        "medicine_\(String(describing: medicineID))_\(AdaptiveReminderTimeKey.key(from: scheduledTime))"
    }

    func originalIdentifier(for medicineID: PersistentIdentifier, scheduledTime: Date) -> String {
        originalIdentifier(
            for: medicineID,
            scheduledTime: calendar.dateComponents([.hour, .minute], from: scheduledTime)
        )
    }

    func resetSchedulesToOriginal(medicineID: PersistentIdentifier, scheduledTime: DateComponents) async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let adaptiveID = adaptiveIdentifier(for: medicineID, scheduledTime: scheduledTime)
        let originalID = originalIdentifier(for: medicineID, scheduledTime: scheduledTime)
        let matchingIdentifiers = pendingRequests
            .map(\.identifier)
            .filter { $0 == adaptiveID || $0 == originalID || ($0.contains(String(describing: medicineID)) && $0.contains(AdaptiveReminderTimeKey.key(from: scheduledTime))) }

        guard !matchingIdentifiers.isEmpty else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: matchingIdentifiers)
    }

    func resetToOriginalSchedule(for medicine: Medicine) async {
        let medicineID = medicine.persistentModelID
        let medicineIDText = String(describing: medicineID)
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        let matchingRequests = pendingRequests.filter { $0.identifier.contains(medicineIDText) }
        let sortedTimes = medicine.times.sorted()

        guard !matchingRequests.isEmpty, !sortedTimes.isEmpty else { return }

        for (index, request) in matchingRequests.enumerated() {
            let originalTime = sortedTimes[min(index, sortedTimes.count - 1)]
            let components = calendar.dateComponents([.hour, .minute], from: futureSafeDate(for: originalTime))
            let content = mutableContent(from: request.content)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let newRequest = UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger)

            notificationCenter.removePendingNotificationRequests(withIdentifiers: [request.identifier])
            do {
                try await notificationCenter.add(newRequest)
            } catch {
                continue
            }
        }
    }

    func resetAllToOriginalSchedule() async {
        let descriptor = FetchDescriptor<Medicine>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.name)]
        )
        guard let medicines = try? modelContext.fetch(descriptor) else { return }
        for medicine in medicines {
            await resetToOriginalSchedule(for: medicine)
        }
    }

    private func nextDate(from components: DateComponents) -> Date? {
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: .now)
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        return calendar.date(from: dateComponents)
    }

    private func futureSafeDate(for date: Date) -> Date {
        guard date <= .now,
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: date)
        else {
            return date
        }
        return tomorrow
    }

    private func mutableContent(from content: UNNotificationContent) -> UNMutableNotificationContent {
        let mutable = UNMutableNotificationContent()
        mutable.title = content.title
        mutable.subtitle = content.subtitle
        mutable.body = content.body
        mutable.badge = content.badge
        mutable.sound = content.sound
        mutable.categoryIdentifier = content.categoryIdentifier
        mutable.threadIdentifier = content.threadIdentifier
        mutable.userInfo = content.userInfo
        mutable.attachments = content.attachments
        if #available(iOS 15.0, *) {
            mutable.interruptionLevel = content.interruptionLevel
            mutable.relevanceScore = content.relevanceScore
        }
        return mutable
    }
}
