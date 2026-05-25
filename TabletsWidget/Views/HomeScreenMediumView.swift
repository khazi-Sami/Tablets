import SwiftUI

struct HomeScreenMediumView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: MedicineWidgetEntry

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Label("TODAY'S MEDICINES", systemImage: "pills.fill")
                    .font(WidgetBrandFont.badge)
                    .foregroundStyle(WidgetBrandColor.medicalBlue)

                ProgressView(value: entry.adherencePercent, total: 100)
                    .tint(WidgetBrandColor.mintGreenDeep)

                Text("\(Int(entry.adherencePercent))% done")
                    .font(WidgetBrandFont.bodyStrong)
                    .foregroundStyle(WidgetBrandColor.secondaryText(colorScheme))

                Spacer(minLength: 0)

                nextMedicineBlock
            }

            Divider()

            VStack(alignment: .leading, spacing: 5) {
                Text("Upcoming")
                    .font(WidgetBrandFont.badge)
                    .foregroundStyle(WidgetBrandColor.secondaryText(colorScheme))

                if entry.upcomingMedicines.isEmpty {
                    Text(entry.hasMedicinesDueToday ? "All logged for now" : "No medicines today")
                        .font(WidgetBrandFont.body)
                        .foregroundStyle(WidgetBrandColor.secondaryText(colorScheme))
                } else {
                    ForEach(entry.upcomingMedicines.prefix(2), id: \.self) { medicine in
                        Text("• \(medicine.time) - \(medicine.name)")
                            .font(WidgetBrandFont.body)
                            .foregroundStyle(WidgetBrandColor.text(colorScheme))
                            .lineLimit(1)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .widgetBrandCard(colorScheme, cornerRadius: 24)
    }

    private var nextMedicineBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Next")
                .font(WidgetBrandFont.badge)
                .foregroundStyle(WidgetBrandColor.secondaryText(colorScheme))
            Text(entry.nextMedicineName ?? (entry.hasAnyMedicines ? "All medicines taken" : "Add medicine"))
                .font(WidgetBrandFont.sectionTitle)
                .foregroundStyle(WidgetBrandColor.text(colorScheme))
                .lineLimit(1)
            if let dosage = entry.nextMedicineDosage {
                Text(dosage)
                    .font(WidgetBrandFont.body)
                    .foregroundStyle(WidgetBrandColor.secondaryText(colorScheme))
                    .lineLimit(1)
            }
            Text(entry.timeRemaining ?? "")
                .font(WidgetBrandFont.bodyStrong)
                .foregroundStyle(entry.isOverdue ? WidgetBrandColor.softRed : WidgetBrandColor.secondaryText(colorScheme))
                .lineLimit(1)
        }
        .padding(10)
        .widgetBrandInset(colorScheme, cornerRadius: 18)
    }
}
