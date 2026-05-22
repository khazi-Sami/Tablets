import Combine
import Foundation

@MainActor
final class VoiceNavigationCoordinator: ObservableObject {
    private let appRouter: AppRouter
    private let dismissAssistant: (() -> Void)?

    init(appRouter: AppRouter, dismissAssistant: (() -> Void)? = nil) {
        self.appRouter = appRouter
        self.dismissAssistant = dismissAssistant
    }

    func navigate(to intent: AppNavigationIntent) async {
        switch intent {
        case .openDashboard:
            appRouter.selectedTab = .dashboard
        case .openMedicines:
            appRouter.selectedTab = .medicines
        case .openHealthTracking:
            appRouter.selectedTab = .healthTracking
        case .openHealthJourney:
            appRouter.selectedTab = .healthJourney
        case .openMore:
            appRouter.selectedTab = .more
        case .openAddMedicine:
            appRouter.selectedTab = .medicines
            post(VoiceNavigationNotification.openAddMedicine)
        case .openSugarTracking:
            appRouter.selectedTab = .healthTracking
            post(VoiceNavigationNotification.openSugarTracking)
        case .openSugarLog:
            appRouter.selectedTab = .healthTracking
            post(VoiceNavigationNotification.openSugarLog)
        case .openBPTracking:
            appRouter.selectedTab = .healthTracking
            post(VoiceNavigationNotification.openBPTracking)
        case .openBPLog:
            appRouter.selectedTab = .healthTracking
            post(VoiceNavigationNotification.openBPLog)
        case .openPeriods:
            appRouter.selectedTab = .more
            post(VoiceNavigationNotification.openWomensHealth)
        case .openAddPeriodLog:
            appRouter.selectedTab = .more
            post(VoiceNavigationNotification.openAddPeriodLog)
        case .openCyclePrediction:
            appRouter.selectedTab = .more
            post(VoiceNavigationNotification.openCyclePrediction)
        case .openDoctorVisit:
            appRouter.selectedTab = .more
            post(VoiceNavigationNotification.openDoctorVisit)
        case .openPrescriptionScanner:
            appRouter.selectedTab = .more
            post(VoiceNavigationNotification.openPrescriptionScanner)
        case .openFamilyCare:
            appRouter.selectedTab = .more
            post(VoiceNavigationNotification.openFamilyCare)
        case .openProfile:
            appRouter.selectedTab = .more
            post(VoiceNavigationNotification.openProfile)
        case .openAmbientIntelligence:
            appRouter.selectedTab = .more
            post(VoiceNavigationNotification.openSettings)
        case .openHealthMemory:
            appRouter.selectedTab = .more
            post(VoiceNavigationNotification.openHealthMemory)
        case .openMedicineReminder:
            appRouter.selectedTab = .medicines
            post(VoiceNavigationNotification.openMedicineReminder)
        case .openDailyCheckIn:
            appRouter.selectedTab = .healthJourney
            post(VoiceNavigationNotification.openDailyCheckIn)
        case .openSettings:
            appRouter.selectedTab = .more
            post(VoiceNavigationNotification.openSettings)
        case .goBack:
            await goBack()
            return
        case .helpGeneral, .helpWithFeature, .unknown:
            break
        }

        dismissAssistant?()
        try? await Task.sleep(for: .milliseconds(300))
    }

    func goBack() async {
        dismissAssistant?()
    }

    private func post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
}
