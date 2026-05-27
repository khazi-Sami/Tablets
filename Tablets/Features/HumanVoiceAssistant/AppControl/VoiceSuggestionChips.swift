import Foundation

enum VoiceSuggestionChips {
    static func suggestions(for date: Date = .now, calendar: Calendar = .current) -> [String] {
        let weekday = calendar.component(.weekday, from: date)
        let daily: [String]

        switch weekday {
        case 2:
            daily = ["Record BP", "How is my sugar?", "What's pending?"]
        case 3:
            daily = ["Log period", "Scan prescription", "Health summary"]
        case 4:
            daily = ["Add medicine", "Doctor visit", "How was my week?"]
        case 5:
            daily = ["Record sugar", "Open periods", "Did I take my tablet?"]
        case 6:
            daily = ["My BP is...", "Family medicines", "Open settings"]
        case 7:
            daily = ["Log symptoms", "Health journey", "Check-in today"]
        default:
            daily = ["How is my BP?", "Next period?", "Medicine schedule"]
        }

        return Array((["Add my first medicine", "Log BP", "What medicine is next?"] + daily + ["Open medicines", "Help"]).uniqued().prefix(6))
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
