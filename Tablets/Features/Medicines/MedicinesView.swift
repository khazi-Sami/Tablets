import SwiftData
import SwiftUI
import WidgetKit

struct MedicinesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medicine.name) private var medicines: [Medicine]
    @StateObject private var viewModel = MedicinesViewModel()
    @State private var reminderMedicine: Medicine?
    @State private var editingMedicine: Medicine?
    @State private var searchText = ""
    @State private var filter: MedicineFilter = .active
    #if DEBUG
    @State private var pendingNotifications: [MedicineNotificationScheduler.PendingMedicineNotification] = []
    @State private var isShowingPendingNotifications = false
    #endif

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                Group {
                    if medicines.isEmpty {
                        VStack(spacing: Spacing.medium) {
                            VoiceCoachingCard(
                                message: "No medicines saved yet.",
                                command: "Add medicine"
                            )

                            EmptyStateView(
                                title: "No medicines",
                                message: "Create your medicine list and reminders.",
                                systemImage: "pills",
                                actionTitle: "Add Medicine"
                            ) {
                                viewModel.isPresentingAddMedicine = true
                            }
                        }
                        .padding(Spacing.medium)
                    } else {
                        List {
                            searchAndFilter
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)

                            ForEach(filteredMedicines) { medicine in
                                MedicineRowView(
                                    medicine: medicine,
                                    status: status(for: medicine),
                                    nextDose: nextDose(for: medicine),
                                    onEdit: { editingMedicine = medicine },
                                    onMarkTaken: { markTaken(medicine) }
                                )
                                .onTapGesture {
                                    HapticsManager.selection()
                                    reminderMedicine = medicine
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions {
                                    Button {
                                        editingMedicine = medicine
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(AppColor.medicalBlue)

                                    Button(role: .destructive) {
                                        viewModel.delete(medicine, modelContext: modelContext)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }

                            Color.clear
                                .frame(height: 90)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .contentMargins(.vertical, Spacing.small, for: .scrollContent)
                        .scrollDismissesKeyboard(.interactively)
                    }
                }
                .dismissKeyboardOnTap()
            }
            .navigationTitle("Medicines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isPresentingAddMedicine = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Medicine")
                }

                #if DEBUG
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await loadPendingNotifications() }
                    } label: {
                        Image(systemName: "bell.badge")
                    }
                    .accessibilityLabel("Show Pending Notifications")
                }
                #endif
            }
            .sheet(isPresented: $viewModel.isPresentingAddMedicine) {
                AddMedicineView()
            }
            .sheet(item: $reminderMedicine) { medicine in
                MedicineReminderView(medicine: medicine)
            }
            .sheet(item: $editingMedicine) { medicine in
                EditMedicineView(medicine: medicine)
            }
            #if DEBUG
            .sheet(isPresented: $isShowingPendingNotifications) {
                PendingNotificationsDebugView(notifications: pendingNotifications)
            }
            #endif
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openAddMedicine)) { _ in
                viewModel.isPresentingAddMedicine = true
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openMedicineReminder)) { notification in
                if let idString = notification.userInfo?["medicineID"] as? String,
                   let id = UUID(uuidString: idString),
                   let medicine = medicines.first(where: { $0.id == id }) {
                    reminderMedicine = medicine
                } else {
                    reminderMedicine = medicines.first(where: \.isActive) ?? medicines.first
                }
            }
            .alert("Something went wrong", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var filteredMedicines: [Medicine] {
        medicines.filter { medicine in
            let matchesSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                medicine.name.localizedCaseInsensitiveContains(searchText) ||
                medicine.dosage.localizedCaseInsensitiveContains(searchText)

            guard matchesSearch else { return false }

            switch filter {
            case .active:
                return medicine.isActive
            case .dueToday:
                return medicine.isActive && nextDose(for: medicine) != nil
            case .lowStock:
                return medicine.isActive && medicine.stockCount <= medicine.lowStockAlertCount
            case .all:
                return true
            }
        }
    }

    private var searchAndFilter: some View {
        VStack(spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColor.secondaryInk)
                TextField("Search medicines", text: $searchText)
                    .font(AppFont.body)
            }
            .padding(Spacing.medium)
            .background(AppColor.warmWhite.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))

            Picker("Filter", selection: $filter) {
                ForEach(MedicineFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func nextDose(for medicine: Medicine) -> Date? {
        guard medicine.isActive else { return nil }
        let now = Date()
        let calendar = Calendar.current
        let todayTimes = medicine.times
            .map { time -> Date in
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                return calendar.date(from: components) ?? time
            }
            .sorted()

        return todayTimes.first { scheduledTime in
            hasLogged(medicine: medicine, scheduledTime: scheduledTime) == false &&
            calendar.isDate(scheduledTime, inSameDayAs: now)
        } ?? todayTimes.first(where: { $0 > now })
    }

    private func status(for medicine: Medicine) -> MedicineTodayStatus {
        guard medicine.isActive else { return .inactive }
        guard let nextDose = nextDose(for: medicine) else {
            return medicine.times.isEmpty ? .noDoseToday : .taken
        }
        if hasLogged(medicine: medicine, scheduledTime: nextDose) {
            return .taken
        }
        return nextDose < Date() ? .overdue : .pending
    }

    private func hasLogged(medicine: Medicine, scheduledTime: Date) -> Bool {
        let key = AdaptiveReminderTimeKey.key(from: scheduledTime)
        return medicine.logs.contains { log in
            Calendar.current.isDate(log.scheduledTime, inSameDayAs: scheduledTime) &&
            AdaptiveReminderTimeKey.key(from: log.scheduledTime) == key &&
            (log.status == .taken || log.status == .skipped || log.status == .snoozed)
        }
    }

    private func markTaken(_ medicine: Medicine) {
        guard let scheduledTime = nextDose(for: medicine) else { return }
        let log = MedicineLog(
            medicine: medicine,
            scheduledTime: scheduledTime,
            takenTime: Date(),
            status: .taken
        )
        modelContext.insert(log)

        do {
            try modelContext.save()
            MissedDoseFollowUpManager(modelContext: modelContext).cancelFollowUp(for: medicine, scheduledAt: scheduledTime)
            WidgetCenter.shared.reloadAllTimelines()
            HapticsManager.notification(.success)
        } catch {
            viewModel.errorMessage = error.localizedDescription
            HapticsManager.notification(.error)
        }
    }

    #if DEBUG
    private func loadPendingNotifications() async {
        pendingNotifications = await MedicineNotificationScheduler().pendingMedicineNotifications()
        isShowingPendingNotifications = true
    }
    #endif
}

private struct MedicineRowView: View {
    let medicine: Medicine
    let status: MedicineTodayStatus
    let nextDose: Date?
    let onEdit: () -> Void
    let onMarkTaken: () -> Void

    var body: some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack(spacing: Spacing.medium) {
                    MedicineBottleBadge(type: medicine.medicineType)

                    VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                        HStack(spacing: Spacing.xSmall) {
                            Text(medicine.name)
                                .font(AppFont.sectionTitle)
                                .foregroundStyle(AppColor.ink)
                                .lineLimit(2)

                            if !medicine.isActive {
                                Text("Inactive")
                                    .font(AppFont.badge)
                                    .foregroundStyle(AppColor.secondaryInk)
                                    .padding(.horizontal, Spacing.xSmall)
                                    .padding(.vertical, 4)
                                    .background(AppColor.hairline.opacity(0.35))
                                    .clipShape(Capsule())
                            }
                        }

                        Text("\(medicine.dosage) • \(medicine.frequencyType.title)")
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.secondaryInk)

                        Text(nextDoseText)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.tertiaryInk)
                    }

                    Spacer()

                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColor.medicalBlueDeep)
                            .frame(width: 44, height: 44)
                            .background(AppColor.medicalBlue.opacity(0.10))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit \(medicine.name)")
                }

                HStack(spacing: Spacing.xSmall) {
                    MedicineStatusChip(status: status)
                    StockChip(medicine: medicine)
                    Spacer()

                    if status == .pending || status == .overdue {
                        Button(action: onMarkTaken) {
                            Label("Mark Taken", systemImage: "checkmark.circle.fill")
                                .font(AppFont.badge)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.small)
                                .frame(minHeight: 44)
                                .background(AppColor.mintGreenDeep)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, Spacing.xxSmall)
    }

    private var nextDoseText: String {
        guard medicine.isActive else { return "Reminders paused" }
        guard let nextDose else { return "No dose today" }
        return "Next: \(nextDose.formatted(date: .omitted, time: .shortened))"
    }
}

private struct MedicineBottleBadge: View {
    let type: MedicineType

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(AppGradient.lavenderWash)
                .frame(width: 54, height: 64)

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(AppColor.medicalBlue.opacity(0.20))
                .frame(width: 24, height: 8)
                .offset(y: -29)

            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColor.medicalBlue)
        }
        .accessibilityHidden(true)
    }

    private var icon: String {
        switch type {
        case .tablet: return "pills.fill"
        case .capsule: return "capsule.fill"
        case .syrup: return "cross.vial.fill"
        case .injection: return "syringe.fill"
        case .drops: return "drop.fill"
        case .powder: return "sparkles"
        }
    }
}

private enum MedicineFilter: String, CaseIterable, Identifiable {
    case active
    case dueToday
    case lowStock
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: return "Active"
        case .dueToday: return "Due"
        case .lowStock: return "Low"
        case .all: return "All"
        }
    }
}

private enum MedicineTodayStatus: Equatable {
    case taken
    case pending
    case overdue
    case noDoseToday
    case inactive
}

private struct MedicineStatusChip: View {
    let status: MedicineTodayStatus

    var body: some View {
        Label(title, systemImage: icon)
            .font(AppFont.badge)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.xSmall)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var title: String {
        switch status {
        case .taken: return "Taken"
        case .pending: return "Pending"
        case .overdue: return "Overdue"
        case .noDoseToday: return "No dose today"
        case .inactive: return "Inactive"
        }
    }

    private var icon: String {
        switch status {
        case .taken: return "checkmark.circle.fill"
        case .pending: return "hourglass"
        case .overdue: return "exclamationmark.circle.fill"
        case .noDoseToday: return "circle"
        case .inactive: return "pause.circle.fill"
        }
    }

    private var color: Color {
        switch status {
        case .taken: return AppColor.mintGreenDeep
        case .pending: return Color.orange
        case .overdue: return AppColor.softRed
        case .noDoseToday, .inactive: return AppColor.secondaryInk
        }
    }
}

private struct StockChip: View {
    let medicine: Medicine

    var body: some View {
        Label(text, systemImage: medicine.stockCount <= medicine.lowStockAlertCount ? "shippingbox.fill" : "shippingbox")
            .font(AppFont.badge)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.xSmall)
            .padding(.vertical, 6)
            .background(color.opacity(0.11))
            .clipShape(Capsule())
    }

    private var text: String {
        medicine.stockCount <= medicine.lowStockAlertCount ? "Low: \(medicine.stockCount)" : "Stock: \(medicine.stockCount)"
    }

    private var color: Color {
        medicine.stockCount <= medicine.lowStockAlertCount ? Color.orange : AppColor.secondaryInk
    }
}

#if DEBUG
private struct PendingNotificationsDebugView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [MedicineNotificationScheduler.PendingMedicineNotification]
    @State private var authorizationStatus = "Checking"
    @State private var testMessage: String?

    init(notifications: [MedicineNotificationScheduler.PendingMedicineNotification]) {
        _notifications = State(initialValue: notifications)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Authorization") {
                    LabeledContent("Status", value: authorizationStatus)
                    Button {
                        Task { await sendTestNotification() }
                    } label: {
                        Label("Send Test Notification in 10 Seconds", systemImage: "bell.badge.fill")
                    }
                    if let testMessage {
                        Text(testMessage)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    }
                }

                Section("Pending Requests") {
                    if notifications.isEmpty {
                        Text("No pending notifications.")
                            .foregroundStyle(AppColor.secondaryInk)
                    } else {
                        ForEach(notifications) { notification in
                            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                                Text(notification.title)
                                    .font(AppFont.bodyStrong)
                                diagnosticRow("Identifier", notification.id)
                                diagnosticRow("Body", notification.body)
                                diagnosticRow("Trigger", notification.triggerType)
                                diagnosticRow("Next fire", notification.fireDate?.formatted(date: .abbreviated, time: .standard) ?? "No fire date")
                                diagnosticRow("Repeats", notification.repeats ? "true" : "false")
                                diagnosticRow("Medicine ID", notification.medicineID)
                                diagnosticRow("Scheduled time", notification.scheduledTime)
                                diagnosticRow("Time key", notification.scheduledTimeKey)
                                diagnosticRow("Sound", notification.sound)
                                diagnosticRow("Authorization", notification.authorizationStatus)
                            }
                            .padding(.vertical, Spacing.xSmall)
                        }
                    }
                }
            }
            .navigationTitle("Pending Notifications")
            .task {
                await refreshDiagnostics()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Refresh") {
                        Task { await refreshDiagnostics() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func diagnosticRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.tertiaryInk)
            Text(value)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
                .textSelection(.enabled)
        }
    }

    private func sendTestNotification() async {
        let success = await MedicineNotificationScheduler().scheduleTestNotificationIn10Seconds()
        testMessage = success ? "Test notification scheduled. Lock the phone or leave the app to verify sound." : "Notifications are not authorized. Open iOS Settings and allow notifications for Tablets."
        await refreshDiagnostics()
    }

    private func refreshDiagnostics() async {
        let scheduler = MedicineNotificationScheduler()
        authorizationStatus = await scheduler.authorizationStatusDescription()
        notifications = await scheduler.pendingMedicineNotifications()
    }
}
#endif

#Preview {
    MedicinesView()
        .modelContainer(SampleData.previewContainer)
}
