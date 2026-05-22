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
        AppTheme.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
