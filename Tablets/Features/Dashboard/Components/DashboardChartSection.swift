import Charts
import SwiftUI

enum DashboardChartKind: String, CaseIterable, Identifiable {
    case bp = "BP"
    case sugar = "Sugar"
    case medicine = "Medicine"
    case weight = "Weight"
    var id: String { rawValue }
}

struct DashboardChartSection: View {
    @Binding var selection: DashboardChartKind
    let dataProvider: DashboardDataProvider

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Chart", selection: $selection) {
                ForEach(DashboardChartKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            chartBody
                .frame(height: 200)
                .padding(16)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
    }

    @ViewBuilder
    private var chartBody: some View {
        switch selection {
        case .bp:
            if dataProvider.bpLast7Days.count >= 2 {
                Chart(dataProvider.bpLast7Days) { record in
                    LineMark(x: .value("Day", record.measuredAt), y: .value("Systolic", record.value1))
                        .foregroundStyle(AppColor.softRed)
                    if let value2 = record.value2 {
                        LineMark(x: .value("Day", record.measuredAt), y: .value("Diastolic", value2))
                            .foregroundStyle(AppColor.softRed.opacity(0.45))
                    }
                }
                .chartXAxis { AxisMarks(values: .stride(by: .day)) { AxisValueLabel(format: .dateTime.weekday(.narrow)) } }
            } else {
                placeholder(count: dataProvider.bpLast7Days.count)
            }
        case .sugar:
            if dataProvider.sugarLast7Days.count >= 2 {
                Chart(dataProvider.sugarLast7Days) { record in
                    LineMark(x: .value("Day", record.measuredAt), y: .value("Sugar", record.value1))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.orange)
                    PointMark(x: .value("Day", record.measuredAt), y: .value("Sugar", record.value1))
                        .foregroundStyle(Color.orange)
                }
                .chartXAxis { AxisMarks(values: .stride(by: .day)) { AxisValueLabel(format: .dateTime.weekday(.narrow)) } }
            } else {
                placeholder(count: dataProvider.sugarLast7Days.count)
            }
        case .medicine:
            if dataProvider.medicineAdherenceLast7Days.count >= 2 {
                Chart(dataProvider.medicineAdherenceLast7Days) { point in
                    BarMark(x: .value("Day", point.date), y: .value("Adherence", point.adherence * 100))
                        .foregroundStyle(AppColor.mintGreenDeep.gradient)
                }
                .chartYScale(domain: 0...100)
                .chartXAxis { AxisMarks(values: .stride(by: .day)) { AxisValueLabel(format: .dateTime.weekday(.narrow)) } }
            } else {
                placeholder(count: dataProvider.medicineAdherenceLast7Days.count)
            }
        case .weight:
            if dataProvider.weightLast7Days.count >= 2 {
                Chart(dataProvider.weightLast7Days) { record in
                    LineMark(x: .value("Day", record.measuredAt), y: .value("Weight", record.value1))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AppColor.medicalBlue)
                }
                .chartXAxis { AxisMarks(values: .stride(by: .day)) { AxisValueLabel(format: .dateTime.weekday(.narrow)) } }
            } else {
                placeholder(count: dataProvider.weightLast7Days.count)
            }
        }
    }

    private func placeholder(count: Int) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(count == 0 ? "Start logging to see your trend" : "Log one more reading to see your trend")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
