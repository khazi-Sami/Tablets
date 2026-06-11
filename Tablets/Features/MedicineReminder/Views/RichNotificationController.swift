import Foundation

enum RichNotificationController {
    static let categoryIdentifier = "MEDICINE_REMINDER"
    static let takenActionIdentifier = "medicine_taken"
    static let snoozeActionIdentifier = "medicine_snooze"
    static let skipActionIdentifier = "medicine_skip"
    static let openAppActionIdentifier = "medicine_open_app"

    // A full custom notification appearance requires a Notification Content Extension target.
    // This enum keeps the identifiers and SwiftUI surface ready without changing the app's
    // notification architecture.
}
