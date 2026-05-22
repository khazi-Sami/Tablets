import SwiftUI

struct HealthInsightsView: View {
    let records: [HealthRecord]

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView {
                    VStack(spacing: Spacing.medium) {
                        PillCardContainer(style: .alert) {
                            Text("These insights are based only on your saved logs and are not medical advice.")
                                .font(AppFont.body)
                                .foregroundStyle(AppColor.secondaryInk)
                        }

                        insight("Missed logs", "You have not recorded BP for 3 days.", "calendar.badge.exclamationmark", AppColor.lavenderDeep)
                        insight("Sugar trend", "Your sugar readings are higher this week based on your logs.", "drop.fill", AppColor.softRed)
                        insight("Heart rate", "Your heart rate looks stable based on recent entries.", "heart.fill", AppColor.mintGreenDeep)
                        insight("Average BP", averageBPText, "heart.text.square.fill", AppColor.medicalBlue)
                        insight("Average sugar", averageSugarText, "chart.line.uptrend.xyaxis", AppColor.lavenderDeep)
                    }
                    .padding(Spacing.medium)
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var averageBPText: String {
        let bp = records.filter { $0.type == .bloodPressure }
        guard !bp.isEmpty else { return "No BP average yet. Add a few readings to see this." }
        let systolic = bp.map(\.value1).reduce(0, +) / Double(bp.count)
        let diastolic = bp.compactMap(\.value2).reduce(0, +) / Double(max(bp.compactMap(\.value2).count, 1))
        return "Average BP based on logs: \(Int(systolic))/\(Int(diastolic)) mmHg."
    }

    private var averageSugarText: String {
        let sugar = records.filter { $0.type == .bloodSugar }
        guard !sugar.isEmpty else { return "No sugar average yet. Add readings to see this." }
        let average = sugar.map(\.value1).reduce(0, +) / Double(sugar.count)
        return "Average sugar based on logs: \(Int(average)) mg/dL."
    }

    private func insight(_ title: String, _ body: String, _ icon: String, _ color: Color) -> some View {
        HealthGlassCard {
            HStack(spacing: Spacing.medium) {
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: 52, height: 52)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(title)
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)
                    Text(body)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                }
                Spacer()
            }
        }
    }
}
