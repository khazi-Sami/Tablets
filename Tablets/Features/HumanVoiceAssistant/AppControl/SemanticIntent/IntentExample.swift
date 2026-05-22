import Foundation

struct IntentExampleGroup: Codable, Identifiable {
    var id: String { intentId }
    let intentId: String
    let displayName: String
    let category: String
    let examples: [String]
    let responseTemplate: String?
}

struct IntentExampleMatch {
    let intent: AppNavigationIntent
    let confidence: Double
    let rawTranscript: String
    let matchedExample: String?
    let displayName: String?
    let needsConfirmation: Bool
}

struct RouteResult {
    let intent: AppNavigationIntent
    let confidence: Double
    let rawTranscript: String
    let matchedExample: String?
    let needsConfirmation: Bool
}
