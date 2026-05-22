import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    var displayName: String {
        let trimmedName = UserHealthProfile.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Your Profile" : trimmedName
    }

    var subtitle: String {
        "\(UserHealthProfile.gender.title) · Medicine reminders and health tracking"
    }
}
