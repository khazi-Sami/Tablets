import Foundation

final class AppHelpResponseEngine {
    private let variations = ResponseVariationPool()

    func response(for intent: AppNavigationIntent) -> String {
        switch intent {
        case .openDashboard: return variations.navigation(["Opening your dashboard.", "Taking you home.", "Here is your health overview."])
        case .openMedicines: return variations.navigation(["Here are your medicines.", "Opening your medicine list.", "Taking you to your tablets."])
        case .openAddMedicine: return variations.navigation(["Opening the add medicine screen.", "Let's add a medicine.", "Ready to add a new tablet."])
        case .openHealthTracking: return variations.navigation(["Opening health tracking.", "Here are your health records.", "Taking you to your vitals."])
        case .openSugarTracking: return variations.navigation(["Opening sugar tracking.", "Here are your sugar records.", "Taking you to diabetes tracking."])
        case .openSugarLog: return variations.navigation(["Let's record your sugar.", "Opening sugar entry.", "Ready to add your sugar reading."])
        case .openBPTracking: return variations.navigation(["Opening your blood pressure records.", "Here is your BP tracking.", "Taking you to pressure records."])
        case .openBPLog: return variations.navigation(["Ready to record your blood pressure.", "Opening BP entry.", "Let's add your pressure reading."])
        case .openPeriods: return variations.navigation(["Opening your period tracker.", "Taking you to women's health.", "Here is your cycle tracker."])
        case .openAddPeriodLog: return variations.navigation(["Opening period logging.", "Ready to log your period.", "Opening cycle entry."])
        case .openCyclePrediction: return variations.navigation(["Opening cycle prediction.", "Showing your estimated cycle view.", "Taking you to period estimates."])
        case .openDoctorVisit: return variations.navigation(["Opening your doctor visit log.", "Taking you to doctor visits.", "Here are your appointment notes."])
        case .openDoctorReport: return variations.navigation(["Opening your doctor report preview.", "Creating your doctor report screen.", "Taking you to the doctor PDF report."])
        case .openHealthReport: return "Opening your health report."
        case .openPrescriptionScanner: return variations.navigation(["Opening the prescription scanner.", "Ready to scan your prescription.", "Opening the scanner."])
        case .openFamilyCare: return variations.navigation(["Opening family care.", "Taking you to family care.", "Here are family profiles."])
        case .openProfile: return variations.navigation(["Opening profile.", "Taking you to profile.", "Here are your profile settings."])
        case .openAmbientIntelligence: return variations.navigation(["Opening ambient intelligence.", "Taking you to adaptive health mode.", "Here are your quiet insights."])
        case .openHealthMemory: return variations.navigation(["Opening health memory.", "Taking you to health patterns.", "Here are your saved habit insights."])
        case .openMedicineReminder: return variations.navigation(["Opening medicine reminder.", "Taking you to the reminder screen.", "Here is your medicine reminder."])
        case .openDailyCheckIn: return variations.navigation(["Opening daily check-in.", "Let's check in for today.", "Taking you to your daily log."])
        case .openHealthJourney: return variations.navigation(["Here is your health journey.", "Opening your wellness timeline.", "Taking you to your progress."])
        case .openMore: return variations.navigation(["Opening more options.", "Here are more tools.", "Taking you to more."])
        case .openSettings: return variations.navigation(["Opening settings.", "Taking you to settings.", "Here are your app preferences."])
        case .openPregnancyPlanning, .openPregnancySetup, .openPregnancyDashboard:
            return variations.navigation(["Opening your pregnancy journey.", "Taking you to Pregnancy & Planning.", "Opening your pregnancy tracker."])
        case .openPregnancySymptomLog:
            return variations.navigation(["Let's log how you're feeling today.", "Opening pregnancy symptom log.", "Ready to save your pregnancy symptoms."])
        case .openPregnancyWeightLog:
            return variations.navigation(["Opening pregnancy weight log.", "Ready to save pregnancy weight.", "Taking you to pregnancy weight tracking."])
        case .openBabyKickCounter:
            return variations.navigation(["Opening the kick counter. Tap each time you feel baby move.", "Taking you to baby kick counter.", "Opening baby movement tracking."])
        case .openPregnancyAppointments:
            return variations.navigation(["Opening your pregnancy appointments.", "Taking you to appointment planning.", "Here are pregnancy appointments."])
        case .openPregnancyWeekGuide:
            return variations.navigation(["Opening your week-by-week pregnancy guide.", "Taking you to the pregnancy week guide.", "Here is your baby's week guide."])
        case .openPregnancyMilestones:
            return variations.navigation(["Opening pregnancy milestones.", "Taking you to beautiful moments.", "Here are your pregnancy milestones."])
        case .openContractionTimer:
            return "Opening contraction timer."
        case .openPregnancyMoodLog:
            return "Let's log how you're feeling."
        case .openPregnancyTimeline:
            return "Opening your pregnancy journey timeline."
        case .openPregnancyWeightChart:
            return "Opening pregnancy weight chart."
        case .openBirthPlan:
            return "Opening your birth plan."
        case .openPregnancyNotes:
            return "Opening your pregnancy notes."
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
        case .openDoctorReport: return "Doctor Report"
        case .openHealthReport: return "Health Report"
        case .openPrescriptionScanner: return "Prescription Scanner"
        case .openFamilyCare: return "Family Care"
        case .openProfile: return "Profile"
        case .openAmbientIntelligence: return "Ambient Intelligence"
        case .openHealthMemory: return "Health Memory"
        case .openMedicineReminder: return "Medicine Reminder"
        case .openDailyCheckIn: return "Daily Check-In"
        case .openSettings: return "Settings"
        case .openPregnancyPlanning: return "Pregnancy & Planning"
        case .openPregnancySetup: return "Pregnancy Setup"
        case .openPregnancyDashboard: return "Pregnancy Dashboard"
        case .openPregnancySymptomLog: return "Pregnancy Symptom Log"
        case .openPregnancyWeightLog: return "Pregnancy Weight Log"
        case .openBabyKickCounter: return "Baby Kick Counter"
        case .openPregnancyAppointments: return "Pregnancy Appointments"
        case .openPregnancyWeekGuide: return "Pregnancy Week Guide"
        case .openPregnancyMilestones: return "Pregnancy Milestones"
        case .openContractionTimer: return "Contraction Timer"
        case .openPregnancyMoodLog: return "Pregnancy Mood Log"
        case .openPregnancyTimeline: return "Pregnancy Timeline"
        case .openPregnancyWeightChart: return "Pregnancy Weight Chart"
        case .openBirthPlan: return "Birth Plan"
        case .openPregnancyNotes: return "Pregnancy Notes"
        case .goBack: return "Back"
        case .helpGeneral: return "Help"
        case .helpWithFeature(let feature): return feature
        case .unknown: return "this section"
        }
    }

    func generalHelpResponse() -> String {
        "You can start by adding your medicines, logging BP or sugar, or trying the voice assistant. Good first commands are: Add my first medicine, Log BP, or What medicine is next?"
    }

    func unknownResponse() -> String {
        "I didn't quite catch that. You can say Help, open any section, or ask about your saved health logs."
    }
}
