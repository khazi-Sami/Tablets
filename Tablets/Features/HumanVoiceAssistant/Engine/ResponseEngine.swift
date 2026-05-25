import Foundation
import HealthKit
import SwiftData

@MainActor
struct ResponseEngine {
    let modelContext: ModelContext
    let comparisonEngine = HealthComparisonEngine()
    let memorySearchEngine = HealthMemorySearchEngine()
    let variationPool = ResponseVariationPool()

    func respond(
        to command: ParsedHealthCommand,
        medicines: [Medicine],
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        symptomLogs: [WomensHealthDailyLog] = []
    ) -> HealthAssistantResponse {
        if command.confidence < 0.62 {
            return HealthAssistantResponse(text: "I want to make sure I heard you correctly. Please confirm or edit this before I save anything.", requiresConfirmation: true, confidence: command.confidence)
        }

        if let memoryAnswer = memorySearchEngine.answer(command, healthRecords: healthRecords, medicineLogs: medicineLogs, symptomLogs: symptomLogs) {
            return HealthAssistantResponse(text: memoryAnswer, requiresConfirmation: false, confidence: command.confidence)
        }

        switch command.intent {
        case .logSugar:
            return logSugar(command, healthRecords: healthRecords)
        case .logBloodPressure:
            return logBloodPressure(command)
        case .logWeight:
            return logWeight(command)
        case .askSugar:
            return HealthAssistantResponse(text: comparisonEngine.latestSugarComparison(records: healthRecords), requiresConfirmation: false, confidence: command.confidence)
        case .askBloodPressure:
            return HealthAssistantResponse(text: comparisonEngine.bpComparison(records: healthRecords), requiresConfirmation: false, confidence: command.confidence)
        case .askMedicineTaken:
            return didTakeMedicine(medicines: medicines, logs: medicineLogs)
        case .memorySearch:
            return HealthAssistantResponse(text: "I searched your saved logs, but I do not have enough matching history for that yet. This is informational only.", requiresConfirmation: false, confidence: command.confidence)
        case .logSymptoms:
            return logSymptoms(command, symptomLogs: symptomLogs)
        case .medicineTaken:
            return markMedicineTaken(command: command, medicines: medicines)
        case .pendingMedicine:
            return pendingMedicine(medicines: medicines)
        case .reminderRequest:
            return HealthAssistantResponse(text: "I heard your reminder request. Reminder scheduling can be connected next, and I will not change any medicine dosage.", requiresConfirmation: true, confidence: command.confidence)
        case .startPeriod:
            return startPeriod()
        case .weeklyHealth:
            return HealthAssistantResponse(text: comparisonEngine.weeklySummary(records: healthRecords), requiresConfirmation: false, confidence: command.confidence)
        case .logPregnancyWeight:
            return logPregnancyWeight(command)
        case .logBabyKick:
            return logBabyKick(command)
        case .logPregnancySymptom:
            return logPregnancySymptom(command)
        case .askPregnancyWeek, .askDueDate:
            return HealthAssistantResponse(text: pregnancyProfileSummary(), requiresConfirmation: false, confidence: command.confidence)
        case .startContraction:
            return startContraction()
        case .stopContraction:
            return stopContraction()
        case .logPregnancyMood:
            return logPregnancyMood(command)
        case .logPregnancyNote:
            return logPregnancyNote(command)
        case .unknown:
            return HealthAssistantResponse(text: "I did not catch that clearly. You can say, my sugar is 145 after food, or how is my BP.", requiresConfirmation: true, confidence: command.confidence)
        }
    }

    private func logSugar(_ command: ParsedHealthCommand, healthRecords: [HealthRecord]) -> HealthAssistantResponse {
        guard let value = command.numbers.first else {
            return HealthAssistantResponse(text: "Please say the sugar value again before I save it.", requiresConfirmation: true, confidence: command.confidence)
        }
        let testType = command.entities["sugarTestType"].flatMap(SugarTestType.init(rawValue:)) ?? .random
        let record = HealthRecord(type: .bloodSugar, value1: value, unit: "mg/dL", notes: "Added by Human Voice Assistant", sugarTestType: testType)
        modelContext.insert(record)
        guard save() else {
            return HealthAssistantResponse(text: "I understood the sugar reading, but I could not save it locally just now. Please try again.", requiresConfirmation: false, confidence: command.confidence)
        }
        let safetyText = safetyMessage(for: record)
        writeHealthKitSideEffect(type: .bloodSugar, value1: value, value2: nil, date: .now)
        let comparison = comparisonEngine.sugarComparison(value: value, testType: testType, records: healthRecords)
        return HealthAssistantResponse(text: variationPool.sugarSaved(value: Int(value), context: testType.title.lowercased(), comparison: comparison) + safetyText + healthKitSyncNote(for: .bloodSugar), requiresConfirmation: false, confidence: command.confidence)
    }

    private func logBloodPressure(_ command: ParsedHealthCommand) -> HealthAssistantResponse {
        guard command.numbers.count >= 2 else {
            return HealthAssistantResponse(text: "Please say both BP numbers, like 120 over 80, before I save it.", requiresConfirmation: true, confidence: command.confidence)
        }
        let record = HealthRecord(type: .bloodPressure, value1: command.numbers[0], value2: command.numbers[1], unit: "mmHg", notes: "Added by Human Voice Assistant")
        modelContext.insert(record)
        guard save() else {
            return HealthAssistantResponse(text: "I understood the BP reading, but I could not save it locally just now. Please try again.", requiresConfirmation: false, confidence: command.confidence)
        }
        let safetyText = safetyMessage(for: record)
        writeHealthKitSideEffect(type: .bloodPressure, value1: command.numbers[0], value2: command.numbers[1], date: .now)
        return HealthAssistantResponse(text: variationPool.bpSaved(systolic: Int(command.numbers[0]), diastolic: Int(command.numbers[1]), comparison: variationPool.safeComparison()) + safetyText + healthKitSyncNote(for: .bloodPressure), requiresConfirmation: false, confidence: command.confidence)
    }

    private func logWeight(_ command: ParsedHealthCommand) -> HealthAssistantResponse {
        guard let value = command.numbers.first else {
            return HealthAssistantResponse(text: "Please say the weight again before I save it.", requiresConfirmation: true, confidence: command.confidence)
        }
        let record = HealthRecord(type: .weight, value1: value, unit: "kg", notes: "Added by Human Voice Assistant")
        modelContext.insert(record)
        guard save() else {
            return HealthAssistantResponse(text: "I understood the weight reading, but I could not save it locally just now. Please try again.", requiresConfirmation: false, confidence: command.confidence)
        }
        let safetyText = safetyMessage(for: record)
        writeHealthKitSideEffect(type: .weight, value1: value, value2: nil, date: .now)
        return HealthAssistantResponse(text: "Saved your weight as \(Int(value)) kg. This is informational only." + safetyText + healthKitSyncNote(for: .weight), requiresConfirmation: false, confidence: command.confidence)
    }

    private func logSymptoms(_ command: ParsedHealthCommand, symptomLogs: [WomensHealthDailyLog]) -> HealthAssistantResponse {
        let symptoms = command.symptoms.isEmpty ? ["symptom"] : command.symptoms
        modelContext.insert(WomensHealthDailyLog(symptoms: [], notes: "Voice symptoms: \(symptoms.joined(separator: ", "))"))
        guard save() else {
            return HealthAssistantResponse(text: "I understood the symptom log, but I could not save it locally just now. Please try again.", requiresConfirmation: false, confidence: command.confidence)
        }
        let repeated = repeatedSymptomMessage(symptoms: symptoms, logs: symptomLogs)
        return HealthAssistantResponse(text: "\(variationPool.symptomSaved(symptoms: symptoms.joined(separator: " and "))) \(repeated)", requiresConfirmation: false, confidence: command.confidence)
    }

    private func markMedicineTaken(command: ParsedHealthCommand, medicines: [Medicine]) -> HealthAssistantResponse {
        guard let medicine = matchedMedicine(for: command, medicines: medicines) ?? medicines.first(where: \.isActive) else {
            return HealthAssistantResponse(text: "I do not see an active medicine to mark as taken.", requiresConfirmation: false, confidence: 0.75)
        }
        modelContext.insert(MedicineLog(medicine: medicine, scheduledTime: medicine.times.first ?? .now, takenTime: .now, status: .taken))
        guard save() else {
            return HealthAssistantResponse(text: "I found \(medicine.name), but I could not save the taken log locally just now. Please try again.", requiresConfirmation: false, confidence: 0.80)
        }
        return HealthAssistantResponse(text: variationPool.medicineTaken(medicine: medicine.name), requiresConfirmation: false, confidence: 0.80)
    }

    private func matchedMedicine(for command: ParsedHealthCommand, medicines: [Medicine]) -> Medicine? {
        let text = command.originalText.lowercased()
        let active = medicines.filter(\.isActive)
        if let direct = active.first(where: { text.contains($0.name.lowercased()) }) {
            return direct
        }
        if let hint = command.entities["medicineHint"] {
            return active.first {
                $0.name.lowercased().contains(hint) ||
                $0.notes.lowercased().contains(hint) ||
                $0.medicineType.title.lowercased().contains(hint)
            }
        }
        return nil
    }

    private func pendingMedicine(medicines: [Medicine]) -> HealthAssistantResponse {
        let active = medicines.filter(\.isActive)
        guard !active.isEmpty else {
            return HealthAssistantResponse(text: "I do not see active medicines in your list right now.", requiresConfirmation: false, confidence: 0.80)
        }
        return HealthAssistantResponse(text: "Your pending medicine list includes \(active.prefix(3).map(\.name).joined(separator: ", ")). Please check the reminder time before taking anything.", requiresConfirmation: false, confidence: 0.82)
    }

    private func didTakeMedicine(medicines: [Medicine], logs: [MedicineLog]) -> HealthAssistantResponse {
        let todayTaken = logs.filter { $0.status == .taken && Calendar.current.isDateInToday($0.scheduledTime) }
        if let latest = todayTaken.sorted(by: { ($0.takenTime ?? $0.scheduledTime) > ($1.takenTime ?? $1.scheduledTime) }).first {
            let name = latest.medicine?.name ?? "medicine"
            return HealthAssistantResponse(text: "Based on your saved logs, \(name) was marked taken today at \((latest.takenTime ?? latest.scheduledTime).formatted(date: .omitted, time: .shortened)). Please check your medicine list before taking anything.", requiresConfirmation: false, confidence: 0.84)
        }

        let active = medicines.filter(\.isActive)
        if active.isEmpty {
            return HealthAssistantResponse(text: "I do not see active medicines in your list right now.", requiresConfirmation: false, confidence: 0.80)
        }

        return HealthAssistantResponse(text: "Based on your saved logs, I do not see a medicine marked taken today yet. Please check your schedule before taking anything.", requiresConfirmation: false, confidence: 0.82)
    }

    private func repeatedSymptomMessage(symptoms: [String], logs: [WomensHealthDailyLog]) -> String {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        for symptom in symptoms {
            if let previous = logs.first(where: { $0.date >= weekAgo && ($0.symptoms.contains(symptom) || $0.notes.lowercased().contains(symptom)) }) {
                let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: previous.date), to: Calendar.current.startOfDay(for: .now)).day ?? 0
                return "You also logged \(symptom) \(days == 0 ? "earlier today" : "\(days) day\(days == 1 ? "" : "s") ago") based on your saved symptom logs. "
            }
        }
        return ""
    }

    private func startPeriod() -> HealthAssistantResponse {
        modelContext.insert(PeriodRecord(startDate: .now, notes: "Started by Human Voice Assistant"))
        guard save() else {
            return HealthAssistantResponse(text: "I understood that your period started today, but I could not save it locally just now. Please try again.", requiresConfirmation: false, confidence: 0.84)
        }
        return HealthAssistantResponse(text: "I saved your period start for today. This is based only on your saved logs and is not medical advice.", requiresConfirmation: false, confidence: 0.84)
    }

    private func logPregnancyWeight(_ command: ParsedHealthCommand) -> HealthAssistantResponse {
        guard let profile = activePregnancyProfile() else {
            return HealthAssistantResponse(text: "I don't have pregnancy information saved yet. You can set up your pregnancy journey by saying Open pregnancy.", requiresConfirmation: false, confidence: command.confidence)
        }
        guard let value = command.numbers.first else {
            return HealthAssistantResponse(text: "Please say the pregnancy weight again before I save it.", requiresConfirmation: true, confidence: command.confidence)
        }
        let week = max(1, min(42, profile.currentWeek))
        modelContext.insert(PregnancyWeightLog(pregnancyProfileId: profile.id, weight: value, unit: .kg, loggedAt: .now, weekNumber: week, notes: "Added by Human Voice Assistant"))
        guard save() else {
            return HealthAssistantResponse(text: "I understood the pregnancy weight, but I could not save it locally just now. Please try again.", requiresConfirmation: false, confidence: command.confidence)
        }
        return HealthAssistantResponse(text: variationPool.pregnancyWeightSaved(week: week), requiresConfirmation: false, confidence: command.confidence)
    }

    private func logBabyKick(_ command: ParsedHealthCommand) -> HealthAssistantResponse {
        guard let profile = activePregnancyProfile() else {
            return HealthAssistantResponse(text: "I don't have pregnancy information saved yet. You can set up your pregnancy journey by saying Open pregnancy.", requiresConfirmation: false, confidence: command.confidence)
        }
        let count = max(1, Int(command.numbers.first ?? 1))
        modelContext.insert(BabyKickLog(pregnancyProfileId: profile.id, sessionStartedAt: .now, sessionEndedAt: .now, kickCount: count, durationMinutes: nil, notes: "Added by Human Voice Assistant"))
        guard save() else {
            return HealthAssistantResponse(text: "I understood the baby kick log, but I could not save it locally just now. Please try again.", requiresConfirmation: false, confidence: command.confidence)
        }
        return HealthAssistantResponse(text: variationPool.babyKickSaved(count: count, duration: nil), requiresConfirmation: false, confidence: command.confidence)
    }

    private func logPregnancySymptom(_ command: ParsedHealthCommand) -> HealthAssistantResponse {
        guard let profile = activePregnancyProfile() else {
            return HealthAssistantResponse(text: "I don't have pregnancy information saved yet. You can set up your pregnancy journey by saying Open pregnancy.", requiresConfirmation: false, confidence: command.confidence)
        }
        let symptoms = command.symptoms.isEmpty ? ["pregnancy symptom"] : command.symptoms
        modelContext.insert(PregnancySymptomLog(pregnancyProfileId: profile.id, symptoms: symptoms, severity: .mild, mood: .calm, notes: "Added by Human Voice Assistant"))
        guard save() else {
            return HealthAssistantResponse(text: "I understood the pregnancy symptoms, but I could not save them locally just now. Please try again.", requiresConfirmation: false, confidence: command.confidence)
        }
        PregnancyHydrationService().handleSymptomLogged(symptoms, isEnabled: profile.hydrationRemindersEnabled != false)
        let guidance = PregnancySymptomGuidanceEngine().getGuidance(for: symptoms, week: max(1, min(42, profile.currentWeek)))
        return HealthAssistantResponse(text: "\(variationPool.pregnancySymptomSaved()) \(guidance)", requiresConfirmation: false, confidence: command.confidence)
    }

    private func activePregnancyProfile() -> PregnancyProfile? {
        let descriptor = FetchDescriptor<PregnancyProfile>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? modelContext.fetch(descriptor))?.first(where: \.isActive)
    }

    private func startContraction() -> HealthAssistantResponse {
        guard let profile = activePregnancyProfile() else {
            return HealthAssistantResponse(text: "I don't have pregnancy information saved yet. Say Open pregnancy to set up your journey.", requiresConfirmation: false, confidence: 0.8)
        }
        modelContext.insert(ContractionLog(pregnancyProfileId: profile.id, startedAt: .now, notes: "Started by voice"))
        guard save() else {
            return HealthAssistantResponse(text: "I could not start the contraction timer locally just now. Please try again.", requiresConfirmation: false, confidence: 0.8)
        }
        return HealthAssistantResponse(text: "Contraction started. Say stop contraction when it ends. Please contact your doctor or midwife if you are unsure or concerned.", requiresConfirmation: false, confidence: 0.9)
    }

    private func stopContraction() -> HealthAssistantResponse {
        guard let profile = activePregnancyProfile() else {
            return HealthAssistantResponse(text: "I don't have pregnancy information saved yet. Say Open pregnancy to set up your journey.", requiresConfirmation: false, confidence: 0.8)
        }
        let descriptor = FetchDescriptor<ContractionLog>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        guard let log = (try? modelContext.fetch(descriptor))?.first(where: { $0.pregnancyProfileId == profile.id && $0.endedAt == nil }) else {
            return HealthAssistantResponse(text: "I do not see an active contraction timer. You can say start contraction when one begins.", requiresConfirmation: false, confidence: 0.8)
        }
        let end = Date()
        log.endedAt = end
        log.durationSeconds = max(1, Int(end.timeIntervalSince(log.startedAt)))
        guard save() else {
            return HealthAssistantResponse(text: "I could not save the contraction locally just now. Please try again.", requiresConfirmation: false, confidence: 0.8)
        }
        return HealthAssistantResponse(text: "Contraction saved. Duration was \(log.durationSeconds ?? 0) seconds. Please contact your doctor or midwife if contractions become regular, painful, or concerning.", requiresConfirmation: false, confidence: 0.9)
    }

    private func logPregnancyMood(_ command: ParsedHealthCommand) -> HealthAssistantResponse {
        guard let profile = activePregnancyProfile() else {
            return HealthAssistantResponse(text: "I don't have pregnancy information saved yet. Say Open pregnancy to set up your journey.", requiresConfirmation: false, confidence: command.confidence)
        }
        let mood = command.entities["pregnancyMood"].flatMap(PregnancyMood.init(rawValue:)) ?? .calm
        modelContext.insert(PregnancyMoodLog(pregnancyProfileId: profile.id, mood: mood, emotions: [], energyLevel: 3, note: "Logged by voice", weekNumber: profile.currentWeek))
        guard save() else {
            return HealthAssistantResponse(text: "I could not save your pregnancy mood locally just now. Please try again.", requiresConfirmation: false, confidence: command.confidence)
        }
        let support = (mood == .anxious || mood == .worried) ? " It is understandable to feel this during pregnancy. Try a few slow deep breaths. If it feels overwhelming, please speak to your doctor or midwife." : ""
        return HealthAssistantResponse(text: "Saved your pregnancy mood as \(mood.rawValue).\(support) This is informational only.", requiresConfirmation: false, confidence: command.confidence)
    }

    private func logPregnancyNote(_ command: ParsedHealthCommand) -> HealthAssistantResponse {
        guard let profile = activePregnancyProfile() else {
            return HealthAssistantResponse(text: "I don't have pregnancy information saved yet. Say Open pregnancy to set up your journey.", requiresConfirmation: false, confidence: command.confidence)
        }
        let text = command.entities["pregnancyNote"] ?? command.originalText
        let category = command.entities["pregnancyNoteCategory"].flatMap(NoteCategory.init(rawValue:)) ?? .general
        modelContext.insert(PregnancyNote(pregnancyProfileId: profile.id, text: text, category: category, weekNumber: profile.currentWeek))
        guard save() else {
            return HealthAssistantResponse(text: "I could not save your pregnancy note locally just now. Please try again.", requiresConfirmation: false, confidence: command.confidence)
        }
        if category == .forDoctor {
            return HealthAssistantResponse(text: "Saved as a question for your doctor. I'll keep it ready for your next appointment.", requiresConfirmation: false, confidence: command.confidence)
        }
        return HealthAssistantResponse(text: "Saved to your pregnancy notes.", requiresConfirmation: false, confidence: command.confidence)
    }

    private func pregnancyProfileSummary() -> String {
        guard let profile = activePregnancyProfile() else {
            return "I don't have any pregnancy information saved yet. You can set up your pregnancy journey by saying Open pregnancy and I'll take you there."
        }
        let week = max(1, min(42, profile.currentWeek))
        let info = PregnancyWeekGuide.info(for: week)
        let days = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: profile.dueDate)).day ?? 0)
        return "You are in week \(week) of your pregnancy. Your baby is about the size of a \(info.fruitComparison) this week. Your due date is \(profile.dueDate.formatted(date: .abbreviated, time: .omitted)), which is \(days) days away. This is informational only — please follow your doctor's guidance throughout your pregnancy."
    }

    private func save() -> Bool {
        do {
            try modelContext.save()
            NotificationCenter.default.post(name: .healthDataDidUpdate, object: nil)
            return true
        } catch {
            return false
        }
    }

    private func safetyMessage(for record: HealthRecord) -> String {
        guard let alert = HealthSafetyAlerter.alert(for: record) else { return "" }
        HealthSafetyAlerter.recordIfNeeded(alert)
        return " \(alert.title) \(alert.message)"
    }

    private func writeHealthKitSideEffect(type: HealthRecordType, value1: Double, value2: Double?, date: Date) {
        guard UserHealthProfile.healthKitWriteEnabled else { return }
        Task {
            let service = HealthKitService()
            service.refreshAuthorizationStatus()
            let writeService = HealthKitWriteService(service: service)
            let success: Bool
            switch type {
            case .bloodPressure:
                guard let value2 else { return }
                success = await writeService.writeBP(systolic: value1, diastolic: value2, date: date)
            case .bloodSugar:
                success = await writeService.writeBloodSugar(value: value1, date: date)
            case .weight:
                success = await writeService.writeWeight(kg: value1, date: date)
            case .temperature:
                success = await writeService.writeTemperature(celsius: value1, date: date)
            case .oxygen:
                success = await writeService.writeOxygen(percentage: value1, date: date)
            case .heartRate:
                success = await writeService.writeHeartRate(bpm: value1, date: date)
            }
            if !success {
                print("[ResponseEngine] Apple Health write skipped or failed for \(type.rawValue)")
            }
        }
    }

    private func healthKitSyncNote(for type: HealthRecordType) -> String {
        guard UserHealthProfile.healthKitWriteEnabled else { return "" }
        let service = HealthKitService()
        service.refreshAuthorizationStatus()
        guard service.isAvailable else {
            return " Saved in Tablets. Apple Health sync is off or unavailable."
        }

        switch type {
        case .bloodPressure:
            guard let systolic = HealthKitWriteAuthorization.quantityType(.bloodPressureSystolic),
                  let diastolic = HealthKitWriteAuthorization.quantityType(.bloodPressureDiastolic),
                  service.authorizationStatus(for: systolic) == .sharingAuthorized,
                  service.authorizationStatus(for: diastolic) == .sharingAuthorized else {
                return " Saved in Tablets. Apple Health sync is off or unavailable."
            }
        case .bloodSugar:
            guard let glucose = HealthKitWriteAuthorization.quantityType(.bloodGlucose),
                  service.authorizationStatus(for: glucose) == .sharingAuthorized else {
                return " Saved in Tablets. Apple Health sync is off or unavailable."
            }
        case .weight:
            guard let weight = HealthKitWriteAuthorization.quantityType(.bodyMass),
                  service.authorizationStatus(for: weight) == .sharingAuthorized else {
                return " Saved in Tablets. Apple Health sync is off or unavailable."
            }
        default:
            return ""
        }
        return ""
    }
}

private enum HealthKitWriteAuthorization {
    static func quantityType(_ identifier: HKQuantityTypeIdentifier) -> HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: identifier)
    }
}
