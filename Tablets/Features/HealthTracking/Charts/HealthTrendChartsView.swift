import Charts
import SwiftUI

enum HealthChartRange: String, CaseIterable, Identifiable {
    case seven = "7 days"
    case thirty = "30 days"
    case ninety = "90 days"
    var id: String { rawValue }
    var days: Int { self == .seven ? 7 : self == .thirty ? 30 : 90 }
}

struct HealthTrendChartsView: View {
    let records: [HealthRecord]
    @State private var range: HealthChartRange = .seven

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView {
                    VStack(spacing: Spacing.medium) {
                        Picker("Range", selection: $range) {
                            ForEach(HealthChartRange.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        ForEach(HealthRecordType.allCases) { type in
                            PremiumHealthChartCard(type: type, records: filtered(type))
                        }
                    }
                    .padding(Spacing.medium)
                }
            }
            .navigationTitle("Health Trends")
        }
    }

    private func filtered(_ type: HealthRecordType) -> [HealthRecord] {
        let start = Calendar.current.date(byAdding: .day, value: -range.days, to: .now) ?? .now
        return records.filter { $0.type == type && $0.measuredAt >= start }.sorted { $0.measuredAt < $1.measuredAt }
    }
}

struct PremiumHealthChartCard: View {
    let type: HealthRecordType
    let records: [HealthRecord]
    @State private var animate = false

    var body: some View {
        HealthGlassCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack {
                    Label(type.title, systemImage: type.icon)
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)
                    Spacer()
                    if let last = records.last {
                        Text(last.displayValue)
                            .font(AppFont.badge)
                            .foregroundStyle(AppColor.medicalBlueDeep)
                            .padding(.horizontal, Spacing.small)
                            .padding(.vertical, Spacing.xSmall)
                            .background(AppColor.medicalBlue.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                if records.isEmpty {
                    EmptyStateView(title: "No chart data", message: "Add records to see a trend.", systemImage: type.icon)
                } else {
                    Chart(records) { record in
                        LineMark(
                            x: .value("Date", record.measuredAt),
                            y: .value("Value", animate ? record.value1 : records.first?.value1 ?? record.value1)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AppGradient.primaryButton)

                        PointMark(x: .value("Date", record.measuredAt), y: .value("Value", record.value1))
                            .foregroundStyle(AppColor.medicalBlue)
                    }
                    .frame(height: 190)
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.85)) { animate = true }
                    }
                }
            }
        }
    }
}
