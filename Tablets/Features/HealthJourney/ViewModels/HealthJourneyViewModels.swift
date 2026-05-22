import Combine
import Foundation
import SwiftData
import UIKit

@MainActor
final class HealthJourneyViewModel: ObservableObject {
    @Published var isShowingCheckIn = false
    private let service = HealthJourneyService()

    func feed(medicineLogs: [MedicineLog], healthRecords: [HealthRecord], womensLogs: [WomensHealthDailyLog], periodCycles: [PeriodCycle], checkIns: [DailyHealthCheckIn]) -> [JourneyFeedItem] {
        service.feed(medicineLogs: medicineLogs, healthRecords: healthRecords, womensLogs: womensLogs, periodCycles: periodCycles, checkIns: checkIns)
    }

    func streaks(medicineLogs: [MedicineLog], healthRecords: [HealthRecord], womensLogs: [WomensHealthDailyLog], checkIns: [DailyHealthCheckIn]) -> HealthStreakSummary {
        service.streaks(medicineLogs: medicineLogs, healthRecords: healthRecords, womensLogs: womensLogs, checkIns: checkIns)
    }

    func mode(medicineLogs: [MedicineLog], healthRecords: [HealthRecord], womensLogs: [WomensHealthDailyLog], periodCycles: [PeriodCycle]) -> EmotionalWellnessMode {
        service.mode(medicineLogs: medicineLogs, healthRecords: healthRecords, womensLogs: womensLogs, periodCycles: periodCycles)
    }

    func insights(streaks: HealthStreakSummary, feed: [JourneyFeedItem]) -> [String] {
        service.insights(streaks: streaks, feed: feed)
    }
}

@MainActor
final class DailyCheckInViewModel: ObservableObject {
    @Published var mood: JourneyMood = .calm
    @Published var stressLevel = 3.0
    @Published var energyLevel = 6.0
    @Published var sleepQuality: SleepQuality = .okay
    @Published var symptoms: Set<String> = []
    @Published var notes = ""
    @Published var didSave = false

    let symptomOptions = ["Headache", "Fatigue", "Cramps", "Back pain", "Bloating", "Mood swings", "Stress", "Low energy"]

    func toggleSymptom(_ symptom: String) {
        if symptoms.contains(symptom) {
            symptoms.remove(symptom)
        } else {
            symptoms.insert(symptom)
        }
        HapticsManager.selection()
    }

    func save(modelContext: ModelContext) {
        let checkIn = DailyHealthCheckIn(
            mood: mood,
            stressLevel: Int(stressLevel.rounded()),
            energyLevel: Int(energyLevel.rounded()),
            sleepQuality: sleepQuality,
            symptoms: Array(symptoms),
            notes: notes
        )
        modelContext.insert(checkIn)

        let memory = WellnessMemory(
            habitName: "Daily check-in",
            category: .symptoms,
            preferredHour: Calendar.current.component(.hour, from: .now),
            consistencyScore: 1,
            notes: "User completed an emotional wellness check-in."
        )
        modelContext.insert(memory)

        do {
            try modelContext.save()
            didSave = true
            HapticsManager.notification(.success)
        } catch {
            HapticsManager.notification(.error)
        }
    }
}
