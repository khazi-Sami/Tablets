import SwiftUI

struct AlertsWidgetView: View {
    let alerts: [HealthSafetyAlert]
    let showHistory: () -> Void

    var body: some View {
        if alerts.isEmpty {
            HealthGlassCard {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AppColor.mintGreenDeep)
                        .frame(width: 44, height: 44)
                        .background(AppColor.mintGreen.opacity(0.16))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        Text("Safety watch is on")
                            .font(AppFont.sectionTitle)
                            .foregroundStyle(AppColor.ink)
                        Text("BanyAI will flag readings that may need doctor guidance.")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    }

                    Spacer()
                }
            }
        } else {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack {
                    Text("Readings needing attention")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)
                    Spacer()
                    Button("History", action: showHistory)
                        .font(AppFont.badge)
                        .foregroundStyle(AppColor.medicalBlue)
                }

                ForEach(alerts.prefix(2)) { alert in
                    HealthAlertView(alert: alert, compact: true)
                }
            }
        }
    }
}
