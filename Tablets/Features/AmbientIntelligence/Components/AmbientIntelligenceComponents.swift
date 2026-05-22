import SwiftUI

struct AmbientInsightCard: View {
    let state: AmbientIntelligenceState
    let reminderRecommendation: String

    var body: some View {
        PillCardContainer(style: .highlighted, padding: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(spacing: Spacing.small) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppColor.medicalBlue)
                        .frame(width: 44, height: 44)
                        .background(AppColor.medicalBlue.opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                        Text("Ambient Intelligence")
                            .font(AppFont.sectionTitle)
                            .foregroundStyle(AppColor.ink)
                        Text(state.assistantTone.capitalized)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    }
                }

                Text(state.observations.first ?? "The app is learning gentle local patterns from your saved activity.")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryInk)
                    .lineLimit(3)

                Text(reminderRecommendation)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.medicalBlueDeep)
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.xSmall)
                    .background(AppColor.medicalBlue.opacity(0.10))
                    .clipShape(Capsule())
            }
        }
    }
}

struct AmbientPriorityStrip: View {
    let priorities: [AmbientDashboardPriority]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                ForEach(priorities) { priority in
                    HStack(spacing: Spacing.xSmall) {
                        Image(systemName: priority.symbol)
                            .font(.system(size: 14, weight: .bold))
                        Text(priority.title)
                            .font(AppFont.badge)
                            .lineLimit(1)
                    }
                    .foregroundStyle(priority.color)
                    .padding(.horizontal, Spacing.small)
                    .frame(height: 40)
                    .background(priority.color.opacity(0.11))
                    .clipShape(Capsule())
                }
            }
        }
    }
}

