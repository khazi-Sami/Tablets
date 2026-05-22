import SwiftData
import SwiftUI

extension Notification.Name {
    static let healthDataDidUpdate = Notification.Name("HealthDataDidUpdate")
    static let dashboardVoicePhraseRequested = Notification.Name("DashboardVoicePhraseRequested")
}

struct DashboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.sizeCategory) private var sizeCategory
    @EnvironmentObject private var appRouter: AppRouter
    @AppStorage(UserHealthProfile.elderlyModeKey) private var elderlyMode = false

    @Query(sort: \HealthRecord.measuredAt, order: .reverse) private var healthRecords: [HealthRecord]
    @Query(sort: \MedicineLog.scheduledTime, order: .reverse) private var medicineLogs: [MedicineLog]
    @Query(sort: \WomensHealthDailyLog.date, order: .reverse) private var womensLogs: [WomensHealthDailyLog]
    @Query(sort: \PeriodCycle.startDate, order: .reverse) private var periodCycles: [PeriodCycle]
    @Query(sort: \AmbientInteractionMemory.lastSeenAt, order: .reverse) private var ambientInteractions: [AmbientInteractionMemory]

    @State private var viewModel = DashboardViewModel()
    @State private var dataProvider: DashboardDataProvider?
    @State private var selectedChart: DashboardChartKind = .bp
    @State private var isShowingAddMedicine = false
    @State private var isShowingWomensHealth = false
    @State private var isShowingFamilyCare = false
    @State private var isShowingDoctorVisit = false
    @State private var isShowingHealthTrends = false
    @State private var isShowingHealthKit = false
    @State private var isSavingMedicineLog = false
    @State private var carePlanErrorText: String?
    @State private var didAppear = false
    @AppStorage("dashboard_healthKitPromptDismissed") private var healthKitPromptDismissed = false
    @AppStorage("dashboard_recoveryBannerDismissedDate") private var recoveryBannerDismissedDate = ""

    private let healthColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        GreetingHeader(title: viewModel.greetingText, subtitle: viewModel.statusLine)
                            .dashboardEntrance(didAppear: didAppear, delay: 0.02)

                        HealthCompanionCard(userName: viewModel.userName.isEmpty ? "there" : viewModel.userName)
                            .dashboardEntrance(didAppear: didAppear, delay: 0.04)

                        dashboardAmbientCard
                            .dashboardEntrance(didAppear: didAppear, delay: 0.06)

                        if let dataProvider {
                            TodayCarePlanCard(
                                dataProvider: dataProvider,
                                isSaving: isSavingMedicineLog,
                                errorText: carePlanErrorText,
                                isElderlyMode: elderlyMode,
                                todaySnapshot: dataProvider.todaySnapshot,
                                markTaken: { markNextMedicineTaken() },
                                addMedicine: { isShowingAddMedicine = true }
                            )
                            .dashboardEntrance(didAppear: didAppear, delay: 0.08)

                            AppleHealthDashboardSummary(
                                dataProvider: dataProvider,
                                openHealthKit: { isShowingHealthKit = true }
                            )

                            if dataProvider.isRecoveryDay && !isRecoveryBannerDismissedToday {
                                RecoveryDayBanner(message: dataProvider.readinessSignal?.reason ?? "Recovery day — based on your sleep and heart rate signals.") {
                                    recoveryBannerDismissedDate = Calendar.current.startOfDay(for: .now).formatted(.iso8601.year().month().day())
                                }
                            }

                            DashboardSectionTitle("Health snapshot")
                            LazyVGrid(columns: healthColumns, spacing: 12) {
                                healthSnapshotCards(dataProvider)
                            }
                            secondaryHealthRow(dataProvider)

                            MedicineTodayWidget {
                                isShowingAddMedicine = true
                            }

                            WellnessInsightsCard(insights: dataProvider.wellnessInsights)

                            DashboardSectionTitle("Trends")
                            DashboardChartSection(selection: $selectedChart, dataProvider: dataProvider)

                            if UserHealthProfile.showWomensHealthCard {
                                DashboardWomensHealthCard(
                                    cycleDay: dataProvider.currentCycleDay,
                                    nextPeriodDate: dataProvider.estimatedNextPeriodDate,
                                    symptoms: dataProvider.recentPeriodSymptoms,
                                    isElderlyMode: elderlyMode,
                                    openWomensHealth: { isShowingWomensHealth = true }
                                )
                            }

                            if !dataProvider.lowStockMedicines.isEmpty {
                                LowStockWarningCard(medicines: dataProvider.lowStockMedicines) {
                                    appRouter.selectedTab = .medicines
                                }
                            }

                            FamilyCareSummaryCard(dataProvider: dataProvider) {
                                isShowingFamilyCare = true
                            }

                            if let appointment = dataProvider.nextDoctorAppointment {
                                DoctorVisitSummaryCard(appointment: appointment) {
                                    isShowingDoctorVisit = true
                                }
                            }

                            DashboardSectionTitle("Quick actions")
                            VoiceChipsRow(chips: dataProvider.voiceChips, isElderlyMode: elderlyMode) { chip in
                                NotificationCenter.default.post(name: .dashboardVoicePhraseRequested, object: chip.phrase)
                            }

                            JourneySummaryCard {
                                appRouter.selectedTab = .healthJourney
                            }

                            if shouldShowHealthKitPrompt {
                                ConnectHealthKitPrompt {
                                    healthKitPromptDismissed = true
                                } open: {
                                    isShowingHealthKit = true
                                }
                            }

                            LastUpdatedCaption(date: dataProvider.lastRefreshedAt)
                        }
                    }
                    .padding(Spacing.medium)
                    .padding(.bottom, 140)
                }
                .refreshable {
                    await dataProvider?.refresh()
                }
            }
            .navigationTitle("Dashboard")
            .task {
                DebugStartupLogger.log("DashboardView.task started dataProviderExists=\(dataProvider != nil)")
                configureProviderIfNeeded()
                DebugStartupLogger.log("DashboardView provider configured")
                await viewModel.refresh()
                DebugStartupLogger.log("DashboardViewModel.refresh finished; setting didAppear=true")
                didAppear = true
            }
            .onChange(of: scenePhase) { newPhase in
                DebugStartupLogger.log("DashboardView scenePhase changed to \(String(describing: newPhase))")
                if newPhase == .active {
                    Task { await viewModel.refresh() }
                }
            }
            .onChange(of: didAppear) { newValue in
                DebugStartupLogger.log("DashboardView didAppear changed to \(newValue)")
            }
            .onReceive(NotificationCenter.default.publisher(for: .healthDataDidUpdate)) { _ in
                DebugStartupLogger.log("DashboardView received HealthDataDidUpdate")
                Task { await viewModel.refresh() }
            }
            .sheet(isPresented: $isShowingAddMedicine) {
                AddMedicineView()
                    .onAppear {
                        DebugStartupLogger.log("AddMedicineView sheet appeared from Dashboard")
                    }
            }
            .sheet(isPresented: $isShowingWomensHealth) {
                WomensHealthView()
                    .onAppear {
                        DebugStartupLogger.log("WomensHealthView sheet appeared from Dashboard")
                    }
            }
            .sheet(isPresented: $isShowingFamilyCare) {
                FamilyCareView()
                    .onAppear {
                        DebugStartupLogger.log("FamilyCareView sheet appeared from Dashboard")
                    }
            }
            .sheet(isPresented: $isShowingDoctorVisit) {
                DoctorVisitView()
                    .onAppear {
                        DebugStartupLogger.log("DoctorVisitView sheet appeared from Dashboard")
                    }
            }
            .sheet(isPresented: $isShowingHealthTrends) {
                HealthTrendChartsView(records: healthRecords)
                    .onAppear {
                        DebugStartupLogger.log("HealthTrendChartsView sheet appeared from Dashboard")
                    }
            }
            .sheet(isPresented: $isShowingHealthKit) {
                HealthKitPermissionView()
                    .onAppear {
                        DebugStartupLogger.log("HealthKitPermissionView sheet appeared from Dashboard")
                    }
            }
            .onAppear {
                DebugStartupLogger.log("DashboardView.onAppear healthRecords=\(healthRecords.count) medicineLogs=\(medicineLogs.count) womensLogs=\(womensLogs.count) periodCycles=\(periodCycles.count)")
            }
        }
    }

    private var isRecoveryBannerDismissedToday: Bool {
        recoveryBannerDismissedDate == Calendar.current.startOfDay(for: .now).formatted(.iso8601.year().month().day())
    }

    private var shouldShowHealthKitPrompt: Bool {
        HealthKitService().isAvailable && !UserHealthProfile.healthKitEnabled && !healthKitPromptDismissed
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

    private func configureProviderIfNeeded() {
        if dataProvider == nil {
            DebugStartupLogger.log("DashboardView creating DashboardDataProvider")
            let provider = DashboardDataProvider(modelContext: modelContext)
            dataProvider = provider
            viewModel.configure(dataProvider: provider)
        } else {
            DebugStartupLogger.log("DashboardView reused existing DashboardDataProvider")
        }
    }

    @ViewBuilder
    private func healthSnapshotCards(_ dataProvider: DashboardDataProvider) -> some View {
        HealthSnapshotCard(
            title: "BP",
            systemImage: HealthRecordType.bloodPressure.icon,
            accent: AppColor.softRed,
            latestRecord: dataProvider.latestBP,
            sparklineRecords: dataProvider.bpLast7Days,
            valueText: { "\(Int($0.value1))/\(Int($0.value2 ?? 0))" },
            isElderlyMode: elderlyMode,
            onTap: { openHealth(type: .bloodPressure) }
        )
        HealthSnapshotCard(
            title: "Sugar",
            systemImage: HealthRecordType.bloodSugar.icon,
            accent: Color.orange,
            latestRecord: dataProvider.latestSugar,
            sparklineRecords: dataProvider.sugarLast7Days,
            valueText: { "\(Int($0.value1)) mg/dL" },
            isElderlyMode: elderlyMode,
            onTap: { openHealth(type: .bloodSugar) }
        )
        HealthSnapshotCard(
            title: "Heart Rate",
            systemImage: HealthRecordType.heartRate.icon,
            accent: Color.pink,
            latestRecord: dataProvider.latestHeartRate,
            sparklineRecords: latestRecords(type: .heartRate),
            valueText: { "\(Int($0.value1)) bpm" },
            isElderlyMode: elderlyMode,
            onTap: { openHealth(type: .heartRate) }
        )
        HealthSnapshotCard(
            title: "Oxygen",
            systemImage: HealthRecordType.oxygen.icon,
            accent: Color.blue,
            latestRecord: dataProvider.latestOxygen,
            sparklineRecords: latestRecords(type: .oxygen),
            valueText: { "\(Int($0.value1))%" },
            isElderlyMode: elderlyMode,
            onTap: { openHealth(type: .oxygen) }
        )
    }

    @ViewBuilder
    private func secondaryHealthRow(_ dataProvider: DashboardDataProvider) -> some View {
        if dataProvider.latestWeight != nil || dataProvider.latestTemperature != nil {
            HStack(spacing: 12) {
                if let weight = dataProvider.latestWeight {
                    SecondaryMetricPill(title: "Weight", value: "\(Int(weight.value1)) \(weight.unit)", icon: HealthRecordType.weight.icon)
                }
                if let temperature = dataProvider.latestTemperature {
                    SecondaryMetricPill(title: "Temperature", value: "\(Int(temperature.value1))\(temperature.unit)", icon: HealthRecordType.temperature.icon)
                }
            }
        }
    }

    private func latestRecords(type: HealthRecordType) -> [HealthRecord] {
        Array(healthRecords.filter { $0.type == type }.prefix(5)).sorted { $0.measuredAt < $1.measuredAt }
    }

    private func openHealth(type: HealthRecordType) {
        appRouter.selectedTab = .healthTracking
        switch type {
        case .bloodPressure:
            NotificationCenter.default.post(name: VoiceNavigationNotification.openBPTracking, object: nil)
        case .bloodSugar:
            NotificationCenter.default.post(name: VoiceNavigationNotification.openSugarTracking, object: nil)
        default:
            break
        }
    }

    private func markNextMedicineTaken() {
        guard !isSavingMedicineLog, let next = dataProvider?.nextPendingMedicine else { return }
        isSavingMedicineLog = true
        carePlanErrorText = nil
        modelContext.insert(MedicineLog(medicine: next.medicine, scheduledTime: next.scheduledAt, takenTime: .now, status: .taken))
        do {
            try modelContext.save()
            NotificationCenter.default.post(name: .healthDataDidUpdate, object: nil)
            Task { await viewModel.refresh() }
        } catch {
            carePlanErrorText = "Could not save that dose. Please try again."
            print("[DashboardView] Could not save taken medicine log: \(error)")
        }
        isSavingMedicineLog = false
    }
}

private struct GreetingHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(title)
                    .font(AppFont.display)
                    .foregroundStyle(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Spacing.small)
            Image(systemName: "stethoscope.circle.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(AppColor.medicalBlue)
        }
    }
}

struct DashboardSectionTitle: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppColor.secondaryInk)
            .padding(.top, 2)
    }
}

private struct SecondaryMetricPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        Label {
            Text("\(title): \(value)")
                .font(.caption.weight(.semibold))
        } icon: {
            Image(systemName: icon)
        }
        .foregroundStyle(AppColor.medicalBlueDeep)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(.regularMaterial)
        .clipShape(Capsule())
    }
}

private struct LowStockWarningCard: View {
    let medicines: [Medicine]
    let openMedicines: () -> Void

    var body: some View {
        Button(action: openMedicines) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Low stock", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(AppColor.ink)
                ForEach(medicines.prefix(3)) { medicine in
                    Text("\(medicine.name) · Only \(medicine.stockCount) left")
                        .font(.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.yellow.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct FamilyCareSummaryCard: View {
    let dataProvider: DashboardDataProvider
    let openFamilyCare: () -> Void

    var body: some View {
        Button(action: openFamilyCare) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Family Care", systemImage: "figure.2.and.child.holdinghands")
                    .font(.headline)
                    .foregroundStyle(AppColor.ink)
                if dataProvider.hasFamilyMembers {
                    if dataProvider.pendingFamilyMedicineLogsUnavailable {
                        Text("\(dataProvider.activeFamilyMembers.count) family member\(dataProvider.activeFamilyMembers.count == 1 ? "" : "s") saved")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColor.ink)
                    } else {
                        Text("\(dataProvider.pendingFamilyMedicineLogs.count) family medicine reminders need attention")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColor.ink)
                    }
                    Text(dataProvider.activeFamilyMembers.prefix(3).map(\.name).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                } else {
                    Text("Track medicines for family")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColor.ink)
                    Text("Add a family member to manage shared care.")
                        .font(.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

private struct LastUpdatedCaption: View {
    let date: Date?

    var body: some View {
        Text("Updated \(relativeText)")
            .font(.caption)
            .foregroundStyle(AppColor.tertiaryInk)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 4)
    }

    private var relativeText: String {
        guard let date else { return "just now" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}

private struct DoctorVisitSummaryCard: View {
    let appointment: DoctorAppointment
    let openDoctorVisit: () -> Void

    var body: some View {
        Button(action: openDoctorVisit) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Doctor Visit", systemImage: "stethoscope.circle.fill")
                    .font(.headline)
                    .foregroundStyle(AppColor.ink)
                Text(appointment.doctorName.isEmpty ? "Upcoming appointment" : appointment.doctorName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
                Text("\(appointment.appointmentDate.formatted(date: .abbreviated, time: .shortened)) · \(daysUntilText(appointment.appointmentDate))")
                    .font(.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func daysUntilText(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: date)).day ?? 0
        return days <= 0 ? "Today" : "In \(days) day\(days == 1 ? "" : "s")"
    }
}

private struct JourneySummaryCard: View {
    let openJourney: () -> Void

    var body: some View {
        Button(action: openJourney) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppColor.medicalBlue)
                    .frame(width: 44, height: 44)
                    .background(AppColor.medicalBlue.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("View your health journey")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColor.ink)
                    Text("See your timeline, streaks, and saved health moments.")
                        .font(.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                }
                Spacer()
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct AppleHealthDashboardSummary: View {
    let dataProvider: DashboardDataProvider
    let openHealthKit: () -> Void

    var body: some View {
        if !HealthKitService().isAvailable {
            EmptyView()
        } else if UserHealthProfile.healthKitEnabled {
            VStack(alignment: .leading, spacing: 10) {
                HealthKitStatusCard(
                    status: .connected,
                    lastSyncAt: dataProvider.healthKitLastSyncAt,
                    isWriteSyncEnabled: UserHealthProfile.healthKitWriteEnabled,
                    manageAction: openHealthKit
                )

                if let snapshot = dataProvider.todaySnapshot, hasAnyData(snapshot) {
                    HStack(spacing: 10) {
                        if let steps = snapshot.steps {
                            miniMetric("Steps today", "\(Int(steps))", "figure.walk")
                        }
                        if let sleep = snapshot.sleepDurationHours {
                            miniMetric("Sleep", "\(String(format: "%.1f", sleep)) hrs", "bed.double.fill")
                        }
                        if let heartRate = snapshot.latestHeartRate ?? snapshot.restingHeartRate {
                            miniMetric("Heart", "\(Int(heartRate)) bpm", "heart.fill")
                        }
                    }
                } else {
                    Text("Apple Health is connected, but no recent data is available yet.")
                        .font(.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        } else {
            HealthKitStatusCard(
                status: .notConnected,
                lastSyncAt: nil,
                isWriteSyncEnabled: UserHealthProfile.healthKitWriteEnabled,
                manageAction: openHealthKit
            )
        }
    }

    private func hasAnyData(_ snapshot: HKDailySnapshot) -> Bool {
        snapshot.steps != nil || snapshot.sleepDurationHours != nil || snapshot.latestHeartRate != nil || snapshot.restingHeartRate != nil
    }

    private func miniMetric(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(AppColor.medicalBlue)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppColor.ink)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppColor.secondaryInk)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct WellnessInsightsCard: View {
    let insights: [WellnessInsight]

    var body: some View {
        if !insights.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                DashboardSectionTitle("Wellness insights")
                ForEach(insights.prefix(2)) { insight in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: icon(for: insight.category))
                            .foregroundStyle(AppColor.medicalBlue)
                            .frame(width: 34, height: 34)
                            .background(AppColor.medicalBlue.opacity(0.12))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(insight.message)
                                .font(.subheadline)
                                .foregroundStyle(AppColor.ink)
                            Text("Informational only")
                                .font(.caption)
                                .foregroundStyle(AppColor.secondaryInk)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private func icon(for category: WellnessInsight.InsightCategory) -> String {
        switch category {
        case .activity: return "figure.walk"
        case .sleep: return "bed.double.fill"
        case .heartRate: return "heart.fill"
        case .medicineCorrelation: return "pills.fill"
        case .recoveryMode: return "leaf.fill"
        case .general: return "sparkles"
        }
    }
}

private struct RecoveryDayBanner: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "leaf.fill")
                .foregroundStyle(Color.orange)
            Text(message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.ink)
            Spacer()
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColor.secondaryInk)
            }
            .frame(width: 44, height: 44)
        }
        .padding(14)
        .background(Color.orange.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ConnectHealthKitPrompt: View {
    let dismiss: () -> Void
    let open: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: open) {
                Label("Connect Apple Health for wellness insights →", systemImage: "heart.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            }
            .buttonStyle(.plain)
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColor.secondaryInk)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension View {
    func dashboardEntrance(didAppear: Bool, delay: Double) -> some View {
        opacity(didAppear ? 1 : 0)
            .offset(y: didAppear ? 0 : 14)
            .animation(.spring(response: 0.46, dampingFraction: 0.86).delay(delay), value: didAppear)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppRouter())
        .modelContainer(SampleData.previewContainer)
}
