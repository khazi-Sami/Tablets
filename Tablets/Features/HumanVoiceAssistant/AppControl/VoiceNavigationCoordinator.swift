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
            await postAfterTabChange(VoiceNavigationNotification.openAddMedicine)
        case .openSugarTracking:
            appRouter.selectedTab = .healthTracking
            await postAfterTabChange(VoiceNavigationNotification.openSugarTracking)
        case .openSugarLog:
            appRouter.selectedTab = .healthTracking
            await postAfterTabChange(VoiceNavigationNotification.openSugarLog)
        case .openBPTracking:
            appRouter.selectedTab = .healthTracking
            await postAfterTabChange(VoiceNavigationNotification.openBPTracking)
        case .openBPLog:
            appRouter.selectedTab = .healthTracking
            await postAfterTabChange(VoiceNavigationNotification.openBPLog)
        case .openPeriods:
            appRouter.selectedTab = .more
            await postAfterTabChange(VoiceNavigationNotification.openWomensHealth)
        case .openAddPeriodLog:
            appRouter.selectedTab = .more
            await postAfterTabChange(VoiceNavigationNotification.openAddPeriodLog)
        case .openCyclePrediction:
            appRouter.selectedTab = .more
            await postAfterTabChange(VoiceNavigationNotification.openCyclePrediction)
        case .openDoctorVisit:
            appRouter.selectedTab = .more
            await postAfterTabChange(VoiceNavigationNotification.openDoctorVisit)
        case .openDoctorReport:
            appRouter.selectedTab = .more
            await postAfterTabChange(VoiceNavigationNotification.openDoctorReport)
        case .openPrescriptionScanner:
            appRouter.selectedTab = .more
            await postAfterTabChange(VoiceNavigationNotification.openPrescriptionScanner)
        case .openFamilyCare:
            appRouter.selectedTab = .more
            await postAfterTabChange(VoiceNavigationNotification.openFamilyCare)
        case .openProfile:
            appRouter.selectedTab = .more
            await postAfterTabChange(VoiceNavigationNotification.openProfile)
        case .openAmbientIntelligence:
            appRouter.selectedTab = .more
            await postAfterTabChange(VoiceNavigationNotification.openSettings)
        case .openHealthMemory:
            appRouter.selectedTab = .more
            await postAfterTabChange(VoiceNavigationNotification.openHealthMemory)
        case .openMedicineReminder:
            appRouter.selectedTab = .medicines
            await postAfterTabChange(VoiceNavigationNotification.openMedicineReminder)
        case .openDailyCheckIn:
            appRouter.selectedTab = .healthJourney
            await postAfterTabChange(VoiceNavigationNotification.openDailyCheckIn)
        case .openSettings:
            appRouter.selectedTab = .more
            await postAfterTabChange(VoiceNavigationNotification.openSettings)
        case .goBack:
            await goBack()
            return
        case .helpGeneral, .helpWithFeature, .unknown:
            break
        }

        dismissAssistant?()
    }

    func goBack() async {
        dismissAssistant?()
    }

    private func post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }

    private func postAfterTabChange(_ name: Notification.Name) async {
        try? await Task.sleep(for: .milliseconds(250))
        post(name)
    }
}
