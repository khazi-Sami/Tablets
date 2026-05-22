import AVFoundation
import SwiftData
import SwiftUI

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var assistantPreferences: [HumanAssistantPreference]
    @StateObject private var router = AppRouter()
    @StateObject private var quickSpeechService = WhisperKitSpeechToTextService()
    @StateObject private var quickTTSService = TTSService()
    @State private var isShowingHumanAssistant = false
    @State private var isShowingAssistantOptions = false
    @State private var isShowingModelStatus = false
    @State private var floatingVoiceState: FloatingVoiceState = .idle
    @State private var floatingBubbleText = ""
    @State private var inlineSessionManager: VoiceSessionManager?
    @State private var inlineAutoStopTask: Task<Void, Never>?
    @State private var bubbleHideTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
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
            .padding(.trailing, Spacing.medium)
            .padding(.bottom, 82)
        }
        .environmentObject(router)
        .tint(AppColor.medicalBlue)
        .sheet(isPresented: $isShowingHumanAssistant) {
            HumanVoiceAssistantView(appRouter: router)
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
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how you want to use the local voice assistant.")
        }
        .alert("Offline model status", isPresented: $isShowingModelStatus) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(WhisperModelManager.shared.isReady ? "Offline voice model is ready. Voice understanding runs on this device." : "Offline voice model is not ready yet. Open the full assistant to download it.")
        }
    }

    private func handleInlineVoiceTap() {
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

    private func startInlineListening() {
        inlineAutoStopTask?.cancel()
        quickTTSService.stop()

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
                watchInlineVoiceStop()
                HapticsManager.impact(.soft)
            } catch {
                setError("I could not start listening")
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

            if result.shouldAutoDismiss {
                scheduleSuccessReset(delay: 1.2)
            } else {
                scheduleSuccessReset(delay: 3.0)
            }
        } catch {
            setError("I could not understand that clearly")
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
        floatingVoiceState = .error(message)
        floatingBubbleText = message
        HapticsManager.notification(.error)
        hideBubbleAfter(seconds: 3.0)
    }

    private func scheduleSuccessReset(delay: TimeInterval) {
        bubbleHideTask?.cancel()
        bubbleHideTask = Task {
            await sleep(seconds: delay)
            floatingVoiceState = .success
            try? await Task.sleep(for: .milliseconds(700))
            floatingVoiceState = .idle
            floatingBubbleText = ""
        }
    }

    private func setIdleSoon() {
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

    private func sleep(seconds: TimeInterval) async {
        let nanoseconds = UInt64(max(seconds, 0) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}

#Preview {
    AppRootView()
        .modelContainer(SampleData.previewContainer)
}
