import Combine
import Foundation
import SwiftData

@MainActor
final class PregnancySymptomViewModel: ObservableObject {
    @Published var selectedSymptoms: Set<String> = []
    @Published var severity: SymptomSeverity = .mild
    @Published var mood: PregnancyMood = .calm
    @Published var notes = ""
    @Published var isSaved = false

    func save(context: ModelContext, profileId: UUID) {
        context.insert(PregnancySymptomLog(pregnancyProfileId: profileId, symptoms: Array(selectedSymptoms).sorted(), severity: severity, mood: mood, notes: notes.isEmpty ? nil : notes))
        if (try? context.save()) != nil { isSaved = true }
    }
}
