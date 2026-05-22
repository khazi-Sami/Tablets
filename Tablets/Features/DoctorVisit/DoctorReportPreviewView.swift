import SwiftData
import SwiftUI
import UIKit

struct DoctorReportPreviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medicine.name) private var medicines: [Medicine]
    @Query(sort: \MedicineLog.scheduledTime, order: .reverse) private var medicineLogs: [MedicineLog]
    @Query(sort: \HealthRecord.measuredAt, order: .reverse) private var healthRecords: [HealthRecord]
    @Query(sort: \WomensHealthDailyLog.date, order: .reverse) private var womensLogs: [WomensHealthDailyLog]
    @Query(sort: \PeriodCycle.startDate, order: .reverse) private var periodCycles: [PeriodCycle]
    @Query(sort: \DoctorAppointment.appointmentDate, order: .forward) private var appointments: [DoctorAppointment]

    @State private var selectedRange: DoctorReportRange = .sevenDays
    @State private var customStart = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
    @State private var customEnd = Date()
    @State private var notes = ""
    @State private var generatedPDFURL: URL?
    @State private var isGenerating = false
    @State private var isShowingShareSheet = false
    @State private var errorMessage: String?

    private let builder = DoctorReportBuilder()
    private let pdfService = DoctorReportPDFService()

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        header
                        rangePicker
                        notesCard

                        CapsuleButton("Generate Preview", systemImage: "doc.richtext.fill", isLoading: isGenerating) {
                            Task { await generateReport() }
                        }
                        .frame(minHeight: 52)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.softRed)
                        }

                        if let generatedPDFURL {
                            PDFPreviewView(url: generatedPDFURL)
                                .frame(height: 420)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            HStack(spacing: 10) {
                                CapsuleButton("Share PDF", systemImage: "square.and.arrow.up") {
                                    isShowingShareSheet = true
                                }
                                CapsuleButton("Print", systemImage: "printer.fill", style: .secondary) {
                                    printPDF(generatedPDFURL)
                                }
                            }

                            Text("Use Share PDF to save this report to Files.")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.secondaryInk)
                        }

                        privacyFooter
                    }
                    .padding(Spacing.medium)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Doctor Report")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingShareSheet) {
                if let generatedPDFURL {
                    ShareSheet(items: [generatedPDFURL])
                }
            }
        }
    }

    private var header: some View {
        PillCardContainer(style: .highlighted, padding: Spacing.large) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Professional Doctor Report", systemImage: "doc.text.magnifyingglass")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)
                Text("Create a doctor-friendly PDF from saved logs. Apple Health is included only when connected.")
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
                            selectedRange = range
                            HapticsManager.selection()
                        } label: {
                            Text(range.title)
                                .font(AppFont.badge)
                                .foregroundStyle(selectedRange == range ? .white : AppColor.medicalBlueDeep)
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .background(selectedRange == range ? AppColor.medicalBlue : AppColor.medicalBlue.opacity(0.10))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if selectedRange == .custom {
                    DatePicker("Start", selection: $customStart, displayedComponents: .date)
                    DatePicker("End", selection: $customEnd, displayedComponents: .date)
                }
            }
        }
    }

    private var notesCard: some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Extra notes")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)
                TextField("Questions, symptoms, side effects, or context for your doctor", text: $notes, axis: .vertical)
                    .font(AppFont.body)
                    .padding(Spacing.medium)
                    .background(AppColor.cream.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
            }
        }
    }

    private var privacyFooter: some View {
        Label("This report is generated from your saved logs and Apple Health data if connected. It is informational only and is not a medical diagnosis.", systemImage: "lock.shield.fill")
            .font(AppFont.caption)
            .foregroundStyle(AppColor.secondaryInk)
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func generateReport() async {
        isGenerating = true
        errorMessage = nil
        let report = await builder.build(
            range: selectedRange,
            customStart: customStart,
            customEnd: customEnd,
            medicines: medicines,
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            periodCycles: periodCycles,
            appointments: appointments,
            notes: notes
        )

        do {
            generatedPDFURL = try pdfService.generatePDF(report: report)
            HapticsManager.notification(.success)
        } catch {
            errorMessage = "Could not generate PDF report."
            HapticsManager.notification(.error)
        }
        isGenerating = false
    }

    private func printPDF(_ url: URL) {
        guard UIPrintInteractionController.isPrintingAvailable else { return }
        let controller = UIPrintInteractionController.shared
        controller.printingItem = url
        controller.present(animated: true)
    }
}
