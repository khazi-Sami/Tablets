import SwiftData
import SwiftUI

struct MedicineTodayWidget: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = MedicineTodayWidgetViewModel()

    let addMedicine: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            weeklySummary
            content
            adaptiveInsight
            alerts
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        .task {
            await viewModel.refresh(modelContext: modelContext)
            viewModel.startAutoRefresh(modelContext: modelContext)
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await viewModel.refresh(modelContext: modelContext) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .healthDataDidUpdate)) { _ in
            Task { await viewModel.refresh(modelContext: modelContext) }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "pills.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(AppColor.medicalBlue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("Today’s medicines")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }

            Spacer()
        }
    }

    private var subtitle: String {
        if !viewModel.hasActiveMedicines { return "Start adding medicines to see your routine." }
        if !viewModel.hasScheduledDosesToday { return "No medicines scheduled today." }
        if viewModel.allDosesTakenToday { return "All medicines taken today." }
        if let next = viewModel.nextPendingDose {
            return "Next: \(next.medicineName) at \(next.scheduledTime.formatted(date: .omitted, time: .shortened))"
        }
        return "Every dose logged helps your routine."
    }

    private var weeklySummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.weeklyAdherence.totalCount == 0 {
                Text("Start adding medicines to see your weekly routine.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text("You took \(viewModel.weeklyAdherence.takenCount) of \(viewModel.weeklyAdherence.totalCount) medicines this week")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColor.ink)
                    Spacer()
                    Text("\(Int(viewModel.weeklyAdherence.percent * 100))%")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppColor.medicalBlueDeep)
                }

                ProgressView(value: viewModel.weeklyAdherence.percent)
                    .tint(AppColor.mintGreen)

                HStack(spacing: 8) {
                    if let bestDay = viewModel.weeklyAdherence.bestDayName {
                        summaryChip("Best day: \(bestDay)", icon: "sparkles", color: AppColor.mintGreen)
                    }
                    if viewModel.weeklyAdherence.missedCount > 0 {
                        summaryChip("\(viewModel.weeklyAdherence.missedCount) needs attention", icon: "clock.badge.exclamationmark", color: Color.orange)
                    }
                }
            }
        }
        .padding(14)
        .background(AppColor.medicalBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasActiveMedicines {
            emptyState(
                title: "No medicines added yet",
                message: "Add your first medicine to build a daily routine.",
                buttonTitle: "Add your first medicine",
                action: addMedicine
            )
        } else if !viewModel.hasScheduledDosesToday {
            emptyState(
                title: "No medicines scheduled today",
                message: "Take it easy. Your routine is clear for today.",
                buttonTitle: nil,
                action: nil
            )
        } else if viewModel.allDosesTakenToday {
            allTakenState
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.todayDoses) { dose in
                    DoseTimelineRow(
                        dose: dose,
                        isSaving: viewModel.isSavingDoseID == dose.id,
                        markTaken: {
                            Task { await viewModel.markTaken(dose, modelContext: modelContext) }
                        }
                    )
                }
            }
        }

        if let error = viewModel.errorMessage {
            Text(error)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.softRed)
                .padding(.top, 2)
        }
    }

    private var allTakenState: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColor.mintGreen)
                .frame(width: 48, height: 48)
                .background(AppColor.mintGreen.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("All medicines taken today")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
                Text("Great week. Keep going with your routine.")
                    .font(.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }
            Spacer()
        }
        .padding(14)
        .background(AppColor.mintGreen.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var adaptiveInsight: some View {
        Label {
            Text(viewModel.nextPendingDose?.adaptiveInsight ?? "Keep taking medicines. After a few doses, BanyAI will learn your routine.")
                .font(.caption)
                .foregroundStyle(AppColor.secondaryInk)
        } icon: {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(AppColor.lavenderDeep)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.lavenderDeep.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var alerts: some View {
        if viewModel.overdueCount > 0 || !viewModel.lowStockMedicines.isEmpty || viewModel.missedSkippedTodayCount > 0 {
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.overdueCount > 0 {
                    alertLine(icon: "clock.badge.exclamationmark", text: "\(viewModel.overdueCount) medicine\(viewModel.overdueCount == 1 ? "" : "s") waiting to be logged", color: Color.orange)
                }
                ForEach(viewModel.lowStockMedicines.prefix(3)) { medicine in
                    alertLine(icon: "exclamationmark.triangle.fill", text: "\(medicine.name): only \(medicine.stockCount) left", color: Color.yellow)
                }
            }
        }
    }

    private func emptyState(title: String, message: String, buttonTitle: String?, action: (() -> Void)?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.ink)
            Text(message)
                .font(.caption)
                .foregroundStyle(AppColor.secondaryInk)
            if let buttonTitle, let action {
                Button(action: action) {
                    Label(buttonTitle, systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 46)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.medicalBlue)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.medicalBlue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func summaryChip(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppColor.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.opacity(0.16))
            .clipShape(Capsule())
    }

    private func alertLine(icon: String, text: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppColor.ink)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct DoseTimelineRow: View {
    let dose: TodayMedicineDose
    let isSaving: Bool
    let markTaken: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(spacing: 4) {
                Text(dose.scheduledTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColor.ink)
                Circle()
                    .fill(statusColor.opacity(0.25))
                    .frame(width: 8, height: 8)
            }
            .frame(width: 58)

            Image(systemName: statusIcon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(statusColor)
                .frame(width: 34, height: 34)
                .background(statusColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(dose.medicineName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
                    .lineLimit(1)
                Text("\(dose.dosage) · \(dose.medicineType.title)")
                    .font(.caption)
                    .foregroundStyle(AppColor.secondaryInk)
                Text(statusText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(statusColor)
                if let adaptiveInsight = dose.adaptiveInsight {
                    Text(adaptiveInsight)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColor.lavenderDeep)
                }
            }

            Spacer(minLength: 8)

            if dose.status == .pending || dose.status == .overdue || dose.status == .notLogged {
                Button(action: markTaken) {
                    if isSaving {
                        ProgressView()
                            .frame(width: 28, height: 28)
                    } else {
                        Text("Mark Taken")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .frame(minHeight: 44)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.mintGreen)
                .disabled(isSaving)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var statusIcon: String {
        switch dose.status {
        case .taken: return "checkmark.circle.fill"
        case .pending: return "hourglass"
        case .overdue: return "exclamationmark.circle.fill"
        case .skipped: return "xmark.circle.fill"
        case .snoozed: return "clock.fill"
        case .notLogged: return "circle"
        }
    }

    private var statusColor: Color {
        switch dose.status {
        case .taken: return AppColor.mintGreen
        case .pending: return Color.orange
        case .overdue: return AppColor.softRed
        case .skipped: return Color.gray
        case .snoozed: return AppColor.lavenderDeep
        case .notLogged: return Color.gray
        }
    }

    private var statusText: String {
        switch dose.status {
        case .taken:
            if let taken = dose.actualTakenTime {
                return "Taken at \(taken.formatted(date: .omitted, time: .shortened))"
            }
            return "Taken"
        case .pending:
            return dose.minutesUntilDue <= 0 ? "Due now" : "Due in \(dose.minutesUntilDue) min"
        case .overdue:
            return dose.minutesOverdue <= 0 ? "Waiting to be logged" : "\(dose.minutesOverdue) min overdue"
        case .skipped:
            return "Skipped"
        case .snoozed:
            return "Snoozed"
        case .notLogged:
            return "Not logged yet"
        }
    }
}
