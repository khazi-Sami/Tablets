import SwiftUI

enum WidgetBrandColor {
    static let medicalBlue = Color(red: 0.18, green: 0.50, blue: 0.86)
    static let medicalBlueDeep = Color(red: 0.08, green: 0.31, blue: 0.62)
    static let mintGreen = Color(red: 0.42, green: 0.82, blue: 0.70)
    static let mintGreenDeep = Color(red: 0.18, green: 0.62, blue: 0.50)
    static let warmWhite = Color(red: 0.99, green: 0.97, blue: 0.93)
    static let cream = Color(red: 1.00, green: 0.99, blue: 0.96)
    static let lavender = Color(red: 0.90, green: 0.88, blue: 0.98)
    static let lavenderDeep = Color(red: 0.57, green: 0.49, blue: 0.86)
    static let softRed = Color(red: 0.88, green: 0.31, blue: 0.34)
    static let softRedBackground = Color(red: 1.00, green: 0.90, blue: 0.90)
    static let ink = Color(red: 0.13, green: 0.18, blue: 0.24)
    static let secondaryInk = Color(red: 0.39, green: 0.46, blue: 0.55)
    static let tertiaryInk = Color(red: 0.57, green: 0.63, blue: 0.70)
    static let hairline = Color(red: 0.78, green: 0.86, blue: 0.91)

    static func background(_ colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.11, blue: 0.18),
                    Color(red: 0.12, green: 0.18, blue: 0.28),
                    lavenderDeep.opacity(0.26)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                warmWhite,
                Color(red: 0.93, green: 0.98, blue: 0.99),
                lavender.opacity(0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func card(_ colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.13), Color.white.opacity(0.06)]
                : [cream.opacity(0.96), Color.white.opacity(0.78)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryButton: LinearGradient {
        LinearGradient(
            colors: [medicalBlue, mintGreenDeep],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var calmStatus: LinearGradient {
        LinearGradient(
            colors: [mintGreen.opacity(0.95), Color(red: 0.74, green: 0.92, blue: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func text(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : ink
    }

    static func secondaryText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.68) : secondaryInk
    }
}

enum WidgetBrandFont {
    static let title = Font.system(.title3, design: .rounded).weight(.bold)
    static let sectionTitle = Font.system(.subheadline, design: .rounded).weight(.semibold)
    static let body = Font.system(.caption, design: .rounded).weight(.regular)
    static let bodyStrong = Font.system(.caption, design: .rounded).weight(.semibold)
    static let badge = Font.system(.caption2, design: .rounded).weight(.bold)
}

enum WidgetBrandSpacing {
    static let xxSmall: CGFloat = 4
    static let xSmall: CGFloat = 8
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
}

enum WidgetBrandRadius {
    static let medium: CGFloat = 18
    static let large: CGFloat = 26
    static let pill: CGFloat = 999
}

extension View {
    func widgetBrandBackground(_ colorScheme: ColorScheme) -> some View {
        background(WidgetBrandColor.background(colorScheme))
    }

    func widgetBrandCard(_ colorScheme: ColorScheme, cornerRadius: CGFloat = WidgetBrandRadius.large) -> some View {
        background(WidgetBrandColor.card(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(WidgetBrandColor.hairline.opacity(colorScheme == .dark ? 0.22 : 0.55), lineWidth: 1)
            )
            .shadow(
                color: WidgetBrandColor.medicalBlue.opacity(colorScheme == .dark ? 0.22 : 0.10),
                radius: 18,
                x: 0,
                y: 8
            )
    }

    func widgetBrandInset(_ colorScheme: ColorScheme, cornerRadius: CGFloat = WidgetBrandRadius.medium) -> some View {
        background(
            colorScheme == .dark
                ? Color.black.opacity(0.12)
                : WidgetBrandColor.medicalBlue.opacity(0.08)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.48), lineWidth: 1)
        )
    }
}
