import Foundation
import LocalAuthentication
import Observation

@MainActor
@Observable
final class AppLockService {
    var isLocked = false
    var errorMessage: String?
    private var isAuthenticating = false

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: AppPreferenceKeys.appLockEnabled)
    }

    func lockIfNeeded(canLock: Bool) {
        guard isEnabled, canLock else {
            isLocked = false
            return
        }
        isLocked = true
        errorMessage = nil
    }

    func unlock() async {
        guard isEnabled else {
            isLocked = false
            return
        }
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passcode"
        var authError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) else {
            errorMessage = authError?.localizedDescription ?? "Device authentication is not available."
            isLocked = true
            return
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock BanyAI to view your local health data."
            )
            isLocked = !success
            errorMessage = success ? nil : "Authentication was not completed."
        } catch {
            isLocked = true
            errorMessage = "Authentication was not completed."
            #if DEBUG
            print("[AppLockService] Unlock failed: \(error)")
            #endif
        }
    }
}
