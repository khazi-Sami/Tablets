import Foundation
import SwiftData

@Model
final class PregnancyProfile {
    @Attribute(.unique) var id: UUID = UUID()
    var lastMenstrualPeriodDate: Date = Date()
    var dueDate: Date = Date()
    var dueDateIsManual: Bool = false
    var pregnancyStartedAt: Date = Date()
    var isActive: Bool = true
    var babyNickname: String?
    var notes: String?
    var createdAt: Date = Date()
    var hydrationRemindersEnabled: Bool?
    var supplementRemindersEnabled: Bool?
    var lastOpenedAt: Date?

    init(
        id: UUID = UUID(),
        lastMenstrualPeriodDate: Date,
        dueDate: Date,
        dueDateIsManual: Bool = false,
        pregnancyStartedAt: Date = .now,
        isActive: Bool = true,
        babyNickname: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        hydrationRemindersEnabled: Bool = true,
        supplementRemindersEnabled: Bool = true,
        lastOpenedAt: Date? = nil
    ) {
        self.id = id
        self.lastMenstrualPeriodDate = lastMenstrualPeriodDate
        self.dueDate = dueDate
        self.dueDateIsManual = dueDateIsManual
        self.pregnancyStartedAt = pregnancyStartedAt
        self.isActive = isActive
        self.babyNickname = babyNickname
        self.notes = notes
        self.createdAt = createdAt
        self.hydrationRemindersEnabled = hydrationRemindersEnabled
        self.supplementRemindersEnabled = supplementRemindersEnabled
        self.lastOpenedAt = lastOpenedAt
    }

    var currentWeek: Int {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastMenstrualPeriodDate), to: Calendar.current.startOfDay(for: .now)).day ?? 0
        return max(1, min(42, (days / 7) + 1))
    }
}
