import PDFKit
import SwiftUI
import UIKit

struct DoctorReportPDFService {
    func generatePDF(summary: DoctorVisitSummary, appointment: DoctorAppointment?) throws -> URL {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory.appending(path: "Tablets-Doctor-Report-\(UUID().uuidString).pdf")

        try renderer.writePDF(to: url) { context in
            context.beginPage()
            var y: CGFloat = 42

            draw("Tablets Medical Summary", at: CGPoint(x: 42, y: y), font: .boldSystemFont(ofSize: 24), color: UIColor(AppColor.medicalBlueDeep))
            y += 34
            draw(DoctorVisitSummary.disclaimer, at: CGPoint(x: 42, y: y), width: 528, font: .systemFont(ofSize: 10), color: .darkGray)
            y += 34

            if let appointment {
                section("Patient", y: &y)
                row("Name", appointment.patientName.isEmpty ? "Not added" : appointment.patientName, y: &y)
                row("Age", appointment.patientAge > 0 ? "\(appointment.patientAge)" : "Not added", y: &y)
                row("Doctor", appointment.doctorName.isEmpty ? "Not added" : appointment.doctorName, y: &y)
                row("Appointment", appointment.appointmentDate.mediumDateText, y: &y)
                row("Emergency contact", appointment.emergencyContact.isEmpty ? "Not added" : appointment.emergencyContact, y: &y)
                y += 8
            }

            section("Date Range", y: &y)
            row("From", summary.startDate.mediumDateText, y: &y)
            row("To", summary.endDate.mediumDateText, y: &y)
            y += 8

            section("Medicines", y: &y)
            row("Taken", "\(summary.medicineTakenCount)", y: &y)
            row("Missed / skipped", "\(summary.medicineMissedCount)", y: &y)
            for medicine in summary.medicines.prefix(8) {
                bullet("\(medicine.name) - \(medicine.dosage)", y: &y)
            }
            y += 8

            section("Health Readings", y: &y)
            row("Average BP", summary.averageBP, y: &y)
            row("Average sugar", summary.averageSugar, y: &y)
            row("Highest sugar", summary.highestSugar, y: &y)
            row("Lowest sugar", summary.lowestSugar, y: &y)
            y += 8

            section("Symptoms", y: &y)
            if summary.symptomFrequency.isEmpty {
                bullet("No symptoms logged in this range", y: &y)
            } else {
                for symptom in summary.symptomFrequency.prefix(8) {
                    bullet("\(symptom.0): \(symptom.1)x", y: &y)
                }
            }
            y += 8

            section("Women’s Health", y: &y)
            draw(summary.periodSummary, at: CGPoint(x: 42, y: y), width: 528, font: .systemFont(ofSize: 12), color: .black)
            y += 40

            section("Notes for Doctor", y: &y)
            draw(summary.notes.isEmpty ? "No notes added." : summary.notes, at: CGPoint(x: 42, y: y), width: 528, font: .systemFont(ofSize: 12), color: .black)
        }

        return url
    }

    private func section(_ text: String, y: inout CGFloat) {
        draw(text, at: CGPoint(x: 42, y: y), font: .boldSystemFont(ofSize: 15), color: UIColor(AppColor.medicalBlueDeep))
        y += 22
    }

    private func row(_ title: String, _ value: String, y: inout CGFloat) {
        draw(title, at: CGPoint(x: 52, y: y), font: .boldSystemFont(ofSize: 11), color: .darkGray)
        draw(value, at: CGPoint(x: 190, y: y), width: 360, font: .systemFont(ofSize: 11), color: .black)
        y += 18
    }

    private func bullet(_ text: String, y: inout CGFloat) {
        draw("• \(text)", at: CGPoint(x: 54, y: y), width: 500, font: .systemFont(ofSize: 11), color: .black)
        y += 16
    }

    private func draw(_ text: String, at point: CGPoint, width: CGFloat = 520, font: UIFont, color: UIColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        text.draw(in: CGRect(x: point.x, y: point.y, width: width, height: 100), withAttributes: attributes)
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
