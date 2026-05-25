import SwiftUI

struct ProgressRingView: View {
    @Environment(\.colorScheme) private var colorScheme

    let percent: Double
    var size: CGFloat = 56
    var lineWidth: CGFloat = 5
    var isUrgent: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(WidgetBrandColor.hairline.opacity(colorScheme == .dark ? 0.28 : 0.52), lineWidth: lineWidth)
                .shadow(color: WidgetBrandColor.medicalBlue.opacity(0.12), radius: 7, x: 0, y: 4)

            Circle()
                .trim(from: 0, to: min(max(percent / 100, 0), 1))
                .stroke(
                    isUrgent ? AnyShapeStyle(WidgetBrandColor.softRed) : AnyShapeStyle(WidgetBrandColor.primaryButton),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: (isUrgent ? WidgetBrandColor.softRed : WidgetBrandColor.mintGreenDeep).opacity(0.24), radius: 6, x: 0, y: 3)

            Text("\(Int(percent))%")
                .font(.system(size: max(size * 0.24, 12), weight: .bold))
                .foregroundStyle(WidgetBrandColor.text(colorScheme))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Today adherence \(Int(percent)) percent")
    }
}
