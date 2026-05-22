import SwiftUI

struct CyclePredictionView: View {
    let prediction: CyclePredictionSummary

    var body: some View {
        WomensHealthSection(title: "Cycle estimates", subtitle: "Based on your previous logs. Not a medical diagnosis.") {
            VStack(spacing: Spacing.medium) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.small) {
                    WomensHealthMetricCard(
                        title: "Next period",
                        value: prediction.nextPeriodDate.formatted(date: .abbreviated, time: .omitted),
                        subtitle: "Estimated",
                        systemImage: "calendar"
                    )
                    WomensHealthMetricCard(
                        title: "Cycle length",
                        value: "\(prediction.averageCycleLengthDays)d",
                        subtitle: "Estimated average",
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                    WomensHealthMetricCard(
                        title: "Duration",
                        value: "\(prediction.averagePeriodDurationDays)d",
                        subtitle: "Estimated average",
                        systemImage: "clock"
                    )
                    WomensHealthMetricCard(
                        title: "Ovulation",
                        value: prediction.ovulationDate.formatted(date: .abbreviated, time: .omitted),
                        subtitle: "Estimated",
                        systemImage: "sparkles"
                    )
                }

                Text("Estimated fertile window: \(prediction.fertileWindowStart.formatted(date: .abbreviated, time: .omitted)) - \(prediction.fertileWindowEnd.formatted(date: .abbreviated, time: .omitted)). This is only an estimate and not medical diagnosis.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
