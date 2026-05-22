import SwiftData
import SwiftUI

struct WomensHealthView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PeriodCycle.startDate, order: .reverse) private var cycles: [PeriodCycle]
    @Query(sort: \WomensHealthDailyLog.date, order: .reverse) private var dailyLogs: [WomensHealthDailyLog]
    @Query private var settings: [CyclePredictionSettings]
    @StateObject private var viewModel = WomensHealthViewModel()

    private var prediction: CyclePredictionSummary {
        viewModel.predictionViewModel.prediction(from: cycles, settings: settings.first)
    }

    var body: some View {
        NavigationStack {
            WomensHealthBackground {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.large) {
                        header

                        WomensHealthDashboardCard(
                            cycleDay: viewModel.predictionViewModel.currentCycleDay(from: cycles),
                            daysUntilNextPeriod: max(Calendar.current.dateComponents([.day], from: .now, to: prediction.nextPeriodDate).day ?? 0, 0),
                            nextPeriodDate: prediction.nextPeriodDate,
                            lastSymptoms: latestSymptoms,
                            logTodayAction: { viewModel.isShowingDailyLog = true }
                        )

                        PeriodCalendarView(cycles: cycles, prediction: prediction)

                        CyclePredictionView(prediction: prediction)

                        if let settings = settings.first {
                            ReminderSettingsCard(settings: settings)
                        }

                        recentLogSection
                    }
                    .padding(Spacing.medium)
                    .padding(.bottom, Spacing.large)
                }
            }
            .navigationTitle("Women's Health")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        viewModel.isShowingDailyLog = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("Log today")

                    Button {
                        viewModel.isShowingAddPeriod = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add period")
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddPeriod) {
                AddPeriodLogView()
            }
            .sheet(isPresented: $viewModel.isShowingDailyLog) {
                DailySymptomLogView()
            }
            .onAppear {
                viewModel.ensureSettings(in: modelContext, existing: settings)
            }
        }
    }

    private var header: some View {
        PillCardContainer(style: .highlighted, padding: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Label("Private cycle care", systemImage: "lock.heart.fill")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)

                Text("Estimated insights are based on your previous logs and are not medical diagnosis.")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    CapsuleButton("Add Period", systemImage: "calendar.badge.plus", style: .secondary) {
                        viewModel.isShowingAddPeriod = true
                    }

                    CapsuleButton("Log Today", systemImage: "plus.circle.fill", style: .secondary) {
                        viewModel.isShowingDailyLog = true
                    }
                }
            }
        }
    }

    private var recentLogSection: some View {
        WomensHealthSection(title: "Recent daily log") {
            if let log = dailyLogs.first {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(log.date.formatted(date: .abbreviated, time: .omitted))
                        .font(AppFont.bodyStrong)
                        .foregroundStyle(AppColor.ink)

                    Text(log.symptoms.isEmpty ? "No symptoms selected" : log.symptoms.map(displaySymptom).joined(separator: ", "))
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)

                    Text("Water: \(log.waterIntakeCups) cups • Sleep: \(log.sleepQuality.title)")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                }
            } else {
                Text("No daily log yet. Use Log Today to add one.")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryInk)
            }
        }
    }

    private var latestSymptoms: [String] {
        dailyLogs.first?.symptoms.prefix(3).map(displaySymptom) ?? []
    }

    private func displaySymptom(_ rawValue: String) -> String {
        WomensHealthSymptom(rawValue: rawValue)?.title ?? rawValue
    }
}

#Preview {
    WomensHealthView()
        .modelContainer(SampleData.previewContainer)
}
