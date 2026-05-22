import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        message: String,
        systemImage: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        PillCardContainer(style: .lavender, padding: Spacing.large) {
            VStack(spacing: Spacing.medium) {
                Image(systemName: systemImage)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(AppColor.medicalBlue)
                    .frame(width: 78, height: 78)
                    .background(AppColor.cream.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))

                VStack(spacing: Spacing.xSmall) {
                    Text(title)
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)

                    Text(message)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let actionTitle, let action {
                    CapsuleButton(actionTitle, systemImage: "plus", style: .secondary, action: action)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    EmptyStateView(
        title: "No medicines yet",
        message: "Add your first medicine to start tracking reminders.",
        systemImage: "pills",
        actionTitle: "Add Medicine"
    ) {}
}
