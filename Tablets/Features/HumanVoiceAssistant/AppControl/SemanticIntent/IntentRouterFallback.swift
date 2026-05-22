import Foundation

struct IntentRouterFallback {
    func route(_ transcript: String) -> RouteResult {
        let text = transcript.lowercased()
        let intent: AppNavigationIntent

        if has(text, ["add medicine", "new tablet", "new pill"]) { intent = .openAddMedicine }
        else if has(text, ["medicine", "tablet", "pill"]) { intent = .openMedicines }
        else if has(text, ["record sugar", "log sugar", "enter glucose", "sugar entry"]) { intent = .openSugarLog }
        else if has(text, ["sugar", "glucose", "diabetes"]) { intent = .openSugarTracking }
        else if has(text, ["record bp", "add blood pressure", "enter bp", "log pressure"]) { intent = .openBPLog }
        else if has(text, ["bp", "blood pressure", "pressure"]) { intent = .openBPTracking }
        else if has(text, ["period", "cycle", "women"]) { intent = .openPeriods }
        else if has(text, ["doctor", "clinic", "appointment"]) { intent = .openDoctorVisit }
        else if has(text, ["scan", "prescription", "doctor paper"]) { intent = .openPrescriptionScanner }
        else if has(text, ["journey", "progress", "wellness"]) { intent = .openHealthJourney }
        else if has(text, ["settings", "profile"]) { intent = .openSettings }
        else if has(text, ["help", "confused", "what can you do", "guide"]) { intent = .helpGeneral }
        else { intent = .unknown }

        let confidence = intent == .unknown ? 0.0 : 0.62
        return RouteResult(intent: intent, confidence: confidence, rawTranscript: transcript, matchedExample: nil, needsConfirmation: confidence < 0.72 && intent != .unknown)
    }

    private func has(_ text: String, _ phrases: [String]) -> Bool {
        phrases.contains { text.contains($0) }
    }
}
