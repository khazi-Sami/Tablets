import Combine
import Foundation
import SwiftData

@MainActor
final class DailySymptomLogViewModel: ObservableObject {
    @Published var date = Date()
    @Published var selectedSymptoms: Set<WomensHealthSymptom> = []
    @Published var dischargeNotes = ""
    @Published var medicationTaken = ""
    @Published var waterIntakeCups = 6
    @Published var sleepQuality: SleepQuality = .okay
    @Published var notes = ""
    @Published var errorMessage: String?
    @Published var didSave = false

    func toggle(_ symptom: WomensHealthSymptom) {
        if selectedSymptoms.contains(symptom) {
            selectedSymptoms.remove(symptom)
        } else {
            selectedSymptoms.insert(symptom)
        }
    }

    func save(modelContext: ModelContext) -> Bool {
        let log = WomensHealthDailyLog(
            date: date,
            symptoms: Array(selectedSymptoms),
            dischargeNotes: dischargeNotes.trimmingCharacters(in: .whitespacesAndNewlines),
            medicationTaken: medicationTaken.trimmingCharacters(in: .whitespacesAndNewlines),
            waterIntakeCups: waterIntakeCups,
            sleepQuality: sleepQuality,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            modelContext.insert(log)
            try modelContext.save()
            didSave = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
