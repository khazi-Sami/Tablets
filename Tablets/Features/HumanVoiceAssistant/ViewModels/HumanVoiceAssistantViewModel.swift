import AVFoundation
import Combine
import SwiftData
import SwiftUI

@MainActor
final class HumanVoiceAssistantViewModel: ObservableObject {
    @Published var transcript = ""
    @Published var assistantText = "Hi. I’m ready when you are."
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var needsMicrophonePermission = false
    @Published var pendingConfirmation: ParsedHealthCommand?
    @Published var confirmationValue = ""
    @Published var confirmationType = ""
    @Published var confirmationMedicine = ""
    @Published var lastRecognizedIntent = ""
    @Published var lastAssistantResponse = ""
    @Published var suggestedCommands: [String] = [
        "Record BP",
        "Open periods",
        "How is my sugar?",
        "What medicine is pending?",
        "Scan prescription",
        "Help"
    ]
    @Published var suggestedFeatureCards: [AppFeatureInfo] = []
    @Published var navigationDestinationPreview = ""
    @Published var pendingConfirmationText = ""

    let speechService = WhisperKitSpeechToTextService()
    let ttsService = TTSService()
    let modelManager = WhisperModelManager.shared
    private let confirmationFlow = ConfirmationFlow()
    private let permissionService = AssistantPermissionService()
    private var autoStopTask: Task<Void, Never>?
    private var voiceSessionManager: VoiceSessionManager?

    var isListening: Bool { speechService.isListening }
    var isSpeaking: Bool { ttsService.isSpeaking }
    var isPreparingModel: Bool { speechService.isPreparingModel }
    var modelName: String { speechService.modelName }
    var selectedModelTitle: String { modelManager.selectedModelDisplayName }
    var availableModels: [WhisperLocalModel] { modelManager.availableModels }
    var selectedModel: WhisperLocalModel { modelManager.selectedModel }
    var selectedModelSize: String { modelManager.selectedModel.estimatedSize }
    var selectedModelSetupTime: String { modelManager.selectedModel.estimatedSetupTime }
    var isLocalModelAvailable: Bool { speechService.isLocalModelAvailable }
    var partialTranscript: String { speechService.partialTranscript }
    var audioLevel: Double { speechService.audioLevel }
    var installProgress: Double { modelManager.installProgress }
    var isInstallingModel: Bool { modelManager.isInstalling }
    var isModelLoading: Bool { modelManager.isLoading }
    var modelInstallError: String? { modelManager.installError }
    var activeModelPath: String? { modelManager.activeModelPath }
    var modelStorageUsage: String { modelManager.storageUsageText }
    var modelDownloadStatusText: String { modelManager.downloadStatusText }
    var modelState: WhisperModelState { modelManager.modelState }
    var modelDownloadedText: String {
        ByteCountFormatter.string(fromByteCount: modelManager.downloadedBytes, countStyle: .file)
    }
    var modelTotalText: String {
        ByteCountFormatter.string(fromByteCount: max(modelManager.totalBytes, modelManager.selectedModel.estimatedBytes), countStyle: .file)
    }
    var permissionExplanation: String { permissionService.permissionMessage }

    func configure(modelContext: ModelContext, appRouter: AppRouter, dismissAssistant: @escaping () -> Void, preferencesProvider: @escaping () -> HumanAssistantPreference?) {
        if voiceSessionManager == nil {
            voiceSessionManager = VoiceSessionManager(modelContext: modelContext, ttsService: ttsService, preferencesProvider: preferencesProvider)
        }
        voiceSessionManager?.configureNavigation(appRouter: appRouter, dismissAssistant: dismissAssistant)
        syncVoiceSessionState()
    }

    func refreshPermissions() {
        needsMicrophonePermission = permissionService.microphoneStatus() != .authorized
    }

    func requestMicrophonePermission() {
        Task {
            let granted = await permissionService.requestMicrophoneAccess()
            needsMicrophonePermission = !granted
            if !granted {
                assistantText = "Microphone permission is needed before I can listen. Your voice commands stay private and local."
            }
        }
    }

    func installLocalModel() {
        Task {
            await modelManager.installSelectedModel()
            if modelManager.isInstalled() {
                assistantText = "\(modelManager.selectedModelDisplayName) is ready. Tap Start listening when you want to speak."
                HapticsManager.notification(.success)
            } else if let error = modelManager.installError {
                assistantText = error
                HapticsManager.notification(.error)
            }
        }
    }

    func selectModel(_ model: WhisperLocalModel) {
        modelManager.selectModel(model)
        assistantText = "\(model.title) selected. Download it once, then voice works offline."
    }

    func preloadModelIfPossible() {
        if !modelManager.isInstalled() {
            modelManager.selectBestModelForDevice(preferAccuracy: true)
        }
    }

    func toggleListening(modelContext: ModelContext, medicines: [Medicine], medicineLogs: [MedicineLog], healthRecords: [HealthRecord], symptomLogs: [WomensHealthDailyLog], interactions: [AssistantInteractionMemory], preferences: HumanAssistantPreference?) {
        if speechService.isListening {
            stopAndProcess(modelContext: modelContext, medicines: medicines, medicineLogs: medicineLogs, healthRecords: healthRecords, symptomLogs: symptomLogs, interactions: interactions, preferences: preferences)
        } else {
            refreshPermissions()
            guard !needsMicrophonePermission else {
                requestMicrophonePermission()
                return
            }
            guard modelManager.isReady else {
                assistantText = "The local Whisper voice model is not installed yet. Download it once, then voice works offline."
                errorMessage = "Local voice model missing"
                HapticsManager.notification(.error)
                return
            }
            ttsService.stop()
            Task {
                do {
                    try await speechService.startListening()
                    assistantText = "I’m listening. Speak naturally, then pause or tap Stop."
                    watchForAutomaticStop(modelContext: modelContext, medicines: medicines, medicineLogs: medicineLogs, healthRecords: healthRecords, symptomLogs: symptomLogs, interactions: interactions, preferences: preferences)
                    HapticsManager.impact(.soft)
            } catch {
                errorMessage = modelManager.modelError ?? "I could not start listening or load the local voice model. Please retry model setup."
                assistantText = errorMessage ?? assistantText
                HapticsManager.notification(.error)
            }
            }
        }
    }

    private func stopAndProcess(modelContext: ModelContext, medicines: [Medicine], medicineLogs: [MedicineLog], healthRecords: [HealthRecord], symptomLogs: [WomensHealthDailyLog], interactions: [AssistantInteractionMemory], preferences: HumanAssistantPreference?) {
        autoStopTask?.cancel()
        Task {
            do {
                let text = try await speechService.stopListening()
                transcript = text
                process(text, modelContext: modelContext, medicines: medicines, medicineLogs: medicineLogs, healthRecords: healthRecords, symptomLogs: symptomLogs, interactions: interactions, preferences: preferences)
            } catch {
                errorMessage = "I could not transcribe that audio. Please try again in a quiet place."
                assistantText = errorMessage ?? assistantText
                HapticsManager.notification(.error)
            }
        }
    }

    private func watchForAutomaticStop(modelContext: ModelContext, medicines: [Medicine], medicineLogs: [MedicineLog], healthRecords: [HealthRecord], symptomLogs: [WomensHealthDailyLog], interactions: [AssistantInteractionMemory], preferences: HumanAssistantPreference?) {
        autoStopTask?.cancel()
        autoStopTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self else { return }
                if self.speechService.autoStopRequested && self.speechService.isListening {
                    self.stopAndProcess(modelContext: modelContext, medicines: medicines, medicineLogs: medicineLogs, healthRecords: healthRecords, symptomLogs: symptomLogs, interactions: interactions, preferences: preferences)
                    return
                }
            }
        }
    }

    func process(_ text: String, modelContext: ModelContext, medicines: [Medicine], medicineLogs: [MedicineLog], healthRecords: [HealthRecord], symptomLogs: [WomensHealthDailyLog], interactions: [AssistantInteractionMemory], preferences: HumanAssistantPreference?) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            assistantText = "I did not hear anything clearly. Please try again."
            errorMessage = "Empty transcript"
            return
        }

        isProcessing = true
        errorMessage = nil

        if voiceSessionManager == nil {
            voiceSessionManager = VoiceSessionManager(modelContext: modelContext, ttsService: ttsService) { preferences }
        }

        Task {
            _ = await voiceSessionManager?.process(transcript: cleaned)
            syncVoiceSessionState()
            assistantText = lastAssistantResponse.isEmpty ? assistantText : lastAssistantResponse
            pendingConfirmation = nil
            isProcessing = false
        }
    }

    func runSuggestedCommand(_ command: String, modelContext: ModelContext, preferences: HumanAssistantPreference?) {
        transcript = command
        process(command, modelContext: modelContext, medicines: [], medicineLogs: [], healthRecords: [], symptomLogs: [], interactions: [], preferences: preferences)
    }

    func confirmPending(modelContext: ModelContext, medicines: [Medicine], medicineLogs: [MedicineLog], healthRecords: [HealthRecord], symptomLogs: [WomensHealthDailyLog], preferences: HumanAssistantPreference?) {
        guard let pendingConfirmation else { return }
        self.pendingConfirmation = nil
        let editedNumbers = Double(confirmationValue).map { [$0] } ?? pendingConfirmation.numbers
        var editedEntities = pendingConfirmation.entities
        if !confirmationMedicine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            editedEntities["medicineHint"] = confirmationMedicine
        }
        let boosted = ParsedHealthCommand(intent: pendingConfirmation.intent, originalText: pendingConfirmation.originalText, numbers: editedNumbers, symptoms: pendingConfirmation.symptoms, entities: editedEntities, confidence: 0.9)
        let response = ResponseEngine(modelContext: modelContext).respond(to: boosted, medicines: medicines, medicineLogs: medicineLogs, healthRecords: healthRecords, symptomLogs: symptomLogs)
        assistantText = response.text
        modelContext.insert(HumanAssistantConversation(userText: pendingConfirmation.originalText, assistantText: response.text, intent: boosted.intent, confidence: boosted.confidence))
        try? modelContext.save()
        if preferences?.prefersSpokenResponses ?? true {
            ttsService.speak(response.text, preferredVoiceIdentifier: preferences?.voiceIdentifier ?? "com.apple.ttsbundle.Samantha-compact")
        }
    }

    func cancelPending() {
        pendingConfirmation = nil
        assistantText = "No problem. I did not save that."
        ttsService.stop()
    }

    func retryListening() {
        pendingConfirmation = nil
        pendingConfirmationText = ""
        transcript = ""
        confirmationValue = ""
        confirmationType = ""
        confirmationMedicine = ""
        assistantText = "No problem. Tap Start listening and try again."
    }

    func editManually() {
        pendingConfirmation = nil
        pendingConfirmationText = ""
        assistantText = "Manual editing can be done from the matching health or medicine screen. I did not save this voice command."
    }

    private func syncVoiceSessionState() {
        guard let voiceSessionManager else { return }
        lastRecognizedIntent = voiceSessionManager.lastRecognizedIntent
        lastAssistantResponse = voiceSessionManager.lastAssistantResponse
        suggestedCommands = voiceSessionManager.suggestedCommands
        suggestedFeatureCards = voiceSessionManager.suggestedFeatureCards
        navigationDestinationPreview = voiceSessionManager.navigationDestinationPreview
        pendingConfirmationText = voiceSessionManager.pendingConfirmationText
    }
}
