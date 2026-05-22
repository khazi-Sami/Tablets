import Foundation
import SwiftUI

struct HealthCompanionMessage: Identifiable, Equatable {
    enum Tone {
        case greeting
        case encouragement
        case reminder
        case streak
        case checkIn

        var icon: String {
            switch self {
            case .greeting: return "sparkles"
            case .encouragement: return "heart.fill"
            case .reminder: return "bell.fill"
            case .streak: return "flame.fill"
            case .checkIn: return "checklist.checked"
            }
        }

        var color: Color {
            switch self {
            case .greeting: return AppColor.medicalBlue
            case .encouragement: return AppColor.mintGreenDeep
            case .reminder: return AppColor.lavenderDeep
            case .streak: return AppColor.softRed
            case .checkIn: return AppColor.medicalBlueDeep
            }
        }
    }

    let id = UUID()
    let text: String
    let tone: Tone
}
