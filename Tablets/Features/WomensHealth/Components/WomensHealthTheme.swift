import SwiftUI

enum WomensHealthTheme {
    static let blush = Color(red: 0.98, green: 0.68, blue: 0.76)
    static let blushSoft = Color(red: 1.00, green: 0.90, blue: 0.92)
    static let lavender = AppColor.lavender
    static let mint = AppColor.mintGreen
    static let warm = AppColor.warmWhite

    static let gradient = LinearGradient(
        colors: [
            warm,
            blushSoft.opacity(0.92),
            lavender.opacity(0.70),
            Color(red: 0.91, green: 0.98, blue: 0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
