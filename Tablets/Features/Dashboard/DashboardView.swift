import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.sizeCategory) private var sizeCategory
    @StateObject private var viewModel = DashboardViewModel()
    @Query(sort: \HealthRecord.measuredAt, order: .reverse) private var healthRecords: [HealthRecord]
    @Query(sort: \MedicineLog.scheduledTime, order: .reverse) private var medicineLogs: [MedicineLog]
    @Query(sort: \WomensHealthDailyLog.date, order: .reverse) private var womensLogs: [WomensHealthDailyLog]
    @Query(sort: \PeriodCycle.startDate, order: .reverse) private var periodCycles: [PeriodCycle]
    @Query(sort: \AmbientInteractionMemory.lastSeenAt, order: .reverse) private var ambientInteractions: [AmbientInteractionMemory]
    @State private var didAppear = false
    @State private var isShowingAddMedicine = false
    @State private var isShowingWomensHealthLog = false
    @State private var selectedHealthRecordType: HealthRecordType?
    @State private var isShowingHealthTrends = false

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.small),
        GridItem(.flexible(), spacing: Spacing.small)
    ]

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.large) {
                        GreetingHeader(
                            greeting: viewModel.title,
                            name: viewModel.userName
                        )
                        .dashboardEntrance(didAppear: didAppear, delay: 0.02)

                        HealthCompanionCard(userName: viewModel.userName)
                            .dashboardEntrance(didAppear: didAppear, delay: 0.06)

                        dashboardAmbientCard
                            .dashboardEntrance(didAppear: didAppear, delay: 0.09)

                        NextMedicineCard(medicine: viewModel.nextMedicine)
                            .dashboardEntrance(didAppear: didAppear, delay: 0.12)

                        MedicineProgressCard(progress: viewModel.medicineProgress)
                            .dashboardEntrance(didAppear: didAppear, delay: 0.16)

                        WomensHealthDashboardCard(
                            cycleDay: 18,
                            daysUntilNextPeriod: 10,
                            nextPeriodDate: Calendar.current.date(byAdding: .day, value: 10, to: .now) ?? .now,
                            lastSymptoms: ["Bloating", "Fatigue"],
                            logTodayAction: { isShowingWomensHealthLog = true }
                        )
                        .dashboardEntrance(didAppear: didAppear, delay: 0.20)

                        DashboardSectionTitle("Quick actions")
                            .dashboardEntrance(didAppear: didAppear, delay: 0.24)

                        LazyVGrid(columns: columns, spacing: Spacing.small) {
                            ForEach(Array(viewModel.quickActions.enumerated()), id: \.element.id) { index, action in
                                DashboardQuickActionButton(action: action) {
                                    handleQuickAction(action)
                                }
                                    .dashboardEntrance(didAppear: didAppear, delay: 0.26 + Double(index) * 0.04)
                            }
                        }

                        DashboardSectionTitle("Today's timeline")
                            .dashboardEntrance(didAppear: didAppear, delay: 0.38)

                        TodayTimelineCard(items: viewModel.timeline)
                            .dashboardEntrance(didAppear: didAppear, delay: 0.42)

                        DashboardSectionTitle("Health snapshot")
                            .dashboardEntrance(didAppear: didAppear, delay: 0.48)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.small) {
                                ForEach(Array(viewModel.healthSnapshots.enumerated()), id: \.element.id) { index, snapshot in
                                    HealthSnapshotCard(snapshot: snapshot)
                                        .frame(width: 176)
                                        .dashboardEntrance(didAppear: didAppear, delay: 0.50 + Double(index) * 0.04)
                                }
                            }
                            .padding(.vertical, Spacing.xxSmall)
                        }

                        LowStockAlertCard(lowStock: viewModel.lowStock)
                            .dashboardEntrance(didAppear: didAppear, delay: 0.62)
                    }
                    .padding(Spacing.medium)
                    .padding(.bottom, Spacing.large)
                }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                didAppear = true
            }
            .sheet(isPresented: $isShowingWomensHealthLog) {
                DailySymptomLogView()
            }
            .sheet(isPresented: $isShowingAddMedicine) {
                AddMedicineView()
            }
            .sheet(item: $selectedHealthRecordType) { type in
                AddHealthRecordView(type: type)
            }
            .sheet(isPresented: $isShowingHealthTrends) {
                HealthTrendChartsView(records: healthRecords)
            }
        }
    }

    private var dashboardAmbientCard: some View {
        let environment = AmbientEnvironmentService().context(colorScheme: colorScheme, sizeCategory: sizeCategory)
        let state = AmbientIntelligenceBuilder.state(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            periodCycles: periodCycles,
            interactions: ambientInteractions,
            environment: environment
        )
        let recommendation = AmbientIntelligenceBuilder.reminderRecommendation(
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            interactions: ambientInteractions,
            elderlyMode: state.elderlyModeSuggested
        )

        return AmbientInsightCard(state: state, reminderRecommendation: recommendation)
    }

    private func handleQuickAction(_ action: DashboardQuickAction) {
        HapticsManager.selection()

        switch action.kind {
        case .addMedicine:
            isShowingAddMedicine = true
        case .recordBP:
            selectedHealthRecordType = .bloodPressure
        case .recordSugar:
            selectedHealthRecordType = .bloodSugar
        case .periodLog:
            isShowingWomensHealthLog = true
        case .viewHealthTrends:
            isShowingHealthTrends = true
        }
    }
}

private struct GreetingHeader: View {
    let greeting: String
    let name: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("\(greeting), \(name)")
                    .font(AppFont.display)
                    .foregroundStyle(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("I checked your care plan. One medicine is coming up next.")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Spacing.small)

            Image(systemName: "stethoscope.circle.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(AppColor.medicalBlue)
                .accessibilityHidden(true)
        }
    }
}

private struct NextMedicineCard: View {
    let medicine: DashboardNextMedicine

    var body: some View {
        PillCardContainer(style: .highlighted, padding: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(spacing: Spacing.medium) {
                    DashboardIconTile(systemImage: medicine.iconName, color: AppColor.medicalBlue)

                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        Text("Next medicine")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)

                        Text(medicine.name)
                            .font(AppFont.title)
                            .foregroundStyle(AppColor.ink)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: Spacing.xxSmall) {
                        Text(medicine.time)
                            .font(AppFont.sectionTitle)
                            .foregroundStyle(AppColor.medicalBlueDeep)

                        HealthStatusBadge(status: .upcoming)
                    }
                }

                HStack(spacing: Spacing.small) {
                    DashboardInfoPill(text: medicine.dosage, systemImage: "cross.case.fill")
                    DashboardInfoPill(text: medicine.instruction, systemImage: "fork.knife")
                }

                CapsuleButton("Mark as Taken", systemImage: "checkmark.circle.fill") {}
                    .frame(minHeight: 60)
            }
        }
    }
}

private struct MedicineProgressCard: View {
    let progress: Double

    var body: some View {
        PillCardContainer(padding: Spacing.large) {
            HStack(spacing: Spacing.large) {
                ZStack {
                    Circle()
                        .stroke(AppColor.medicalBlue.opacity(0.12), lineWidth: 14)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AppGradient.primaryButton,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: Spacing.xxxSmall) {
                        Text("\(Int(progress * 100))%")
                            .font(AppFont.title)
                            .foregroundStyle(AppColor.ink)

                        Text("done")
                            .font(AppFont.badge)
                            .foregroundStyle(AppColor.secondaryInk)
                    }
                }
                .frame(width: 108, height: 108)
                .accessibilityLabel("Medicine progress \(Int(progress * 100)) percent complete")

                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Medicine progress")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)

                    Text("2 of 4 doses are complete. Your next dose is right on schedule.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

private struct DashboardQuickActionButton: View {
    let action: DashboardQuickAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.small) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(tint.opacity(0.14))
                    .clipShape(Circle())

                Text(action.title)
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.88)

                Spacer(minLength: 0)
            }
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .background(AppGradient.card)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                    .stroke(AppColor.hairline.opacity(0.52), lineWidth: 1)
            )
            .appShadow(AppShadow.soft)
        }
        .buttonStyle(.plain)
    }

    private var tint: Color {
        switch action.tint {
        case .blue:
            return AppColor.medicalBlue
        case .mint:
            return AppColor.mintGreenDeep
        case .lavender:
            return AppColor.lavenderDeep
        case .red:
            return AppColor.softRed
        }
    }
}

private struct TodayTimelineCard: View {
    let items: [DashboardTimelineItem]

    var body: some View {
        PillCardContainer {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    DashboardTimelineRow(
                        item: item,
                        isLast: index == items.count - 1
                    )
                }
            }
        }
    }
}

private struct DashboardTimelineRow: View {
    let item: DashboardTimelineItem
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(spacing: Spacing.xxSmall) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(statusColor.opacity(0.20), lineWidth: 7)
                    )

                if !isLast {
                    Rectangle()
                        .fill(AppColor.hairline.opacity(0.72))
                        .frame(width: 2, height: 48)
                }
            }
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                HStack {
                    Text(item.time)
                        .font(AppFont.bodyStrong)
                        .foregroundStyle(AppColor.medicalBlueDeep)

                    Spacer()

                    HealthStatusBadge(status: badgeStatus)
                }

                Text(item.title)
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                Text(item.subtitle)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }
            .padding(.bottom, isLast ? 0 : Spacing.medium)
        }
        .frame(minHeight: 76)
    }

    private var statusColor: Color {
        switch item.status {
        case .taken:
            return AppColor.mintGreenDeep
        case .next:
            return AppColor.medicalBlue
        case .upcoming:
            return AppColor.lavenderDeep
        case .missed:
            return AppColor.softRed
        }
    }

    private var badgeStatus: HealthStatusBadge.Status {
        switch item.status {
        case .taken:
            return .good
        case .next, .upcoming:
            return .upcoming
        case .missed:
            return .missed
        }
    }
}

private struct HealthSnapshotCard: View {
    let snapshot: DashboardHealthSnapshot

    var body: some View {
        PillCardContainer(style: .lavender, padding: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack {
                    Image(systemName: snapshot.systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppColor.medicalBlue)
                        .frame(width: 46, height: 46)
                        .background(AppColor.cream.opacity(0.84))
                        .clipShape(Circle())

                    Spacer()

                    Text(snapshot.status)
                        .font(AppFont.badge)
                        .foregroundStyle(AppColor.mintGreenDeep)
                        .padding(.horizontal, Spacing.xSmall)
                        .padding(.vertical, Spacing.xxSmall)
                        .background(AppColor.mintGreen.opacity(0.18))
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                    Text(snapshot.title)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)

                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xxSmall) {
                        Text(snapshot.value)
                            .font(AppFont.title)
                            .foregroundStyle(AppColor.ink)

                        Text(snapshot.unit)
                            .font(AppFont.badge)
                            .foregroundStyle(AppColor.secondaryInk)
                    }
                }
            }
        }
    }
}

private struct LowStockAlertCard: View {
    let lowStock: DashboardLowStockMedicine

    var body: some View {
        PillCardContainer(style: .alert, padding: Spacing.large) {
            HStack(spacing: Spacing.medium) {
                DashboardIconTile(systemImage: "exclamationmark.triangle.fill", color: AppColor.softRed)

                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text("Low stock alert")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)

                    Text("\(lowStock.name) has \(lowStock.remaining) left. Refill before it drops below \(lowStock.threshold).")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

struct DashboardSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(AppFont.sectionTitle)
            .foregroundStyle(AppColor.ink)
            .padding(.top, Spacing.xxSmall)
    }
}

private struct DashboardInfoPill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(AppFont.badge)
            .foregroundStyle(AppColor.medicalBlueDeep)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(AppColor.cream.opacity(0.84))
            .clipShape(Capsule(style: .continuous))
    }
}

private struct DashboardIconTile: View {
    let systemImage: String
    let color: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(color)
            .frame(width: 62, height: 62)
            .background(color.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
            .accessibilityHidden(true)
    }
}

private extension View {
    func dashboardEntrance(didAppear: Bool, delay: Double) -> some View {
        opacity(didAppear ? 1 : 0)
            .offset(y: didAppear ? 0 : 14)
            .animation(
                .spring(response: 0.46, dampingFraction: 0.86).delay(delay),
                value: didAppear
            )
    }
}

#Preview {
    DashboardView()
        .modelContainer(SampleData.previewContainer)
}
