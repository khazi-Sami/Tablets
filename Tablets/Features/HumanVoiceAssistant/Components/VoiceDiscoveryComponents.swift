import SwiftUI

struct VoiceSuggestionChipsView: View {
    let suggestions: [String]
    let action: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: Spacing.xSmall)], alignment: .trailing, spacing: Spacing.xSmall) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    action(suggestion)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(suggestion)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .font(AppFont.badge)
                    .foregroundStyle(AppColor.medicalBlueDeep)
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, 9)
                    .frame(minHeight: 40)
                    .background(AppColor.cream.opacity(0.96), in: Capsule())
                    .overlay(
                        Capsule().stroke(AppColor.medicalBlue.opacity(0.18), lineWidth: 1)
                    )
                    .appShadow(AppShadow.soft)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Voice suggestion: \(suggestion)")
            }
        }
        .frame(maxWidth: 340, alignment: .trailing)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct VoiceTipBannerView: View {
    let tip: VoiceTip
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColor.lavenderDeep)
                .frame(width: 30, height: 30)
                .background(AppColor.lavender.opacity(0.75), in: Circle())

            Text(tip.text)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColor.secondaryInk)
                    .frame(width: 28, height: 28)
                    .background(AppColor.warmWhite.opacity(0.8), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss voice tip")
        }
        .padding(Spacing.small)
        .frame(maxWidth: 330, alignment: .leading)
        .background(AppColor.cream.opacity(0.98), in: RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                .stroke(AppColor.lavenderDeep.opacity(0.18), lineWidth: 1)
        )
        .appShadow(AppShadow.soft)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
