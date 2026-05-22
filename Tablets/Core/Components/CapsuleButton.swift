import SwiftUI

struct CapsuleButton: View {
    enum Style {
        case primary
        case secondary
        case alert
    }

    let title: String
    let systemImage: String?
    let style: Style
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        style: Style = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xSmall) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }

                Text(title)
                    .font(AppFont.button)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .padding(.horizontal, Spacing.medium)
            .background(background)
            .clipShape(Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .appShadow(style == .primary ? AppShadow.button : AppShadow.soft)
            .scaleEffect(isLoading ? 0.99 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .animation(.spring(response: 0.30, dampingFraction: 0.82), value: isLoading)
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            AppGradient.primaryButton
        case .secondary:
            AppColor.cream.opacity(0.88)
        case .alert:
            AppColor.softRed
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .alert:
            return .white
        case .secondary:
            return AppColor.medicalBlueDeep
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return Color.white.opacity(0.24)
        case .secondary:
            return AppColor.hairline.opacity(0.72)
        case .alert:
            return AppColor.softRed.opacity(0.2)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CapsuleButton("Add Medicine", systemImage: "plus") {}
        CapsuleButton("Secondary", systemImage: "heart", style: .secondary) {}
    }
    .padding()
    .background(AppGradient.background)
}
