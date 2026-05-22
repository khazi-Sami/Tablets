import PDFKit
import SwiftUI
import UIKit

struct DoctorReportPDFService {
    private let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
    private let margin: CGFloat = 42
    private let footer = "This report is generated from your saved logs and Apple Health data if connected. It is informational only and is not a medical diagnosis."

    func generatePDF(summary: DoctorVisitSummary, appointment: DoctorAppointment?) throws -> URL {
        let data = DoctorReportData(
            startDate: summary.startDate,
            endDate: summary.endDate,
            patientName: appointment?.patientName ?? UserHealthProfile.userName,
            patientAge: appointment?.patientAge ?? 0,
            medicines: summary.medicines,
            medicineLogs: [],
            healthRecords: [],
            symptoms: summary.symptomFrequency,
            periodSummary: UserHealthProfile.showWomensHealthCard ? summary.periodSummary : nil,
            appointments: appointment.map { [$0] } ?? [],
            notes: summary.notes,
            appleHealthSummary: nil
        )
        return try generatePDF(report: data)
    }

    func generatePDF(report: DoctorReportData) throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory.appending(path: "Tablets-Doctor-Report-\(UUID().uuidString).pdf")

        try renderer.writePDF(to: url) { context in
            var y = beginPage(context, title: "Tablets Doctor Report", report: report)

            if !report.hasClinicalData {
                section("Report Status", y: &y)
                paragraph("Not enough saved data yet. Start logging BP, sugar, medicines, and symptoms.", y: &y)
                drawFooter()
                return
            }

            section("Patient Profile", y: &y)
            row("Name", report.patientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Not added" : report.patientName, y: &y)
            row("Age", report.patientAge > 0 ? "\(report.patientAge)" : "Not added", y: &y)
            row("Date range", "\(report.startDate.mediumDateText) - \(report.endDate.mediumDateText)", y: &y)

            ensureSpace(&y, context: context, report: report)
            section("Current Medicines", y: &y)
            if report.medicines.isEmpty {
                bullet("No current medicines saved.", y: &y)
            } else {
                report.medicines.prefix(10).forEach { bullet("\($0.name) - \($0.dosage)", y: &y) }
            }

            ensureSpace(&y, context: context, report: report)
            section("Medicine Adherence", y: &y)
            let taken = report.medicineLogs.filter { $0.status == .taken }.count
            let missed = report.medicineLogs.filter { $0.status == .missed || $0.status == .skipped }.count
            row("Taken", "\(taken)", y: &y)
            row("Missed / skipped", "\(missed)", y: &y)
            drawBarChart(title: "Medicine adherence", values: adherenceValues(report.medicineLogs, start: report.startDate, end: report.endDate), y: &y)

            ensureSpace(&y, context: context, report: report)
            section("Blood Pressure Summary", y: &y)
            let bpRecords = report.healthRecords.filter { $0.type == .bloodPressure }
            row("Average BP", averageBP(bpRecords), y: &y)
            drawLineChart(title: "BP trend", points: bpRecords.map { DoctorReportChartPoint(date: $0.measuredAt, value: $0.value1, secondaryValue: $0.value2) }, y: &y)

            ensureSpace(&y, context: context, report: report)
            section("Sugar Summary", y: &y)
            let sugarRecords = report.healthRecords.filter { $0.type == .bloodSugar }
            row("Average sugar", average(sugarRecords.map(\.value1), unit: "mg/dL"), y: &y)
            drawLineChart(title: "Sugar trend", points: sugarRecords.map { DoctorReportChartPoint(date: $0.measuredAt, value: $0.value1, secondaryValue: nil) }, y: &y)

            ensureSpace(&y, context: context, report: report)
            section("Weight Trend", y: &y)
            let weights = report.healthRecords.filter { $0.type == .weight }
            drawLineChart(title: "Weight trend", points: weights.map { DoctorReportChartPoint(date: $0.measuredAt, value: $0.value1, secondaryValue: nil) }, y: &y)

            ensureSpace(&y, context: context, report: report)
            section("Symptoms", y: &y)
            if report.symptoms.isEmpty {
                bullet("No symptoms logged in this range.", y: &y)
            } else {
                report.symptoms.prefix(8).forEach { bullet("\($0.0): \($0.1)x", y: &y) }
            }

            if let periodSummary = report.periodSummary {
                ensureSpace(&y, context: context, report: report)
                section("Period Summary", y: &y)
                paragraph(periodSummary, y: &y)
            }

            ensureSpace(&y, context: context, report: report)
            section("Doctor Appointments and Notes", y: &y)
            if report.appointments.isEmpty {
                bullet("No doctor appointment notes saved in this range.", y: &y)
            } else {
                report.appointments.prefix(5).forEach {
                    bullet("\($0.appointmentDate.mediumDateText): \($0.doctorName.isEmpty ? "Doctor visit" : $0.doctorName) - \($0.notesForDoctor.isEmpty ? "No notes" : $0.notesForDoctor)", y: &y)
                }
            }
            if !report.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                paragraph("Patient notes: \(report.notes)", y: &y)
            }

            if let appleHealth = report.appleHealthSummary {
                ensureSpace(&y, context: context, report: report)
                section("Apple Health Summary", y: &y)
                row("Average steps", appleHealth.averageSteps.map { "\(Int($0)) steps" } ?? "No recent data", y: &y)
                row("Sleep average", appleHealth.averageSleepHours.map { String(format: "%.1f hrs", $0) } ?? "No recent data", y: &y)
                row("Latest heart rate", appleHealth.latestHeartRate.map { "\(Int($0)) bpm" } ?? "No recent data", y: &y)
                row("Resting heart rate", appleHealth.restingHeartRate.map { "\(Int($0)) bpm" } ?? "No recent data", y: &y)
            }

            drawFooter()
        }

        return url
    }

    private func beginPage(_ context: UIGraphicsPDFRendererContext, title: String, report: DoctorReportData) -> CGFloat {
        context.beginPage()
        draw(title, at: CGPoint(x: margin, y: 38), font: .boldSystemFont(ofSize: 24), color: UIColor(AppColor.medicalBlueDeep))
        draw("\(report.startDate.mediumDateText) - \(report.endDate.mediumDateText)", at: CGPoint(x: margin, y: 68), font: .systemFont(ofSize: 11), color: .darkGray)
        draw(footer, at: CGPoint(x: margin, y: 724), width: 528, font: .systemFont(ofSize: 9), color: .darkGray)
        return 96
    }

    private func ensureSpace(_ y: inout CGFloat, context: UIGraphicsPDFRendererContext, report: DoctorReportData, needed: CGFloat = 145) {
        if y + needed > 710 {
            y = beginPage(context, title: "Tablets Doctor Report", report: report)
        }
    }

    private func drawFooter() {
        draw(footer, at: CGPoint(x: margin, y: 724), width: 528, font: .systemFont(ofSize: 9), color: .darkGray)
    }

    private func section(_ text: String, y: inout CGFloat) {
        draw(text, at: CGPoint(x: margin, y: y), font: .boldSystemFont(ofSize: 15), color: UIColor(AppColor.medicalBlueDeep))
        y += 22
    }

    private func row(_ title: String, _ value: String, y: inout CGFloat) {
        draw(title, at: CGPoint(x: margin + 10, y: y), font: .boldSystemFont(ofSize: 11), color: .darkGray)
        draw(value, at: CGPoint(x: 190, y: y), width: 360, font: .systemFont(ofSize: 11), color: .black)
        y += 18
    }

    private func bullet(_ text: String, y: inout CGFloat) {
        draw("- \(text)", at: CGPoint(x: margin + 12, y: y), width: 500, font: .systemFont(ofSize: 11), color: .black)
        y += 16
    }

    private func paragraph(_ text: String, y: inout CGFloat) {
        draw(text, at: CGPoint(x: margin + 10, y: y), width: 500, font: .systemFont(ofSize: 11), color: .black)
        y += 42
    }

    private func drawLineChart(title: String, points: [DoctorReportChartPoint], y: inout CGFloat) {
        draw(title, at: CGPoint(x: margin + 10, y: y), font: .boldSystemFont(ofSize: 11), color: .darkGray)
        y += 16
        guard points.count >= 2 else {
            draw("Not enough data for trend.", at: CGPoint(x: margin + 10, y: y), font: .systemFont(ofSize: 11), color: .darkGray)
            y += 24
            return
        }

        let rect = CGRect(x: margin + 10, y: y, width: 500, height: 92)
        UIColor.systemGray5.setStroke()
        UIBezierPath(rect: rect).stroke()

        let values = points.flatMap { [$0.value] + [$0.secondaryValue].compactMap { $0 } }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        drawPolyline(points.map(\.value), in: rect, minValue: minValue, maxValue: maxValue, color: UIColor(AppColor.medicalBlueDeep))
        let secondary = points.compactMap(\.secondaryValue)
        if secondary.count == points.count {
            drawPolyline(secondary, in: rect, minValue: minValue, maxValue: maxValue, color: UIColor(AppColor.softRed))
        }
        y += 112
    }

    private func drawBarChart(title: String, values: [Double], y: inout CGFloat) {
        draw(title, at: CGPoint(x: margin + 10, y: y), font: .boldSystemFont(ofSize: 11), color: .darkGray)
        y += 16
        guard values.count >= 2 else {
            draw("Not enough data for trend.", at: CGPoint(x: margin + 10, y: y), font: .systemFont(ofSize: 11), color: .darkGray)
            y += 24
            return
        }
        let rect = CGRect(x: margin + 10, y: y, width: 500, height: 82)
        UIColor.systemGray5.setStroke()
        UIBezierPath(rect: rect).stroke()
        let barWidth = rect.width / CGFloat(values.count)
        UIColor(AppColor.mintGreenDeep).setFill()
        for (index, value) in values.enumerated() {
            let height = rect.height * CGFloat(min(max(value, 0), 1))
            let bar = CGRect(x: rect.minX + CGFloat(index) * barWidth + 3, y: rect.maxY - height, width: max(barWidth - 6, 4), height: height)
            UIBezierPath(rect: bar).fill()
        }
        y += 102
    }

    private func drawPolyline(_ values: [Double], in rect: CGRect, minValue: Double, maxValue: Double, color: UIColor) {
        guard values.count >= 2 else { return }
        let path = UIBezierPath()
        let range = max(maxValue - minValue, 1)
        for (index, value) in values.enumerated() {
            let x = rect.minX + CGFloat(index) / CGFloat(values.count - 1) * rect.width
            let scaled = (value - minValue) / range
            let yy = rect.maxY - CGFloat(scaled) * rect.height
            let point = CGPoint(x: x, y: yy)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        color.setStroke()
        path.lineWidth = 2
        path.stroke()
    }

    private func adherenceValues(_ logs: [MedicineLog], start: Date, end: Date) -> [Double] {
        let calendar = Calendar.current
        let dayCount = max(calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0, 1)
        return (0...dayCount).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: start)) else { return nil }
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let dayLogs = logs.filter { $0.scheduledTime >= day && $0.scheduledTime < next }
            guard !dayLogs.isEmpty else { return 0 }
            return Double(dayLogs.filter { $0.status == .taken }.count) / Double(dayLogs.count)
        }
    }

    private func averageBP(_ records: [HealthRecord]) -> String {
        let bp = records.filter { $0.value2 != nil }
        guard !bp.isEmpty else { return "No BP logs" }
        let systolic = bp.map(\.value1).reduce(0, +) / Double(bp.count)
        let diastolic = bp.compactMap(\.value2).reduce(0, +) / Double(bp.count)
        return "\(Int(systolic.rounded()))/\(Int(diastolic.rounded())) mmHg"
    }

    private func average(_ values: [Double], unit: String) -> String {
        guard !values.isEmpty else { return "No logs" }
        return "\(Int((values.reduce(0, +) / Double(values.count)).rounded())) \(unit)"
    }

    private func draw(_ text: String, at point: CGPoint, width: CGFloat = 520, font: UIFont, color: UIColor) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        text.draw(in: CGRect(x: point.x, y: point.y, width: width, height: 110), withAttributes: attributes)
    }
}

struct PDFPreviewView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(url: url)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
