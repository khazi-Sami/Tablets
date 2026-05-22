import SwiftUI
import UIKit

struct AmbientEnvironmentContext {
    let prefersReducedMotion: Bool
    let lowPowerModeEnabled: Bool
    let colorScheme: ColorScheme
    let accessibilityCategory: ContentSizeCategory
}

struct AmbientEnvironmentService {
    func context(colorScheme: ColorScheme, sizeCategory: ContentSizeCategory) -> AmbientEnvironmentContext {
        AmbientEnvironmentContext(
            prefersReducedMotion: UIAccessibility.isReduceMotionEnabled,
            lowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled,
            colorScheme: colorScheme,
            accessibilityCategory: sizeCategory
        )
    }
}
