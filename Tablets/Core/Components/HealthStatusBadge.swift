import SwiftUI

struct HealthStatusBadge: View {
    enum Status {
        case good
        case upcoming
        case attention
        case missed

        var title: String {
            switch self {
            case .good:
                return "On Track"
            case .upcoming:
                return "Upcoming"
            case .attention:
                return "Check"
            case .missed:
                return "Alert"
            }
        }

        var systemImage: String {
            switch self {
            case .good:
                return "checkmark.circle.fill"
            case .upcoming:
                return "clock.fill"
            case .attention:
                return "stethoscope"
            case .missed:
                return "exclamationmark.triangle.fill"
            }
        }

        var foreground: Color {
            switch self {
            case .good:
                return AppColor.mintGreenDeep
            case .upcoming:
                return AppColor.medicalBlueDeep
            case .attention:
                return AppColor.lavenderDeep
            case .missed:
                return AppColor.softRed
            }
        }

        var background: Color {
            switch self {
            case .good:
                return AppColor.mintGreen.opacity(0.22)
            case .upcoming:
                return AppColor.medicalBlue.opacity(0.12)
            case .attention:
                return AppColor.lavender.opacity(0.55)
            case .missed:
                return AppColor.softRedBackground
            }
        }
    }

    let status: Status

    var body: some View {
        Label(status.title, systemImage: status.systemImage)
            .font(AppFont.badge)
            .foregroundStyle(status.foreground)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(status.background)
            .clipShape(Capsule(style: .continuous))
            .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        HealthStatusBadge(status: .good)
        HealthStatusBadge(status: .missed)
    }
    .padding()
}
