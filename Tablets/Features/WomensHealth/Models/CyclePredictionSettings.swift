import Foundation
import SwiftData

@Model
final class CyclePredictionSettings {
    @Attribute(.unique) var id: UUID
    var averageCycleLengthDays: Int
    var averagePeriodDurationDays: Int
    var periodExpectedReminderEnabled: Bool
    var ovulationReminderEnabled: Bool
    var pmsReminderEnabled: Bool
    var periodMedicineReminderEnabled: Bool
    var doctorVisitReminderEnabled: Bool
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        averageCycleLengthDays: Int = 28,
        averagePeriodDurationDays: Int = 5,
        periodExpectedReminderEnabled: Bool = true,
        ovulationReminderEnabled: Bool = false,
        pmsReminderEnabled: Bool = true,
        periodMedicineReminderEnabled: Bool = false,
        doctorVisitReminderEnabled: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.averageCycleLengthDays = averageCycleLengthDays
        self.averagePeriodDurationDays = averagePeriodDurationDays
        self.periodExpectedReminderEnabled = periodExpectedReminderEnabled
        self.ovulationReminderEnabled = ovulationReminderEnabled
        self.pmsReminderEnabled = pmsReminderEnabled
        self.periodMedicineReminderEnabled = periodMedicineReminderEnabled
        self.doctorVisitReminderEnabled = doctorVisitReminderEnabled
        self.updatedAt = updatedAt
    }
}
