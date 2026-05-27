import AVFoundation
import SwiftData
import SwiftUI
import UserNotifications
import WidgetKit

struct AppRootView: View {
    let isAppLockAllowed: Bool

    init(isAppLockAllowed: Bool = true) {
        self.isAppLockAllowed = isAppLockAllowed
    }

    @Environment(\.modelContext) private var modelContext
    @Query private var assistantPreferences: [HumanAssistantPreference]
    @StateObject private var router = AppRouter()
    @StateObject private var quickSpeechService = WhisperKitSpeechToTextService()
    @StateObject private var quickTTSService = TTSService()
    @StateObject private var voiceTipManager = VoiceTipManager()
    @State private var isShowingHumanAssistant = false
    @State private var isShowingAssistantOptions = false
    @State private var isShowingModelStatus = false
    @State private var floatingVoiceState: FloatingVoiceState = .idle
    @State private var floatingBubbleText = ""
    @State private var isShowingSuggestionChips = false
    @State private var currentVoiceTip: VoiceTip?
    @State private var inlineSessionManager: VoiceSessionManager?
    @State private var inlineAutoStopTask: Task<Void, Never>?
    @State private var bubbleHideTask: Task<Void, Never>?
    @State private var tipHideTask: Task<Void, Never>?
    @State private var lastInlineVoiceTapAt = Date.distantPast
    @State private var appLockService = AppLockService()
    @AppStorage(AppPreferenceKeys.theme) private var themePreference = AppThemePreference.system.rawValue
    @AppStorage(AppPreferenceKeys.textSize) private var textSizePreference = AppTextSizePreference.standard.rawValue
    @AppStorage(AppPreferenceKeys.boldText) private var boldTextEnabled = false
    @AppStorage(AppPreferenceKeys.reduceAnimations) private var reduceAnimations = false
    @AppStorage(AppPreferenceKeys.appLockEnabled) private var appLockEnabled = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppColor.warmWhite
                .ignoresSafeArea()

            TabView(selection: $router.selectedTab) {
                DashboardView()
                    .tabItem {
                        Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.systemImage)
                    }
                    .tag(AppTab.dashboard)

                MedicinesView()
                    .tabItem {
                        Label(AppTab.medicines.title, systemImage: AppTab.medicines.systemImage)
                    }
                    .tag(AppTab.medicines)

                HealthTrackingView()
                    .tabItem {
                        Label(AppTab.healthTracking.title, systemImage: AppTab.healthTracking.systemImage)
                    }
                    .tag(AppTab.healthTracking)

                HealthJourneyView()
                    .tabItem {
                        Label(AppTab.healthJourney.title, systemImage: AppTab.healthJourney.systemImage)
                    }
                    .tag(AppTab.healthJourney)

                MoreView()
                    .tabItem {
                        Label(AppTab.more.title, systemImage: AppTab.more.systemImage)
                    }
                    .tag(AppTab.more)
            }

            VStack(alignment: .trailing, spacing: Spacing.small) {
                if let currentVoiceTip {
                    VoiceTipBannerView(tip: currentVoiceTip) {
                        dismissVoiceTip()
                    }
                }

                if isShowingSuggestionChips {
                    VoiceSuggestionChipsView(suggestions: VoiceSuggestionChips.suggestions()) { suggestion in
                        HapticsManager.selection()
                        Task { await processSuggestionChip(suggestion) }
                    }
                }

                HumanAssistantFloatingButton(
                    voiceState: floatingVoiceState,
                    bubbleText: floatingBubbleText,
                    audioLevel: quickSpeechService.audioLevel
                ) {
                    HapticsManager.selection()
                    handleInlineVoiceTap()
                } doubleTapAction: {
                    HapticsManager.selection()
                    isShowingHumanAssistant = true
                } longPressAction: {
                    isShowingAssistantOptions = true
                }
            }
            .padding(.trailing, Spacing.medium)
            .padding(.bottom, 82)
            .zIndex(10_000)

            if appLockService.isLocked {
                AppLockView(errorMessage: appLockService.errorMessage) {
                    Task { await appLockService.unlock() }
                }
                .zIndex(20_000)
                .transition(.opacity)
            }
        }
        .environmentObject(router)
        .tint(AppColor.medicalBlue)
        .preferredColorScheme(preferredColorScheme)
        .dynamicTypeSize(dynamicTypeSizeRange)
        .environment(\.legibilityWeight, boldTextEnabled ? .bold : .regular)
        .transaction { transaction in
            if reduceAnimations {
                transaction.animation = nil
            }
        }
        .sheet(isPresented: $isShowingHumanAssistant) {
            HumanVoiceAssistantView(appRouter: router)
                .onAppear {
                    DebugStartupLogger.log("HumanVoiceAssistantView sheet appeared")
                }
        }
        .confirmationDialog("Voice Assistant", isPresented: $isShowingAssistantOptions, titleVisibility: .visible) {
            Button("Open full assistant") {
                isShowingHumanAssistant = true
            }
            Button("Voice settings") {
                router.selectedTab = .more
                NotificationCenter.default.post(name: VoiceNavigationNotification.openSettings, object: nil)
            }
            Button("Privacy/offline model status") {
                isShowingModelStatus = true
            }
            #if DEBUG
            Button("Play last recording") {
                quickSpeechService.playLastRecordingForDebug()
            }
            #endif
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how you want to use the local voice assistant.")
        }
        .alert("Offline model status", isPresented: $isShowingModelStatus) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(WhisperModelManager.shared.isReady ? "Offline voice model is ready. Voice understanding runs on this device." : "Offline voice model is not ready yet. Open the full assistant to download it.")
        }
        .onAppear {
            handleRootAppear()
        }
        .onChange(of: router.selectedTab) { _, newValue in
            DebugStartupLogger.log("AppRootView selectedTab changed")
        }
        .onChange(of: scenePhaseForLock) { _, phase in
            switch phase {
            case .background:
                appLockService.lockIfNeeded(canLock: canUseAppLock)
            case .inactive:
                if appLockEnabled && canUseAppLock {
                    appLockService.lockIfNeeded(canLock: true)
                }
            case .active:
                break
            default:
                break
            }
        }
        .onChange(of: isShowingHumanAssistant) { _, isPresented in
            DebugStartupLogger.log("isShowingHumanAssistant changed to \(isPresented)")
        }
        .onChange(of: isShowingAssistantOptions) { _, isPresented in
            DebugStartupLogger.log("isShowingAssistantOptions changed to \(isPresented)")
        }
        .onChange(of: isShowingModelStatus) { _, isPresented in
            DebugStartupLogger.log("isShowingModelStatus changed to \(isPresented)")
        }
        .onChange(of: isShowingSuggestionChips) { _, isPresented in
            DebugStartupLogger.log("isShowingSuggestionChips changed to \(isPresented)")
        }
        .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openMedicineReminder)) { _ in
            router.selectedTab = .medicines
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickStartOpenAddMedicine)) { _ in
            router.selectedTab = .medicines
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                NotificationCenter.default.post(name: VoiceNavigationNotification.openAddMedicine, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickStartOpenBPLog)) { _ in
            router.selectedTab = .healthTracking
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                NotificationCenter.default.post(name: VoiceNavigationNotification.openBPLog, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickStartOpenHealthKit)) { _ in
            router.selectedTab = .more
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                NotificationCenter.default.post(name: VoiceNavigationNotification.openSettings, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickStartOpenHealthReport)) { _ in
            router.selectedTab = .more
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                NotificationCenter.default.post(name: VoiceNavigationNotification.openHealthReport, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .quickStartHighlightVoice)) { _ in
            showBubble("Tap here and try: What medicine is next?")
            isShowingSuggestionChips = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .dashboardStartInlineVoiceRequested)) { _ in
            handleInlineVoiceTap()
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .dashboardVoicePhraseRequested)) { notification in
            guard let phrase = notification.object as? String else { return }
            DebugStartupLogger.log("Received dashboardVoicePhraseRequested: \(phrase)")
            Task { await processSuggestionChip(phrase) }
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch AppThemePreference(rawValue: themePreference) ?? .system {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private var dynamicTypeSizeRange: ClosedRange<DynamicTypeSize> {
        switch AppTextSizePreference(rawValue: textSizePreference) ?? .standard {
        case .standard: return .small ... .accessibility1
        case .large: return .medium ... .accessibility2
        case .extraLarge: return .large ... .accessibility3
        }
    }

    @Environment(\.scenePhase) private var scenePhaseForLock

    private var canUseAppLock: Bool {
        isAppLockAllowed
    }

    private func handleRootAppear() {
        UNUserNotificationCenter.current().delegate = MedicineNotificationDelegate.shared
        MedicineNotificationDelegate.shared.configure(modelContext: modelContext)
        cleanupOrphanMedicineNotifications()
        WidgetMedicineSnapshotWriter.writeAndReload(context: modelContext)
        schedulePregnancyHydrationIfNeeded()
        DebugStartupLogger.log("AppRootView.onAppear completed")
    }

    private func handleInlineVoiceTap() {
        let now = Date()
        guard now.timeIntervalSince(lastInlineVoiceTapAt) >= 0.35 else { return }
        lastInlineVoiceTapAt = now

        switch floatingVoiceState {
        case .idle, .success:
            startInlineListening()
        case .listening, .userSpeaking:
            Task { await stopAndProcessInlineVoice() }
        case .preparing, .processing:
            showBubble("Processing...")
        case .speaking:
            quickTTSService.stop()
            setIdleSoon()
        case .error:
            startInlineListening()
        }
    }

    private func schedulePregnancyHydrationIfNeeded() {
        let descriptor = FetchDescriptor<PregnancyProfile>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        guard let profiles = try? modelContext.fetch(descriptor),
              let profile = profiles.first(where: \.isActive),
              profile.hydrationRemindersEnabled != false else { return }
        Task {
            let result = await PregnancyHydrationService().scheduleHydrationReminders(for: profile)
            if result != .scheduled {
                profile.hydrationRemindersEnabled = false
                try? modelContext.save()
            }
        }
    }

    private func cleanupOrphanMedicineNotifications() {
        Task {
            do {
                let activeIDs = try MedicineRepository(modelContext: modelContext)
                    .fetchActiveMedicines()
                    .map { $0.id.uuidString }
                let cancelled = await MedicineNotificationScheduler()
                    .cleanupOrphanedMedicineNotifications(activeMedicineIDs: Set(activeIDs))
                #if DEBUG
                if cancelled > 0 {
                    print("[AppRootView] Cleaned \(cancelled) orphan medicine notification(s)")
                }
                #endif
            } catch {
                #if DEBUG
                print("[AppRootView] Orphan medicine notification cleanup failed: \(error)")
                #endif
            }
        }
    }

    private func startInlineListening() {
        inlineAutoStopTask?.cancel()
        isShowingSuggestionChips = false

        guard !quickSpeechService.isTranscribing else {
            showBubble("Processing...")
            return
        }

        if quickTTSService.isSpeaking {
            quickTTSService.stop()
        }

        guard WhisperModelManager.shared.isReady else {
            setError("Offline voice model is not ready")
            return
        }

        guard AssistantPermissionService().microphoneStatus() == .authorized else {
            setError("Microphone permission needed")
            return
        }

        floatingVoiceState = .preparing
        showBubble("Preparing...")

        Task {
            do {
                configureInlineSessionIfNeeded()
                try await quickSpeechService.startListening()
                floatingVoiceState = .listening
                showBubble("Listening...")
                isShowingSuggestionChips = true
                watchInlineVoiceStop()
                HapticsManager.impact(.soft)
            } catch {
                setError((error as? LocalizedError)?.errorDescription ?? "I could not start listening")
            }
        }
    }

    private func watchInlineVoiceStop() {
        inlineAutoStopTask?.cancel()
        inlineAutoStopTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(160))
                if quickSpeechService.audioLevel > 0.18 && quickSpeechService.isListening {
                    floatingVoiceState = .userSpeaking
                    showBubble("Listening...")
                } else if quickSpeechService.isListening && floatingVoiceState == .userSpeaking {
                    floatingVoiceState = .listening
                }

                if quickSpeechService.autoStopRequested && quickSpeechService.isListening {
                    await stopAndProcessInlineVoice()
                    return
                }
            }
        }
    }

    private func stopAndProcessInlineVoice() async {
        inlineAutoStopTask?.cancel()
        isShowingSuggestionChips = false
        floatingVoiceState = .processing
        showBubble("Thinking...")

        do {
            let transcript = (try await quickSpeechService.stopListening()).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !transcript.isEmpty else {
                setError("I didn't hear anything. Please try again.")
                return
            }

            configureInlineSessionIfNeeded()
            guard let inlineSessionManager else {
                setError("Assistant is not ready")
                return
            }

            let result = await inlineSessionManager.process(transcript: transcript)
            floatingBubbleText = firstLine(result.response)
            floatingVoiceState = .speaking
            showVoiceTipIfNeeded()

            if result.shouldAutoDismiss {
                scheduleSuccessReset(delay: 1.2)
            } else {
                scheduleSuccessReset(delay: 3.0)
            }
        } catch {
            setError((error as? LocalizedError)?.errorDescription ?? "I could not understand that clearly")
        }
    }

    private func processSuggestionChip(_ suggestion: String) async {
        inlineAutoStopTask?.cancel()
        isShowingSuggestionChips = false
        floatingVoiceState = .processing
        showBubble("Thinking...")

        if quickSpeechService.isListening {
            _ = try? await quickSpeechService.stopListening()
        }

        configureInlineSessionIfNeeded()
        guard let inlineSessionManager else {
            setError("Assistant is not ready")
            return
        }

        let result = await inlineSessionManager.process(transcript: suggestion)
        floatingBubbleText = firstLine(result.response)
        floatingVoiceState = .speaking
        showVoiceTipIfNeeded()

        if result.shouldAutoDismiss {
            scheduleSuccessReset(delay: 1.2)
        } else {
            scheduleSuccessReset(delay: 3.0)
        }
    }

    private func configureInlineSessionIfNeeded() {
        if inlineSessionManager == nil {
            let manager = VoiceSessionManager(modelContext: modelContext, ttsService: quickTTSService) {
                assistantPreferences.first
            }
            manager.configureNavigation(appRouter: router, dismissAssistant: nil)
            inlineSessionManager = manager
        }
    }

    private func showBubble(_ text: String) {
        floatingBubbleText = text
    }

    private func setError(_ message: String) {
        isShowingSuggestionChips = false
        floatingVoiceState = .error(message)
        floatingBubbleText = message
        HapticsManager.notification(.error)
        hideBubbleAfter(seconds: 3.0)
    }

    private func scheduleSuccessReset(delay: TimeInterval) {
        bubbleHideTask?.cancel()
        bubbleHideTask = Task {
            await sleep(seconds: delay)
            isShowingSuggestionChips = false
            floatingVoiceState = .success
            try? await Task.sleep(for: .milliseconds(700))
            floatingVoiceState = .idle
            floatingBubbleText = ""
        }
    }

    private func setIdleSoon() {
        isShowingSuggestionChips = false
        floatingVoiceState = .idle
        hideBubbleAfter(seconds: 0.4)
    }

    private func hideBubbleAfter(seconds: TimeInterval) {
        bubbleHideTask?.cancel()
        bubbleHideTask = Task {
            await sleep(seconds: seconds)
            if !Task.isCancelled {
                floatingBubbleText = ""
                if case .error = floatingVoiceState {
                    floatingVoiceState = .idle
                }
            }
        }
    }

    private func firstLine(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 96 else { return trimmed }
        return "\(trimmed.prefix(96))..."
    }

    private func showVoiceTipIfNeeded() {
        guard let tip = voiceTipManager.nextTipAfterInteraction() else { return }
        currentVoiceTip = tip
        tipHideTask?.cancel()
        tipHideTask = Task {
            await sleep(seconds: 4)
            if !Task.isCancelled {
                currentVoiceTip = nil
            }
        }
    }

    private func dismissVoiceTip() {
        tipHideTask?.cancel()
        currentVoiceTip = nil
    }

    private func sleep(seconds: TimeInterval) async {
        let nanoseconds = UInt64(max(seconds, 0) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme?.lowercased() == "tablets" else { return }

        let host = url.host?.lowercased()
        switch host {
        case "medicine":
            router.selectedTab = .medicines
            let medicineID = url.pathComponents.dropFirst().first
            var userInfo: [String: Any] = [:]
            if let medicineID {
                userInfo["medicineID"] = medicineID
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                NotificationCenter.default.post(
                    name: VoiceNavigationNotification.openMedicineReminder,
                    object: nil,
                    userInfo: userInfo
                )
            }
        case "medicines":
            router.selectedTab = .medicines
        default:
            router.selectedTab = .dashboard
        }
    }
}

#Preview {
    AppRootView()
        .modelContainer(SampleData.previewContainer)
}
