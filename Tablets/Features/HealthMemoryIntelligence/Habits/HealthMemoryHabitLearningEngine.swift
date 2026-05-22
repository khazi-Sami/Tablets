import Foundation
import SwiftData

@MainActor
struct HealthMemoryHabitLearningEngine {
    let modelContext: ModelContext

    func learn(
        command: ParsedHealthCommand,
        medicines: [Medicine],
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord],
        dailyLogs: [WomensHealthDailyLog],
        interactions: [AssistantInteractionMemory]
    ) {
        modelContext.insert(AssistantInteractionMemory(phrase: command.originalText, intent: command.intent, responseTone: .balanced))
        learnCommonPhrase(command)
        learnLoggingHabits(healthRecords)
        learnReminderBehavior(medicineLogs)
        learnRecurringSymptoms(command: command, dailyLogs: dailyLogs)
        learnMedicineTiming(medicines)
        try? modelContext.save()
    }

    private func learnCommonPhrase(_ command: ParsedHealthCommand) {
        modelContext.insert(HealthPatternMemory(
            patternType: .phrase,
            label: command.originalText.lowercased(),
            summary: "Common assistant phrase: \(command.originalText)"
        ))
    }

    private func learnLoggingHabits(_ records: [HealthRecord]) {
        let bpHour = mostCommonHour(records.filter { $0.type == .bloodPressure }.map(\.measuredAt))
        if let bpHour {
            modelContext.insert(UserHealthHabit(
                habitType: .bpLogging,
                title: "Usual BP recording time",
                detail: "You often record BP around \(formattedHour(bpHour)), based on your saved logs.",
                preferredHour: bpHour,
                confidence: 0.72
            ))
        }

        let sugarHour = mostCommonHour(records.filter { $0.type == .bloodSugar }.map(\.measuredAt))
        if let sugarHour {
            modelContext.insert(UserHealthHabit(
                habitType: .sugarLogging,
                title: "Usual sugar logging time",
                detail: "You often log sugar around \(formattedHour(sugarHour)), based on your saved logs.",
                preferredHour: sugarHour,
                confidence: 0.70
            ))
        }
    }

    private func learnReminderBehavior(_ logs: [MedicineLog]) {
        for log in logs.prefix(30) {
            guard let medicineName = log.medicine?.name else { continue }
            let delay = log.takenTime.map { max($0.timeIntervalSince(log.scheduledTime) / 60, 0) } ?? 0
            modelContext.insert(ReminderBehaviorMemory(
                medicineName: medicineName,
                scheduledHour: Calendar.current.component(.hour, from: log.scheduledTime),
                averageDelayMinutes: delay,
                snoozeCount: log.status == .snoozed ? 1 : 0,
                missedCount: log.status == .missed || log.status == .skipped ? 1 : 0,
                takenCount: log.status == .taken ? 1 : 0
            ))
        }
    }

    private func learnRecurringSymptoms(command: ParsedHealthCommand, dailyLogs: [WomensHealthDailyLog]) {
        let symptoms = command.symptoms + dailyLogs.flatMap(\.symptoms)
        for symptom in Set(symptoms) where !symptom.isEmpty {
            let count = symptoms.filter { $0 == symptom }.count
            guard count > 0 else { continue }
            modelContext.insert(HealthPatternMemory(
                patternType: .symptom,
                label: symptom,
                summary: "\(symptom.capitalized) appeared \(count) time\(count == 1 ? "" : "s") based on your saved logs.",
                occurrences: count
            ))
        }
    }

    private func learnMedicineTiming(_ medicines: [Medicine]) {
        for medicine in medicines where medicine.isActive {
            guard let hour = mostCommonHour(medicine.times) else { continue }
            modelContext.insert(UserHealthHabit(
                habitType: .medicineTiming,
                title: "\(medicine.name) timing",
                detail: "\(medicine.name) is usually scheduled around \(formattedHour(hour)), based on your saved reminders.",
                preferredHour: hour,
                confidence: 0.76
            ))
        }
    }

    private func mostCommonHour(_ dates: [Date]) -> Int? {
        Dictionary(grouping: dates) { Calendar.current.component(.hour, from: $0) }
            .max { $0.value.count < $1.value.count }?
            .key
    }

    private func formattedHour(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }
}
