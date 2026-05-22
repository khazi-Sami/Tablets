import Combine
import Foundation
import SwiftData

@MainActor
final class AddPeriodLogViewModel: ObservableObject {
    @Published var startDate = Date()
    @Published var hasEndDate = false
    @Published var endDate = Date()
    @Published var flowLevel: WomensFlowLevel = .medium
    @Published var painLevel = 3.0
    @Published var mood: WomensMood = .calm
    @Published var selectedSymptoms: Set<WomensHealthSymptom> = []
    @Published var notes = ""
    @Published var errorMessage: String?
    @Published var didSave = false

    var canSave: Bool {
        !hasEndDate || endDate >= startDate
    }

    func toggle(_ symptom: WomensHealthSymptom) {
        if selectedSymptoms.contains(symptom) {
            selectedSymptoms.remove(symptom)
        } else {
            selectedSymptoms.insert(symptom)
        }
    }

    func save(modelContext: ModelContext) -> Bool {
        guard canSave else {
            errorMessage = "End date should be after the start date."
            return false
        }

        let cycle = PeriodCycle(
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            flowLevel: flowLevel,
            painLevel: Int(painLevel.rounded()),
            mood: mood,
            symptoms: selectedSymptoms.map(\.rawValue).sorted(),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            modelContext.insert(cycle)
            try modelContext.save()
            didSave = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
