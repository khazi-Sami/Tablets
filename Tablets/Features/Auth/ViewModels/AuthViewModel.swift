import AuthenticationServices
import Foundation
import Observation
import SwiftData

extension Notification.Name {
    static let authSignOutRequested = Notification.Name("AuthSignOutRequested")
    static let authResetOnboardingRequested = Notification.Name("AuthResetOnboardingRequested")
}

enum AuthState: Equatable {
    case checking
    case welcome
    case onboarding
    case main
}

@MainActor
@Observable
final class AuthViewModel {
    var authState: AuthState = .checking
    var isLoading = false
    var errorMessage: String?
    var currentProfile: UserProfile?

    func clearError() {
        errorMessage = nil
    }

    func checkExistingSession(context: ModelContext) {
        clearError()
        transition(to: .checking)

        if AppPreferenceKeys.hasCompletedSession {
            #if DEBUG
            print("[AuthViewModel] \(AppPreferenceKeys.completedSession)=true; routing directly to main before SwiftData fetch")
            #endif
            transition(to: .main)
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let profiles = try fetchProfiles(context: context)
            let profile = selectedProfile(from: profiles)
            currentProfile = profile

            #if DEBUG
            print("[AuthViewModel] profiles found: \(profiles.count)")
            if let profile {
                print("[AuthViewModel] selected profile: \(profile.id) completed=\(profile.hasCompletedOnboarding) method=\(profile.loginMethod)")
            }
            #endif

            guard let profile else {
                #if DEBUG
                print("[AuthViewModel] No UserProfile records; routing to welcome")
                #endif
                transition(to: .welcome)
                return
            }

            if profile.hasCompletedOnboarding {
                markSessionCompleted(reason: "SwiftData completed profile found")
            }
            transition(to: profile.hasCompletedOnboarding ? .main : .onboarding)
        } catch {
            errorMessage = "We could not check your local profile safely."
            transition(to: .welcome)
            #if DEBUG
            print("[AuthViewModel] Session check failed: \(error)")
            #endif
        }
    }

    func signInWithApple(_ result: Result<ASAuthorization, Error>, context: ModelContext) {
        switch result {
        case .success(let authorization):
            clearError()
            markSessionCompleted(reason: "Sign in with Apple success")
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                clearSession(reason: "Apple credential was unavailable")
                setWelcomeError("Apple sign in could not be completed.")
                return
            }

            let name = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            createOrReuseAppleProfile(context: context, name: name, appleUserId: credential.user)
        case .failure(let error):
            setWelcomeError("Apple sign in was cancelled or could not be completed.")
            #if DEBUG
            print("[AuthViewModel] Apple sign in failed: \(error)")
            #endif
        }
    }

    func continueAsGuest(context: ModelContext) {
        clearError()
        markSessionCompleted(reason: "Continue as Guest tapped")
        createOrReuseGuestProfile(context: context)
    }

    func logout(context: ModelContext) {
        signOut(context: context)
    }

    func markOnboardingComplete(profile: UserProfile, context: ModelContext) {
        do {
            clearError()
            markSessionCompleted(reason: "Onboarding final step")
            profile.hasCompletedOnboarding = true
            try context.save()
            currentProfile = profile
            transition(to: .main)
            #if DEBUG
            print("[AuthViewModel] onboarding completed for profile: \(profile.id)")
            #endif
        } catch {
            clearSession(reason: "Onboarding save failed")
            errorMessage = "We could not save onboarding. Please try again."
            #if DEBUG
            print("[AuthViewModel] Onboarding save failed: \(error)")
            #endif
        }
    }

    func signOut(context: ModelContext) {
        clearError()
        HealthAppIntegrityChecker.cleanupForSignOut()
        clearSession(reason: "Sign out requested")
        isLoading = true
        defer { isLoading = false }

        do {
            let profiles = try fetchProfiles(context: context)
            for profile in profiles {
                context.delete(profile)
            }
            try context.save()
            currentProfile = nil
            UserDefaults.standard.set(false, forKey: AppPreferenceKeys.hasSeenQuickStartGuide)
            transition(to: .welcome)
            #if DEBUG
            print("[AuthViewModel] signed out and removed \(profiles.count) local auth profile(s)")
            #endif
        } catch {
            errorMessage = "We could not sign out safely."
            #if DEBUG
            print("[AuthViewModel] Sign out failed: \(error)")
            #endif
        }
    }

    func resetOnboarding(context: ModelContext) {
        do {
            clearError()
            clearSession(reason: "DEBUG reset onboarding requested")
            let profiles = try fetchProfiles(context: context)
            guard let profile = selectedProfile(from: profiles) else {
                transition(to: .welcome)
                return
            }
            profile.hasCompletedOnboarding = false
            try context.save()
            currentProfile = profile
            UserDefaults.standard.set(false, forKey: AppPreferenceKeys.hasSeenQuickStartGuide)
            transition(to: .onboarding)
            #if DEBUG
            print("[AuthViewModel] reset onboarding for profile: \(profile.id)")
            #endif
        } catch {
            errorMessage = "We could not reset onboarding."
            #if DEBUG
            print("[AuthViewModel] Reset onboarding failed: \(error)")
            #endif
        }
    }

    private func markCurrentProfile(_ profile: UserProfile) {
        clearError()
        currentProfile = profile
        transition(to: profile.hasCompletedOnboarding ? .main : .onboarding)
    }

    private func createOrReuseGuestProfile(context: ModelContext) {
        clearError()
        isLoading = true
        defer { isLoading = false }

        do {
            if let existingGuest = try fetchProfiles(context: context).first(where: { $0.loginMethod == "guest" }) {
                markCurrentProfile(existingGuest)
                #if DEBUG
                print("[AuthViewModel] reused guest profile: \(existingGuest.id)")
                #endif
                return
            }

            let profile = UserProfile(
                name: "",
                appleUserId: nil,
                loginMethod: "guest",
                createdAt: .now,
                displayName: nil
            )
            context.insert(profile)
            try context.save()
            markSessionCompleted(reason: "Guest profile saved")
            markCurrentProfile(profile)
            #if DEBUG
            print("[AuthViewModel] created guest profile: \(profile.id)")
            #endif
        } catch {
            clearSession(reason: "Guest profile creation failed")
            errorMessage = "We could not create your local profile."
            #if DEBUG
            print("[AuthViewModel] Guest profile creation failed: \(error)")
            #endif
        }
    }

    private func createOrReuseAppleProfile(context: ModelContext, name: String, appleUserId: String) {
        clearError()
        isLoading = true
        defer { isLoading = false }

        do {
            if let existingApple = try fetchProfiles(context: context).first(where: { $0.appleUserId == appleUserId }) {
                if !name.isEmpty, existingApple.name.isEmpty {
                    existingApple.name = name
                    existingApple.displayName = name
                    try context.save()
                }
                markCurrentProfile(existingApple)
                #if DEBUG
                print("[AuthViewModel] reused Apple profile: \(existingApple.id)")
                #endif
                return
            }

            let profile = UserProfile(
                name: name,
                appleUserId: appleUserId,
                loginMethod: "apple",
                createdAt: .now,
                displayName: name.isEmpty ? nil : name
            )
            context.insert(profile)
            try context.save()
            markSessionCompleted(reason: "Apple profile saved")
            markCurrentProfile(profile)
            #if DEBUG
            print("[AuthViewModel] created Apple profile: \(profile.id)")
            #endif
        } catch {
            clearSession(reason: "Apple profile creation failed")
            errorMessage = "We could not create your Apple profile."
            #if DEBUG
            print("[AuthViewModel] Apple profile creation failed: \(error)")
            #endif
        }
    }

    private func fetchProfiles(context: ModelContext) throws -> [UserProfile] {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    private func selectedProfile(from profiles: [UserProfile]) -> UserProfile? {
        profiles.first(where: { $0.hasCompletedOnboarding }) ?? profiles.first
    }

    private func markSessionCompleted(reason: String) {
        AppPreferenceKeys.setCompletedSession(true)
        #if DEBUG
        print("[AuthViewModel] \(AppPreferenceKeys.completedSession)=true (\(reason))")
        #endif
    }

    private func clearSession(reason: String) {
        AppPreferenceKeys.clearCompletedSession()
        #if DEBUG
        print("[AuthViewModel] \(AppPreferenceKeys.completedSession) removed (\(reason))")
        #endif
    }

    private func transition(to state: AuthState) {
        if state != .welcome {
            clearError()
        }
        authState = state
        #if DEBUG
        print("[AuthViewModel] authState -> \(state)")
        #endif
    }

    private func setWelcomeError(_ message: String) {
        errorMessage = message
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            self?.clearError()
        }
    }
}
