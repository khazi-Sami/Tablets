import SwiftUI

enum ColorPalette {
    static let primary = AppColor.medicalBlue
    static let primaryDark = AppColor.medicalBlueDeep
    static let secondary = AppColor.mintGreenDeep
    static let accent = AppColor.lavenderDeep

    static let background = AppColor.warmWhite
    static let surface = AppColor.cream
    static let elevatedSurface = AppColor.lavender.opacity(0.45)

    static let textPrimary = AppColor.ink
    static let textSecondary = AppColor.secondaryInk
    static let textTertiary = AppColor.tertiaryInk

    static let divider = AppColor.hairline
    static let success = AppColor.mintGreenDeep
    static let warning = AppColor.lavenderDeep
    static let danger = AppColor.softRed
}
