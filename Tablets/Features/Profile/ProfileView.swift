import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appRouter: AppRouter
    @State private var viewModel = ProfileViewModel()
    @AppStorage(UserHealthProfile.userNameKey) private var userName = ""
    @AppStorage(UserHealthProfile.genderKey) private var genderRawValue = UserProfileGender.preferNotToSay.rawValue
    @AppStorage(UserHealthProfile.womenHealthEnabledKey) private var womenHealthEnabled = false
    @AppStorage(UserHealthProfile.elderlyModeKey) private var elderlyMode = false
    @AppStorage(UserHealthProfile.highContrastKey) private var highContrast = false
    @AppStorage(HapticsManager.isEnabledKey) private var isHapticsEnabled = true
    @AppStorage(AppPreferenceKeys.theme) private var themePreference = AppThemePreference.system.rawValue
    @AppStorage(AppPreferenceKeys.textSize) private var textSizePreference = AppTextSizePreference.standard.rawValue
    @AppStorage(AppPreferenceKeys.boldText) private var boldTextEnabled = false
    @AppStorage(AppPreferenceKeys.reduceAnimations) private var reduceAnimations = false
    @AppStorage(AppPreferenceKeys.voiceSpeed) private var voiceSpeed = VoiceSpeedPreference.normal.rawValue
    @AppStorage(AppPreferenceKeys.autoListenAfterResponse) private var autoListenAfterResponse = false
    @AppStorage(AppPreferenceKeys.appLockEnabled) private var appLockEnabled = false

    @State private var isShowingAssistant = false
    @State private var isShowingHealthKit = false
    @State private var exportURL: URL?
    @State private var isShowingShareSheet = false
    @State private var statusMessage: String?
    @State private var resetText = ""
    @State private var isShowingResetAlert = false
    @State private var isShowingSignOutAlert = false
    @State private var isResetting = false

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView {
                    VStack(spacing: Spacing.medium) {
                        headerCard
                        healthProfileCard
                        appearanceCard
                        accessibilityCard
                        voiceAssistantCard
                        privacyCard
                        dataManagementCard
                        aboutCard
                        accountCard
                    }
                    .padding(Spacing.medium)
                    .padding(.bottom, 90)
                }
                .scrollDismissesKeyboard(.interactively)
                .dismissKeyboardOnTap()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $isShowingAssistant) {
                HumanVoiceAssistantView(appRouter: appRouter)
            }
            .sheet(isPresented: $isShowingHealthKit) {
                HealthKitPermissionView()
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
            .alert("Reset app", isPresented: $isShowingResetAlert) {
                TextField("Type RESET", text: $resetText)
                Button("Cancel", role: .cancel) {
                    resetText = ""
                }
                Button("Reset", role: .destructive) {
                    Task { await resetApp() }
                }
                .disabled(resetText != "RESET")
            } message: {
                Text("This deletes local BanyAI data, clears settings, voice history, and pending notifications. Type RESET to confirm.")
            }
            .alert("Sign out?", isPresented: $isShowingSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("This keeps your local health data on this device and returns BanyAI to the welcome screen.")
            }
            .onChange(of: genderRawValue) { _, newValue in
                if newValue == UserProfileGender.male.rawValue {
                    womenHealthEnabled = false
                }
            }
        }
    }

    private var headerCard: some View {
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
    }

    private var healthProfileCard: some View {
        settingsCard("Health profile", icon: "person.text.rectangle.fill") {
            TextField("Your name", text: $userName)
                .font(AppFont.bodyStrong)
                .textInputAutocapitalization(.words)
                .padding(Spacing.medium)
                .background(AppColor.cream.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))

            Picker("Gender", selection: $genderRawValue) {
                ForEach(UserProfileGender.allCases) { gender in
                    Text(gender.title).tag(gender.rawValue)
                }
            }
            .pickerStyle(.menu)

            if genderRawValue != UserProfileGender.male.rawValue {
                settingsToggle("Women's health tracking", subtitle: "Show cycle and wellbeing cards on the dashboard.", icon: "heart.circle.fill", isOn: $womenHealthEnabled)
            }
        }
    }

    private var appearanceCard: some View {
        settingsCard("Appearance", icon: "paintpalette.fill") {
            pickerRow("Theme", selection: $themePreference, values: Array(AppThemePreference.allCases))
            pickerRow("Text size", selection: $textSizePreference, values: Array(AppTextSizePreference.allCases))
        }
    }

    private var accessibilityCard: some View {
        settingsCard("Accessibility", icon: "accessibility.fill") {
            settingsToggle("Haptics", subtitle: "Gentle vibration feedback for key actions.", icon: "iphone.radiowaves.left.and.right", isOn: $isHapticsEnabled)
            settingsToggle("Bold text", subtitle: "Increase text emphasis across the app.", icon: "bold", isOn: $boldTextEnabled)
            settingsToggle("Reduce animations", subtitle: "Keep motion calmer throughout BanyAI.", icon: "circle.dashed", isOn: $reduceAnimations)
            settingsToggle("Elderly-friendly mode", subtitle: "Use calmer, easier-to-read assistant behavior.", icon: "textformat.size", isOn: $elderlyMode)
            settingsToggle("High contrast", subtitle: "Prefer stronger visual contrast for key controls.", icon: "circle.lefthalf.filled", isOn: $highContrast)
        }
    }

    private var voiceAssistantCard: some View {
        settingsCard("Voice Assistant", icon: "waveform.and.mic") {
            pickerRow("Voice speed", selection: $voiceSpeed, values: Array(VoiceSpeedPreference.allCases))
            settingsToggle("Auto-listen after response", subtitle: "Let the assistant keep listening after it speaks.", icon: "ear", isOn: $autoListenAfterResponse)

            Button {
                HapticsManager.selection()
                isShowingAssistant = true
            } label: {
                settingsLinkRow("Open voice assistant", subtitle: "Private, offline-first health assistant.", icon: "mic.circle.fill")
            }
            .buttonStyle(.plain)
        }
    }

    private var privacyCard: some View {
        settingsCard("Privacy & Security", icon: "lock.shield.fill") {
            settingsToggle("Face ID / Touch ID lock", subtitle: "Require device authentication when returning to the app.", icon: "faceid", isOn: $appLockEnabled)
            privacyLine("All data stays on your device")
            privacyLine("No ads")
            privacyLine("No tracking")
            privacyLine("No cloud")
        }
    }

    private var dataManagementCard: some View {
        settingsCard("Data Management", icon: "externaldrive.fill") {
            Button {
                Task { await exportJSON() }
            } label: {
                settingsLinkRow("Export all data as JSON", subtitle: "Create a local backup file you can share or save.", icon: "square.and.arrow.up.fill")
            }
            .buttonStyle(.plain)

            Button {
                Task { await clearVoiceHistory() }
            } label: {
                settingsLinkRow("Clear voice history", subtitle: "Remove saved local assistant conversations.", icon: "trash.fill")
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                resetText = ""
                isShowingResetAlert = true
            } label: {
                settingsLinkRow(isResetting ? "Resetting..." : "Reset app", subtitle: "Danger zone. Requires typing RESET.", icon: "exclamationmark.triangle.fill", color: AppColor.softRed)
            }
            .buttonStyle(.plain)
            .disabled(isResetting)

            if let statusMessage {
                Text(statusMessage)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }
        }
    }

    private var aboutCard: some View {
        settingsCard("About", icon: "info.circle.fill") {
            Text("Version \(appVersion) (\(appBuild))")
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.ink)
            Text("Built with privacy-first principles.")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)

            Button {
                isShowingHealthKit = true
            } label: {
                settingsLinkRow("Apple Health", subtitle: "Manage optional local HealthKit access.", icon: "heart.fill", color: AppColor.softRed)
            }
            .buttonStyle(.plain)
        }
    }

    private var accountCard: some View {
        settingsCard("Account", icon: "person.crop.circle.badge.xmark") {
            Button(role: .destructive) {
                isShowingSignOutAlert = true
            } label: {
                settingsLinkRow("Sign Out", subtitle: "Keep local health data and return to welcome.", icon: "rectangle.portrait.and.arrow.right.fill", color: AppColor.softRed)
            }
            .buttonStyle(.plain)

            #if DEBUG
            Button {
                resetOnboardingForTesting()
            } label: {
                settingsLinkRow("Reset onboarding", subtitle: "DEBUG only. Show onboarding again for testing.", icon: "arrow.counterclockwise.circle.fill", color: AppColor.medicalBlue)
            }
            .buttonStyle(.plain)
            #endif
        }
    }

    private func settingsCard<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Label(title, systemImage: icon)
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)
                content()
            }
        }
    }

    private func pickerRow<T: RawRepresentable & CaseIterable & Identifiable>(_ title: String, selection: Binding<String>, values: [T]) -> some View where T.RawValue == String, T: AnyObjectConvertibleTitle {
        HStack {
            Text(title)
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.ink)
            Spacer()
            Picker(title, selection: selection) {
                ForEach(values) { value in
                    Text(value.title).tag(value.rawValue)
                }
            }
            .pickerStyle(.menu)
        }
        .frame(minHeight: 44)
    }

    private func settingsToggle(_ title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label {
                VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                    Text(title)
                        .font(AppFont.bodyStrong)
                        .foregroundStyle(AppColor.ink)
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                }
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(AppColor.medicalBlue)
            }
        }
        .tint(AppColor.medicalBlue)
    }

    private func settingsLinkRow(_ title: String, subtitle: String, icon: String, color: Color = AppColor.medicalBlue) -> some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                Text(title)
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.ink)
                Text(subtitle)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(AppColor.tertiaryInk)
        }
        .contentShape(Rectangle())
    }

    private func privacyLine(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.seal.fill")
            .font(AppFont.body)
            .foregroundStyle(AppColor.ink)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private func exportJSON() async {
        do {
            exportURL = try DataExportService().exportAllData(context: modelContext)
            isShowingShareSheet = true
            statusMessage = "JSON export created."
            HapticsManager.notification(.success)
        } catch {
            statusMessage = "Could not export data."
            HapticsManager.notification(.error)
        }
    }

    private func clearVoiceHistory() async {
        do {
            for item in try modelContext.fetch(FetchDescriptor<HumanAssistantConversation>()) {
                modelContext.delete(item)
            }
            for item in try modelContext.fetch(FetchDescriptor<HumanVoiceMemory>()) {
                modelContext.delete(item)
            }
            try modelContext.save()
            statusMessage = "Voice history cleared."
            HapticsManager.notification(.success)
        } catch {
            statusMessage = "Could not clear voice history."
            HapticsManager.notification(.error)
        }
    }

    private func resetApp() async {
        guard resetText == "RESET" else { return }
        isResetting = true
        do {
            HealthAppIntegrityChecker.cleanupForAppReset()
            try await DataExportService().resetLocalAppData(context: modelContext)
            statusMessage = "Reset complete."
            NotificationCenter.default.post(name: .authSignOutRequested, object: nil)
            HapticsManager.notification(.success)
        } catch {
            statusMessage = "Could not reset app data."
            HapticsManager.notification(.error)
        }
        resetText = ""
        isResetting = false
    }

    private func signOut() {
        HapticsManager.selection()
        NotificationCenter.default.post(name: .authSignOutRequested, object: nil)
    }

    #if DEBUG
    private func resetOnboardingForTesting() {
        HapticsManager.selection()
        NotificationCenter.default.post(name: .authResetOnboardingRequested, object: nil)
    }
    #endif
}

private protocol AnyObjectConvertibleTitle {
    var title: String { get }
}

extension AppThemePreference: AnyObjectConvertibleTitle {}
extension AppTextSizePreference: AnyObjectConvertibleTitle {}
extension VoiceSpeedPreference: AnyObjectConvertibleTitle {}

#Preview {
    ProfileView()
        .environmentObject(AppRouter())
}
