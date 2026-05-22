import SwiftUI

struct HealingGlowCard<Content: View>: View {
    let color: Color
    let content: Content

    init(color: Color = AppColor.medicalBlue, @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.58))
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                    .stroke(color.opacity(0.14), lineWidth: 1)
            )
            .appShadow(AppShadow.soft)
    }
}

struct HealthStoryCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color

    var body: some View {
        HealingGlowCard(color: color) {
            HStack(spacing: Spacing.medium) {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: 58, height: 58)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(title)
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)
                    Text(subtitle)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }
}

struct StreakBadgeView: View {
    let title: String
    let value: Int
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 46, height: 46)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            Text("\(value)")
                .font(AppFont.title)
                .foregroundStyle(AppColor.ink)
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppGradient.card)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
        .appShadow(AppShadow.soft)
    }
}

struct DailyJourneyTimeline: View {
    let items: [JourneyFeedItem]

    var body: some View {
        HealingGlowCard(color: AppColor.lavenderDeep) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Today’s journey")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                if items.isEmpty {
                    EmptyStateView(
                        title: "Your journey starts softly",
                        message: "Log one medicine, health reading, or mood check-in to begin today’s story.",
                        systemImage: "sparkles"
                    )
                } else {
                    ForEach(items.prefix(12)) { item in
                        HStack(alignment: .top, spacing: Spacing.medium) {
                            VStack(spacing: 0) {
                                Image(systemName: item.symbol)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 34, height: 34)
                                    .background(item.color)
                                    .clipShape(Circle())
                                Rectangle()
                                    .fill(item.color.opacity(0.16))
                                    .frame(width: 2, height: 38)
                            }

                            VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                                Text(item.title)
                                    .font(AppFont.bodyStrong)
                                    .foregroundStyle(AppColor.ink)
                                Text(item.subtitle)
                                    .font(AppFont.caption)
                                    .foregroundStyle(AppColor.secondaryInk)
                                    .lineLimit(2)
                                Text(item.date.shortTimeText)
                                    .font(AppFont.badge)
                                    .foregroundStyle(AppColor.tertiaryInk)
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
