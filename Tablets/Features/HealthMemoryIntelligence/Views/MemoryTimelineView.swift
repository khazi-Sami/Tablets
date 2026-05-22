import SwiftData
import SwiftUI

struct MemoryTimelineView: View {
    @Query(sort: \UserHealthHabit.lastUpdatedAt, order: .reverse) private var habits: [UserHealthHabit]
    @Query(sort: \HealthPatternMemory.lastSeenAt, order: .reverse) private var patterns: [HealthPatternMemory]

    var body: some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Memory timeline")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                if habits.isEmpty && patterns.isEmpty {
                    Text("Private memory appears here as you use the assistant.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                } else {
                    ForEach(habits.prefix(4)) { habit in
                        timelineRow(title: habit.title, message: habit.detail, icon: "clock.badge.checkmark")
                    }
                    ForEach(patterns.prefix(4)) { pattern in
                        timelineRow(title: pattern.label.capitalized, message: pattern.summary, icon: "sparkle.magnifyingglass")
                    }
                }
            }
        }
    }

    private func timelineRow(title: String, message: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            Image(systemName: icon)
                .foregroundStyle(AppColor.medicalBlue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                Text(title)
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.ink)
                Text(message)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }
        }
    }
}
