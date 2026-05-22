import Foundation

final class AppHelpResponseEngine {
    func response(for intent: AppNavigationIntent) -> String {
        switch intent {
        case .openDashboard: return "Opening your dashboard."
        case .openMedicines: return "Here are your medicines."
        case .openAddMedicine: return "Opening the add medicine screen."
        case .openHealthTracking: return "Opening health tracking."
        case .openSugarTracking: return "Opening sugar tracking."
        case .openSugarLog: return "Let's record your sugar."
        case .openBPTracking: return "Opening your blood pressure records."
        case .openBPLog: return "Ready to record your blood pressure."
        case .openPeriods: return "Opening your period tracker."
        case .openAddPeriodLog: return "Opening period logging."
        case .openCyclePrediction: return "Opening cycle prediction."
        case .openDoctorVisit: return "Opening your doctor visit log."
        case .openPrescriptionScanner: return "Opening the prescription scanner."
        case .openFamilyCare: return "Opening family care."
        case .openProfile: return "Opening profile."
        case .openAmbientIntelligence: return "Opening ambient intelligence."
        case .openHealthMemory: return "Opening health memory."
        case .openMedicineReminder: return "Opening medicine reminder."
        case .openDailyCheckIn: return "Opening daily check-in."
        case .openHealthJourney: return "Here is your health journey."
        case .openMore: return "Opening more options."
        case .openSettings: return "Opening settings."
        case .goBack: return "Okay, closing this."
        case .helpGeneral: return generalHelpResponse()
        case .helpWithFeature(let feature): return "I can help with \(feature). You can ask me to open it or explain it."
        case .unknown: return unknownResponse()
        }
    }

    func helpResponse(for feature: AppFeatureInfo) -> String {
        let example = feature.exampleVoiceCommands.first ?? "open \(feature.featureName)"
        return "\(feature.featureName): \(feature.description) You can say, \(example)."
    }

    func displayName(for intent: AppNavigationIntent) -> String {
        switch intent {
        case .openDashboard: return "Dashboard"
        case .openMedicines: return "Medicines"
        case .openHealthTracking: return "Health Tracking"
        case .openHealthJourney: return "Health Journey"
        case .openMore: return "More"
        case .openAddMedicine: return "Add Medicine"
        case .openSugarTracking: return "Sugar Tracking"
        case .openSugarLog: return "Sugar Log"
        case .openBPTracking: return "Blood Pressure Tracking"
        case .openBPLog: return "Blood Pressure Log"
        case .openPeriods: return "Period Tracker"
        case .openAddPeriodLog: return "Period Log"
        case .openCyclePrediction: return "Cycle Prediction"
        case .openDoctorVisit: return "Doctor Visit"
        case .openPrescriptionScanner: return "Prescription Scanner"
        case .openFamilyCare: return "Family Care"
        case .openProfile: return "Profile"
        case .openAmbientIntelligence: return "Ambient Intelligence"
        case .openHealthMemory: return "Health Memory"
        case .openMedicineReminder: return "Medicine Reminder"
        case .openDailyCheckIn: return "Daily Check-In"
        case .openSettings: return "Settings"
        case .goBack: return "Back"
        case .helpGeneral: return "Help"
        case .helpWithFeature(let feature): return feature
        case .unknown: return "this section"
        }
    }

    func generalHelpResponse() -> String {
        "You can ask me to open any section, record readings, or answer from your saved health logs. For example, say: Record BP, Open periods, or How is my sugar this week."
    }

    func unknownResponse() -> String {
        "I didn't quite catch that. You can say Help, open any section, or ask about your saved health logs."
    }
}
