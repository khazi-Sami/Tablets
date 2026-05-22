import Foundation
import SwiftData

@Model
final class FamilyMember {
    @Attribute(.unique) var id: UUID
    var name: String
    var relationshipRawValue: String
    var age: Int
    var avatarSymbol: String
    var gradientRawValue: String
    var notes: String
    var createdAt: Date
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \FamilyMedicineAssignment.member)
    var medicineAssignments: [FamilyMedicineAssignment] = []

    var relationship: FamilyRelationship {
        get { FamilyRelationship(rawValue: relationshipRawValue) ?? .mother }
        set { relationshipRawValue = newValue.rawValue }
    }

    var gradient: FamilyAvatarGradient {
        get { FamilyAvatarGradient(rawValue: gradientRawValue) ?? .sunrise }
        set { gradientRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        relationship: FamilyRelationship,
        age: Int = 0,
        avatarSymbol: String = "person.fill",
        gradient: FamilyAvatarGradient = .sunrise,
        notes: String = "",
        createdAt: Date = .now,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.relationshipRawValue = relationship.rawValue
        self.age = age
        self.avatarSymbol = avatarSymbol
        self.gradientRawValue = gradient.rawValue
        self.notes = notes
        self.createdAt = createdAt
        self.isActive = isActive
    }
}

enum FamilyRelationship: String, Codable, CaseIterable, Identifiable {
    case mother
    case father
    case child
    case husband
    case wife
    case grandparent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mother: return "Mother"
        case .father: return "Father"
        case .child: return "Child"
        case .husband: return "Husband"
        case .wife: return "Wife"
        case .grandparent: return "Grandparent"
        }
    }
}

enum FamilyAvatarGradient: String, Codable, CaseIterable, Identifiable {
    case sunrise
    case mint
    case lavender
    case blush
    case blue
    case warm

    var id: String { rawValue }
}
