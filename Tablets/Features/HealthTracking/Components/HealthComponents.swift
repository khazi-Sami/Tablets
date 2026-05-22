import SwiftUI

struct HealthGlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
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
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            )
            .appShadow(AppShadow.soft)
    }
}

struct HealthMetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let animation: AnyView

    var body: some View {
        HealthGlassCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack {
                    animation
                        .frame(width: 46, height: 46)
                    Spacer()
                }
                Text(title)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
                Text(value)
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)
                Text(subtitle)
                    .font(AppFont.badge)
                    .foregroundStyle(color)
            }
        }
    }
}

struct HealthStatusPill: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(AppFont.badge)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct HealthSuccessOverlay: View {
    let title: String

    var body: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(AppColor.mintGreenDeep)
            Text(title)
                .font(AppFont.title)
                .foregroundStyle(AppColor.ink)
        }
        .padding(Spacing.xLarge)
        .background(AppColor.cream.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
        .appShadow(AppShadow.button)
    }
}
