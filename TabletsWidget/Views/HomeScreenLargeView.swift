import SwiftUI

struct HomeScreenLargeView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: MedicineWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("TODAY'S MEDICINES", systemImage: "pills.fill")
                .font(WidgetBrandFont.sectionTitle)
                .foregroundStyle(WidgetBrandColor.medicalBlue)

            HStack(spacing: 16) {
                ProgressRingView(percent: entry.adherencePercent, size: 74, lineWidth: 7, isUrgent: entry.isOverdue)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Adherence today")
                        .font(WidgetBrandFont.badge)
                        .foregroundStyle(WidgetBrandColor.secondaryText(colorScheme))
                    Text("✓ \(entry.takenCount) taken")
                    Text("⏳ \(entry.pendingCount) pending")
                    if entry.skippedCount > 0 {
                        Text("× \(entry.skippedCount) skipped")
                    }
                }
                .font(WidgetBrandFont.bodyStrong)
                .foregroundStyle(WidgetBrandColor.text(colorScheme))
            }

            nextDueCard

            VStack(alignment: .leading, spacing: 6) {
                Text("Upcoming")
                    .font(WidgetBrandFont.badge)
                    .foregroundStyle(WidgetBrandColor.secondaryText(colorScheme))
                if entry.upcomingMedicines.isEmpty {
                    Text(entry.hasMedicinesDueToday ? "All medicines taken for now" : "No medicines scheduled today")
                        .font(WidgetBrandFont.body)
                        .foregroundStyle(WidgetBrandColor.secondaryText(colorScheme))
                } else {
                    ForEach(entry.upcomingMedicines.prefix(3), id: \.self) { medicine in
                        Text("• \(medicine.time) - \(medicine.name)")
                            .font(WidgetBrandFont.body)
                            .foregroundStyle(WidgetBrandColor.text(colorScheme))
                            .lineLimit(1)
                    }
                }
            }

            if let insight = entry.adaptiveInsight {
                Text("Habit: \(insight)")
                    .font(WidgetBrandFont.body)
                    .foregroundStyle(WidgetBrandColor.secondaryText(colorScheme))
                    .lineLimit(2)
                    .padding(10)
                    .widgetBrandInset(colorScheme, cornerRadius: 16)
            }

            Spacer()
        }
        .padding(16)
        .widgetBrandCard(colorScheme, cornerRadius: 26)
    }

    private var nextDueCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Next due")
                .font(WidgetBrandFont.badge)
                .foregroundStyle(WidgetBrandColor.secondaryText(colorScheme))
            Text(entry.nextMedicineName ?? (entry.hasAnyMedicines ? "All set for now" : "Add your first medicine"))
                .font(WidgetBrandFont.title)
                .foregroundStyle(WidgetBrandColor.text(colorScheme))
                .lineLimit(1)
            if let dosage = entry.nextMedicineDosage {
                Text("\(dosage) • \(entry.nextMedicineInstruction ?? "")")
                    .font(WidgetBrandFont.body)
                    .foregroundStyle(WidgetBrandColor.secondaryText(colorScheme))
                    .lineLimit(1)
            }
            if let time = entry.timeRemaining {
                Text(time)
                    .font(WidgetBrandFont.bodyStrong)
                    .foregroundStyle(entry.isOverdue ? WidgetBrandColor.softRed : WidgetBrandColor.mintGreenDeep)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetBrandInset(colorScheme, cornerRadius: 18)
    }
}
