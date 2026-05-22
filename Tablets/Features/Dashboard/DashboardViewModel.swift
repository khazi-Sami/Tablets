import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    let userName = "Sami"

    let nextMedicine = DashboardNextMedicine(
        name: "Vitamin D",
        dosage: "1000 IU",
        instruction: "After breakfast",
        time: "9:00 AM",
        iconName: "pills.fill"
    )

    let quickActions: [DashboardQuickAction] = [
        DashboardQuickAction(title: "Add Medicine", systemImage: "plus.circle.fill", tint: .blue, kind: .addMedicine),
        DashboardQuickAction(title: "Record BP", systemImage: "heart.text.square.fill", tint: .mint, kind: .recordBP),
        DashboardQuickAction(title: "Record Sugar", systemImage: "drop.fill", tint: .lavender, kind: .recordSugar),
        DashboardQuickAction(title: "View Trends", systemImage: "chart.xyaxis.line", tint: .blue, kind: .viewHealthTrends),
        DashboardQuickAction(title: "Period Log", systemImage: "calendar.badge.plus", tint: .red, kind: .periodLog)
    ]

    let timeline: [DashboardTimelineItem] = [
        DashboardTimelineItem(time: "8:00 AM", title: "Omega 3", subtitle: "1 capsule with food", status: .taken),
        DashboardTimelineItem(time: "9:00 AM", title: "Vitamin D", subtitle: "1000 IU after breakfast", status: .next),
        DashboardTimelineItem(time: "2:00 PM", title: "Eye Drops", subtitle: "2 drops after lunch", status: .upcoming),
        DashboardTimelineItem(time: "9:30 PM", title: "Magnesium", subtitle: "1 tablet before sleep", status: .upcoming)
    ]

    let healthSnapshots: [DashboardHealthSnapshot] = [
        DashboardHealthSnapshot(title: "Blood Pressure", value: "120/80", unit: "mmHg", systemImage: "heart.text.square.fill", status: "Normal"),
        DashboardHealthSnapshot(title: "Sugar", value: "96", unit: "mg/dL", systemImage: "drop.fill", status: "Stable"),
        DashboardHealthSnapshot(title: "Pulse", value: "72", unit: "bpm", systemImage: "waveform.path.ecg", status: "Calm")
    ]

    let lowStock = DashboardLowStockMedicine(name: "Omega 3", remaining: 4, threshold: 5)

    var medicineProgress: Double {
        0.62
    }

    var title: String {
        let hour = Calendar.current.component(.hour, from: .now)

        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    func upcomingDoseText(for medicine: Medicine) -> String {
        guard let firstTime = medicine.times.first else {
            return "No reminder set"
        }

        return "Next dose \(firstTime.shortTimeText)"
    }
}

struct DashboardNextMedicine {
    let name: String
    let dosage: String
    let instruction: String
    let time: String
    let iconName: String
}

struct DashboardQuickAction: Identifiable {
    enum Kind {
        case addMedicine
        case recordBP
        case recordSugar
        case periodLog
        case viewHealthTrends
    }

    enum Tint {
        case blue
        case mint
        case lavender
        case red
    }

    let id = UUID()
    let title: String
    let systemImage: String
    let tint: Tint
    let kind: Kind
}

struct DashboardTimelineItem: Identifiable {
    enum Status {
        case taken
        case next
        case upcoming
        case missed
    }

    let id = UUID()
    let time: String
    let title: String
    let subtitle: String
    let status: Status
}

struct DashboardHealthSnapshot: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let unit: String
    let systemImage: String
    let status: String
}

struct DashboardLowStockMedicine {
    let name: String
    let remaining: Int
    let threshold: Int
}
