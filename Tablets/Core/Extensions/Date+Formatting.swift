import Foundation

extension Date {
    var shortTimeText: String {
        formatted(date: .omitted, time: .shortened)
    }

    var mediumDateText: String {
        formatted(date: .abbreviated, time: .omitted)
    }
}
