import Combine
import Foundation
import SwiftData
import UIKit

@MainActor
final class DoctorVisitViewModel: ObservableObject {
    @Published var selectedRange: DoctorReportRange = .sevenDays
    @Published var customStart = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
    @Published var customEnd = Date()
    @Published var notesForDoctor = ""
    @Published var generatedPDFURL: URL?
    @Published var isGenerating = false
    @Published var isShowingShareSheet = false
    @Published var errorMessage: String?

    private let summaryService = DoctorVisitSummaryService()
    private let pdfService = DoctorReportPDFService()

    let defaultChecklist = [
        "What symptoms did you notice?",
        "Did you miss any medicine?",
        "Any side effects?",
        "Any new reports?",
        "Questions to ask doctor"
    ]

    func summary(medicines: [Medicine], medicineLogs: [MedicineLog], healthRecords: [HealthRecord], womensLogs: [WomensHealthDailyLog], periodCycles: [PeriodCycle]) -> DoctorVisitSummary {
        summaryService.makeSummary(
            range: selectedRange,
            customStart: customStart,
            customEnd: customEnd,
            medicines: medicines,
            medicineLogs: medicineLogs,
            healthRecords: healthRecords,
            womensLogs: womensLogs,
            periodCycles: periodCycles,
            notes: notesForDoctor
        )
    }

    func ensureChecklist(_ items: [DoctorVisitChecklistItem], modelContext: ModelContext) {
        guard items.isEmpty else { return }
        defaultChecklist.forEach { modelContext.insert(DoctorVisitChecklistItem(title: $0)) }
        try? modelContext.save()
    }

    func generatePDF(summary: DoctorVisitSummary, appointment: DoctorAppointment?) {
        isGenerating = true
        do {
            generatedPDFURL = try pdfService.generatePDF(summary: summary, appointment: appointment)
            HapticsManager.notification(.success)
        } catch {
            errorMessage = "Could not generate PDF report."
            HapticsManager.notification(.error)
        }
        isGenerating = false
    }
}
