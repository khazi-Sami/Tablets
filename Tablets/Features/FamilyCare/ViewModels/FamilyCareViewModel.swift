import Combine
import Foundation
import SwiftData
import UIKit

@MainActor
final class FamilyCareViewModel: ObservableObject {
    @Published var isShowingAddMember = false
    @Published var selectedMember: FamilyMember?
    @Published var errorMessage: String?

    func addSampleFamily(modelContext: ModelContext) {
        let members = [
            FamilyMember(name: "Ammi", relationship: .mother, age: 62, avatarSymbol: "heart.fill", gradient: .blush, notes: "Prefers reminders after breakfast."),
            FamilyMember(name: "Abbu", relationship: .father, age: 67, avatarSymbol: "person.fill", gradient: .blue, notes: "Morning BP check.")
        ]

        members.forEach { modelContext.insert($0) }

        do {
            try modelContext.save()
            HapticsManager.notification(.success)
        } catch {
            errorMessage = "Could not add family members. Please try again."
            HapticsManager.notification(.error)
        }
    }

    func missedAssignments(from members: [FamilyMember]) -> Int {
        members.reduce(0) { total, member in
            total + member.medicineAssignments.filter { $0.isActive }.count
        }
    }
}

@MainActor
final class AddFamilyMemberViewModel: ObservableObject {
    @Published var name = ""
    @Published var age = ""
    @Published var relationship: FamilyRelationship = .mother
    @Published var avatarSymbol = "person.fill"
    @Published var gradient: FamilyAvatarGradient = .sunrise
    @Published var notes = ""
    @Published var errorMessage: String?
    @Published var didSave = false

    func save(modelContext: ModelContext) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a family member name."
            HapticsManager.notification(.error)
            return
        }

        let member = FamilyMember(
            name: trimmedName,
            relationship: relationship,
            age: Int(age) ?? 0,
            avatarSymbol: avatarSymbol,
            gradient: gradient,
            notes: notes
        )
        modelContext.insert(member)

        do {
            try modelContext.save()
            didSave = true
            HapticsManager.notification(.success)
        } catch {
            errorMessage = "Could not save this family member."
            HapticsManager.notification(.error)
        }
    }
}
