import SwiftData
import SwiftUI

struct WomensHealthBackground<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            WomensHealthTheme.gradient
                .ignoresSafeArea()

            Circle()
                .fill(WomensHealthTheme.blush.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 30)
                .offset(x: -120, y: -280)

            Circle()
                .fill(WomensHealthTheme.mint.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 36)
                .offset(x: 130, y: 280)

            content
        }
    }
}

struct WomensHealthSection<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                Text(title)
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                }
            }

            PillCardContainer {
                content
            }
        }
    }
}

struct WomensHealthChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.badge)
                .foregroundStyle(isSelected ? .white : AppColor.medicalBlueDeep)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, Spacing.xSmall)
                .background(isSelected ? WomensHealthTheme.blush : AppColor.cream.opacity(0.88))
                .clipShape(Capsule(style: .continuous))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isSelected ? WomensHealthTheme.blush.opacity(0.4) : AppColor.hairline.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct WomensHealthFlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = Spacing.xSmall) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(maxWidth: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.reduce(CGFloat.zero) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * spacing
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(maxWidth: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for element in row.elements {
                element.subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(element.size))
                x += element.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func rows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if current.width + size.width > maxWidth, !current.elements.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.elements.append(Row.Element(subview: subview, size: size))
            current.width += size.width + (current.elements.count > 1 ? spacing : 0)
            current.height = max(current.height, size.height)
        }

        if !current.elements.isEmpty { rows.append(current) }
        return rows
    }

    private struct Row {
        struct Element {
            let subview: LayoutSubview
            let size: CGSize
        }

        var elements: [Element] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }
}

struct WomensHealthMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        PillCardContainer(style: .lavender) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(WomensHealthTheme.blush)
                    .frame(width: 46, height: 46)
                    .background(WomensHealthTheme.blushSoft.opacity(0.9))
                    .clipShape(Circle())

                Text(title)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)

                Text(value)
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)

                Text(subtitle)
                    .font(AppFont.badge)
                    .foregroundStyle(AppColor.secondaryInk)
            }
        }
    }
}

struct ReminderToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label {
                VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                    Text(title)
                        .font(AppFont.bodyStrong)
                        .foregroundStyle(AppColor.ink)

                    Text(subtitle)
                        .font(AppFont.badge)
                        .foregroundStyle(AppColor.secondaryInk)
                }
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(WomensHealthTheme.blush)
            }
        }
        .tint(WomensHealthTheme.blush)
        .padding(Spacing.medium)
        .background(AppColor.cream.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
    }
}

struct ReminderSettingsCard: View {
    @Bindable var settings: CyclePredictionSettings

    var body: some View {
        WomensHealthSection(title: "Reminders", subtitle: "Reminder preferences are stored locally. Notification scheduling can plug in later.") {
            VStack(spacing: Spacing.small) {
                ReminderToggleRow(
                    title: "Period expected",
                    subtitle: "A gentle reminder before your estimated date",
                    systemImage: "calendar.badge.clock",
                    isOn: $settings.periodExpectedReminderEnabled
                )
                ReminderToggleRow(
                    title: "Ovulation",
                    subtitle: "Estimated from previous cycle logs",
                    systemImage: "sparkles",
                    isOn: $settings.ovulationReminderEnabled
                )
                ReminderToggleRow(
                    title: "PMS",
                    subtitle: "Prepare with care routines",
                    systemImage: "heart.text.square",
                    isOn: $settings.pmsReminderEnabled
                )
                ReminderToggleRow(
                    title: "Medicine during period",
                    subtitle: "Helpful if you use period-specific medication",
                    systemImage: "pills.fill",
                    isOn: $settings.periodMedicineReminderEnabled
                )
                ReminderToggleRow(
                    title: "Doctor visit",
                    subtitle: "Keep appointments visible and calm",
                    systemImage: "stethoscope",
                    isOn: $settings.doctorVisitReminderEnabled
                )
            }
        }
    }
}
