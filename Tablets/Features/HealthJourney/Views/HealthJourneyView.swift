import SwiftData
import SwiftUI

struct HealthJourneyView: View {
    @Query(sort: \MedicineLog.scheduledTime, order: .reverse) private var medicineLogs: [MedicineLog]
    @Query(sort: \HealthRecord.measuredAt, order: .reverse) private var healthRecords: [HealthRecord]
    @Query(sort: \WomensHealthDailyLog.date, order: .reverse) private var womensLogs: [WomensHealthDailyLog]
    @Query(sort: \PeriodCycle.startDate, order: .reverse) private var periodCycles: [PeriodCycle]
    @Query(sort: \DailyHealthCheckIn.date, order: .reverse) private var checkIns: [DailyHealthCheckIn]
    @StateObject private var viewModel = HealthJourneyViewModel()
    @State private var didAppear = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        let journeyFeed = viewModel.feed(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            periodCycles: periodCycles,
            checkIns: checkIns
        )
        let streaks = viewModel.streaks(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            checkIns: checkIns
        )
        let mode = viewModel.mode(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            periodCycles: periodCycles
        )

        NavigationStack {
            MedicalBackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.large) {
                        journeyHero(mode: mode, streaks: streaks)
                            .journeyEntrance(didAppear: didAppear, delay: 0.02)

                        HealthStoryCard(
                            title: storyTitle(streaks: streaks),
                            subtitle: "Your wellness story is becoming more visible through small caring actions.",
                            symbol: "sparkles",
                            color: AppColor.medicalBlue
                        )
                        .journeyEntrance(didAppear: didAppear, delay: 0.08)

                        DashboardSectionTitle("Streak badges")
                            .journeyEntrance(didAppear: didAppear, delay: 0.12)

                        LazyVGrid(columns: columns, spacing: Spacing.small) {
                            StreakBadgeView(title: "Medicine", value: streaks.medicine, symbol: "pills.fill", color: AppColor.mintGreenDeep)
                            StreakBadgeView(title: "BP logs", value: streaks.bloodPressure, symbol: "heart.text.square.fill", color: AppColor.medicalBlue)
                            StreakBadgeView(title: "Hydration", value: streaks.hydration, symbol: "drop.fill", color: AppColor.lavenderDeep)
                            StreakBadgeView(title: "Sleep", value: streaks.sleep, symbol: "moon.zzz.fill", color: AppColor.lavenderDeep)
                        }
                        .journeyEntrance(didAppear: didAppear, delay: 0.16)

                        aiInsights(streaks: streaks, feed: journeyFeed)
                            .journeyEntrance(didAppear: didAppear, delay: 0.22)

                        DailyJourneyTimeline(items: journeyFeed)
                            .journeyEntrance(didAppear: didAppear, delay: 0.28)
                    }
                    .padding(Spacing.medium)
                    .padding(.bottom, 140)
                }
            }
            .navigationTitle("Journey")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.selection()
                        viewModel.isShowingCheckIn = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Daily Check-In")
                }
            }
            .onAppear { didAppear = true }
            .sheet(isPresented: $viewModel.isShowingCheckIn) {
                DailyCheckInView()
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openDailyCheckIn)) { _ in
                viewModel.isShowingCheckIn = true
            }
        }
    }

    private func journeyHero(mode: EmotionalWellnessMode, streaks: HealthStreakSummary) -> some View {
        HealingGlowCard(color: AppColor.medicalBlue) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(alignment: .center, spacing: Spacing.medium) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(AppColor.medicalBlue)
                        .frame(width: 56, height: 56)
                        .background(AppColor.medicalBlue.opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                        Text(mode.title)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)

                        Text("Your Health Journey")
                            .font(AppFont.sectionTitle)
                            .foregroundStyle(AppColor.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                }

                Text("A caring timeline of medicines, health logs, mood, sleep, symptoms, and gentle wins.")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryInk)
                    .lineLimit(3)

                HStack(spacing: Spacing.medium) {
                    WellnessProgressRing(progress: min(Double(streaks.best) / 7, 1), color: AppColor.mintGreenDeep)
                        .frame(width: 76, height: 76)

                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        Text("\(streaks.best)-day best streak")
                            .font(AppFont.bodyStrong)
                            .foregroundStyle(AppColor.ink)
                        Text("Milestone level: \(achievementLevel(for: streaks.best))")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func aiInsights(streaks: HealthStreakSummary, feed: [JourneyFeedItem]) -> some View {
        let insights = viewModel.insights(streaks: streaks, feed: feed)
        return HealingGlowCard(color: AppColor.lavenderDeep) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("AI wellness insights")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                ForEach(insights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: Spacing.small) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(AppColor.medicalBlue)
                        Text(insight)
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.secondaryInk)
                            .lineLimit(4)
                    }
                }

                Text("These reflections are based only on saved logs and are not medical advice.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.tertiaryInk)
            }
        }
    }

    private func storyTitle(streaks: HealthStreakSummary) -> String {
        if streaks.medicine >= 1 { return "You completed medicine care moments today" }
        if streaks.bloodPressure >= 3 { return "Your BP tracking improved this week" }
        if streaks.best >= 7 { return "You maintained a 7-day health streak" }
        return "You are building steady care habits"
    }

    private func achievementLevel(for streak: Int) -> String {
        switch streak {
        case 7...: return "Radiant"
        case 3...: return "Growing"
        case 1...: return "Started"
        default: return "Ready"
        }
    }
}

private extension View {
    func journeyEntrance(didAppear: Bool, delay: Double) -> some View {
        opacity(didAppear ? 1 : 0)
            .animation(.easeOut(duration: 0.20).delay(delay), value: didAppear)
    }
}

#Preview {
    HealthJourneyView()
        .modelContainer(SampleData.previewContainer)
}
