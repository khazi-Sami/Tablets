import Foundation
import SwiftData

@Model
final class DoctorAppointment {
    @Attribute(.unique) var id: UUID
    var doctorName: String
    var clinicName: String
    var appointmentDate: Date
    var patientName: String
    var patientAge: Int
    var emergencyContact: String
    var notesForDoctor: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        doctorName: String = "",
        clinicName: String = "",
        appointmentDate: Date = .now,
        patientName: String = "",
        patientAge: Int = 0,
        emergencyContact: String = "",
        notesForDoctor: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.doctorName = doctorName
        self.clinicName = clinicName
        self.appointmentDate = appointmentDate
        self.patientName = patientName
        self.patientAge = patientAge
        self.emergencyContact = emergencyContact
        self.notesForDoctor = notesForDoctor
        self.createdAt = createdAt
    }
}

@Model
final class DoctorVisitChecklistItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var answer: String
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        answer: String = "",
        isCompleted: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.answer = answer
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

enum DoctorReportRange: String, CaseIterable, Identifiable {
    case sevenDays
    case thirtyDays
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sevenDays: return "7 days"
        case .thirtyDays: return "30 days"
        case .custom: return "Custom"
        }
    }
}

struct DoctorVisitSummary {
    let startDate: Date
    let endDate: Date
    let medicines: [Medicine]
    let medicineTakenCount: Int
    let medicineMissedCount: Int
    let averageBP: String
    let averageSugar: String
    let highestSugar: String
    let lowestSugar: String
    let symptomFrequency: [(String, Int)]
    let periodSummary: String
    let notes: String

    static let disclaimer = "This report is generated from your saved logs and is not a medical diagnosis."
}
