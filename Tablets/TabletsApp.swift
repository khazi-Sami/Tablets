//
//  TabletsApp.swift
//  Tablets
//
//  Created by sami Siddiqui on 14/05/26.
//

import SwiftUI
import SwiftData

@main
struct TabletsApp: App {
    private let sharedModelContainer = AppModelContainer.make()

    init() {
        DebugStartupLogger.log("TabletsApp.init started")
        AppTheme.configureAppearance()
        DebugStartupLogger.log("AppTheme configured")
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .onAppear {
                    DebugStartupLogger.log("WindowGroup root AppRootView appeared")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
