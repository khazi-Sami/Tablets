import Foundation
import SwiftData
import UserNotifications

struct DataExportService {
    @MainActor
    func exportAllData(context: ModelContext) throws -> URL {
        let payload: [String: Any] = [
            "exportedAt": ISO8601DateFormatter().string(from: .now),
            "app": appInfo(),
            "profile": profilePayload(context: context),
            "settings": settingsPayload(),
            "medicines": fetch(context, FetchDescriptor<Medicine>()).map(medicinePayload),
            "medicineLogs": fetch(context, FetchDescriptor<MedicineLog>()).map(medicineLogPayload),
            "healthRecords": fetch(context, FetchDescriptor<HealthRecord>()).map(healthRecordPayload),
            "periods": fetch(context, FetchDescriptor<PeriodCycle>()).map(periodPayload),
            "womensHealthLogs": fetch(context, FetchDescriptor<WomensHealthDailyLog>()).map(womensLogPayload),
            "pregnancyProfiles": fetch(context, FetchDescriptor<PregnancyProfile>()).map(pregnancyPayload),
            "pregnancySymptoms": fetch(context, FetchDescriptor<PregnancySymptomLog>()).map(pregnancySymptomPayload),
            "pregnancyWeights": fetch(context, FetchDescriptor<PregnancyWeightLog>()).map(pregnancyWeightPayload),
            "babyKicks": fetch(context, FetchDescriptor<BabyKickLog>()).map(kickPayload),
            "doctorVisits": fetch(context, FetchDescriptor<DoctorAppointment>()).map(doctorVisitPayload)
        ]

        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        let url = FileManager.default.temporaryDirectory
            .appending(path: "Tablets-Data-Export-\(UUID().uuidString).json")
        try data.write(to: url, options: [.atomic])
        return url
    }

    @MainActor
    func resetLocalAppData(context: ModelContext) async throws {
        try deleteAll(context, FetchDescriptor<MedicineLog>())
        try deleteAll(context, FetchDescriptor<Medicine>())
        try deleteAll(context, FetchDescriptor<HealthRecord>())
        try deleteAll(context, FetchDescriptor<PeriodRecord>())
        try deleteAll(context, FetchDescriptor<PeriodCycle>())
        try deleteAll(context, FetchDescriptor<WomensHealthDailyLog>())
        try deleteAll(context, FetchDescriptor<CyclePredictionSettings>())
        try deleteAll(context, FetchDescriptor<FamilyMedicineAssignment>())
        try deleteAll(context, FetchDescriptor<FamilyMember>())
        try deleteAll(context, FetchDescriptor<DailyHealthCheckIn>())
        try deleteAll(context, FetchDescriptor<WellnessMemory>())
        try deleteAll(context, FetchDescriptor<AmbientHabitSignal>())
        try deleteAll(context, FetchDescriptor<AmbientInteractionMemory>())
        try deleteAll(context, FetchDescriptor<DoctorAppointment>())
        try deleteAll(context, FetchDescriptor<DoctorVisitChecklistItem>())
        try deleteAll(context, FetchDescriptor<HumanAssistantConversation>())
        try deleteAll(context, FetchDescriptor<HumanAssistantPreference>())
        try deleteAll(context, FetchDescriptor<HumanVoiceMemory>())
        try deleteAll(context, FetchDescriptor<CustomVoiceShortcut>())
        try deleteAll(context, FetchDescriptor<UserHealthHabit>())
        try deleteAll(context, FetchDescriptor<HealthPatternMemory>())
        try deleteAll(context, FetchDescriptor<AssistantInteractionMemory>())
        try deleteAll(context, FetchDescriptor<ReminderBehaviorMemory>())
        try deleteAll(context, FetchDescriptor<UserProfile>())
        try deleteAll(context, FetchDescriptor<PregnancyProfile>())
        try deleteAll(context, FetchDescriptor<PregnancySymptomLog>())
        try deleteAll(context, FetchDescriptor<PregnancyWeightLog>())
        try deleteAll(context, FetchDescriptor<BabyKickLog>())
        try deleteAll(context, FetchDescriptor<PregnancyAppointment>())
        try deleteAll(context, FetchDescriptor<PregnancyMilestone>())
        try deleteAll(context, FetchDescriptor<ContractionLog>())
        try deleteAll(context, FetchDescriptor<PregnancyMoodLog>())
        try deleteAll(context, FetchDescriptor<PregnancyNote>())
        try deleteAll(context, FetchDescriptor<BirthPlan>())
        try context.save()

        AppPreferenceKeys.clearCompletedSession()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        AppPreferenceKeys.sharedDefaults.removeObject(forKey: AppPreferenceKeys.completedSession)
        UserDefaults.standard.synchronize()
        AppPreferenceKeys.sharedDefaults.synchronize()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    @MainActor
    private func deleteAll<T: PersistentModel>(_ context: ModelContext, _ descriptor: FetchDescriptor<T>) throws {
        for model in try context.fetch(descriptor) {
            context.delete(model)
        }
    }

    @MainActor
    private func fetch<T: PersistentModel>(_ context: ModelContext, _ descriptor: FetchDescriptor<T>) -> [T] {
        (try? context.fetch(descriptor)) ?? []
    }

    private func appInfo() -> [String: Any] {
        [
            "name": "Tablets",
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        ]
    }

    @MainActor
    private func profilePayload(context: ModelContext) -> [String: Any] {
        let profile = fetch(context, FetchDescriptor<UserProfile>()).first
        return [
            "name": profile?.name ?? UserHealthProfile.userName,
            "displayName": profile?.displayName ?? "",
            "age": profile?.age ?? 0,
            "gender": profile?.gender?.title ?? UserHealthProfile.gender.title,
            "loginMethod": profile?.loginMethod ?? "local"
        ]
    }

    private func settingsPayload() -> [String: Any] {
        let defaults = UserDefaults.standard
        return [
            "theme": defaults.string(forKey: AppPreferenceKeys.theme) ?? AppThemePreference.system.rawValue,
            "textSize": defaults.string(forKey: AppPreferenceKeys.textSize) ?? AppTextSizePreference.standard.rawValue,
            "hapticsEnabled": defaults.bool(forKey: HapticsManager.isEnabledKey),
            "appLockEnabled": defaults.bool(forKey: AppPreferenceKeys.appLockEnabled),
            "voiceLanguage": defaults.string(forKey: AppPreferenceKeys.voiceLanguage) ?? VoiceLanguagePreference.english.rawValue,
            "voiceSpeed": defaults.string(forKey: AppPreferenceKeys.voiceSpeed) ?? VoiceSpeedPreference.normal.rawValue
        ]
    }

    private func medicinePayload(_ medicine: Medicine) -> [String: Any] {
        [
            "id": medicine.id.uuidString,
            "name": medicine.name,
            "dosage": medicine.dosage,
            "type": medicine.medicineType.title,
            "instruction": medicine.instruction.title,
            "frequency": medicine.frequencyType.title,
            "times": medicine.times.map { $0.ISO8601Format() },
            "stockCount": medicine.stockCount,
            "lowStockAlertCount": medicine.lowStockAlertCount,
            "isActive": medicine.isActive
        ]
    }

    private func medicineLogPayload(_ log: MedicineLog) -> [String: Any] {
        [
            "id": log.id.uuidString,
            "medicine": log.medicine?.name ?? "",
            "scheduledTime": log.scheduledTime.ISO8601Format(),
            "takenTime": log.takenTime?.ISO8601Format() ?? "",
            "status": log.status.title
        ]
    }

    private func healthRecordPayload(_ record: HealthRecord) -> [String: Any] {
        [
            "id": record.id.uuidString,
            "type": record.type.title,
            "value1": record.value1,
            "value2": record.value2 ?? NSNull(),
            "unit": record.unit,
            "measuredAt": record.measuredAt.ISO8601Format(),
            "notes": record.notes,
            "symptoms": record.symptoms,
            "sugarTestType": record.sugarTestType?.title ?? ""
        ]
    }

    private func periodPayload(_ cycle: PeriodCycle) -> [String: Any] {
        [
            "id": cycle.id.uuidString,
            "startDate": cycle.startDate.ISO8601Format(),
            "endDate": cycle.endDate?.ISO8601Format() ?? "",
            "flow": cycle.flowLevel.title,
            "painLevel": cycle.painLevel,
            "symptoms": cycle.symptoms
        ]
    }

    private func womensLogPayload(_ log: WomensHealthDailyLog) -> [String: Any] {
        [
            "id": log.id.uuidString,
            "date": log.date.ISO8601Format(),
            "symptoms": log.symptoms,
            "waterIntakeCups": log.waterIntakeCups,
            "sleepQuality": log.sleepQuality.title,
            "notes": log.notes
        ]
    }

    private func pregnancyPayload(_ profile: PregnancyProfile) -> [String: Any] {
        [
            "id": profile.id.uuidString,
            "lmp": profile.lastMenstrualPeriodDate.ISO8601Format(),
            "dueDate": profile.dueDate.ISO8601Format(),
            "currentWeek": profile.currentWeek,
            "babyNickname": profile.babyNickname ?? "",
            "isActive": profile.isActive
        ]
    }

    private func pregnancySymptomPayload(_ log: PregnancySymptomLog) -> [String: Any] {
        [
            "id": log.id.uuidString,
            "pregnancyProfileId": log.pregnancyProfileId.uuidString,
            "loggedAt": log.loggedAt.ISO8601Format(),
            "symptoms": log.symptoms,
            "severity": log.severity.rawValue,
            "mood": log.mood.rawValue,
            "notes": log.notes ?? ""
        ]
    }

    private func pregnancyWeightPayload(_ log: PregnancyWeightLog) -> [String: Any] {
        [
            "id": log.id.uuidString,
            "pregnancyProfileId": log.pregnancyProfileId.uuidString,
            "weight": log.weight,
            "unit": log.unit.rawValue,
            "weekNumber": log.weekNumber,
            "loggedAt": log.loggedAt.ISO8601Format()
        ]
    }

    private func kickPayload(_ log: BabyKickLog) -> [String: Any] {
        [
            "id": log.id.uuidString,
            "pregnancyProfileId": log.pregnancyProfileId.uuidString,
            "sessionStartedAt": log.sessionStartedAt.ISO8601Format(),
            "sessionEndedAt": log.sessionEndedAt?.ISO8601Format() ?? "",
            "kickCount": log.kickCount,
            "durationMinutes": log.durationMinutes ?? 0
        ]
    }

    private func doctorVisitPayload(_ appointment: DoctorAppointment) -> [String: Any] {
        [
            "id": appointment.id.uuidString,
            "doctorName": appointment.doctorName,
            "clinicName": appointment.clinicName,
            "appointmentDate": appointment.appointmentDate.ISO8601Format(),
            "patientName": appointment.patientName,
            "patientAge": appointment.patientAge,
            "notesForDoctor": appointment.notesForDoctor
        ]
    }
}
