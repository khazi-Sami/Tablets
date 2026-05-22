import SwiftData
import SwiftUI

struct HealthMemoryIntelligenceView: View {
    @Query(sort: \Medicine.name) private var medicines: [Medicine]
    @Query(sort: \MedicineLog.scheduledTime, order: .reverse) private var medicineLogs: [MedicineLog]
    @Query(sort: \HealthRecord.measuredAt, order: .reverse) private var healthRecords: [HealthRecord]
    @Query(sort: \UserHealthHabit.lastUpdatedAt, order: .reverse) private var habits: [UserHealthHabit]
    @Query(sort: \AssistantInteractionMemory.createdAt, order: .reverse) private var interactions: [AssistantInteractionMemory]
    @Query(sort: \WomensHealthDailyLog.date, order: .reverse) private var symptomLogs: [WomensHealthDailyLog]
    @StateObject private var viewModel = HealthMemoryIntelligenceViewModel()

    var body: some View {
        MedicalBackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.large) {
                    HStack(spacing: Spacing.medium) {
                        EmotionalStatusOrb(tone: viewModel.tone)
                        PersonalizedGreetingView(habits: habits)
                    }

                    AdaptiveAssistantBubble(text: viewModel.assistantMessage)

                    HabitInsightCards(cards: viewModel.cards)

                    MemoryTimelineView()

                    Text("Insights are based only on your saved logs and are informational only.")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.medium)
                }
                .padding(Spacing.medium)
            }
        }
        .navigationTitle("Health Memory")
        .onAppear(perform: refresh)
        .onChange(of: healthRecords.count) { _, _ in refresh() }
        .onChange(of: medicineLogs.count) { _, _ in refresh() }
    }

    private func refresh() {
        viewModel.refresh(
            medicines: medicines,
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            habits: habits,
            interactions: interactions,
            symptomLogs: symptomLogs
        )
    }
}

#Preview {
    NavigationStack {
        HealthMemoryIntelligenceView()
    }
    .modelContainer(SampleData.previewContainer)
}
