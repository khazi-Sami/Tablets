import SwiftUI

struct PillCardContainer<Content: View>: View {
    enum Style {
        case standard
        case highlighted
        case lavender
        case alert
    }

    private let style: Style
    private let padding: CGFloat
    private let content: Content

    init(
        style: Style = .standard,
        padding: CGFloat = Spacing.medium,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .appShadow(AppShadow.pill)
            .animation(.spring(response: 0.36, dampingFraction: 0.86), value: styleKey)
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .standard:
            AppGradient.card
        case .highlighted:
            AppGradient.calmStatus.opacity(0.92)
        case .lavender:
            AppGradient.lavenderWash
        case .alert:
            AppGradient.alertStatus
        }
    }

    private var borderColor: Color {
        switch style {
        case .standard:
            return AppColor.hairline.opacity(0.55)
        case .highlighted:
            return AppColor.mintGreenDeep.opacity(0.22)
        case .lavender:
            return AppColor.lavenderDeep.opacity(0.18)
        case .alert:
            return AppColor.softRed.opacity(0.18)
        }
    }

    private var styleKey: String {
        switch style {
        case .standard:
            return "standard"
        case .highlighted:
            return "highlighted"
        case .lavender:
            return "lavender"
        case .alert:
            return "alert"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PillCardContainer {
            Text("Pill card")
        }

        PillCardContainer(style: .highlighted) {
            Text("Highlighted")
        }
    }
    .padding()
    .background(AppGradient.background)
}
