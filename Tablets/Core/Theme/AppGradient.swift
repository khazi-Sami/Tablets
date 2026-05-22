import SwiftUI

enum AppGradient {
    static let background = LinearGradient(
        colors: [
            AppColor.warmWhite,
            Color(red: 0.93, green: 0.98, blue: 0.99),
            AppColor.lavender.opacity(0.72)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let card = LinearGradient(
        colors: [
            AppColor.cream.opacity(0.96),
            Color.white.opacity(0.78)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let primaryButton = LinearGradient(
        colors: [
            AppColor.medicalBlue,
            AppColor.mintGreenDeep
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let calmStatus = LinearGradient(
        colors: [
            AppColor.mintGreen.opacity(0.95),
            Color(red: 0.74, green: 0.92, blue: 0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let alertStatus = LinearGradient(
        colors: [
            AppColor.softRedBackground,
            Color(red: 1.00, green: 0.95, blue: 0.90)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let lavenderWash = LinearGradient(
        colors: [
            AppColor.lavender.opacity(0.92),
            Color(red: 0.92, green: 0.98, blue: 0.97)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
