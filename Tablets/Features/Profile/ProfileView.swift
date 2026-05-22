import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appRouter: AppRouter
    @State private var viewModel = ProfileViewModel()
    @AppStorage(UserHealthProfile.userNameKey) private var userName = ""
    @AppStorage(UserHealthProfile.genderKey) private var genderRawValue = UserProfileGender.preferNotToSay.rawValue
    @AppStorage(UserHealthProfile.womenHealthEnabledKey) private var womenHealthEnabled = false
    @AppStorage(UserHealthProfile.elderlyModeKey) private var elderlyMode = false
    @AppStorage(UserHealthProfile.highContrastKey) private var highContrast = false
    @AppStorage(HapticsManager.isEnabledKey) private var isHapticsEnabled = true
    @State private var isShowingAssistant = false
    @State private var isShowingHealthKit = false

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
                            VStack(alignment: .leading, spacing: Spacing.medium) {
                                Text("Health profile")
                                    .font(AppFont.sectionTitle)
                                    .foregroundStyle(AppColor.ink)

                                TextField("Your name", text: $userName)
                                    .font(AppFont.bodyStrong)
                                    .textInputAutocapitalization(.words)
                                    .padding(Spacing.medium)
                                    .background(AppColor.cream.opacity(0.82))
                                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
                                    .accessibilityLabel("Profile name")

                                Picker("Gender", selection: $genderRawValue) {
                                    ForEach(UserProfileGender.allCases) { gender in
                                        Text(gender.title).tag(gender.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(minHeight: 44)

                                if genderRawValue != UserProfileGender.male.rawValue {
                                    Toggle(isOn: $womenHealthEnabled) {
                                        Label {
                                            VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                                                Text("Women's health tracking")
                                                    .font(AppFont.bodyStrong)
                                                    .foregroundStyle(AppColor.ink)
                                                Text("Show cycle and wellbeing cards on the dashboard.")
                                                    .font(AppFont.caption)
                                                    .foregroundStyle(AppColor.secondaryInk)
                                            }
                                        } icon: {
                                            Image(systemName: "heart.circle.fill")
                                                .foregroundStyle(AppColor.lavenderDeep)
                                        }
                                    }
                                    .tint(AppColor.medicalBlue)
                                }

                                Toggle(isOn: $elderlyMode) {
                                    Label {
                                        VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                                            Text("Elderly-friendly mode")
                                                .font(AppFont.bodyStrong)
                                                .foregroundStyle(AppColor.ink)
                                            Text("Use calmer, easier-to-read assistant behavior.")
                                                .font(AppFont.caption)
                                                .foregroundStyle(AppColor.secondaryInk)
                                        }
                                    } icon: {
                                        Image(systemName: "textformat.size")
                                            .foregroundStyle(AppColor.medicalBlue)
                                    }
                                }
                                .tint(AppColor.medicalBlue)

                                Toggle(isOn: $highContrast) {
                                    Label {
                                        VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                                            Text("High contrast")
                                                .font(AppFont.bodyStrong)
                                                .foregroundStyle(AppColor.ink)
                                            Text("Prefer stronger visual contrast across key controls.")
                                                .font(AppFont.caption)
                                                .foregroundStyle(AppColor.secondaryInk)
                                        }
                                    } icon: {
                                        Image(systemName: "circle.lefthalf.filled")
                                            .foregroundStyle(AppColor.medicalBlue)
                                    }
                                }
                                .tint(AppColor.medicalBlue)
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
                                isShowingHealthKit = true
                            } label: {
                                HStack(spacing: Spacing.medium) {
                                    Image(systemName: "heart.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .frame(width: 48, height: 48)
                                        .background(AppColor.softRed, in: Circle())

                                    VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                                        Text("Apple Health")
                                            .font(AppFont.bodyStrong)
                                            .foregroundStyle(AppColor.ink)
                                        Text("Connect steps, sleep, heart rate, and optional reading sync.")
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
                            .accessibilityLabel("Open Apple Health connection")
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
            .sheet(isPresented: $isShowingHealthKit) {
                HealthKitPermissionView()
            }
            .onChange(of: genderRawValue) { _, newValue in
                if newValue == UserProfileGender.male.rawValue {
                    womenHealthEnabled = false
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppRouter())
}
