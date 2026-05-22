#if DEBUG
import SwiftData
import SwiftUI

struct AdaptiveReminderDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medicine.name) private var medicines: [Medicine]

    @State private var patterns: [MedicineTakePattern] = []
    @State private var shifts: [AdaptiveShift] = []
    @State private var followUpManager: MissedDoseFollowUpManager?
    @State private var isWorking = false

    var body: some View {
        List {
            Section {
                Label("Developer Debug Only", systemImage: "hammer.fill")
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.medicalBlueDeep)
                Text("Use this screen to inspect learned reminder timing and test follow-up notifications. It is hidden from production builds.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }

            Section("Computed Patterns") {
                if patterns.isEmpty {
                    Text("No adaptive patterns yet. At least 5 taken logs are needed.")
                        .foregroundStyle(AppColor.secondaryInk)
                } else {
                    ForEach(patterns) { pattern in
                        VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                            Text(pattern.medicineName)
                                .font(AppFont.bodyStrong)
                            Text("Scheduled: \(timeText(pattern.scheduledTime))")
                            Text("Average offset: \(pattern.averageActualMinuteOffset) min")
                            Text("Samples: \(pattern.sampleCount) • \(pattern.confidenceLevel.title)")
                        }
                        .font(AppFont.caption)
                    }
                }
            }

            Section("Actions") {
                Button("Apply Shifts Now") {
                    Task { await applyShifts() }
                }
                .disabled(isWorking)

                Button("Reset All to Original") {
                    Task { await resetAll() }
                }
                .disabled(isWorking)
            }

            Section("Medicines") {
                if medicines.isEmpty {
                    Text("No medicines found.")
                        .foregroundStyle(AppColor.secondaryInk)
                } else {
                    ForEach(medicines) { medicine in
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                                Text(medicine.name)
                                    .font(AppFont.bodyStrong)
                                Text("\(medicine.times.count) scheduled time(s)")
                                    .font(AppFont.caption)
                                    .foregroundStyle(AppColor.secondaryInk)
                            }

                            Spacer()

                            Button("Simulate Missed Dose") {
                                Task { await simulateMissedDose(for: medicine) }
                            }
                            .font(AppFont.caption)
                        }
                    }
                }
            }

            Section("Applied Shift History") {
                if shifts.isEmpty {
                    Text("No shifts applied in this debug session.")
                        .foregroundStyle(AppColor.secondaryInk)
                } else {
                    ForEach(shifts) { shift in
                        VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                            Text(shift.medicineName)
                                .font(AppFont.bodyStrong)
                            Text("\(shift.originalTime.formatted(date: .omitted, time: .shortened)) → \(shift.shiftedTime.formatted(date: .omitted, time: .shortened))")
                            Text("Shift: \(shift.shiftMinutes) min")
                        }
                        .font(AppFont.caption)
                    }
                }
            }

            Section("Active Follow-Ups") {
                let activeFollowUps = followUpManager?.activeFollowUps ?? []
                if activeFollowUps.isEmpty {
                    Text("No active follow-ups in this debug session.")
                        .foregroundStyle(AppColor.secondaryInk)
                } else {
                    ForEach(activeFollowUps) { followUp in
                        VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                            Text(followUp.medicineName)
                                .font(AppFont.bodyStrong)
                            Text("Fires: \(followUp.followUpFireAt.formatted(date: .abbreviated, time: .shortened))")
                            Text(followUp.isCancelled ? "Cancelled" : "Pending")
                        }
                        .font(AppFont.caption)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColor.warmWhite)
        .safeAreaPadding(.bottom, 110)
        .navigationTitle("Adaptive Reminder Debug")
        .task {
            ensureFollowUpManager()
            await refreshPatterns()
        }
    }

    private func ensureFollowUpManager() {
        if followUpManager == nil {
            followUpManager = MissedDoseFollowUpManager(modelContext: modelContext)
        }
    }

    private func refreshPatterns() async {
        isWorking = true
        let engine = AdaptiveReminderEngine(modelContext: modelContext)
        patterns = await engine.analyzePatternsForAllMedicines()
        isWorking = false
    }

    private func applyShifts() async {
        isWorking = true
        let engine = AdaptiveReminderEngine(modelContext: modelContext)
        let scheduler = AdaptiveReminderScheduler(engine: engine, modelContext: modelContext)
        shifts = await scheduler.applyAdaptiveShifts()
        patterns = await engine.analyzePatternsForAllMedicines()
        isWorking = false
    }

    private func resetAll() async {
        isWorking = true
        let engine = AdaptiveReminderEngine(modelContext: modelContext)
        let scheduler = AdaptiveReminderScheduler(engine: engine, modelContext: modelContext)
        await scheduler.resetAllToOriginalSchedule()
        isWorking = false
    }

    private func simulateMissedDose(for medicine: Medicine) async {
        ensureFollowUpManager()
        await followUpManager?.scheduleFollowUp(for: medicine, scheduledAt: .now)
    }

    private func timeText(_ components: DateComponents) -> String {
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
}
#endif
