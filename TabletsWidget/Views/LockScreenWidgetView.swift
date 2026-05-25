import SwiftUI
import WidgetKit

struct LockScreenWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: MedicineWidgetEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 2) {
                ProgressRingView(percent: entry.adherencePercent, size: 42, lineWidth: 4, isUrgent: entry.isOverdue)
                Text(entry.pendingCount > 0 ? "\(entry.pendingCount) due" : "Done")
                    .font(WidgetBrandFont.badge)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .accessibilityLabel("Medicines \(Int(entry.adherencePercent)) percent done")
        default:
            HStack(spacing: 8) {
                Image(systemName: "pills.fill")
                    .foregroundStyle(WidgetBrandColor.medicalBlue)
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.nextMedicineName ?? (entry.hasAnyMedicines ? "All set" : "Add medicine"))
                        .font(WidgetBrandFont.sectionTitle)
                        .foregroundStyle(WidgetBrandColor.text(colorScheme))
                        .lineLimit(1)
                    Text(entry.timeRemaining ?? "\(entry.takenCount) taken • \(entry.pendingCount) pending")
                        .font(WidgetBrandFont.badge)
                        .foregroundStyle(entry.isOverdue ? WidgetBrandColor.softRed : WidgetBrandColor.secondaryText(colorScheme))
                        .lineLimit(1)
                }
            }
            .padding(8)
            .widgetBrandCard(colorScheme, cornerRadius: 18)
            .accessibilityLabel("Next medicine \(entry.nextMedicineName ?? "none")")
        }
    }
}
