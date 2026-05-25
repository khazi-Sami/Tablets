import Combine
import Foundation
import SwiftData

@MainActor
final class MoodTrackingViewModel: ObservableObject {
    @Published var selectedMood: PregnancyMood?
    @Published var selectedEmotions: Set<String> = []
    @Published var energyLevel = 3
    @Published var note = ""
    @Published var recentMoods: [PregnancyMoodLog] = []
    @Published var moodTrend: [PregnancyMoodLog] = []
    @Published var savedMessage: String?

    func save(context: ModelContext, profileId: UUID, week: Int) {
        let mood = selectedMood ?? .calm
        let log = PregnancyMoodLog(pregnancyProfileId: profileId, mood: mood, emotions: Array(selectedEmotions), energyLevel: energyLevel, note: note.isEmpty ? nil : note, weekNumber: week)
        context.insert(log)
        try? context.save()
        savedMessage = (mood == .anxious || mood == .worried) ? "It is completely understandable to feel \(mood.rawValue.lowercased()) during pregnancy. You are doing amazingly well. Try taking a few slow deep breaths. If feelings feel overwhelming, please speak to your doctor or midwife." : "Mood saved for today."
        loadRecent(context: context, profileId: profileId)
    }

    func loadRecent(context: ModelContext, profileId: UUID) {
        let descriptor = FetchDescriptor<PregnancyMoodLog>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)])
        let logs = ((try? context.fetch(descriptor)) ?? []).filter { $0.pregnancyProfileId == profileId }
        recentMoods = Array(logs.prefix(5))
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
        moodTrend = logs.filter { $0.loggedAt >= cutoff }.sorted { $0.loggedAt < $1.loggedAt }
    }

    func moodSummaryForWeek(context: ModelContext) -> String {
        guard let latest = recentMoods.first else { return "No pregnancy mood logs saved this week yet." }
        return "Your latest pregnancy mood was \(latest.mood.rawValue), with energy level \(latest.energyLevel) out of 5. This is informational only."
    }
}
