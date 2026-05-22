import Charts
import SwiftUI

struct HealthSnapshotCard: View {
    let title: String
    let systemImage: String
    let accent: Color
    let latestRecord: HealthRecord?
    let sparklineRecords: [HealthRecord]
    let valueText: (HealthRecord) -> String
    let isElderlyMode: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(latestRecord == nil ? AppColor.secondaryInk : accent)
                        .frame(width: isElderlyMode ? 52 : 44, height: isElderlyMode ? 52 : 44)
                        .background((latestRecord == nil ? AppColor.secondaryInk : accent).opacity(0.14))
                        .clipShape(Circle())

                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColor.ink)
                        .lineLimit(2)

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let latestRecord {
                        Text(valueText(latestRecord))
                            .font((isElderlyMode ? Font.title2 : Font.title3).weight(.bold))
                            .foregroundStyle(AppColor.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .elderlyScaled(isElderlyMode)

                        Text(relativeText(for: latestRecord.measuredAt))
                            .font(.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    } else {
                        Text("No reading yet")
                            .font((isElderlyMode ? Font.title2 : Font.title3).weight(.bold))
                            .foregroundStyle(AppColor.secondaryInk)
                            .elderlyScaled(isElderlyMode)
                        Text("Tap to record")
                            .font(.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    }
                }

                if sparklineRecords.count >= 2 {
                    Chart(sparklineRecords.suffix(5)) { record in
                        LineMark(
                            x: .value("Date", record.measuredAt),
                            y: .value("Value", record.value1)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(accent)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 38)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accent.opacity(0.10))
                        .frame(height: 38)
                }
            }
            .padding(isElderlyMode ? 20 : 16)
            .frame(maxWidth: .infinity, minHeight: 176, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(latestRecord.map(valueText) ?? "No reading yet")")
    }

    private func relativeText(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}
