import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var dataProvider: DashboardDataProvider?

    func configure(dataProvider: DashboardDataProvider) {
        if self.dataProvider == nil {
            self.dataProvider = dataProvider
        }
    }

    func refresh() async {
        await dataProvider?.refresh()
    }

    var userName: String {
        UserHealthProfile.userName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var title: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var greetingText: String {
        userName.isEmpty ? title : "\(title), \(userName)"
    }

    var statusLine: String {
        guard let dataProvider else { return "Loading your care plan..." }
        if dataProvider.todayMedicineLogs.isEmpty {
            if let bp = dataProvider.latestBP {
                return "No medicines scheduled today · Last BP: \(bpDisplay(bp))"
            }
            if dataProvider.latestSugar == nil {
                return "Sugar not logged today"
            }
            return "No medicines scheduled today"
        }

        if dataProvider.pendingCountToday == 0 {
            return "All medicines taken today"
        }

        var parts = ["\(dataProvider.pendingCountToday) medicines pending"]
        if let bp = dataProvider.latestBP {
            parts.append("Last BP: \(bpDisplay(bp))")
        } else if dataProvider.latestSugar == nil {
            parts.append("Sugar not logged today")
        }
        return parts.joined(separator: " · ")
    }

    private func bpDisplay(_ record: HealthRecord) -> String {
        "\(Int(record.value1))/\(Int(record.value2 ?? 0))"
    }
}
