import Combine
import Foundation
import SwiftData

@MainActor
final class AddMedicineViewModel: ObservableObject {
    @Published var name = ""
    @Published var dosage = ""
    @Published var medicineType: MedicineType = .tablet
    @Published var instruction: MedicineInstruction = .afterFood
    @Published var frequencyType: MedicineFrequencyType = .daily
    @Published var reminderTime = Date()
    @Published var startDate = Date()
    @Published var hasEndDate = false
    @Published var endDate = Date()
    @Published var stockCount = 10
    @Published var lowStockAlertCount = 5
    @Published var notes = ""
    @Published var errorMessage: String?
    @Published var didSave = false

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (!hasEndDate || endDate >= startDate)
    }

    func save(modelContext: ModelContext) -> Bool {
        guard canSave else {
            errorMessage = "Please enter medicine name and dosage. End date must be after the start date."
            return false
        }

        let medicine = Medicine(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            dosage: dosage.trimmingCharacters(in: .whitespacesAndNewlines),
            medicineType: medicineType,
            instruction: instruction,
            frequencyType: frequencyType,
            times: [reminderTime],
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            stockCount: max(0, stockCount),
            lowStockAlertCount: max(0, lowStockAlertCount),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try MedicineRepository(modelContext: modelContext).add(medicine)
            didSave = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
