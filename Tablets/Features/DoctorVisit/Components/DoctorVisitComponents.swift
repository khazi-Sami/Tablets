import SwiftUI

struct DoctorReportMetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        PillCardContainer(padding: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: 46, height: 46)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                Text(value)
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(title)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }
        }
    }
}

struct DoctorChecklistRow: View {
    @Bindable var item: DoctorVisitChecklistItem

    var body: some View {
        PillCardContainer(padding: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Toggle(isOn: $item.isCompleted) {
                    Text(item.title)
                        .font(AppFont.bodyStrong)
                        .foregroundStyle(AppColor.ink)
                }
                .tint(AppColor.mintGreenDeep)

                TextField("Add note", text: $item.answer, axis: .vertical)
                    .font(AppFont.body)
                    .padding(Spacing.small)
                    .background(AppColor.cream.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
            }
        }
    }
}

struct ReportGeneratingOverlay: View {
    @State private var spin = false

    var body: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(AppColor.medicalBlue)
                .rotationEffect(.degrees(spin ? 4 : -4))
                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: spin)
            Text("Preparing report")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.ink)
        }
        .padding(Spacing.xLarge)
        .background(AppColor.cream.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
        .appShadow(AppShadow.button)
        .onAppear { spin = true }
    }
}
