import SwiftData
import SwiftUI

struct MedicineReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MedicineReminderViewModel()
    @State private var isEditingMedicine = false

    let medicine: Medicine?

    init(medicine: Medicine? = nil) {
        self.medicine = medicine
    }

    var body: some View {
        ZStack {
            ReminderTimeBackground()
                .ignoresSafeArea()

            BreathingGlowView(color: backgroundAccent)
                .offset(y: -130)

            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.medium) {
                    topBar

                    FloatingMedicineAnimationView(
                        medicineType: medicineType,
                        isHeartMedicine: isHeartMedicine
                    )
                    .frame(height: 160)
                    .padding(.top, Spacing.small)

                    VStack(spacing: Spacing.small) {
                        Text(timeMessage)
                            .font(AppFont.caption)
                            .foregroundStyle(secondaryText)

                        Text("Time for \(medicineName)")
                            .font(AppFont.title)
                            .foregroundStyle(primaryText)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.78)

                        Text(dosageText)
                            .font(AppFont.sectionTitle)
                            .foregroundStyle(accentText)

                        Text(viewModel.caringMessage)
                            .font(AppFont.body)
                            .foregroundStyle(secondaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, Spacing.small)
                    }

                    ReminderVoiceButton(isSpeaking: viewModel.isSpeaking) {
                        viewModel.speakReminder(
                            medicineName: medicineName,
                            dosage: dosageText,
                            instruction: instructionText
                        )
                    }

                    if let medicine {
                        AdaptiveReminderToggleCard(medicine: medicine)
                    }

                    if viewModel.didTakeMedicine {
                        ReminderSuccessAnimationView()
                            .transition(.scale.combined(with: .opacity))
                    }

                    Color.clear.frame(height: 150)
                }
                .padding(Spacing.medium)
            }
        }
        .safeAreaInset(edge: .bottom) {
            reminderActions
                .padding(Spacing.medium)
                .background(
                    LinearGradient(
                        colors: [
                            AppColor.warmWhite.opacity(isNight ? 0.04 : 0.20),
                            AppColor.warmWhite.opacity(isNight ? 0.18 : 0.92)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                )
        }
        .sheet(isPresented: $isEditingMedicine) {
            if let medicine {
                EditMedicineView(medicine: medicine)
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: viewModel.didTakeMedicine)
        .onDisappear {
            viewModel.stopVoice()
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                Text("Gentle Reminder")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(primaryText)
                Text(instructionText)
                    .font(AppFont.caption)
                    .foregroundStyle(secondaryText)
            }

            Spacer()

            if medicine != nil {
                Button {
                    HapticsManager.selection()
                    isEditingMedicine = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(primaryText)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(isNight ? 0.12 : 0.62))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Edit medicine")
            }

            Button {
                HapticsManager.selection()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(primaryText)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(isNight ? 0.12 : 0.62))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close reminder")
        }
    }

    private var reminderActions: some View {
        VStack(spacing: Spacing.small) {
            Button {
                viewModel.markTaken(medicine: medicine, modelContext: modelContext)
            } label: {
                Label("Taken", systemImage: "checkmark.circle.fill")
                    .font(AppFont.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 66)
                    .background(AppGradient.primaryButton)
                    .clipShape(Capsule())
                    .appShadow(AppShadow.button)
            }
            .buttonStyle(.plain)

            HStack(spacing: Spacing.small) {
                ReminderSecondaryAction(title: "Snooze", systemImage: "bell.badge.fill", color: AppColor.lavenderDeep) {
                    viewModel.snooze(medicine: medicine, modelContext: modelContext)
                }

                ReminderSecondaryAction(title: "Skip", systemImage: "forward.end.fill", color: AppColor.softRed) {
                    viewModel.skip(medicine: medicine, modelContext: modelContext)
                }
            }
        }
    }

    private var medicineName: String {
        medicine?.name ?? "Vitamin D"
    }

    private var dosageText: String {
        medicine?.dosage ?? "1000 IU"
    }

    private var instructionText: String {
        medicine?.instruction.title ?? "After breakfast"
    }

    private var medicineType: MedicineType {
        medicine?.medicineType ?? .capsule
    }

    private var isHeartMedicine: Bool {
        let name = medicineName.lowercased()
        return name.contains("heart") || name.contains("bp") || name.contains("cardio")
    }

    private var hour: Int {
        Calendar.current.component(.hour, from: .now)
    }

    private var isNight: Bool {
        hour < 6 || hour >= 19
    }

    private var timeMessage: String {
        switch hour {
        case 5..<12: return "A soft morning nudge"
        case 12..<17: return "A caring afternoon check-in"
        case 17..<19: return "A gentle evening reminder"
        default: return "A calm night reminder"
        }
    }

    private var backgroundAccent: Color {
        isNight ? AppColor.lavenderDeep : AppColor.medicalBlue
    }

    private var primaryText: Color {
        isNight ? AppColor.warmWhite : AppColor.ink
    }

    private var secondaryText: Color {
        isNight ? AppColor.warmWhite.opacity(0.78) : AppColor.secondaryInk
    }

    private var accentText: Color {
        isNight ? AppColor.mintGreen : AppColor.medicalBlueDeep
    }
}

private struct ReminderTimeBackground: View {
    private var hour: Int {
        Calendar.current.component(.hour, from: .now)
    }

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            AppColor.warmWhite.opacity(hour >= 19 || hour < 6 ? 0.03 : 0.28)
        )
    }

    private var colors: [Color] {
        switch hour {
        case 5..<12:
            return [
                Color(red: 1.0, green: 0.82, blue: 0.62),
                AppColor.warmWhite,
                AppColor.mintGreen.opacity(0.46)
            ]
        case 12..<19:
            return [
                AppColor.medicalBlue.opacity(0.44),
                AppColor.warmWhite,
                Color(red: 1.0, green: 0.88, blue: 0.68)
            ]
        default:
            return [
                Color(red: 0.08, green: 0.10, blue: 0.20),
                Color(red: 0.16, green: 0.18, blue: 0.34),
                AppColor.lavenderDeep.opacity(0.62)
            ]
        }
    }
}

private struct ReminderVoiceButton: View {
    let isSpeaking: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.small) {
                Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 22, weight: .bold))
                Text(isSpeaking ? "Stop voice" : "Hear reminder")
                    .font(AppFont.bodyStrong)
            }
            .foregroundStyle(AppColor.medicalBlueDeep)
            .padding(.horizontal, Spacing.large)
            .frame(minHeight: 56)
            .background(.white.opacity(0.66))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.72), lineWidth: 1))
            .appShadow(AppShadow.soft)
        }
        .buttonStyle(.plain)
    }
}

private struct ReminderSecondaryAction: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppFont.button)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, minHeight: 62)
                .background(.white.opacity(0.68))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(color.opacity(0.18), lineWidth: 1))
                .appShadow(AppShadow.soft)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MedicineReminderView()
        .modelContainer(SampleData.previewContainer)
}
