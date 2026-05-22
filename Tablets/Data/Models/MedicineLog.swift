import Foundation
import SwiftData

@Model
final class MedicineLog {
    @Attribute(.unique) var id: UUID
    var medicine: Medicine?
    var scheduledTime: Date
    var takenTime: Date?
    var statusRawValue: String

    var status: MedicineLogStatus {
        get { MedicineLogStatus(rawValue: statusRawValue) ?? .missed }
        set { statusRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        medicine: Medicine? = nil,
        scheduledTime: Date,
        takenTime: Date? = nil,
        status: MedicineLogStatus = .missed
    ) {
        self.id = id
        self.medicine = medicine
        self.scheduledTime = scheduledTime
        self.takenTime = takenTime
        self.statusRawValue = status.rawValue
    }
}

enum MedicineLogStatus: String, Codable, CaseIterable, Identifiable {
    case taken
    case missed
    case skipped
    case snoozed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .taken:
            return "Taken"
        case .missed:
            return "Missed"
        case .skipped:
            return "Skipped"
        case .snoozed:
            return "Snoozed"
        }
    }
}
