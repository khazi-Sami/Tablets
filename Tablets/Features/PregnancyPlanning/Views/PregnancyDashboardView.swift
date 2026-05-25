import SwiftData
import SwiftUI

struct PregnancyDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("pregnancy_hydration_reminders_enabled") private var hydrationEnabled = false
    let profile: PregnancyProfile
    @Binding var destination: PregnancyPlanningDestination?
    @StateObject private var viewModel = PregnancyDashboardViewModel()
    @State private var customHydrationMinutes = 20
    @State private var hydrationMessage: String?
    @State private var isShowingNutritionSuggestion = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        PregnancyDashboardCard(profile: profile, weekInfo: PregnancyWeekGuide.info(for: profile.currentWeek), daysUntilDue: viewModel.daysUntilDueDate)
                        LazyVGrid(columns: columns, spacing: 12) {
                            PregnancyActionTile(title: "Log Symptoms", subtitle: "How you feel today", symbol: PregnancyTheme.iconSymptom) { destination = .symptoms }
                            PregnancyActionTile(title: "Log Weight", subtitle: "Track gently", symbol: PregnancyTheme.iconWeight) { destination = .weight }
                            PregnancyActionTile(title: "Count Kicks", subtitle: "Tap each movement", symbol: PregnancyTheme.iconKick) { destination = .kicks }
                            PregnancyActionTile(title: "Contractions", subtitle: "Timer and history", symbol: "timer") { destination = .contractions }
                            PregnancyActionTile(title: "Log Mood", subtitle: "Feelings and energy", symbol: PregnancyTheme.iconMood) { destination = .mood }
                            PregnancyActionTile(title: "Quick Note", subtitle: "Save for doctor", symbol: PregnancyTheme.iconNotes) { destination = .notes }
                        }
                        featureRow
                        hydrationCard
                        supplementsCard
                        nutritionCard
                        recentSection
                    }
                    .padding(PregnancyTheme.pagePadding)
                }
            }
            .navigationTitle("Pregnancy & Planning")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                hydrationEnabled = profile.hydrationRemindersEnabled != false
                viewModel.loadDashboard(context: modelContext)
            }
            .onChange(of: hydrationEnabled) { _, enabled in
                profile.hydrationRemindersEnabled = enabled
                try? modelContext.save()
                if enabled {
                    hydrationMessage = nil
                    Task {
                        let result = await PregnancyHydrationService().scheduleHydrationReminders(for: profile)
                        handleHydrationScheduleResult(result, turningOnDailyReminders: true)
                    }
                } else {
                    hydrationMessage = "Hydration reminders are off."
                    PregnancyHydrationService().cancelAllHydrationReminders()
                }
            }
            .sheet(item: $destination) { destinationView($0) }
            .sheet(isPresented: $isShowingNutritionSuggestion) {
                nutritionSuggestionSheet
            }
        }
    }

    private var featureRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                featureButton("Week Guide", PregnancyTheme.iconWeekGuide, .weekGuide)
                featureButton("Milestones", PregnancyTheme.iconMilestone, .milestones)
                featureButton("Weight Chart", PregnancyTheme.iconGrowth, .weightChart)
                featureButton("Birth Plan", "list.clipboard.fill", .birthPlan)
                featureButton("Appointments", PregnancyTheme.iconAppointment, .appointments)
                featureButton("Timeline", "calendar.day.timeline.left", .timeline)
                nutritionButton
                featureButton("Supplements", "pills.fill", .appointments)
            }
        }
    }

    private func featureButton(_ title: String, _ symbol: String, _ destination: PregnancyPlanningDestination) -> some View {
        Button { self.destination = destination } label: {
            Label(title, systemImage: symbol)
                .font(PregnancyTheme.captionFont)
                .foregroundStyle(PregnancyTheme.deepRose)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(.white.opacity(0.66), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var nutritionButton: some View {
        Button {
            isShowingNutritionSuggestion = true
        } label: {
            Label("Nutrition Tip", systemImage: "carrot.fill")
                .font(PregnancyTheme.captionFont)
                .foregroundStyle(PregnancyTheme.deepRose)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(.white.opacity(0.66), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var recentSection: some View {
        PregnancyCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent logs")
                    .font(PregnancyTheme.headingFont)
                Text(viewModel.recentSymptoms.first?.symptoms.joined(separator: ", ") ?? "No symptom logs yet.")
                Text(viewModel.recentWeights.first.map { "Last weight: \($0.weight, specifier: "%.1f") \($0.unit.rawValue)" } ?? "No weight logs yet.")
                Text(viewModel.upcomingAppointments.first.map { "Next appointment: \($0.title)" } ?? "No upcoming pregnancy appointments.")
                Text(viewModel.recentMoods.first.map { "Last mood: \($0.mood.rawValue)" } ?? "No mood logs yet.")
                Text(viewModel.recentKicks.first.map { "Last kicks: \($0.kickCount)" } ?? "No kick sessions yet.")
                Text(viewModel.notesForDoctorCount > 0 ? "\(viewModel.notesForDoctorCount) notes for doctor" : "No doctor notes yet.")
                Text("This app supports your pregnancy journey with information and logging tools. It is not a substitute for professional medical care. Always follow your doctor's or midwife's advice.")
                    .font(PregnancyTheme.captionFont)
            }
            .font(PregnancyTheme.bodyFont)
            .foregroundStyle(AppColor.secondaryInk)
        }
    }

    private var hydrationCard: some View {
        PregnancyCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Hydration Reminders", systemImage: "drop.fill")
                        .font(PregnancyTheme.headingFont)
                        .foregroundStyle(PregnancyTheme.deepRose)
                    Spacer()
                    Toggle("", isOn: $hydrationEnabled)
                        .labelsHidden()
                }

                Text("Status: \(hydrationEnabled ? "ON" : "OFF")")
                    .font(PregnancyTheme.bodyFont.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
                Text(hydrationEnabled ? "Next reminder: 3:00 PM" : "Turn on gentle pregnancy-aware water reminders.")
                    .font(PregnancyTheme.captionFont)
                    .foregroundStyle(AppColor.secondaryInk)

                Text("One-time reminders")
                    .font(PregnancyTheme.bodyFont.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
                Text(hydrationEnabled ? "Set a one-time water reminder." : "Turn hydration reminders on to use quick reminders.")
                    .font(PregnancyTheme.captionFont)
                    .foregroundStyle(AppColor.secondaryInk)

                HStack(spacing: 10) {
                    hydrationButton("15 min", minutes: 15)
                    hydrationButton("30 min", minutes: 30)
                    hydrationButton("1 hour", minutes: 60)
                }

                HStack(spacing: 10) {
                    Stepper("\(customHydrationMinutes) min", value: $customHydrationMinutes, in: 5...180, step: 5)
                        .font(PregnancyTheme.captionFont)
                    Button("Set") {
                        scheduleHydration(minutes: customHydrationMinutes)
                    }
                    .font(PregnancyTheme.captionFont.weight(.bold))
                    .foregroundStyle(hydrationEnabled ? .white : AppColor.secondaryInk)
                    .frame(minWidth: 64, minHeight: 44)
                    .background(hydrationEnabled ? PregnancyTheme.deepRose : Color.gray.opacity(0.22), in: Capsule())
                    .disabled(!hydrationEnabled)
                }

                if let hydrationMessage {
                    Text(hydrationMessage)
                        .font(PregnancyTheme.captionFont)
                        .foregroundStyle(PregnancyTheme.deepRose)
                }
            }
        }
    }

    private func hydrationButton(_ title: String, minutes: Int) -> some View {
        Button {
            scheduleHydration(minutes: minutes)
        } label: {
            Text(title)
                .font(PregnancyTheme.captionFont)
                .foregroundStyle(hydrationEnabled ? PregnancyTheme.deepRose : AppColor.secondaryInk)
                .frame(minHeight: 44)
                .padding(.horizontal, 12)
                .background(hydrationEnabled ? PregnancyTheme.blushPink.opacity(0.55) : Color.gray.opacity(0.18), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!hydrationEnabled)
    }

    private func scheduleHydration(minutes: Int) {
        guard hydrationEnabled else {
            PregnancyHydrationService().cancelAllHydrationReminders()
            hydrationMessage = "Turn hydration reminders on before setting a water reminder."
            return
        }
        Task {
            let result = await PregnancyHydrationService().scheduleQuickReminder(minutes: minutes)
            handleHydrationScheduleResult(result, minutes: minutes)
        }
    }

    private func handleHydrationScheduleResult(
        _ result: PregnancyHydrationScheduleResult,
        minutes: Int? = nil,
        turningOnDailyReminders: Bool = false
    ) {
        switch result {
        case .scheduled:
            if let minutes {
                hydrationMessage = "Water reminder set for \(minutes) minute\(minutes == 1 ? "" : "s")."
            } else if turningOnDailyReminders {
                hydrationMessage = "Hydration reminders are on."
            }
        case .denied:
            hydrationEnabled = false
            profile.hydrationRemindersEnabled = false
            try? modelContext.save()
            PregnancyHydrationService().cancelAllHydrationReminders()
            hydrationMessage = "Notifications are off. Turn them on in Settings to use hydration reminders."
        case .failed:
            if turningOnDailyReminders {
                hydrationEnabled = false
                profile.hydrationRemindersEnabled = false
                try? modelContext.save()
                PregnancyHydrationService().cancelAllHydrationReminders()
            }
            hydrationMessage = "Could not schedule that reminder. Please try again."
        }
    }

    private var supplementsCard: some View {
        PregnancyCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Supplements", systemImage: "pills.fill")
                    .font(PregnancyTheme.headingFont)
                    .foregroundStyle(PregnancyTheme.deepRose)

                if viewModel.supplementSuggestions.isEmpty {
                    Text("No supplement suggestions for this week.")
                        .font(PregnancyTheme.bodyFont)
                        .foregroundStyle(AppColor.secondaryInk)
                } else {
                    ForEach(viewModel.supplementSuggestions.prefix(3)) { suggestion in
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(suggestion.name) · \(suggestion.importanceLevel.rawValue)")
                                .font(PregnancyTheme.bodyFont.weight(.semibold))
                                .foregroundStyle(AppColor.ink)
                            Text(suggestion.reason)
                                .font(PregnancyTheme.captionFont)
                                .foregroundStyle(AppColor.secondaryInk)
                        }
                    }
                }

                if !viewModel.trackedSupplements.isEmpty {
                    Text("Tracked in Medicines: \(viewModel.trackedSupplements.prefix(3).map(\.name).joined(separator: ", "))")
                        .font(PregnancyTheme.captionFont)
                        .foregroundStyle(PregnancyTheme.deepRose)
                }

                Text("Please confirm with your doctor before starting any supplement.")
                    .font(PregnancyTheme.captionFont)
                    .foregroundStyle(AppColor.secondaryInk)

                NavigationLink {
                    MedicinesView()
                } label: {
                    Text("Open Medicines")
                        .font(PregnancyTheme.bodyFont.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(PregnancyTheme.deepRose, in: RoundedRectangle(cornerRadius: PregnancyTheme.buttonRadius))
                }
            }
        }
    }

    private var nutritionCard: some View {
        let guide = PregnancyNutritionGuide().getSuggestion(for: profile.currentWeek, query: "pregnancy nutrition")
        return PregnancyCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Nutrition Tip", systemImage: "carrot.fill")
                    .font(PregnancyTheme.headingFont)
                    .foregroundStyle(PregnancyTheme.deepRose)
                Text(guide)
                    .font(PregnancyTheme.captionFont)
                    .foregroundStyle(AppColor.secondaryInk)
                    .lineLimit(5)
                Button {
                    isShowingNutritionSuggestion = true
                } label: {
                    Text("View full suggestion")
                        .font(PregnancyTheme.bodyFont.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(PregnancyTheme.deepRose, in: RoundedRectangle(cornerRadius: PregnancyTheme.buttonRadius))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var nutritionSuggestionSheet: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()
                ScrollView {
                    PregnancyCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Nutrition suggestion", systemImage: "carrot.fill")
                                .font(PregnancyTheme.headingFont)
                                .foregroundStyle(PregnancyTheme.deepRose)
                            Text(PregnancyNutritionGuide().getSuggestion(for: profile.currentWeek, query: "pregnancy nutrition"))
                                .font(PregnancyTheme.bodyFont)
                                .foregroundStyle(AppColor.secondaryInk)
                            Text("This screen does not start voice playback.")
                                .font(PregnancyTheme.captionFont)
                                .foregroundStyle(AppColor.secondaryInk)
                        }
                    }
                    .padding(PregnancyTheme.pagePadding)
                }
            }
            .navigationTitle("Nutrition Tip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isShowingNutritionSuggestion = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView(_ destination: PregnancyPlanningDestination) -> some View {
        switch destination {
        case .symptoms: PregnancySymptomLogView(profile: profile)
        case .weight: PregnancyWeightLogView(profile: profile)
        case .kicks: BabyKickCounterView(profile: profile)
        case .appointments: PregnancyAppointmentView(profile: profile)
        case .weekGuide: PregnancyWeekGuideView(currentWeek: profile.currentWeek)
        case .milestones: PregnancyMilestoneView(profile: profile)
        case .contractions: ContractionTimerView(profile: profile)
        case .mood: MoodTrackingView(profile: profile)
        case .timeline: PregnancyTimelineView(profile: profile)
        case .weightChart: PregnancyWeightChartView(profile: profile)
        case .birthPlan: BirthPlanView(profile: profile)
        case .notes: PregnancyNotesView(profile: profile)
        }
    }
}
