import Foundation
import SwiftData

struct AdaptiveReminderPreferenceStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isEnabled(medicineID: PersistentIdentifier, scheduledTime: DateComponents) -> Bool {
        let key = preferenceKey(medicineID: medicineID, scheduledTime: scheduledTime)
        guard defaults.object(forKey: key) != nil else { return true }
        return defaults.bool(forKey: key)
    }

    func isEnabled(medicineID: PersistentIdentifier, scheduledTime: Date, calendar: Calendar = .current) -> Bool {
        isEnabled(medicineID: medicineID, scheduledTime: calendar.dateComponents([.hour, .minute], from: scheduledTime))
    }

    func setEnabled(_ isEnabled: Bool, medicineID: PersistentIdentifier, scheduledTime: DateComponents) {
        defaults.set(isEnabled, forKey: preferenceKey(medicineID: medicineID, scheduledTime: scheduledTime))
    }

    func setEnabled(_ isEnabled: Bool, medicineID: PersistentIdentifier, scheduledTime: Date, calendar: Calendar = .current) {
        setEnabled(isEnabled, medicineID: medicineID, scheduledTime: calendar.dateComponents([.hour, .minute], from: scheduledTime))
    }

    func reset(medicineID: PersistentIdentifier, scheduledTime: DateComponents) {
        defaults.removeObject(forKey: preferenceKey(medicineID: medicineID, scheduledTime: scheduledTime))
    }

    func reset(medicineID: PersistentIdentifier, scheduledTime: Date, calendar: Calendar = .current) {
        reset(medicineID: medicineID, scheduledTime: calendar.dateComponents([.hour, .minute], from: scheduledTime))
    }

    func resetAll(for medicineID: PersistentIdentifier) {
        let prefix = "adaptive_reminder_enabled_\(String(describing: medicineID))_"
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }

    private func preferenceKey(medicineID: PersistentIdentifier, scheduledTime: DateComponents) -> String {
        "adaptive_reminder_enabled_\(String(describing: medicineID))_\(AdaptiveReminderTimeKey.key(from: scheduledTime))"
    }
}
