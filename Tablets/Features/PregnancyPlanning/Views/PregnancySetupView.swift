import SwiftData
import SwiftUI

struct PregnancySetupView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = PregnancySetupViewModel()
    @State private var step = 0
    let onCompleted: (PregnancyProfile) -> Void

    init(onCompleted: @escaping (PregnancyProfile) -> Void = { _ in }) {
        self.onCompleted = onCompleted
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.heroGradient.ignoresSafeArea()
                VStack(spacing: 22) {
                    Text(["🌸", "💛", "🎀"][min(step, 2)])
                        .font(.system(size: 72))
                        .scaleEffect(1.0)
                    PregnancyCard {
                        VStack(alignment: .leading, spacing: 18) {
                            Text(stepTitle)
                                .font(PregnancyTheme.titleFont)
                                .foregroundStyle(AppColor.ink)
                            stepContent
                            if let validationMessage = viewModel.validationMessage {
                                Text(validationMessage)
                                    .font(PregnancyTheme.captionFont)
                                    .foregroundStyle(AppColor.softRed)
                                    .accessibilityLabel(validationMessage)
                            }
                            if let saveErrorMessage = viewModel.saveErrorMessage {
                                Text(saveErrorMessage)
                                    .font(PregnancyTheme.captionFont)
                                    .foregroundStyle(AppColor.softRed)
                                    .accessibilityLabel(saveErrorMessage)
                            }
                        }
                    }
                    Spacer()
                    Button {
                        guard viewModel.validateCurrentStep(step) else { return }

                        if step < 2 {
                            #if DEBUG
                            print("[PregnancySetup] Moving from step \(step) to step \(step + 1)")
                            #endif
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { step += 1 }
                        } else if let profile = viewModel.saveProfile(context: modelContext) {
                            #if DEBUG
                            print("[PregnancySetup] Setup completed. profileID=\(profile.id)")
                            #endif
                            onCompleted(profile)
                        }
                    } label: {
                        HStack {
                            if viewModel.isSaving {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.isSaving ? "Saving..." : step == 2 ? "Start My Journey" : "Continue")
                                .font(PregnancyTheme.bodyFont.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(PregnancyTheme.deepRose.opacity(viewModel.isSaving ? 0.72 : 1), in: RoundedRectangle(cornerRadius: PregnancyTheme.buttonRadius))
                    }
                    .disabled(viewModel.isSaving)
                }
                .padding(PregnancyTheme.pagePadding)
            }
            .navigationTitle("Pregnancy & Planning")
            .navigationBarTitleDisplayMode(.inline)
        }
        .dismissKeyboardOnTap()
    }

    private var stepTitle: String {
        step == 0 ? "Set up your journey" : step == 1 ? "Baby nickname" : "Ready to begin"
    }

    @ViewBuilder
    private var stepContent: some View {
        if step == 0 {
            Picker("Setup mode", selection: $viewModel.setupMode) {
                Text("I know my Last Period date").tag(PregnancySetupViewModel.SetupMode.lmp)
                Text("I know my Due Date").tag(PregnancySetupViewModel.SetupMode.dueDate)
                Text("I am planning for pregnancy").tag(PregnancySetupViewModel.SetupMode.planning)
            }
            .pickerStyle(.inline)
            if viewModel.setupMode == .dueDate {
                DatePicker("Due date", selection: $viewModel.dueDate, displayedComponents: .date)
            } else {
                DatePicker("Last period date", selection: $viewModel.lmpDate, displayedComponents: .date)
            }
        } else if step == 1 {
            TextField("Little one, Peanut, Star...", text: $viewModel.babyNickname)
                .font(PregnancyTheme.bodyFont)
                .padding(14)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: PregnancyTheme.buttonRadius))
        } else {
            let due = viewModel.setupMode == .dueDate ? viewModel.dueDate : viewModel.calculateDueDate(from: viewModel.lmpDate)
            let lmp = viewModel.setupMode == .dueDate ? viewModel.calculateLMP(from: due) : viewModel.lmpDate
            let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lmp), to: Calendar.current.startOfDay(for: .now)).day ?? 0
            let week = max(1, min(42, (days / 7) + 1))
            let info = PregnancyWeekGuide.info(for: week)
            Text("Due date: \(due.formatted(date: .abbreviated, time: .omitted))")
            Text("Current estimate: Week \(week)")
            Text("Baby size this week: \(info.fruitComparison) \(info.emoji)")
            Text("Informational only. Please follow your doctor's guidance.")
                .font(PregnancyTheme.captionFont)
                .foregroundStyle(AppColor.secondaryInk)
        }
    }
}
