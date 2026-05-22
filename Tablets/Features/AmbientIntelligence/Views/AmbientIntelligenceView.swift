import SwiftData
import SwiftUI

struct AmbientIntelligenceView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.sizeCategory) private var sizeCategory
    @Query(sort: \MedicineLog.scheduledTime, order: .reverse) private var medicineLogs: [MedicineLog]
    @Query(sort: \HealthRecord.measuredAt, order: .reverse) private var healthRecords: [HealthRecord]
    @Query(sort: \WomensHealthDailyLog.date, order: .reverse) private var womensLogs: [WomensHealthDailyLog]
    @Query(sort: \PeriodCycle.startDate, order: .reverse) private var periodCycles: [PeriodCycle]
    @Query(sort: \AmbientInteractionMemory.lastSeenAt, order: .reverse) private var interactions: [AmbientInteractionMemory]
    @StateObject private var viewModel = AmbientIntelligenceViewModel()

    var body: some View {
        let environment = AmbientEnvironmentService().context(colorScheme: colorScheme, sizeCategory: sizeCategory)
        let state = viewModel.state(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            periodCycles: periodCycles,
            interactions: interactions,
            environment: environment
        )
        let recommendation = viewModel.reminderRecommendation(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            interactions: interactions,
            elderlyMode: state.elderlyModeSuggested
        )

        ZStack {
            AmbientAdaptiveGradientView(state: state)
                .ignoresSafeArea()
            AmbientBreathingGlow(state: state)
                .offset(x: 110, y: -220)
            AmbientPulseWaveView(state: state)
                .frame(width: 220, height: 220)
                .offset(x: -90, y: 180)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    Text("Ambient Intelligence")
                        .font(AppFont.display)
                        .foregroundStyle(state.timeMode == .night ? AppColor.warmWhite : AppColor.ink)

                    AmbientInsightCard(state: state, reminderRecommendation: recommendation)
                    AmbientPriorityStrip(priorities: state.dashboardPriority)

                    PillCardContainer {
                        VStack(alignment: .leading, spacing: Spacing.medium) {
                            Text("Quiet observations")
                                .font(AppFont.sectionTitle)
                                .foregroundStyle(AppColor.ink)
                            ForEach(state.observations, id: \.self) { observation in
                                Label(observation, systemImage: "leaf.fill")
                                    .font(AppFont.body)
                                    .foregroundStyle(AppColor.secondaryInk)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Text("All intelligence is local first. No diagnosis, no scary warnings, no online sharing without consent.")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.tertiaryInk)
                        }
                    }
                }
                .padding(Spacing.medium)
                .padding(.bottom, 120)
            }
        }
    }
}

#Preview {
    AmbientIntelligenceView()
        .modelContainer(SampleData.previewContainer)
}
