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
    @Published var reminderTimes: [Date] = [Date()]
    @Published var startDate = Date()
    @Published var hasEndDate = false
    @Published var endDate = Date()
    @Published var stockCount = 10
    @Published var lowStockAlertCount = 5
    @Published var notes = ""
    @Published var errorMessage: String?
    @Published var notificationMessage: String?
    @Published var didSave = false

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (!hasEndDate || endDate >= startDate)
    }

    func save(modelContext: ModelContext) -> Bool {
        saveMedicine(modelContext: modelContext) != nil
    }

    func saveMedicine(modelContext: ModelContext) -> Medicine? {
        guard canSave else {
            errorMessage = "Please enter medicine name and dosage. End date must be after the start date."
            return nil
        }

        let times = sanitizedReminderTimes
        let medicine = Medicine(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            dosage: dosage.trimmingCharacters(in: .whitespacesAndNewlines),
            medicineType: medicineType,
            instruction: instruction,
            frequencyType: frequencyType,
            times: times,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            stockCount: max(0, stockCount),
            lowStockAlertCount: max(0, lowStockAlertCount),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try MedicineRepository(modelContext: modelContext).add(medicine)
            didSave = true
            return medicine
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func addReminderTime() {
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: reminderTimes.last ?? reminderTime) ?? Date()
        reminderTimes.append(next)
    }

    func removeReminderTime(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where reminderTimes.indices.contains(index) {
            reminderTimes.remove(at: index)
        }
        if reminderTimes.isEmpty {
            reminderTimes = [Date()]
        }
    }

    var sanitizedReminderTimes: [Date] {
        let source = reminderTimes.isEmpty ? [reminderTime] : reminderTimes
        return source
            .sorted()
            .reduce(into: [Date]()) { result, date in
                let key = AdaptiveReminderTimeKey.key(from: date)
                let hasKey = result.contains { AdaptiveReminderTimeKey.key(from: $0) == key }
                if !hasKey {
                    result.append(date)
                }
            }
    }
}
