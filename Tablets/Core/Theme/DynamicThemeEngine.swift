import SwiftUI

enum HealthAuraMood: String, CaseIterable {
    case stable
    case sunrise
    case lavenderCycle
    case attention
    case restorative

    var title: String {
        switch self {
        case .stable: return "Stable"
        case .sunrise: return "Positive streak"
        case .lavenderCycle: return "Cycle care"
        case .attention: return "Gentle attention"
        case .restorative: return "Rest"
        }
    }
}

struct HealthAuraStyle {
    let mood: HealthAuraMood
    let colors: [Color]
    let accent: Color
    let secondaryAccent: Color
    let particleOpacity: Double
    let glowIntensity: Double
    let lightingOpacity: Double
}

enum DynamicThemeEngine {
    static func style(for mood: HealthAuraMood) -> HealthAuraStyle {
        switch mood {
        case .stable:
            return HealthAuraStyle(
                mood: mood,
                colors: [
                    AppColor.warmWhite,
                    Color(red: 0.86, green: 0.96, blue: 1.0),
                    AppColor.mintGreen.opacity(0.48)
                ],
                accent: AppColor.medicalBlue,
                secondaryAccent: AppColor.mintGreenDeep,
                particleOpacity: 0.26,
                glowIntensity: 0.20,
                lightingOpacity: 0.22
            )
        case .sunrise:
            return HealthAuraStyle(
                mood: mood,
                colors: [
                    Color(red: 1.0, green: 0.86, blue: 0.62),
                    AppColor.warmWhite,
                    AppColor.mintGreen.opacity(0.38)
                ],
                accent: Color(red: 0.96, green: 0.56, blue: 0.30),
                secondaryAccent: AppColor.mintGreenDeep,
                particleOpacity: 0.34,
                glowIntensity: 0.26,
                lightingOpacity: 0.30
            )
        case .lavenderCycle:
            return HealthAuraStyle(
                mood: mood,
                colors: [
                    AppColor.lavender.opacity(0.96),
                    Color(red: 1.0, green: 0.91, blue: 0.95),
                    AppColor.warmWhite
                ],
                accent: AppColor.lavenderDeep,
                secondaryAccent: AppColor.softRed.opacity(0.76),
                particleOpacity: 0.30,
                glowIntensity: 0.24,
                lightingOpacity: 0.28
            )
        case .attention:
            return HealthAuraStyle(
                mood: mood,
                colors: [
                    Color(red: 1.0, green: 0.92, blue: 0.78),
                    AppColor.warmWhite,
                    Color(red: 0.98, green: 0.80, blue: 0.58).opacity(0.62)
                ],
                accent: Color(red: 0.95, green: 0.54, blue: 0.28),
                secondaryAccent: AppColor.softRed,
                particleOpacity: 0.24,
                glowIntensity: 0.22,
                lightingOpacity: 0.26
            )
        case .restorative:
            return HealthAuraStyle(
                mood: mood,
                colors: [
                    Color(red: 0.85, green: 0.91, blue: 0.98),
                    AppColor.lavender.opacity(0.78),
                    AppColor.warmWhite
                ],
                accent: AppColor.lavenderDeep,
                secondaryAccent: AppColor.medicalBlue,
                particleOpacity: 0.20,
                glowIntensity: 0.18,
                lightingOpacity: 0.20
            )
        }
    }
}
