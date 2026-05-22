import Foundation
import SwiftData

@Model
final class FamilyMedicineAssignment {
    @Attribute(.unique) var id: UUID
    var member: FamilyMember?
    var medicine: Medicine?
    var reminderNote: String
    var caretakerNote: String
    var createdAt: Date
    var isActive: Bool

    init(
        id: UUID = UUID(),
        member: FamilyMember? = nil,
        medicine: Medicine? = nil,
        reminderNote: String = "",
        caretakerNote: String = "",
        createdAt: Date = .now,
        isActive: Bool = true
    ) {
        self.id = id
        self.member = member
        self.medicine = medicine
        self.reminderNote = reminderNote
        self.caretakerNote = caretakerNote
        self.createdAt = createdAt
        self.isActive = isActive
    }
}
