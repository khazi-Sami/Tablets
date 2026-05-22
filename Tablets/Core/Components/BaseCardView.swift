import SwiftUI

struct BaseCardView<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    init(padding: CGFloat = Spacing.medium, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        PillCardContainer(padding: padding) {
            content
        }
    }
}

#Preview {
    BaseCardView {
        Text("Card content")
    }
    .padding()
    .background(AppGradient.background)
}
