import SwiftData
import SwiftUI

struct MedicineAdaptiveSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let medicine: Medicine

    @State private var patterns: [MedicineTakePattern] = []
    @State private var isLoading = true
    private let preferenceStore = AdaptiveReminderPreferenceStore()
    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            List {
                Section {
            Text("BanyAI can learn when you usually take each reminder time and gently adjust the suggestion. This is just a helpful reminder adjustment.")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                }

                Section("Reminder Times") {
                    if medicine.times.isEmpty {
                        Text("No reminder times saved for this medicine.")
                            .foregroundStyle(AppColor.secondaryInk)
                    } else if isLoading {
                        ProgressView()
                    } else {
                        ForEach(medicine.times.sorted(), id: \.self) { time in
                            timeRow(for: time)
                        }
                    }
                }

                Section {
            Button("Reset all timing preferences", role: .destructive) {
                preferenceStore.resetAll(for: medicine.persistentModelID)
                Task {
                    let engine = AdaptiveReminderEngine(modelContext: modelContext)
                    let scheduler = AdaptiveReminderScheduler(engine: engine, modelContext: modelContext)
                    await scheduler.resetToOriginalSchedule(for: medicine)
                }
            }
                }
            }
            .navigationTitle("Timing Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                let engine = AdaptiveReminderEngine(modelContext: modelContext)
                patterns = await engine.analyzePatterns(for: medicine)
                isLoading = false
            }
        }
    }

    private func timeRow(for time: Date) -> some View {
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let pattern = pattern(for: time)
        let enabled = preferenceStore.isEnabled(medicineID: medicine.persistentModelID, scheduledTime: components)

        return VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                    Text(time.formatted(date: .omitted, time: .shortened))
                        .font(AppFont.bodyStrong)
                    if let pattern, pattern.sampleCount >= 5 {
                        Text(learnedSummary(for: pattern, originalTime: time))
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    } else {
                        Text("Keep taking medicines. After a few doses, BanyAI will learn your routine.")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    }
                }

                Spacer()

                Toggle("Adjust reminder to my habit", isOn: Binding(
                    get: { enabled },
                    set: { preferenceStore.setEnabled($0, medicineID: medicine.persistentModelID, scheduledTime: components) }
                ))
                .labelsHidden()
                .disabled(pattern == nil || (pattern?.sampleCount ?? 0) < 5)
            }

            if let pattern, pattern.sampleCount >= 5, enabled {
                AdaptiveTimingInsight(pattern: pattern, learnedTime: learnedTime(for: pattern, originalTime: time))
            }

            Button("Reset this time") {
                preferenceStore.reset(medicineID: medicine.persistentModelID, scheduledTime: components)
                Task {
                    let engine = AdaptiveReminderEngine(modelContext: modelContext)
                    let scheduler = AdaptiveReminderScheduler(engine: engine, modelContext: modelContext)
                    await scheduler.resetSchedulesToOriginal(medicineID: medicine.persistentModelID, scheduledTime: components)
                }
            }
            .font(AppFont.caption)
        }
        .padding(.vertical, Spacing.xxSmall)
    }

    private func pattern(for time: Date) -> MedicineTakePattern? {
        let key = AdaptiveReminderTimeKey.key(from: time, calendar: calendar)
        return patterns.first { AdaptiveReminderTimeKey.key(from: $0.scheduledTime) == key }
    }

    private func learnedSummary(for pattern: MedicineTakePattern, originalTime: Date) -> String {
        guard let learnedTime = learnedTime(for: pattern, originalTime: originalTime) else {
            return "Based on \(pattern.sampleCount) doses."
        }
        return "Your body clock says \(learnedTime.formatted(date: .omitted, time: .shortened)), based on \(pattern.sampleCount) doses."
    }

    private func learnedTime(for pattern: MedicineTakePattern, originalTime: Date) -> Date? {
        calendar.date(byAdding: .minute, value: pattern.averageActualMinuteOffset, to: originalTime)
    }
}
