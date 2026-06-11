import Foundation
import Observation

@Observable
final class HealthKitVoiceQueryHandler {
    private let service: HealthKitService
    private let readingsProvider: HealthKitReadingsProvider

    init(service: HealthKitService? = nil) {
        let resolvedService = service ?? HealthKitService()
        self.service = resolvedService
        self.readingsProvider = HealthKitReadingsProvider(service: resolvedService)
    }

    func answer(_ transcript: String) async -> String? {
        let text = transcript.lowercased()
        guard matchesHealthKitQuery(text) else { return nil }
        service.refreshAuthorizationStatus()

        if containsAny(text, ["what apple health data", "what health data can you read", "what can you read from apple health"]) {
            return "With your permission, I can read steps, sleep, heart rate, oxygen, and weight from Apple Health. Your Apple Health data stays on your device."
        }

        if containsAny(text, ["is apple health connected", "apple health connected", "healthkit connected"]) {
            if !service.isAvailable {
                return "Apple Health is not available on this device. BanyAI still works with your saved logs."
            }
            return service.isAuthorized ? "Apple Health is connected. I can use it for steps, sleep, and heart insights with your permission." : notConnected
        }

        if containsAny(text, ["can you save my bp to apple health", "save bp to apple health", "save blood pressure to apple health", "save sugar to apple health"]) {
            return UserHealthProfile.healthKitWriteEnabled
                ? "Yes. When Apple Health write sync is enabled and permission is granted, I can save BP, sugar, and weight readings to Apple Health after saving them in BanyAI."
                : "Apple Health write sync is off. Your readings are saved in BanyAI. You can turn Apple Health write sync on from the Apple Health screen."
        }

        if containsAny(text, ["turn off apple health", "disable apple health", "stop apple health", "how do i turn off apple health"]) {
            return "To turn off Apple Health, open Profile or More, choose Apple Health, and turn off write sync. You can also remove read permissions in the iOS Health app under Apps and Services."
        }

        guard service.isAvailable, service.isAuthorized else {
            return notConnected
        }

        if containsAny(text, ["steps", "kadam"]) {
            let snapshot = await readingsProvider.fetchTodaySnapshot()
            guard let steps = snapshot.steps else { return noData }
            return "Based on Apple Health, you have walked around \(Int(steps)) steps so far today."
        }

        if containsAny(text, ["sleep", "neend"]) {
            let snapshot = await readingsProvider.fetchTodaySnapshot()
            guard let hours = snapshot.sleepDurationHours else { return noData }
            let tip = hours < 6 ? " Your body signals suggest a gentler day, informational only." : ""
            return "Apple Health shows around \(String(format: "%.1f", hours)) hours of sleep last night.\(tip)"
        }

        if containsAny(text, ["heart rate", "dhadkan", "dil ki dhadkan"]) {
            let snapshot = await readingsProvider.fetchTodaySnapshot()
            guard let heartRate = snapshot.latestHeartRate ?? snapshot.restingHeartRate else { return noData }
            return "Based on Apple Health, your latest heart rate reading today is around \(Int(heartRate)) beats per minute. Informational only."
        }

        if containsAny(text, ["active", "activity"]) {
            let snapshot = await readingsProvider.fetchTodaySnapshot()
            if let steps = snapshot.steps {
                return "Based on Apple Health, you have around \(Int(steps)) steps today. Informational only."
            }
            return noData
        }

        return nil
    }

    private var noData: String {
        "I don't have that reading from Apple Health yet. Make sure Apple Health is connected in settings."
    }

    private var notConnected: String {
        "Apple Health is not connected yet."
    }

    private func matchesHealthKitQuery(_ text: String) -> Bool {
        containsAny(text, [
            "how many steps today", "steps today", "kadam",
            "how did i sleep", "sleep last night", "neend",
            "what was my heart rate", "heart rate today", "dhadkan", "dil ki dhadkan",
            "was i active today", "activity today", "compare sleep yesterday",
            "sleep compared to yesterday",
            "what apple health data", "what health data can you read", "what can you read from apple health",
            "is apple health connected", "apple health connected", "healthkit connected",
            "can you save my bp to apple health", "save bp to apple health", "save blood pressure to apple health", "save sugar to apple health",
            "turn off apple health", "disable apple health", "stop apple health", "how do i turn off apple health"
        ])
    }

    private func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains { text.contains($0) }
    }
}
