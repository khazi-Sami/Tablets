import Foundation

enum AppNavigationIntent: Equatable {
    case openDashboard
    case openMedicines
    case openHealthTracking
    case openHealthJourney
    case openMore
    case openAddMedicine
    case openSugarTracking
    case openSugarLog
    case openBPTracking
    case openBPLog
    case openPeriods
    case openAddPeriodLog
    case openCyclePrediction
    case openDoctorVisit
    case openDoctorReport
    case openPrescriptionScanner
    case openFamilyCare
    case openProfile
    case openAmbientIntelligence
    case openHealthMemory
    case openMedicineReminder
    case openDailyCheckIn
    case openSettings
    case openPregnancyPlanning
    case openPregnancySetup
    case openPregnancyDashboard
    case openPregnancySymptomLog
    case openPregnancyWeightLog
    case openBabyKickCounter
    case openPregnancyAppointments
    case openPregnancyWeekGuide
    case openPregnancyMilestones
    case openContractionTimer
    case openPregnancyMoodLog
    case openPregnancyTimeline
    case openPregnancyWeightChart
    case openBirthPlan
    case openPregnancyNotes
    case goBack
    case helpGeneral
    case helpWithFeature(feature: String)
    case unknown

    var id: String {
        switch self {
        case .openDashboard: return "openDashboard"
        case .openMedicines: return "openMedicines"
        case .openHealthTracking: return "openHealthTracking"
        case .openHealthJourney: return "openHealthJourney"
        case .openMore: return "openMore"
        case .openAddMedicine: return "openAddMedicine"
        case .openSugarTracking: return "openSugarTracking"
        case .openSugarLog: return "openSugarLog"
        case .openBPTracking: return "openBPTracking"
        case .openBPLog: return "openBPLog"
        case .openPeriods: return "openPeriods"
        case .openAddPeriodLog: return "openAddPeriodLog"
        case .openCyclePrediction: return "openCyclePrediction"
        case .openDoctorVisit: return "openDoctorVisit"
        case .openDoctorReport: return "openDoctorReport"
        case .openPrescriptionScanner: return "openPrescriptionScanner"
        case .openFamilyCare: return "openFamilyCare"
        case .openProfile: return "openProfile"
        case .openAmbientIntelligence: return "openAmbientIntelligence"
        case .openHealthMemory: return "openHealthMemory"
        case .openMedicineReminder: return "openMedicineReminder"
        case .openDailyCheckIn: return "openDailyCheckIn"
        case .openSettings: return "openSettings"
        case .openPregnancyPlanning: return "openPregnancyPlanning"
        case .openPregnancySetup: return "openPregnancySetup"
        case .openPregnancyDashboard: return "openPregnancyDashboard"
        case .openPregnancySymptomLog: return "openPregnancySymptomLog"
        case .openPregnancyWeightLog: return "openPregnancyWeightLog"
        case .openBabyKickCounter: return "openBabyKickCounter"
        case .openPregnancyAppointments: return "openPregnancyAppointments"
        case .openPregnancyWeekGuide: return "openPregnancyWeekGuide"
        case .openPregnancyMilestones: return "openPregnancyMilestones"
        case .openContractionTimer: return "openContractionTimer"
        case .openPregnancyMoodLog: return "openPregnancyMoodLog"
        case .openPregnancyTimeline: return "openPregnancyTimeline"
        case .openPregnancyWeightChart: return "openPregnancyWeightChart"
        case .openBirthPlan: return "openBirthPlan"
        case .openPregnancyNotes: return "openPregnancyNotes"
        case .goBack: return "goBack"
        case .helpGeneral: return "helpGeneral"
        case .helpWithFeature(let feature): return "helpWithFeature:\(feature)"
        case .unknown: return "unknown"
        }
    }

    init(intentId: String) {
        switch intentId {
        case "openDashboard": self = .openDashboard
        case "openMedicines": self = .openMedicines
        case "openHealthTracking": self = .openHealthTracking
        case "openHealthJourney": self = .openHealthJourney
        case "openMore": self = .openMore
        case "openAddMedicine": self = .openAddMedicine
        case "openSugarTracking": self = .openSugarTracking
        case "openSugarLog": self = .openSugarLog
        case "openBPTracking": self = .openBPTracking
        case "openBPLog": self = .openBPLog
        case "openPeriods": self = .openPeriods
        case "openAddPeriodLog": self = .openAddPeriodLog
        case "openCyclePrediction": self = .openCyclePrediction
        case "openDoctorVisit": self = .openDoctorVisit
        case "openDoctorReport": self = .openDoctorReport
        case "openPrescriptionScanner": self = .openPrescriptionScanner
        case "openFamilyCare": self = .openFamilyCare
        case "openProfile": self = .openProfile
        case "openAmbientIntelligence": self = .openAmbientIntelligence
        case "openHealthMemory": self = .openHealthMemory
        case "openMedicineReminder": self = .openMedicineReminder
        case "openDailyCheckIn": self = .openDailyCheckIn
        case "openSettings": self = .openSettings
        case "openPregnancyPlanning": self = .openPregnancyPlanning
        case "openPregnancySetup": self = .openPregnancySetup
        case "openPregnancyDashboard": self = .openPregnancyDashboard
        case "openPregnancySymptomLog": self = .openPregnancySymptomLog
        case "openPregnancyWeightLog": self = .openPregnancyWeightLog
        case "openBabyKickCounter": self = .openBabyKickCounter
        case "openPregnancyAppointments": self = .openPregnancyAppointments
        case "openPregnancyWeekGuide": self = .openPregnancyWeekGuide
        case "openPregnancyMilestones": self = .openPregnancyMilestones
        case "openContractionTimer": self = .openContractionTimer
        case "openPregnancyMoodLog": self = .openPregnancyMoodLog
        case "openPregnancyTimeline": self = .openPregnancyTimeline
        case "openPregnancyWeightChart": self = .openPregnancyWeightChart
        case "openBirthPlan": self = .openBirthPlan
        case "openPregnancyNotes": self = .openPregnancyNotes
        case "goBack": self = .goBack
        case "helpGeneral": self = .helpGeneral
        default: self = .unknown
        }
    }
}
