import SwiftUI
import UIKit

enum AppTheme {
    static let colors = ColorPalette.self
    static let typography = Typography.self
    static let spacing = Spacing.self

    static func configureAppearance() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithTransparentBackground()
        navigationAppearance.backgroundColor = UIColor.clear
        navigationAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppColor.ink)]
        navigationAppearance.titleTextAttributes = [.foregroundColor: UIColor(AppColor.ink)]

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(AppColor.tertiaryInk)
    }
}
