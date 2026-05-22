import Foundation

struct AppFeatureInfo: Identifiable {
    let id = UUID()
    let featureName: String
    let description: String
    let exampleVoiceCommands: [String]
    let navigationIntent: AppNavigationIntent
    let keywords: [String]
}

final class AppKnowledgeBase {
    private let features: [AppFeatureInfo] = [
        .init(featureName: "Medicine Tracker", description: "View medicines, doses, stock, and reminders.", exampleVoiceCommands: ["open medicines"], navigationIntent: .openMedicines, keywords: ["medicine", "tablet", "pill", "dose"]),
        .init(featureName: "Add Medicine", description: "Create a new medicine reminder.", exampleVoiceCommands: ["add medicine"], navigationIntent: .openAddMedicine, keywords: ["add medicine", "new tablet", "new pill"]),
        .init(featureName: "BP Tracking", description: "Record and review blood pressure logs.", exampleVoiceCommands: ["record BP"], navigationIntent: .openBPTracking, keywords: ["bp", "blood pressure", "pressure"]),
        .init(featureName: "Sugar Tracking", description: "Record and review sugar or glucose readings.", exampleVoiceCommands: ["record sugar"], navigationIntent: .openSugarTracking, keywords: ["sugar", "glucose", "diabetes"]),
        .init(featureName: "Period Tracker", description: "Track periods, symptoms, moods, and estimates.", exampleVoiceCommands: ["open periods"], navigationIntent: .openPeriods, keywords: ["period", "cycle", "women"]),
        .init(featureName: "Doctor Visit", description: "Prepare notes and summaries for doctor visits.", exampleVoiceCommands: ["open doctor visit"], navigationIntent: .openDoctorVisit, keywords: ["doctor", "clinic", "appointment"]),
        .init(featureName: "Prescription Scanner", description: "Scan prescriptions and review medicine drafts.", exampleVoiceCommands: ["scan prescription"], navigationIntent: .openPrescriptionScanner, keywords: ["prescription", "scan", "camera"]),
        .init(featureName: "Family Care", description: "Manage family members and shared medicine care.", exampleVoiceCommands: ["open family care"], navigationIntent: .openFamilyCare, keywords: ["family", "mother", "father", "caretaker"]),
        .init(featureName: "Health Journey", description: "See a caring timeline of logs and progress.", exampleVoiceCommands: ["show health journey"], navigationIntent: .openHealthJourney, keywords: ["journey", "progress", "timeline"]),
        .init(featureName: "Health Memory", description: "Review private habit insights and saved patterns.", exampleVoiceCommands: ["open health memory"], navigationIntent: .openHealthMemory, keywords: ["memory", "habit", "pattern"]),
        .init(featureName: "Daily Check-In", description: "Log mood, sleep, energy, stress, and symptoms.", exampleVoiceCommands: ["daily check in"], navigationIntent: .openDailyCheckIn, keywords: ["check in", "mood", "sleep", "stress"]),
        .init(featureName: "Settings", description: "Adjust profile, haptics, and app preferences.", exampleVoiceCommands: ["open settings"], navigationIntent: .openSettings, keywords: ["settings", "profile", "preference"]),
        .init(featureName: "Apple Health", description: "Connect Apple Health for steps, sleep, heart rate, and optional reading sync. Your Apple Health data stays on your device.", exampleVoiceCommands: ["is Apple Health connected", "how many steps today"], navigationIntent: .openSettings, keywords: ["apple health", "healthkit", "steps", "sleep", "heart rate"]),
        .init(featureName: "Privacy and Offline AI", description: "Voice commands are processed locally after setup.", exampleVoiceCommands: ["how does offline ai work"], navigationIntent: .helpGeneral, keywords: ["privacy", "offline", "ai", "voice"])
    ]

    func allFeatures() -> [AppFeatureInfo] { features }

    func search(_ transcript: String) -> AppFeatureInfo? {
        let normalized = transcript.lowercased()
        return features
            .map { feature in
                (feature, feature.keywords.filter { normalized.contains($0) }.count)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .first?.0
    }

    func topSuggestions() -> [AppFeatureInfo] {
        Array(features.prefix(6))
    }
}
