import Foundation

struct ConfirmationFlow {
    func needsConfirmation(_ response: HealthAssistantResponse) -> Bool {
        response.requiresConfirmation || response.confidence < 0.62
    }
}
