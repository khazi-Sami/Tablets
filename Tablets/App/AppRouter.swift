import Combine
import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case dashboard
    case medicines
    case healthTracking
    case healthJourney
    case more
    case womensHealth
    case familyCare
    case profile

    var title: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .medicines:
            return "Medicines"
        case .healthTracking:
            return "Health"
        case .healthJourney:
            return "Journey"
        case .more:
            return "More"
        case .womensHealth:
            return "Women"
        case .familyCare:
            return "Family"
        case .profile:
            return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            return "house"
        case .medicines:
            return "pills"
        case .healthTracking:
            return "heart.text.square"
        case .healthJourney:
            return "sparkles"
        case .more:
            return "ellipsis"
        case .womensHealth:
            return "heart.circle"
        case .familyCare:
            return "figure.2.and.child.holdinghands"
        case .profile:
            return "person"
        }
    }
}

final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .dashboard
}
