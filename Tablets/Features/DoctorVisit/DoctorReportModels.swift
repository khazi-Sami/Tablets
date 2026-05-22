import Foundation

struct DoctorReportData {
    let startDate: Date
    let endDate: Date
    let patientName: String
    let patientAge: Int
    let medicines: [Medicine]
    let medicineLogs: [MedicineLog]
    let healthRecords: [HealthRecord]
    let symptoms: [(String, Int)]
    let periodSummary: String?
    let appointments: [DoctorAppointment]
    let notes: String
    let appleHealthSummary: DoctorReportAppleHealthSummary?

    var hasClinicalData: Bool {
        !medicines.isEmpty || !medicineLogs.isEmpty || !healthRecords.isEmpty || !symptoms.isEmpty || periodSummary != nil || !appointments.isEmpty || appleHealthSummary != nil
    }
}

struct DoctorReportAppleHealthSummary {
    let averageSteps: Double?
    let averageSleepHours: Double?
    let latestHeartRate: Double?
    let restingHeartRate: Double?
}

struct DoctorReportChartPoint {
    let date: Date
    let value: Double
    let secondaryValue: Double?
}
