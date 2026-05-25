import SwiftData
import SwiftUI

struct HealthTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthRecord.measuredAt, order: .reverse) private var records: [HealthRecord]
    @StateObject private var viewModel = HealthTrackingViewModel()
    @State private var didAppear = false

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.small),
        GridItem(.flexible(), spacing: Spacing.small)
    ]

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.large) {
                        HealthAssistantHero(
                            showCharts: {
                                HapticsManager.selection()
                                viewModel.isShowingCharts = true
                            },
                            showInsights: {
                                HapticsManager.selection()
                                viewModel.isShowingInsights = true
                            }
                        )
                        .healthEntrance(didAppear: didAppear, delay: 0.02)

                        if !hasBPRecords {
                            VoiceCoachingCard(
                                message: "No BP readings yet.",
                                command: "My BP is 120 over 80"
                            )
                            .healthEntrance(didAppear: didAppear, delay: 0.05)
                        }

                        if !hasSugarRecords {
                            VoiceCoachingCard(
                                message: "No sugar readings yet.",
                                command: "My sugar is 145 after food"
                            )
                            .healthEntrance(didAppear: didAppear, delay: 0.07)
                        }

                        AlertsWidgetView(alerts: viewModel.activeSafetyAlerts(from: records)) {
                            HapticsManager.selection()
                            viewModel.isShowingAlertHistory = true
                        }
                        .healthEntrance(didAppear: didAppear, delay: 0.075)

                        LazyVGrid(columns: columns, spacing: Spacing.small) {
                            ForEach(Array(HealthRecordType.allCases.enumerated()), id: \.element.id) { index, type in
                                HealthMetricTile(
                                    title: type.title,
                                    value: latestValue(for: type),
                                    subtitle: latestSubtitle(for: type),
                                    color: color(for: type),
                                    animation: animation(for: type)
                                )
                                .onTapGesture {
                                    HapticsManager.impact(.soft)
                                    viewModel.selectedAddType = type
                                }
                                .healthEntrance(didAppear: didAppear, delay: 0.08 + Double(index) * 0.04)
                            }
                        }

                        DashboardSectionTitle("Quick add")
                            .healthEntrance(didAppear: didAppear, delay: 0.32)

                        LazyVGrid(columns: columns, spacing: Spacing.small) {
                            ForEach(HealthRecordType.allCases) { type in
                                HealthQuickAddButton(type: type) {
                                    HapticsManager.selection()
                                    viewModel.selectedAddType = type
                                }
                            }

                            HealthQuickAddButton(title: "Diabetes", systemImage: "drop.degreesign.fill", color: AppColor.lavenderDeep) {
                                HapticsManager.selection()
                                viewModel.isShowingDiabetes = true
                            }

                            HealthQuickAddButton(title: "Trends", systemImage: "chart.xyaxis.line", color: AppColor.medicalBlue) {
                                HapticsManager.selection()
                                viewModel.isShowingCharts = true
                            }
                        }
                        .healthEntrance(didAppear: didAppear, delay: 0.36)

                        WeeklyHealthSummaryCard(records: records)
                            .healthEntrance(didAppear: didAppear, delay: 0.42)

                        RecentHealthTimeline(records: Array(records.prefix(6)))
                            .healthEntrance(didAppear: didAppear, delay: 0.48)

                        HealthGlassCard {
                            Text("These insights are based only on your saved logs and are not medical advice.")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.secondaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .healthEntrance(didAppear: didAppear, delay: 0.54)
                    }
                    .padding(Spacing.medium)
                    .padding(.bottom, Spacing.large)
                }
            }
            .navigationTitle("Health")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.selection()
                        viewModel.isShowingInsights = true
                    } label: {
                        Image(systemName: "lightbulb.max.fill")
                    }
                    .accessibilityLabel("Health Insights")

                    Button {
                        HapticsManager.selection()
                        viewModel.isShowingAlertHistory = true
                    } label: {
                        Image(systemName: "checkmark.shield.fill")
                    }
                    .accessibilityLabel("Safety Alert History")

                    Button {
                        HapticsManager.selection()
                        viewModel.selectedAddType = .bloodPressure
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Health Record")
                }
            }
            .onAppear {
                didAppear = true
            }
            .sheet(item: $viewModel.selectedAddType) { type in
                AddHealthRecordView(type: type)
            }
            .sheet(isPresented: $viewModel.isShowingDiabetes) {
                DiabetesTrackingView()
            }
            .sheet(isPresented: $viewModel.isShowingCharts) {
                HealthTrendChartsView(records: records)
            }
            .sheet(isPresented: $viewModel.isShowingInsights) {
                HealthInsightsView(records: records)
            }
            .sheet(isPresented: $viewModel.isShowingAlertHistory) {
                AlertHistoryView()
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openSugarTracking)) { _ in
                viewModel.isShowingDiabetes = true
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openSugarLog)) { _ in
                viewModel.selectedAddType = .bloodSugar
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openBPTracking)) { _ in
                viewModel.isShowingCharts = true
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openBPLog)) { _ in
                viewModel.selectedAddType = .bloodPressure
            }
        }
    }

    private func latestValue(for type: HealthRecordType) -> String {
        viewModel.latest(type, from: records)?.displayValue ?? "--"
    }

    private func latestSubtitle(for type: HealthRecordType) -> String {
        guard let record = viewModel.latest(type, from: records) else {
            return "Tap to record"
        }

        return record.measuredAt.shortTimeText
    }

    private var hasBPRecords: Bool {
        records.contains { $0.type == .bloodPressure }
    }

    private var hasSugarRecords: Bool {
        records.contains { $0.type == .bloodSugar }
    }

    private func color(for type: HealthRecordType) -> Color {
        switch type {
        case .bloodPressure, .heartRate: return AppColor.softRed
        case .bloodSugar, .temperature: return AppColor.lavenderDeep
        case .oxygen, .weight: return AppColor.mintGreenDeep
        }
    }

    private func animation(for type: HealthRecordType) -> AnyView {
        switch type {
        case .bloodPressure: return AnyView(BPMonitorAnimationView())
        case .bloodSugar: return AnyView(GlucoseDropAnimationView())
        case .heartRate: return AnyView(BeatingHeartView(size: 38))
        case .oxygen: return AnyView(OxygenBubbleAnimationView())
        case .weight: return AnyView(WeightScaleAnimationView())
        case .temperature: return AnyView(ThermometerFillAnimationView())
        }
    }
}

private struct HealthAssistantHero: View {
    let showCharts: () -> Void
    let showInsights: () -> Void

    var body: some View {
        PillCardContainer(style: .highlighted, padding: Spacing.large) {
            HStack(alignment: .center, spacing: Spacing.large) {
                ZStack {
                    PulseWaveView(color: AppColor.softRed)
                    BeatingHeartView(size: 58)
                }
                .frame(width: 96, height: 96)

                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Your health assistant")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.ink)

                    Text("Track BP, sugar, oxygen, weight, temperature, and heart trends in one calm place.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: Spacing.small) {
                        CapsuleButton("Trends", systemImage: "chart.xyaxis.line", action: showCharts)
                        CapsuleButton("Insights", systemImage: "sparkles", style: .secondary, action: showInsights)
                    }
                }
            }
        }
    }
}

private struct HealthQuickAddButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    init(type: HealthRecordType, action: @escaping () -> Void) {
        self.title = type.title
        self.systemImage = type.icon
        self.color = HealthQuickAddButton.color(for: type)
        self.action = action
    }

    init(title: String, systemImage: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.small) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: 46, height: 46)
                    .background(color.opacity(0.14))
                    .clipShape(Capsule())

                Text(title)
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(.white.opacity(0.58))
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.6), lineWidth: 1))
            .appShadow(AppShadow.soft)
        }
        .buttonStyle(.plain)
    }

    private static func color(for type: HealthRecordType) -> Color {
        switch type {
        case .bloodPressure, .heartRate: return AppColor.softRed
        case .bloodSugar, .temperature: return AppColor.lavenderDeep
        case .oxygen, .weight: return AppColor.mintGreenDeep
        }
    }
}

private struct WeeklyHealthSummaryCard: View {
    let records: [HealthRecord]

    var body: some View {
        HealthGlassCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack {
                    Text("Weekly summary")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)
                    Spacer()
                    HealthStatusPill(title: "Based on logs", color: AppColor.medicalBlue)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.small) {
                    SummaryMiniMetric(title: "Avg sugar", value: average(.bloodSugar, suffix: "mg/dL"))
                    SummaryMiniMetric(title: "Avg heart", value: average(.heartRate, suffix: "bpm"))
                    SummaryMiniMetric(title: "Avg oxygen", value: average(.oxygen, suffix: "%"))
                    SummaryMiniMetric(title: "Logs", value: "\(weeklyRecords.count)")
                }
            }
        }
    }

    private var weeklyRecords: [HealthRecord] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return records.filter { $0.measuredAt >= weekAgo }
    }

    private func average(_ type: HealthRecordType, suffix: String) -> String {
        let values = weeklyRecords.filter { $0.type == type }.map(\.value1)
        guard !values.isEmpty else { return "--" }
        let average = values.reduce(0, +) / Double(values.count)
        return "\(average.formatted(.number.precision(.fractionLength(0)))) \(suffix)"
    }
}

private struct SummaryMiniMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
            Text(value)
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.warmWhite.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
    }
}

private struct RecentHealthTimeline: View {
    let records: [HealthRecord]

    var body: some View {
        HealthGlassCard {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Recent records")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                if records.isEmpty {
                    EmptyStateView(
                        title: "No records yet",
                        message: "Your recent vitals will appear here after you save your first reading.",
                        systemImage: "heart.text.square"
                    )
                } else {
                    ForEach(records) { record in
                        HStack(spacing: Spacing.small) {
                            Image(systemName: record.type.icon)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(AppColor.medicalBlue)
                                .frame(width: 38, height: 38)
                                .background(AppColor.medicalBlue.opacity(0.12))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                                Text(record.type.title)
                                    .font(AppFont.bodyStrong)
                                    .foregroundStyle(AppColor.ink)
                                Text(record.measuredAt.mediumDateText)
                                    .font(AppFont.caption)
                                    .foregroundStyle(AppColor.secondaryInk)
                            }

                            Spacer()

                            Text(record.displayValue)
                                .font(AppFont.bodyStrong)
                                .foregroundStyle(AppColor.medicalBlueDeep)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                }
            }
        }
    }
}

private extension View {
    func healthEntrance(didAppear: Bool, delay: Double) -> some View {
        opacity(didAppear ? 1 : 0)
            .offset(y: didAppear ? 0 : 16)
            .animation(.spring(response: 0.55, dampingFraction: 0.88).delay(delay), value: didAppear)
    }
}

#Preview {
    HealthTrackingView()
        .modelContainer(SampleData.previewContainer)
}
