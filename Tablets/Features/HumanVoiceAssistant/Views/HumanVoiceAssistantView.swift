import SwiftData
import SwiftUI

struct HumanVoiceAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medicine.name) private var medicines: [Medicine]
    @Query(sort: \MedicineLog.scheduledTime, order: .reverse) private var medicineLogs: [MedicineLog]
    @Query(sort: \HealthRecord.measuredAt, order: .reverse) private var healthRecords: [HealthRecord]
    @Query(sort: \WomensHealthDailyLog.date, order: .reverse) private var symptomLogs: [WomensHealthDailyLog]
    @Query(sort: \AssistantInteractionMemory.createdAt, order: .reverse) private var interactionMemories: [AssistantInteractionMemory]
    @Query(sort: \HumanAssistantConversation.createdAt, order: .reverse) private var conversations: [HumanAssistantConversation]
    @Query private var preferences: [HumanAssistantPreference]
    @StateObject private var viewModel = HumanVoiceAssistantViewModel()
    @StateObject private var fallbackRouter = AppRouter()
    @State private var isShowingCustomShortcuts = false
    @AppStorage(AssistantAccessibilitySettings.slowerVoiceKey) private var slowerVoice = false
    @AppStorage(AssistantAccessibilitySettings.highContrastKey) private var highContrast = false
    @AppStorage(AssistantAccessibilitySettings.simplifiedVoiceModeKey) private var simplifiedMode = false
    private let providedRouter: AppRouter?

    init(appRouter: AppRouter? = nil) {
        self.providedRouter = appRouter
    }

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.large) {
                        VStack(spacing: Spacing.small) {
                            HumanAssistantOrbView(isListening: viewModel.isListening, isSpeaking: viewModel.isSpeaking, isProcessing: viewModel.isProcessing || viewModel.isPreparingModel, audioLevel: viewModel.audioLevel)
                                .allowsHitTesting(false)

                            Text(statusTitle)
                                .font(AppFont.title)
                                .foregroundStyle(AppColor.ink)

                            Text("Offline first using \(viewModel.modelName). Use the microphone button below to speak.")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.secondaryInk)
                                .multilineTextAlignment(.center)
                        }

                        if viewModel.needsMicrophonePermission {
                            permissionCard
                        }

                        accessibilityCard

                        Button {
                            isShowingCustomShortcuts = true
                        } label: {
                            Label("My Voice Shortcuts", systemImage: "mic.badge.plus")
                                .font(AppFont.bodyStrong)
                                .foregroundStyle(AppColor.medicalBlueDeep)
                                .frame(maxWidth: .infinity)
                                .padding(Spacing.medium)
                                .background(AppColor.medicalBlue.opacity(0.10), in: Capsule())
                        }
                        .buttonStyle(.plain)

                        if !viewModel.modelManager.isReady || viewModel.isInstallingModel || viewModel.isModelLoading {
                            AIModelDownloadCard(
                                modelTitle: viewModel.selectedModelTitle,
                                estimatedSize: viewModel.selectedModelSize,
                                estimatedSetupTime: viewModel.selectedModelSetupTime,
                                progress: viewModel.installProgress,
                                isInstalling: viewModel.isInstallingModel,
                                isLoading: viewModel.isModelLoading,
                                isInstalled: viewModel.modelManager.isReady,
                                storageUsage: viewModel.modelStorageUsage,
                                statusText: viewModel.modelDownloadStatusText,
                                downloadedText: viewModel.modelDownloadedText,
                                totalText: viewModel.modelTotalText,
                                modelState: viewModel.modelState,
                                errorMessage: viewModel.modelInstallError
                            ) {
                                viewModel.installLocalModel()
                            }
                        }

                        AssistantMicControlButton(
                            title: micButtonTitle,
                            subtitle: micButtonSubtitle,
                            systemImage: viewModel.isListening ? "stop.fill" : "mic.fill",
                            isActive: viewModel.isListening,
                            highContrast: highContrast,
                            isDisabled: viewModel.isProcessing || viewModel.isPreparingModel || !viewModel.modelManager.isReady || viewModel.isInstallingModel || viewModel.isModelLoading
                        ) {
                            toggleListening()
                        }

                        if viewModel.isListening {
                            LiveTranscriptionCard(partialTranscript: viewModel.partialTranscript, audioLevel: viewModel.audioLevel)
                        }

                        HumanAssistantMessageCard(transcript: viewModel.transcript, partialTranscript: viewModel.partialTranscript, response: viewModel.assistantText)

                        if !viewModel.pendingConfirmationText.isEmpty {
                            navigationConfirmationCard
                        }

                        if viewModel.pendingConfirmation != nil {
                            confirmationCard
                        }

                        proactiveInsights

                        if !simplifiedMode {
                            testCommands
                        }

                        conversationHistory
                    }
                    .padding(Spacing.medium)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle("Voice Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        viewModel.ttsService.stop()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.ttsService.stop()
                    } label: {
                        Image(systemName: "speaker.slash.fill")
                    }
                    .accessibilityLabel("Stop speaking")
                }
            }
        }
        .onAppear {
            viewModel.refreshPermissions()
            viewModel.preloadModelIfPossible()
            viewModel.configure(modelContext: modelContext, appRouter: activeAppRouter, dismissAssistant: { dismiss() }) {
                currentPreference
            }
        }
        .sheet(isPresented: $isShowingCustomShortcuts) {
            CustomShortcutsView()
        }
    }

    private var statusTitle: String {
        if !viewModel.modelManager.isReady { return "Set up voice model" }
        if viewModel.isPreparingModel { return "Preparing local voice model" }
        if viewModel.isProcessing { return "Thinking..." }
        if viewModel.isListening { return "Listening..." }
        if viewModel.isSpeaking { return "Speaking..." }
        return "Human Voice Assistant"
    }

    private var micButtonTitle: String {
        if viewModel.isListening { return "Stop and process" }
        if viewModel.isPreparingModel { return "Preparing voice model" }
        return "Start listening"
    }

    private var micButtonSubtitle: String {
        if viewModel.isListening { return "Tap when you finish speaking." }
        if !viewModel.modelManager.isReady { return "Download the offline model once, then voice works locally." }
        return "Tap once, speak naturally, then tap again to finish."
    }

    private var permissionCard: some View {
        PillCardContainer(style: .highlighted, padding: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Label("Private voice access", systemImage: "mic.badge.plus")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)
                Text(viewModel.permissionExplanation)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryInk)
                CapsuleButton("Allow Microphone", systemImage: "mic.fill") {
                    viewModel.requestMicrophonePermission()
                }
            }
        }
    }

    private var accessibilityCard: some View {
        PillCardContainer(padding: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Label("Comfort options", systemImage: "accessibility")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)
                Toggle("Slower spoken replies", isOn: $slowerVoice)
                    .tint(AppColor.medicalBlue)
                Toggle("High contrast controls", isOn: $highContrast)
                    .tint(AppColor.medicalBlue)
                Toggle("Simplified voice mode", isOn: $simplifiedMode)
                    .tint(AppColor.medicalBlue)
            }
            .font(AppFont.body)
        }
    }

    private var confirmationCard: some View {
        PillCardContainer(style: .lavender) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Confirm before saving")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)
                Text("Please review what I detected. You can adjust the value before saving.")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryInk)
                VStack(spacing: Spacing.small) {
                    confirmationField("Detected type", text: $viewModel.confirmationType)
                    confirmationField("Detected value", text: $viewModel.confirmationValue)
                    confirmationField("Medicine hint", text: $viewModel.confirmationMedicine)
                }
                HStack(spacing: Spacing.small) {
                    CapsuleButton("Save", systemImage: "checkmark.circle.fill") {
                        viewModel.confirmPending(modelContext: modelContext, medicines: medicines, medicineLogs: medicineLogs, healthRecords: healthRecords, symptomLogs: symptomLogs, preferences: currentPreference)
                    }
                    CapsuleButton("Retry", systemImage: "arrow.counterclockwise", style: .secondary) {
                        viewModel.retryListening()
                    }
                }
                Button("Edit manually") {
                    viewModel.editManually()
                }
                .font(AppFont.caption)
                .foregroundStyle(AppColor.medicalBlueDeep)
            }
        }
    }

    private var navigationConfirmationCard: some View {
        PillCardContainer(style: .lavender) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Label("Confirm action", systemImage: "questionmark.circle.fill")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                Text(viewModel.pendingConfirmationText)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Say yes to continue, or no to cancel.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.tertiaryInk)
            }
        }
    }

    private func confirmationField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
            Text(title)
                .font(AppFont.badge)
                .foregroundStyle(AppColor.secondaryInk)
            TextField(title, text: text)
                .font(AppFont.body)
                .padding(Spacing.small)
                .background(.white.opacity(0.72), in: Capsule())
        }
    }

    private var testCommands: some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Try saying")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)
                Text("Tap one, or use the microphone and speak naturally.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
                ForEach(viewModel.suggestedCommands, id: \.self) { example in
                    Button {
                        HapticsManager.selection()
                        viewModel.runSuggestedCommand(example, modelContext: modelContext, preferences: currentPreference)
                    } label: {
                        Text(example)
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.medicalBlueDeep)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Spacing.small)
                            .background(AppColor.medicalBlue.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Try command \(example)")
                }

                if !viewModel.suggestedFeatureCards.isEmpty {
                    ForEach(viewModel.suggestedFeatureCards.prefix(2)) { feature in
                        VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                            Text(feature.featureName)
                                .font(AppFont.bodyStrong)
                                .foregroundStyle(AppColor.ink)
                            Text(feature.description)
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.secondaryInk)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.small)
                        .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
                    }
                }
            }
        }
    }

    private var conversationHistory: some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Recent conversations")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)
                if conversations.isEmpty {
                    Text("Your local voice history will appear here.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                } else {
                    ForEach(conversations.prefix(5)) { conversation in
                        VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                            Text(conversation.userText)
                                .font(AppFont.bodyStrong)
                                .foregroundStyle(AppColor.ink)
                            Text(conversation.assistantText)
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.secondaryInk)
                                .lineLimit(3)
                        }
                    }
                }
            }
        }
    }

    private var proactiveInsights: some View {
        let cards = ProactiveHealthSuggestionEngine().suggestions(medicines: medicines, medicineLogs: medicineLogs, healthRecords: healthRecords, habits: [])
        return Group {
            if !cards.isEmpty {
                HabitInsightCards(cards: cards)
            }
        }
    }

    private var currentPreference: HumanAssistantPreference? {
        preferences.first
    }

    private var activeAppRouter: AppRouter {
        providedRouter ?? fallbackRouter
    }

    private func toggleListening() {
        viewModel.toggleListening(modelContext: modelContext, medicines: medicines, medicineLogs: medicineLogs, healthRecords: healthRecords, symptomLogs: symptomLogs, interactions: interactionMemories, preferences: currentPreference)
    }
}

#Preview {
    HumanVoiceAssistantView()
        .modelContainer(SampleData.previewContainer)
}
