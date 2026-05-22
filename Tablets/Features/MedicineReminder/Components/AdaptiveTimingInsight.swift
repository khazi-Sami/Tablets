import SwiftUI

struct AdaptiveTimingInsight: View {
    let pattern: MedicineTakePattern
    let learnedTime: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Label("We learned your habit", systemImage: "sparkles")
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.ink)

            Text(habitText)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)

            if let learnedTime {
                Text("Your body clock says: \(learnedTime.formatted(date: .omitted, time: .shortened))")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.medicalBlueDeep)
            }

            Text("Based on \(pattern.sampleCount) doses. This is just a helpful reminder adjustment.")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
        }
        .padding(Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.lavenderDeep.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
    }

    private var habitText: String {
        let minutes = abs(pattern.averageActualMinuteOffset)
        if minutes == 0 {
            return "You usually take this close to the reminder time."
        }
        let direction = pattern.averageActualMinuteOffset > 0 ? "after" : "before"
        return "You usually take this \(minutes) minutes \(direction) the reminder."
    }
}
