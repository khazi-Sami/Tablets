import Combine
import Foundation
import SwiftData
import SwiftUI

struct VoiceSessionResult {
    let transcript: String
    let response: String
    let category: VoiceSessionCategory
    let shouldAutoDismiss: Bool
}

enum VoiceSessionCategory {
    case healthLogging
    case healthQuery
    case navigation
    case help
    case fallback
    case error
}

@MainActor
final class VoiceSessionManager: ObservableObject {
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

    private let parser: HealthIntentParser
    private let semanticRouter: SemanticIntentRouting
    private let healthQueryEngine: HealthQueryAnswering
    private let knowledgeBase: AppKnowledgeBase
    private let helpEngine: AppHelpResponseEngine
    private let responseEngine: ResponseEngine
    private let ttsService: TTSServiceProtocol
    private let modelContext: ModelContext
    private let preferencesProvider: () -> HumanAssistantPreference?
    private var actionExecutor: AppVoiceActionExecutor?
    private var pendingIntent: AppNavigationIntent?
    private var awaitingConfirmation = false
    private var confirmationStartedAt: Date?

    init(
        modelContext: ModelContext,
        ttsService: TTSServiceProtocol,
        preferencesProvider: @escaping () -> HumanAssistantPreference?,
        parser: HealthIntentParser? = nil,
        semanticRouter: SemanticIntentRouting? = nil,
        healthQueryEngine: HealthQueryAnswering? = nil,
        knowledgeBase: AppKnowledgeBase? = nil,
        helpEngine: AppHelpResponseEngine? = nil
    ) {
        self.modelContext = modelContext
        self.ttsService = ttsService
        self.preferencesProvider = preferencesProvider
        self.parser = parser ?? HealthIntentParser()
        self.semanticRouter = semanticRouter ?? SemanticIntentRouter()
        self.healthQueryEngine = healthQueryEngine ?? HealthQueryEngine()
        self.knowledgeBase = knowledgeBase ?? AppKnowledgeBase()
        self.helpEngine = helpEngine ?? AppHelpResponseEngine()
        self.responseEngine = ResponseEngine(modelContext: modelContext)
        self.suggestedFeatureCards = Array(self.knowledgeBase.topSuggestions().prefix(3))
    }

    func configureNavigation(appRouter: AppRouter, dismissAssistant: (() -> Void)?) {
        let coordinator = VoiceNavigationCoordinator(appRouter: appRouter, dismissAssistant: dismissAssistant)
        self.actionExecutor = AppVoiceActionExecutor(coordinator: coordinator, helpEngine: helpEngine)
    }

    func process(transcript: String) async -> VoiceSessionResult {
        let cleaned = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            return await respond("I did not hear anything clearly. Please try again.", userText: transcript, intent: .unknown, confidence: 0.2, category: .error, shouldAutoDismiss: false)
        }

        if await handlePendingConfirmation(cleaned) {
            return VoiceSessionResult(transcript: cleaned, response: lastAssistantResponse, category: .navigation, shouldAutoDismiss: true)
        }

        let command = parser.parse(cleaned)
        if isDirectHealthCommand(command) {
            SwiftDataHealthMemoryService(modelContext: modelContext).remember(command)
            HealthMemoryHabitLearningEngine(modelContext: modelContext).learn(
                command: command,
                medicines: fetchMedicines(),
                medicineLogs: fetchMedicineLogs(),
                healthRecords: fetchHealthRecords(),
                dailyLogs: fetchSymptomLogs(),
                interactions: fetchInteractions()
            )
            let response = responseEngine.respond(
                to: command,
                medicines: fetchMedicines(),
                medicineLogs: fetchMedicineLogs(),
                healthRecords: fetchHealthRecords(),
                symptomLogs: fetchSymptomLogs()
            )
            return await respond(response.text, userText: cleaned, intent: command.intent, confidence: command.confidence, category: .healthLogging, shouldAutoDismiss: true)
        }

        if let queryAnswer = await healthQueryEngine.answer(cleaned, modelContext: modelContext) {
            return await respond(queryAnswer, userText: cleaned, intent: command.intent, confidence: 0.82, category: .healthQuery, shouldAutoDismiss: false)
        }

        let route = await semanticRouter.route(cleaned)
        if route.intent != .unknown {
            lastRecognizedIntent = route.intent.id
            navigationDestinationPreview = route.intent.id

            if route.confidence >= 0.72 {
                return await execute(route.intent, userText: cleaned, confidence: route.confidence)
            }

            if route.needsConfirmation {
                return await askToConfirm(route.intent, userText: cleaned)
            }
        }

        if let feature = knowledgeBase.search(cleaned) {
            suggestedFeatureCards = [feature]
            pendingIntent = feature.navigationIntent
            awaitingConfirmation = true
            confirmationStartedAt = .now
            pendingConfirmationText = "Would you like me to open \(feature.featureName)?"
            let response = "\(helpEngine.helpResponse(for: feature)) Would you like me to open it?"
            return await respond(response, userText: cleaned, intent: .unknown, confidence: 0.64, category: .help, shouldAutoDismiss: false)
        }

        suggestedFeatureCards = Array(knowledgeBase.topSuggestions().prefix(3))
        return await respond(helpEngine.unknownResponse(), userText: cleaned, intent: .unknown, confidence: 0.3, category: .fallback, shouldAutoDismiss: false)
    }

    private func handlePendingConfirmation(_ transcript: String) async -> Bool {
        guard awaitingConfirmation, let pendingIntent else { return false }

        if let started = confirmationStartedAt, Date().timeIntervalSince(started) > 15 {
            clearPendingConfirmation()
            return false
        }

        let normalized = transcript.lowercased()
        if containsAny(normalized, ["yes", "yeah", "sure", "ok", "okay", "open it", "go ahead", "continue"]) {
            clearPendingConfirmation(keepIntent: true)
            _ = await execute(pendingIntent, userText: transcript, confidence: 0.72)
            return true
        }

        if containsAny(normalized, ["no", "cancel", "stop", "never mind", "not now"]) {
            clearPendingConfirmation()
            _ = await respond("Okay, cancelled.", userText: transcript, intent: .unknown, confidence: 0.72, category: .fallback, shouldAutoDismiss: true)
            return true
        }

        clearPendingConfirmation()
        return false
    }

    private func execute(_ intent: AppNavigationIntent, userText: String, confidence: Double) async -> VoiceSessionResult {
        switch intent {
        case .helpGeneral:
            return await respond(helpEngine.generalHelpResponse(), userText: userText, intent: .unknown, confidence: confidence, category: .help, shouldAutoDismiss: false)
        case .helpWithFeature(let feature):
            let fallback = AppFeatureInfo(featureName: feature, description: "I can help you find and use this section.", exampleVoiceCommands: [], navigationIntent: .helpGeneral, keywords: [])
            return await respond(helpEngine.helpResponse(for: fallback), userText: userText, intent: .unknown, confidence: confidence, category: .help, shouldAutoDismiss: false)
        case .unknown:
            return await respond(helpEngine.unknownResponse(), userText: userText, intent: .unknown, confidence: confidence, category: .fallback, shouldAutoDismiss: false)
        default:
            guard let actionExecutor else {
                return await respond(helpEngine.response(for: intent), userText: userText, intent: .unknown, confidence: confidence, category: .navigation, shouldAutoDismiss: true)
            }
            let response = await actionExecutor.execute(intent)
            return await respond(response, userText: userText, intent: .unknown, confidence: confidence, category: .navigation, shouldAutoDismiss: true)
        }
    }

    private func askToConfirm(_ intent: AppNavigationIntent, userText: String) async -> VoiceSessionResult {
        pendingIntent = intent
        awaitingConfirmation = true
        confirmationStartedAt = .now
        let featureName = helpEngine.displayName(for: intent)
        pendingConfirmationText = "I think you want to open \(featureName). Should I continue?"
        return await respond(pendingConfirmationText, userText: userText, intent: .unknown, confidence: 0.62, category: .help, shouldAutoDismiss: false)
    }

    private func respond(_ text: String, userText: String, intent: HealthVoiceIntent, confidence: Double, category: VoiceSessionCategory, shouldAutoDismiss: Bool) async -> VoiceSessionResult {
        let safeText = SafetyLanguageFilter.filtered(text)
        lastAssistantResponse = safeText
        modelContext.insert(HumanAssistantConversation(userText: userText, assistantText: safeText, intent: intent, confidence: confidence))
        do {
            try modelContext.save()
        } catch {
            lastAssistantResponse = "\(safeText) I could not save this conversation locally just now."
        }

        if preferencesProvider()?.prefersSpokenResponses ?? true {
            ttsService.speak(safeText, preferredVoiceIdentifier: preferencesProvider()?.voiceIdentifier ?? "com.apple.ttsbundle.Samantha-compact")
        }

        return VoiceSessionResult(transcript: userText, response: safeText, category: category, shouldAutoDismiss: shouldAutoDismiss)
    }

    private func isDirectHealthCommand(_ command: ParsedHealthCommand) -> Bool {
        switch command.intent {
        case .logSugar:
            return !command.numbers.isEmpty
        case .logBloodPressure:
            return command.numbers.count >= 2
        case .logSymptoms:
            return !command.symptoms.isEmpty
        case .medicineTaken, .startPeriod:
            return true
        default:
            return false
        }
    }

    private func clearPendingConfirmation(keepIntent: Bool = false) {
        if !keepIntent {
            pendingIntent = nil
        }
        awaitingConfirmation = false
        confirmationStartedAt = nil
        pendingConfirmationText = ""
    }

    private func fetchMedicines() -> [Medicine] {
        fetch(FetchDescriptor<Medicine>(sortBy: [SortDescriptor(\.name)]))
    }

    private func fetchMedicineLogs() -> [MedicineLog] {
        fetch(FetchDescriptor<MedicineLog>(sortBy: [SortDescriptor(\.scheduledTime, order: .reverse)]))
    }

    private func fetchHealthRecords() -> [HealthRecord] {
        fetch(FetchDescriptor<HealthRecord>(sortBy: [SortDescriptor(\.measuredAt, order: .reverse)]))
    }

    private func fetchSymptomLogs() -> [WomensHealthDailyLog] {
        fetch(FetchDescriptor<WomensHealthDailyLog>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
    }

    private func fetchInteractions() -> [AssistantInteractionMemory] {
        fetch(FetchDescriptor<AssistantInteractionMemory>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
    }

    private func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) -> [T] {
        (try? modelContext.fetch(descriptor)) ?? []
    }

    private func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains { text.contains($0) }
    }
}

private enum SafetyLanguageFilter {
    static func filtered(_ text: String) -> String {
        var safeText = text
        let replacements = [
            "You are fine": "Based on your saved logs, this looks stable",
            "No need to worry": "Please consult your doctor if symptoms continue",
            "You are healthy": "Your saved logs look stable",
            "This is normal": "This is within a common reference range — informational only",
            "Everything looks good": "This looks stable compared to your saved logs",
            "That is a good reading": "That reading was saved",
            "Nothing to worry about": "Please consult your doctor if symptoms continue"
        ]
        replacements.forEach { unsafe, replacement in
            safeText = safeText.replacingOccurrences(of: unsafe, with: replacement, options: [.caseInsensitive])
        }
        return safeText
    }
}
