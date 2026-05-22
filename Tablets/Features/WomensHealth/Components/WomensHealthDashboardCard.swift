import SwiftUI

struct WomensHealthDashboardCard: View {
    let cycleDay: Int
    let daysUntilNextPeriod: Int
    let nextPeriodDate: Date
    let lastSymptoms: [String]
    let logTodayAction: () -> Void

    var body: some View {
        PillCardContainer(style: .lavender, padding: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(spacing: Spacing.medium) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(WomensHealthTheme.blush)

                    VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                        Text("Women's Health")
                            .font(AppFont.title)
                            .foregroundStyle(AppColor.ink)

                        Text("Private, local cycle insights")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    }

                    Spacer()
                }

                HStack(spacing: Spacing.small) {
                    metric(title: "Cycle day", value: "\(cycleDay)")
                    metric(title: "Next period", value: "\(daysUntilNextPeriod)d")
                }

                Text("Estimated next period: \(nextPeriodDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)

                Text("Last symptoms: \(lastSymptoms.isEmpty ? "No symptoms logged" : lastSymptoms.joined(separator: ", "))")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
                    .lineLimit(2)

                CapsuleButton("Log Today", systemImage: "plus.circle.fill", style: .secondary, action: logTodayAction)
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
            Text(title)
                .font(AppFont.badge)
                .foregroundStyle(AppColor.secondaryInk)

            Text(value)
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.small)
        .background(AppColor.cream.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
    }
}
