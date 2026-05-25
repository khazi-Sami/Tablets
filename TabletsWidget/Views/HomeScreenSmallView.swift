import SwiftUI

struct HomeScreenSmallView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: MedicineWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Spacer(minLength: 2)

            if let error = entry.errorMessage {
                emptyText(error)
            } else if !entry.hasAnyMedicines {
                emptyText("Add your first medicine\nto see it here.")
            } else if !entry.hasMedicinesDueToday {
                emptyText("Rest well!\nNo medicines scheduled.")
            } else {
                Text(entry.nextMedicineName ?? "All done")
                    .font(WidgetBrandFont.sectionTitle)
                    .foregroundStyle(WidgetBrandColor.text(colorScheme))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(entry.timeRemaining ?? "All medicines taken")
                    .font(WidgetBrandFont.bodyStrong)
                    .foregroundStyle(entry.isOverdue ? WidgetBrandColor.softRed : WidgetBrandColor.secondaryText(colorScheme))
                    .lineLimit(1)

                Spacer(minLength: 2)

                HStack {
                    ProgressRingView(percent: entry.adherencePercent, size: 44, lineWidth: 4, isUrgent: entry.isOverdue)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("✓ \(entry.takenCount)")
                        Text("⏳ \(entry.pendingCount)")
                    }
                    .font(WidgetBrandFont.badge)
                    .foregroundStyle(WidgetBrandColor.secondaryText(colorScheme))
                }
            }
        }
        .padding(12)
        .widgetBrandCard(colorScheme, cornerRadius: 22)
        .accessibilityLabel(accessibilityText)
    }

    private var header: some View {
        Label("MEDICINES", systemImage: "pills.fill")
            .font(WidgetBrandFont.badge)
            .foregroundStyle(WidgetBrandColor.medicalBlue)
            .lineLimit(1)
    }

    private func emptyText(_ text: String) -> some View {
        Text(text)
            .font(WidgetBrandFont.bodyStrong)
            .foregroundStyle(WidgetBrandColor.secondaryText(colorScheme))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var accessibilityText: String {
        if let name = entry.nextMedicineName {
            return "Next medicine \(name), \(entry.timeRemaining ?? "")"
        }
        return "Medicines widget"
    }
}
