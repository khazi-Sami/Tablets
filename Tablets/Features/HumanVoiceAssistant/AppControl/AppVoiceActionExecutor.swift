import Foundation

@MainActor
final class AppVoiceActionExecutor {
    private let coordinator: VoiceNavigationCoordinator
    private let helpEngine: AppHelpResponseEngine

    init(coordinator: VoiceNavigationCoordinator, helpEngine: AppHelpResponseEngine? = nil) {
        self.coordinator = coordinator
        self.helpEngine = helpEngine ?? AppHelpResponseEngine()
    }

    func execute(_ intent: AppNavigationIntent) async -> String {
        await coordinator.navigate(to: intent)
        return helpEngine.response(for: intent)
    }
}
