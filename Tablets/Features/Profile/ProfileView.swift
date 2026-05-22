import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appRouter: AppRouter
    @StateObject private var viewModel = ProfileViewModel()
    @AppStorage(HapticsManager.isEnabledKey) private var isHapticsEnabled = true
    @State private var isShowingAssistant = false

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView {
                    VStack(spacing: Spacing.medium) {
                        PillCardContainer(style: .highlighted, padding: Spacing.large) {
                            HStack(spacing: Spacing.medium) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 52))
                                    .foregroundStyle(AppColor.medicalBlue)

                                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                                    Text(viewModel.displayName)
                                        .font(AppFont.title)
                                        .foregroundStyle(AppColor.ink)

                                    Text(viewModel.subtitle)
                                        .font(AppFont.body)
                                        .foregroundStyle(AppColor.secondaryInk)
                                }

                                Spacer()
                            }
                        }

                        PillCardContainer {
                            Toggle(isOn: $isHapticsEnabled) {
                                Label {
                                    VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                                        Text("Haptic feedback")
                                            .font(AppFont.bodyStrong)
                                            .foregroundStyle(AppColor.ink)

                                        Text("Use gentle vibrations for taps, saves, and success moments.")
                                            .font(AppFont.caption)
                                            .foregroundStyle(AppColor.secondaryInk)
                                    }
                                } icon: {
                                    Image(systemName: "iphone.radiowaves.left.and.right")
                                        .foregroundStyle(AppColor.medicalBlue)
                                }
                            }
                            .tint(AppColor.medicalBlue)
                            .onChange(of: isHapticsEnabled) { _, newValue in
                                if newValue { HapticsManager.notification(.success) }
                            }
                        }

                        PillCardContainer {
                            Button {
                                HapticsManager.selection()
                                isShowingAssistant = true
                            } label: {
                                HStack(spacing: Spacing.medium) {
                                    Image(systemName: "waveform.and.mic")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .frame(width: 48, height: 48)
                                        .background(AppGradient.primaryButton, in: Circle())

                                    VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                                        Text("Voice assistant")
                                            .font(AppFont.bodyStrong)
                                            .foregroundStyle(AppColor.ink)
                                        Text("Open the private, offline-first health assistant.")
                                            .font(AppFont.caption)
                                            .foregroundStyle(AppColor.secondaryInk)
                                    }

                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(AppColor.secondaryInk)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open voice assistant")
                        }
                    }
                    .padding(Spacing.medium)
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $isShowingAssistant) {
                HumanVoiceAssistantView(appRouter: appRouter)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppRouter())
}
