import Foundation
import SwiftData

enum AppModelContainer {
    private static let appGroupID = "group.com.developer.apple.Tablets"

    static func makeState() -> AppModelContainerState {
        do {
            return .loaded(try make())
        } catch {
            #if DEBUG
            print("[AppModelContainer] Could not create ModelContainer: \(error)")
            #endif
            return .failed(.from(error))
        }
    }

    static func make() throws -> ModelContainer {
        let schema = Schema([
            Medicine.self,
            MedicineLog.self,
            HealthRecord.self,
            PeriodRecord.self,
            PeriodCycle.self,
            WomensHealthDailyLog.self,
            CyclePredictionSettings.self,
            FamilyMember.self,
            FamilyMedicineAssignment.self,
            DailyHealthCheckIn.self,
            WellnessMemory.self,
            AmbientHabitSignal.self,
            AmbientInteractionMemory.self,
            DoctorAppointment.self,
            DoctorVisitChecklistItem.self,
            HumanAssistantConversation.self,
            HumanAssistantPreference.self,
            HumanVoiceMemory.self,
            CustomVoiceShortcut.self,
            UserHealthHabit.self,
            HealthPatternMemory.self,
            AssistantInteractionMemory.self,
            ReminderBehaviorMemory.self
            ,
            PregnancyProfile.self,
            PregnancySymptomLog.self,
            PregnancyWeightLog.self,
            BabyKickLog.self,
            PregnancyAppointment.self,
            PregnancyMilestone.self,
            ContractionLog.self,
            PregnancyMoodLog.self,
            PregnancyNote.self,
            BirthPlan.self
        ])
        let configuration = ModelConfiguration(
            "TabletsModelV11",
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupID)
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func resetLocalStoreForRecovery() throws {
        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            throw CocoaError(.fileNoSuchFile)
        }

        let supportURL = containerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
        let storeURL = supportURL.appendingPathComponent("TabletsModelV11.store")
        let relatedURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        for url in relatedURLs where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
}
