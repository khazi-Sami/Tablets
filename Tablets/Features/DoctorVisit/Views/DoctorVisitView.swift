import Charts
import SwiftData
import SwiftUI

struct DoctorVisitView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medicine.name) private var medicines: [Medicine]
    @Query(sort: \MedicineLog.scheduledTime, order: .reverse) private var medicineLogs: [MedicineLog]
    @Query(sort: \HealthRecord.measuredAt, order: .reverse) private var healthRecords: [HealthRecord]
    @Query(sort: \WomensHealthDailyLog.date, order: .reverse) private var womensLogs: [WomensHealthDailyLog]
    @Query(sort: \PeriodCycle.startDate, order: .reverse) private var periodCycles: [PeriodCycle]
    @Query(sort: \DoctorAppointment.appointmentDate, order: .forward) private var appointments: [DoctorAppointment]
    @Query(sort: \DoctorVisitChecklistItem.createdAt) private var checklist: [DoctorVisitChecklistItem]
    @StateObject private var viewModel = DoctorVisitViewModel()

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        let summary = viewModel.summary(
            medicines: medicines,
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            periodCycles: periodCycles
        )

        NavigationStack {
            MedicalBackgroundView {
                ZStack {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: Spacing.large) {
                            hero(summary: summary)

                            rangePicker

                            LazyVGrid(columns: columns, spacing: Spacing.small) {
                                DoctorReportMetricCard(title: "Avg BP", value: summary.averageBP, systemImage: "heart.text.square.fill", color: AppColor.medicalBlue)
                                DoctorReportMetricCard(title: "Avg Sugar", value: summary.averageSugar, systemImage: "drop.fill", color: AppColor.lavenderDeep)
                                DoctorReportMetricCard(title: "Taken", value: "\(summary.medicineTakenCount)", systemImage: "checkmark.circle.fill", color: AppColor.mintGreenDeep)
                                DoctorReportMetricCard(title: "Missed", value: "\(summary.medicineMissedCount)", systemImage: "bell.badge.fill", color: AppColor.softRed)
                            }

                            chartCard

                            medicinesCard(summary: summary)

                            checklistCard

                            notesCard

                            privacyCard

                            CapsuleButton("Generate PDF Report", systemImage: "doc.richtext.fill", isLoading: viewModel.isGenerating) {
                                viewModel.generatePDF(summary: summary, appointment: appointments.first)
                            }

                            if let url = viewModel.generatedPDFURL {
                                pdfActions(url)
                            }
                        }
                        .padding(Spacing.medium)
                        .padding(.bottom, 140)
                    }

                    if viewModel.isGenerating {
                        ReportGeneratingOverlay()
                    }
                }
            }
            .navigationTitle("Doctor Visit")
            .onAppear {
                viewModel.ensureChecklist(checklist, modelContext: modelContext)
            }
            .sheet(isPresented: $viewModel.isShowingShareSheet) {
                if let url = viewModel.generatedPDFURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func hero(summary: DoctorVisitSummary) -> some View {
        PillCardContainer(style: .highlighted, padding: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(spacing: Spacing.medium) {
                    Image(systemName: "stethoscope.circle.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(AppColor.medicalBlue)
                    VStack(alignment: .leading) {
                        Text("Doctor Visit Mode")
                            .font(AppFont.title)
                            .foregroundStyle(AppColor.ink)
                        Text("\(summary.startDate.mediumDateText) - \(summary.endDate.mediumDateText)")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    }
                }

                Text("Prepare a clean, local summary of medicines, readings, symptoms, and notes before your appointment.")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryInk)
            }
        }
    }

    private var rangePicker: some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Report range")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                HStack {
                    ForEach(DoctorReportRange.allCases) { range in
                        Button {
                            viewModel.selectedRange = range
                            HapticsManager.selection()
                        } label: {
                            Text(range.title)
                                .font(AppFont.badge)
                                .foregroundStyle(viewModel.selectedRange == range ? .white : AppColor.medicalBlueDeep)
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .background(viewModel.selectedRange == range ? AppColor.medicalBlue : AppColor.medicalBlue.opacity(0.10))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if viewModel.selectedRange == .custom {
                    DatePicker("Start", selection: $viewModel.customStart, displayedComponents: .date)
                    DatePicker("End", selection: $viewModel.customEnd, displayedComponents: .date)
                }
            }
        }
    }

    private var chartCard: some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Recent health chart")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                Chart(healthRecords.prefix(12)) { record in
                    LineMark(
                        x: .value("Date", record.measuredAt),
                        y: .value("Value", record.value1)
                    )
                    .foregroundStyle(record.type == .bloodSugar ? AppColor.lavenderDeep : AppColor.medicalBlue)
                }
                .frame(height: 180)
            }
        }
    }

    private func medicinesCard(summary: DoctorVisitSummary) -> some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Current medicines")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)
                if summary.medicines.isEmpty {
                    Text("No active medicines saved.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                } else {
                    ForEach(summary.medicines.prefix(8)) { medicine in
                        HStack {
                            Image(systemName: "pills.fill")
                                .foregroundStyle(AppColor.medicalBlue)
                            Text("\(medicine.name) - \(medicine.dosage)")
                                .font(AppFont.body)
                                .foregroundStyle(AppColor.ink)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            DashboardSectionTitle("Ask before visit")
            ForEach(checklist) { item in
                DoctorChecklistRow(item: item)
            }
        }
    }

    private var notesCard: some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Notes for doctor")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)
                TextField("Write questions, symptoms, side effects, or report notes", text: $viewModel.notesForDoctor, axis: .vertical)
                    .font(AppFont.body)
                    .padding(Spacing.medium)
                    .background(AppColor.cream.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
            }
        }
    }

    private var privacyCard: some View {
        PillCardContainer(style: .lavender) {
            Label(DoctorVisitSummary.disclaimer, systemImage: "lock.shield.fill")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
        }
    }

    private func pdfActions(_ url: URL) -> some View {
        VStack(spacing: Spacing.small) {
            NavigationLink {
                PDFPreviewView(url: url)
                    .navigationTitle("Report Preview")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                CapsuleButton("Preview PDF", systemImage: "doc.text.magnifyingglass", style: .secondary) {}
            }
            .buttonStyle(.plain)

            CapsuleButton("Share Report", systemImage: "square.and.arrow.up") {
                viewModel.isShowingShareSheet = true
            }
        }
    }
}

#Preview {
    DoctorVisitView()
        .modelContainer(SampleData.previewContainer)
}
