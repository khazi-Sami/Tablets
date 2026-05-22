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
        case .unknown:
            return HealthAssistantResponse(text: "I did not catch that clearly. You can say, my sugar is 145 after food, or how is my BP.", requiresConfirmation: true, confidence: command.confidence)
        }
    }

    private func logSugar(_ command: ParsedHealthCommand, healthRecords: [HealthRecord]) -> HealthAssistantResponse {
        guard let value = command.numbers.first else {
            return HealthAssistantResponse(text: "Please say the sugar value again before I save it.", requiresConfirmation: true, confidence: command.confidence)
        }
        let testType = command.entities["sugarTestType"].flatMap(SugarTestType.init(rawValue:)) ?? .random
        modelContext.insert(HealthRecord(type: .bloodSugar, value1: value, unit: "mg/dL", notes: "Added by Human Voice Assistant", sugarTestType: testType))
        guard save() else {
            return HealthAssistantResponse(text: "I understood the sugar reading, but I could not save it locally just now. Please try again.", requiresConfirmation: false, confidence: command.confidence)
        }
        writeHealthKitSideEffect(type: .bloodSugar, value1: value, value2: nil, date: .now)
        let comparison = comparisonEngine.sugarComparison(value: value, testType: testType, records: healthRecords)
        return HealthAssistantResponse(text: variationPool.sugarSaved(value: Int(value), context: testType.title.lowercased(), comparison: comparison) + healthKitSyncNote(for: .bloodSugar), requiresConfirmation: false, confidence: command.confidence)
    }

    private func logBloodPressure(_ command: ParsedHealthCommand) -> HealthAssistantResponse {
        guard command.numbers.count >= 2 else {
            return HealthAssistantResponse(text: "Please say both BP numbers, like 120 over 80, before I save it.", requiresConfirmation: true, confidence: command.confidence)
        }
        modelContext.insert(HealthRecord(type: .bloodPressure, value1: command.numbers[0], value2: command.numbers[1], unit: "mmHg", notes: "Added by Human Voice Assistant"))
        guard save() else {
            return HealthAssistantResponse(text: "I understood the BP reading, but I could not save it locally just now. Please try again.", requiresConfirmation: false, confidence: command.confidence)
        }
        writeHealthKitSideEffect(type: .bloodPressure, value1: command.numbers[0], value2: command.numbers[1], date: .now)
        return HealthAssistantResponse(text: variationPool.bpSaved(systolic: Int(command.numbers[0]), diastolic: Int(command.numbers[1]), comparison: variationPool.safeComparison()) + healthKitSyncNote(for: .bloodPressure), requiresConfirmation: false, confidence: command.confidence)
    }

    private func logWeight(_ command: ParsedHealthCommand) -> HealthAssistantResponse {
        guard let value = command.numbers.first else {
            return HealthAssistantResponse(text: "Please say the weight again before I save it.", requiresConfirmation: true, confidence: command.confidence)
        }
        modelContext.insert(HealthRecord(type: .weight, value1: value, unit: "kg", notes: "Added by Human Voice Assistant"))
        guard save() else {
            return HealthAssistantResponse(text: "I understood the weight reading, but I could not save it locally just now. Please try again.", requiresConfirmation: false, confidence: command.confidence)
        }
        writeHealthKitSideEffect(type: .weight, value1: value, value2: nil, date: .now)
        return HealthAssistantResponse(text: "Saved your weight as \(Int(value)) kg. This is informational only." + healthKitSyncNote(for: .weight), requiresConfirmation: false, confidence: command.confidence)
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

    private func save() -> Bool {
        do {
            try modelContext.save()
            NotificationCenter.default.post(name: .healthDataDidUpdate, object: nil)
            return true
        } catch {
            return false
        }
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
