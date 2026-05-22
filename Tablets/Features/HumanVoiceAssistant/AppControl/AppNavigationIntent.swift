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
    case openPrescriptionScanner
    case openFamilyCare
    case openProfile
    case openAmbientIntelligence
    case openHealthMemory
    case openMedicineReminder
    case openDailyCheckIn
    case openSettings
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
        case .openPrescriptionScanner: return "openPrescriptionScanner"
        case .openFamilyCare: return "openFamilyCare"
        case .openProfile: return "openProfile"
        case .openAmbientIntelligence: return "openAmbientIntelligence"
        case .openHealthMemory: return "openHealthMemory"
        case .openMedicineReminder: return "openMedicineReminder"
        case .openDailyCheckIn: return "openDailyCheckIn"
        case .openSettings: return "openSettings"
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
        case "openPrescriptionScanner": self = .openPrescriptionScanner
        case "openFamilyCare": self = .openFamilyCare
        case "openProfile": self = .openProfile
        case "openAmbientIntelligence": self = .openAmbientIntelligence
        case "openHealthMemory": self = .openHealthMemory
        case "openMedicineReminder": self = .openMedicineReminder
        case "openDailyCheckIn": self = .openDailyCheckIn
        case "openSettings": self = .openSettings
        case "goBack": self = .goBack
        case "helpGeneral": self = .helpGeneral
        default: self = .unknown
        }
    }
}
