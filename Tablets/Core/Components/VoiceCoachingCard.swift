import SwiftUI

struct VoiceCoachingCard: View {
    let message: String
    let command: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(AppGradient.primaryButton, in: Circle())
                .appShadow(AppShadow.button)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(message)
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Say '\(command)'")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.medicalBlueDeep)
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, 8)
                    .background(AppColor.medicalBlue.opacity(0.10), in: Capsule())
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.medium)
        .background(
            LinearGradient(
                colors: [AppColor.lavender.opacity(0.42), AppColor.mintGreen.opacity(0.18), AppColor.cream.opacity(0.94)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                .stroke(AppColor.medicalBlue.opacity(0.12), lineWidth: 1)
        )
        .appShadow(AppShadow.soft)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message) Say \(command)")
    }
}
