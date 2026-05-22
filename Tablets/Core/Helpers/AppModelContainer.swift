import SwiftData

enum AppModelContainer {
    static func make() -> ModelContainer {
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
            UserHealthHabit.self,
            HealthPatternMemory.self,
            AssistantInteractionMemory.self,
            ReminderBehaviorMemory.self
        ])
        let configuration = ModelConfiguration(
            "TabletsModelV10",
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

}
