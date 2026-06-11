//
//  TabletsApp.swift
//  Tablets
//
//  Created by sami Siddiqui on 14/05/26.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct TabletsApp: App {
    @State private var modelContainerState = AppModelContainer.makeState()

    init() {
        DebugStartupLogger.log("TabletsApp.init started")
        AppTheme.configureAppearance()
        UNUserNotificationCenter.current().delegate = MedicineNotificationDelegate.shared
        DebugStartupLogger.log("AppTheme configured")
    }

    var body: some Scene {
        WindowGroup {
            rootView
        }
    }

    @ViewBuilder
    private var rootView: some View {
        switch modelContainerState {
        case .loaded(let container):
            AuthGateView()
                .modelContainer(container)
                .onAppear {
                    DebugStartupLogger.log("WindowGroup root AuthGateView appeared")
                }
        case .failed(let error):
            AppModelContainerErrorView(
                error: error,
                retry: {
                    modelContainerState = AppModelContainer.makeState()
                },
                resetLocalData: {
                    do {
                        HealthAppIntegrityChecker.cleanupForAppReset()
                        try AppModelContainer.resetLocalStoreForRecovery()
                        modelContainerState = AppModelContainer.makeState()
                    } catch {
                        modelContainerState = .failed(.from(error))
                    }
                }
            )
        }
    }
}
