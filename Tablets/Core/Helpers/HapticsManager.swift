import SwiftUI
import UIKit

enum HapticsManager {
    static let isEnabledKey = "isHapticsEnabled"

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .soft) {
        guard UserDefaults.standard.object(forKey: isEnabledKey) as? Bool ?? true else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard UserDefaults.standard.object(forKey: isEnabledKey) as? Bool ?? true else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        guard UserDefaults.standard.object(forKey: isEnabledKey) as? Bool ?? true else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
