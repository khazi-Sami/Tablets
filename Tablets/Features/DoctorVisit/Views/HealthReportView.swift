import SwiftData
import SwiftUI
import UIKit

struct HealthReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medicine.name) private var medicines: [Medicine]
    @Query(sort: \MedicineLog.scheduledTime, order: .reverse) private var medicineLogs: [MedicineLog]
    @Query(sort: \HealthRecord.measuredAt, order: .reverse) private var healthRecords: [HealthRecord]
    @Query(sort: \WomensHealthDailyLog.date, order: .reverse) private var womensLogs: [WomensHealthDailyLog]
    @Query(sort: \PeriodCycle.startDate, order: .reverse) private var periodCycles: [PeriodCycle]
    @Query(sort: \PregnancyProfile.createdAt, order: .reverse) private var pregnancyProfiles: [PregnancyProfile]
    @Query(sort: \PregnancySymptomLog.loggedAt, order: .reverse) private var pregnancySymptoms: [PregnancySymptomLog]
    @Query(sort: \DoctorAppointment.appointmentDate, order: .reverse) private var appointments: [DoctorAppointment]

    @State private var selectedRange: HealthReportRange = .thirtyDays
    @State private var customStart = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
    @State private var customEnd = Date()
    @State private var generatedURL: URL?
    @State private var isGenerating = false
    @State private var isShowingShareSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        header
                        rangeCard
                        previewCard

                        CapsuleButton("Generate Report", systemImage: "doc.richtext.fill", isLoading: isGenerating) {
                            Task { await generate() }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.softRed)
                        }

                        if let generatedURL {
                            PDFPreviewView(url: generatedURL)
                                .frame(height: 420)
                                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))

                            HStack(spacing: Spacing.small) {
                                CapsuleButton("Share", systemImage: "square.and.arrow.up") {
                                    isShowingShareSheet = true
                                }
                                CapsuleButton("Print", systemImage: "printer.fill", style: .secondary) {
                                    printPDF(generatedURL)
                                }
                            }

                            Text("Use Share to save the PDF to Files.")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.secondaryInk)
                        }

                        Label("Generated from saved logs only. Informational only. Not medical advice.", systemImage: "lock.shield.fill")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                            .padding(.bottom, 80)
                    }
                    .padding(Spacing.medium)
                }
            }
            .navigationTitle("Health Report")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingShareSheet) {
                if let generatedURL {
                    ShareSheet(items: [generatedURL])
                }
            }
        }
    }

    private var header: some View {
        PillCardContainer(style: .highlighted, padding: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Label("Personal Health Report", systemImage: "doc.text.magnifyingglass")
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)
                Text("Create a local PDF for your doctor from medicines, health logs, women’s health, pregnancy, and visit notes.")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryInk)
            }
        }
    }

    private var rangeCard: some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Date range")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.small) {
                    ForEach(HealthReportRange.allCases) { range in
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

    private var previewCard: some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Included sections")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                reportRow("Blood Pressure", count: filteredHealth(.bloodPressure).count, icon: "heart.text.square.fill")
                reportRow("Blood Sugar", count: filteredHealth(.bloodSugar).count, icon: "drop.fill")
                reportRow("Medicines", count: medicines.filter(\.isActive).count, icon: "pills.fill")
                reportRow("Symptoms", count: symptomCount, icon: "cross.case.fill")
                reportRow("Women’s Health", count: filteredWomens.count + filteredPeriods.count, icon: "heart.circle.fill")
                reportRow("Pregnancy", count: pregnancyProfiles.filter(\.isActive).count + filteredPregnancySymptoms.count, icon: "figure.maternity")
                reportRow("Doctor Visits", count: filteredAppointments.count, icon: "stethoscope")
            }
        }
    }

    private func reportRow(_ title: String, count: Int, icon: String) -> some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: icon)
                .foregroundStyle(AppColor.medicalBlue)
                .frame(width: 28)
            Text("\(title) — \(count)")
                .font(AppFont.body)
                .foregroundStyle(AppColor.ink)
            Spacer()
        }
    }

    private var dates: (Date, Date) {
        let end = selectedRange == .custom ? customEnd : Date()
        let start: Date
        switch selectedRange {
        case .sevenDays:
            start = Calendar.current.date(byAdding: .day, value: -7, to: end) ?? end
        case .thirtyDays:
            start = Calendar.current.date(byAdding: .day, value: -30, to: end) ?? end
        case .threeMonths:
            start = Calendar.current.date(byAdding: .month, value: -3, to: end) ?? end
        case .custom:
            start = customStart
        }
        return (min(start, end), max(start, end))
    }

    private func filteredHealth(_ type: HealthRecordType) -> [HealthRecord] {
        let range = dates
        return healthRecords.filter { $0.type == type && $0.measuredAt >= range.0 && $0.measuredAt <= range.1 }
    }

    private var filteredWomens: [WomensHealthDailyLog] {
        let range = dates
        return womensLogs.filter { $0.date >= range.0 && $0.date <= range.1 }
    }

    private var filteredPeriods: [PeriodCycle] {
        let range = dates
        return periodCycles.filter { $0.startDate <= range.1 && ($0.endDate ?? .now) >= range.0 }
    }

    private var filteredPregnancySymptoms: [PregnancySymptomLog] {
        let range = dates
        return pregnancySymptoms.filter { $0.loggedAt >= range.0 && $0.loggedAt <= range.1 }
    }

    private var filteredAppointments: [DoctorAppointment] {
        let range = dates
        return appointments.filter { $0.appointmentDate >= range.0 && $0.appointmentDate <= range.1 }
    }

    private var symptomCount: Int {
        healthRecords.flatMap(\.symptoms).count + filteredWomens.flatMap(\.symptoms).count + filteredPregnancySymptoms.flatMap(\.symptoms).count
    }

    private func generate() async {
        isGenerating = true
        errorMessage = nil
        let range = dates
        let input = HealthReportInput(
            startDate: range.0,
            endDate: range.1,
            patientName: UserHealthProfile.userName,
            patientAge: appointments.first?.patientAge ?? 0,
            patientGender: UserHealthProfile.gender.title,
            medicines: medicines,
            medicineLogs: medicineLogs.filter { $0.scheduledTime >= range.0 && $0.scheduledTime <= range.1 },
            healthRecords: healthRecords.filter { $0.measuredAt >= range.0 && $0.measuredAt <= range.1 },
            womensLogs: filteredWomens,
            periodCycles: filteredPeriods,
            pregnancyProfiles: pregnancyProfiles,
            pregnancySymptoms: filteredPregnancySymptoms,
            appointments: filteredAppointments,
            appleHealthSummary: nil
        )

        do {
            generatedURL = try HealthReportGenerator().generate(input: input)
            HapticsManager.notification(.success)
        } catch {
            errorMessage = "Could not generate report."
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

private enum HealthReportRange: String, CaseIterable, Identifiable {
    case sevenDays
    case thirtyDays
    case threeMonths
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sevenDays: return "7 days"
        case .thirtyDays: return "30 days"
        case .threeMonths: return "3 months"
        case .custom: return "Custom"
        }
    }
}
