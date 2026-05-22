import SwiftUI

struct DashboardWomensHealthCard: View {
    let cycleDay: Int?
    let nextPeriodDate: Date?
    let symptoms: [String]
    let isElderlyMode: Bool
    let openWomensHealth: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Women's Health", systemImage: "heart.circle.fill")
                .font(.headline)
                .foregroundStyle(AppColor.ink)

            Text(cycleDay.map { "Day \($0)" } ?? "Start tracking your cycle")
                .font((isElderlyMode ? Font.title2 : Font.title3).weight(.bold))
                .foregroundStyle(AppColor.ink)
                .elderlyScaled(isElderlyMode)

            if cycleDay != nil, let nextPeriodDate {
                Text(nextPeriodDate < .now ? "Period may have started" : "Estimated next period: \(nextPeriodDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }

            if symptoms.isEmpty {
                Text("No symptoms logged recently")
                    .font(.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            } else {
                HStack {
                    ForEach(symptoms.prefix(3), id: \.self) { symptom in
                        Text(symptom)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(AppColor.lavender.opacity(0.18))
                            .clipShape(Capsule())
                    }
                }
            }

            CapsuleButton(cycleDay == nil ? "Start Tracking" : "Log Today", systemImage: "plus.circle.fill", style: .secondary, action: openWomensHealth)
                .frame(minHeight: isElderlyMode ? 56 : 50)
        }
        .padding(isElderlyMode ? 20 : 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}
