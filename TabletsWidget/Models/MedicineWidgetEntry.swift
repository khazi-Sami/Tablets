import Foundation
import WidgetKit

struct MedicineWidgetEntry: TimelineEntry {
    let date: Date
    let takenCount: Int
    let pendingCount: Int
    let skippedCount: Int
    let adherencePercent: Double
    let adherenceTrend: String?
    let nextMedicineName: String?
    let nextMedicineDosage: String?
    let nextMedicineInstruction: String?
    let nextMedicineID: String?
    let timeRemaining: String?
    let isOverdue: Bool
    let upcomingMedicines: [UpcomingMedicine]
    let adaptiveInsight: String?
    let hasAnyMedicines: Bool
    let hasMedicinesDueToday: Bool
    let errorMessage: String?

    static let placeholder = MedicineWidgetEntry(
        date: .now,
        takenCount: 2,
        pendingCount: 1,
        skippedCount: 0,
        adherencePercent: 67,
        adherenceTrend: nil,
        nextMedicineName: "Aspirin",
        nextMedicineDosage: "500 mg",
        nextMedicineInstruction: "With food",
        nextMedicineID: nil,
        timeRemaining: "45 min",
        isOverdue: false,
        upcomingMedicines: [
            UpcomingMedicine(time: "2:00 PM", name: "SUP...", status: "pending"),
            UpcomingMedicine(time: "6:00 PM", name: "Sep...", status: "pending")
        ],
        adaptiveInsight: "You usually take this 10 mins later",
        hasAnyMedicines: true,
        hasMedicinesDueToday: true,
        errorMessage: nil
    )
}

struct UpcomingMedicine: Hashable {
    let time: String
    let name: String
    let status: String
}
