import SwiftUI

struct HealthAlertView: View {
    @Environment(\.openURL) private var openURL

    let alert: HealthSafetyAlert
    var compact = false
    var onDismiss: (() -> Void)?

    var body: some View {
        HealthGlassCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack(alignment: .top, spacing: Spacing.small) {
                    Image(systemName: iconName)
                        .font(.system(size: compact ? 20 : 26, weight: .bold))
                        .foregroundStyle(alert.severity.color)
                        .frame(width: compact ? 34 : 44, height: compact ? 34 : 44)
                        .background(alert.severity.color.opacity(0.14))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        Text(alert.severity.title)
                            .font(compact ? AppFont.badge : AppFont.sectionTitle)
                            .foregroundStyle(alert.severity.color)
                        Text(alert.title)
                            .font(compact ? AppFont.bodyStrong : AppFont.title)
                            .foregroundStyle(AppColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(alert.metricTitle): \(alert.valueText)")
                            .font(AppFont.badge)
                            .foregroundStyle(AppColor.secondaryInk)
                    }

                    Spacer()

                    if let onDismiss {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(AppFont.badge)
                                .foregroundStyle(AppColor.tertiaryInk)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Dismiss alert")
                    }
                }

                Text(alert.message)
                    .font(compact ? AppFont.caption : AppFont.body)
                    .foregroundStyle(AppColor.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)

                if !compact {
                    HStack(spacing: Spacing.small) {
                        Button {
                            openURL(URL(string: "tel://") ?? URL(fileURLWithPath: "/"))
                        } label: {
                            Label("Call doctor", systemImage: "phone.fill")
                                .font(AppFont.badge)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(AppColor.medicalBlue)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            openURL(URL(string: "tel://911") ?? URL(fileURLWithPath: "/"))
                        } label: {
                            Label("Emergency", systemImage: "cross.case.fill")
                                .font(AppFont.badge)
                                .foregroundStyle(alert.severity.color)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(alert.severity.color.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(alert.severity.title). \(alert.title). \(alert.message)")
    }

    private var iconName: String {
        switch alert.severity {
        case .info: return "checkmark.shield.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .urgent: return "heart.text.square.fill"
        case .emergency: return "cross.case.fill"
        }
    }
}
