import Foundation
import SwiftData

enum SampleData {
    static let medicines: [Medicine] = [
        Medicine(
            name: "Vitamin D",
            dosage: "1000 IU",
            medicineType: .tablet,
            instruction: .afterFood,
            frequencyType: .daily,
            times: [.now],
            stockCount: 28,
            lowStockAlertCount: 7,
            notes: "After breakfast"
        ),
        Medicine(
            name: "Omega 3",
            dosage: "1 capsule",
            medicineType: .capsule,
            instruction: .withFood,
            frequencyType: .daily,
            times: [.now],
            stockCount: 18,
            lowStockAlertCount: 5,
            notes: "With lunch"
        )
    ]

    static let healthRecords: [HealthRecord] = [
        HealthRecord(type: .heartRate, value1: 72, unit: "bpm", notes: "Resting"),
        HealthRecord(type: .bloodPressure, value1: 120, value2: 80, unit: "mmHg"),
        HealthRecord(type: .bloodSugar, value1: 96, unit: "mg/dL", sugarTestType: .fasting),
        HealthRecord(type: .oxygen, value1: 98, unit: "%"),
        HealthRecord(type: .weight, value1: 68, unit: "kg"),
        HealthRecord(type: .temperature, value1: 98.4, unit: "°F")
    ]

    static let periodRecords: [PeriodRecord] = [
        PeriodRecord(
            startDate: Calendar.current.date(byAdding: .day, value: -21, to: .now) ?? .now,
            endDate: Calendar.current.date(byAdding: .day, value: -17, to: .now),
            flowLevel: .medium,
            symptoms: ["Cramps", "Back pain"],
            mood: .tired,
            notes: "Mild cramps on day one"
        )
    ]

    static let periodCycles: [PeriodCycle] = [
        PeriodCycle(
            startDate: Calendar.current.date(byAdding: .day, value: -29, to: .now) ?? .now,
            endDate: Calendar.current.date(byAdding: .day, value: -25, to: .now),
            flowLevel: .medium,
            painLevel: 4,
            mood: .tired,
            symptoms: [WomensHealthSymptom.cramps.rawValue, WomensHealthSymptom.backPain.rawValue],
            notes: "Mild cramps first two days"
        ),
        PeriodCycle(
            startDate: Calendar.current.date(byAdding: .day, value: -57, to: .now) ?? .now,
            endDate: Calendar.current.date(byAdding: .day, value: -53, to: .now),
            flowLevel: .light,
            painLevel: 2,
            mood: .calm,
            symptoms: [WomensHealthSymptom.fatigue.rawValue],
            notes: ""
        )
    ]

    static let womensHealthLogs: [WomensHealthDailyLog] = [
        WomensHealthDailyLog(
            symptoms: [.bloating, .fatigue],
            dischargeNotes: "Normal",
            medicationTaken: "None",
            waterIntakeCups: 7,
            sleepQuality: .good,
            notes: "Energy improved by evening"
        )
    ]

    @MainActor
    static var previewContainer: ModelContainer {
        do {
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
            ReminderBehaviorMemory.self,
            UserProfile.self
        ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])

            medicines.forEach { container.mainContext.insert($0) }
            healthRecords.forEach { container.mainContext.insert($0) }
            periodRecords.forEach { container.mainContext.insert($0) }
            periodCycles.forEach { container.mainContext.insert($0) }
            womensHealthLogs.forEach { container.mainContext.insert($0) }
            container.mainContext.insert(CyclePredictionSettings())
            container.mainContext.insert(UserProfile(name: "Sam", hasCompletedOnboarding: true, displayName: "Sam"))

            if let firstMedicine = medicines.first {
                container.mainContext.insert(
                    MedicineLog(
                        medicine: firstMedicine,
                        scheduledTime: .now,
                        takenTime: .now,
                        status: .taken
                    )
                )
            }

            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
