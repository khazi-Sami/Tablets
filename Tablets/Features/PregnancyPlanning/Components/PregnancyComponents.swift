import SwiftUI

struct PregnancyCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(PregnancyTheme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PregnancyTheme.cardGradient)
            .clipShape(RoundedRectangle(cornerRadius: PregnancyTheme.cardRadius, style: .continuous))
            .shadow(color: PregnancyTheme.deepRose.opacity(0.12), radius: 16, x: 0, y: 8)
    }
}

struct PregnancyActionTile: View {
    let title: String
    let subtitle: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(PregnancyTheme.deepRose)
                    .frame(width: 46, height: 46)
                    .background(.white.opacity(0.62), in: Circle())

                Text(title)
                    .font(PregnancyTheme.bodyFont.weight(.semibold))
                    .foregroundStyle(AppColor.ink)

                Text(subtitle)
                    .font(PregnancyTheme.captionFont)
                    .foregroundStyle(AppColor.secondaryInk)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
            .padding(14)
            .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: PregnancyTheme.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct PregnancyChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PregnancyTheme.captionFont)
                .foregroundStyle(isSelected ? .white : PregnancyTheme.deepRose)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(isSelected ? PregnancyTheme.deepRose : .white.opacity(0.70), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct PregnancyFlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(proposal: proposal, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: rows.reduce(0) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(proposal: ProposedViewSize(width: bounds.width, height: proposal.height), subviews: subviews) {
            var x = bounds.minX
            for item in row.items {
                item.subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func rows(proposal: ProposedViewSize, subviews: Subviews) -> [(items: [(subview: LayoutSubviews.Element, size: CGSize)], height: CGFloat)] {
        let maxWidth = proposal.width ?? 320
        var rows: [(items: [(LayoutSubviews.Element, CGSize)], height: CGFloat)] = []
        var current: [(LayoutSubviews.Element, CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if width + size.width > maxWidth, !current.isEmpty {
                rows.append((current, height))
                current = []
                width = 0
                height = 0
            }
            current.append((subview, size))
            width += size.width + spacing
            height = max(height, size.height)
        }
        if !current.isEmpty { rows.append((current, height)) }
        return rows
    }
}

