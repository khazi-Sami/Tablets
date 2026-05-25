import Combine
import Foundation
import SwiftData
import UIKit

@MainActor
final class AddHealthRecordViewModel: ObservableObject {
    @Published var type: HealthRecordType
    @Published var systolic = "120"
    @Published var diastolic = "80"
    @Published var pulse = "72"
    @Published var singleValue = ""
    @Published var sugarTestType: SugarTestType = .fasting
    @Published var measuredAt = Date()
    @Published var mood = ""
    @Published var symptoms: Set<String> = []
    @Published var notes = ""
    @Published var errorMessage: String?
    @Published var didSave = false
    @Published var latestSafetyAlert: HealthSafetyAlert?

    init(type: HealthRecordType = .bloodPressure) {
        self.type = type
        self.singleValue = Self.defaultValue(for: type)
    }

    func save(modelContext: ModelContext) -> Bool {
        guard let record = makeRecord() else {
            errorMessage = "Please enter a valid number."
            HapticsManager.notification(.error)
            return false
        }

        do {
            try HealthRecordRepository(modelContext: modelContext).add(record)
            latestSafetyAlert = HealthSafetyAlerter.alert(for: record)
            HealthSafetyAlerter.recordIfNeeded(latestSafetyAlert)
            didSave = true
            HapticsManager.notification(.success)
            return true
        } catch {
            errorMessage = error.localizedDescription
            HapticsManager.notification(.error)
            return false
        }
    }

    private func makeRecord() -> HealthRecord? {
        switch type {
        case .bloodPressure:
            guard let sys = Double(systolic), let dia = Double(diastolic) else { return nil }
            return HealthRecord(type: .bloodPressure, value1: sys, value2: dia, unit: type.unit, measuredAt: measuredAt, notes: notes, mood: mood, symptoms: Array(symptoms))
        case .bloodSugar:
            guard let value = Double(singleValue) else { return nil }
            return HealthRecord(type: .bloodSugar, value1: value, unit: type.unit, measuredAt: measuredAt, notes: notes, mood: mood, symptoms: Array(symptoms), sugarTestType: sugarTestType)
        case .heartRate, .oxygen, .weight, .temperature:
            guard let value = Double(singleValue) else { return nil }
            return HealthRecord(type: type, value1: value, unit: type.unit, measuredAt: measuredAt, notes: notes, mood: mood, symptoms: Array(symptoms))
        }
    }

    static func defaultValue(for type: HealthRecordType) -> String {
        switch type {
        case .bloodPressure: return ""
        case .bloodSugar: return "96"
        case .heartRate: return "72"
        case .oxygen: return "98"
        case .weight: return "70"
        case .temperature: return "98.6"
        }
    }
}

@MainActor
final class DiabetesTrackingViewModel: ObservableObject {
    @Published var fasting = "96"
    @Published var afterMeal = "132"
    @Published var hba1c = "5.6"
    @Published var medicineNote = ""
    @Published var mealNote = ""
    @Published var exerciseNote = ""
    @Published var symptoms: Set<String> = []
    @Published var didSave = false
    @Published var errorMessage: String?

    let symptomOptions = ["Dizziness", "Sweating", "Fatigue", "Frequent urination", "Blurred vision", "Headache"]

    func toggle(_ symptom: String) {
        if symptoms.contains(symptom) { symptoms.remove(symptom) } else { symptoms.insert(symptom) }
        HapticsManager.selection()
    }

    func save(modelContext: ModelContext) -> Bool {
        guard let fastingValue = Double(fasting), let afterMealValue = Double(afterMeal), let hba1cValue = Double(hba1c) else {
            errorMessage = "Please enter valid sugar values."
            return false
        }
        do {
            let fastingRecord = HealthRecord(type: .bloodSugar, value1: fastingValue, unit: "mg/dL", notes: medicineNote, symptoms: Array(symptoms), sugarTestType: .fasting)
            let afterMealRecord = HealthRecord(type: .bloodSugar, value1: afterMealValue, unit: "mg/dL", notes: mealNote, symptoms: Array(symptoms), sugarTestType: .afterMeal)
            let hba1cRecord = HealthRecord(type: .bloodSugar, value1: hba1cValue, unit: "%", notes: exerciseNote, symptoms: Array(symptoms), sugarTestType: .hba1c)
            try HealthRecordRepository(modelContext: modelContext).add(fastingRecord)
            try HealthRecordRepository(modelContext: modelContext).add(afterMealRecord)
            try HealthRecordRepository(modelContext: modelContext).add(hba1cRecord)
            [fastingRecord, afterMealRecord, hba1cRecord]
                .compactMap(HealthSafetyAlerter.alert(for:))
                .forEach { HealthSafetyAlerter.recordIfNeeded($0) }
            didSave = true
            HapticsManager.notification(.success)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
