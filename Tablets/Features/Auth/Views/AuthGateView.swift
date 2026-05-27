import AuthenticationServices
import SwiftData
import SwiftUI

struct AuthGateView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var authViewModel = AuthViewModel()
    @AppStorage(AppPreferenceKeys.hasSeenQuickStartGuide) private var hasSeenQuickStartGuide = false
    @State private var hasCompletedSession = AppPreferenceKeys.hasCompletedSession

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if hasCompletedSession {
                    mainAppView
                } else {
                    switch authViewModel.authState {
                    case .checking:
                        ProgressView("Preparing Tablets...")
                    case .welcome:
                        WelcomeView(
                            isLoading: authViewModel.isLoading,
                            appleSignInAction: { result in
                                authViewModel.signInWithApple(result, context: modelContext)
                            },
                            guestAction: {
                                authViewModel.clearError()
                                authViewModel.continueAsGuest(context: modelContext)
                            }
                        )
                    case .onboarding:
                        if let profile = authViewModel.currentProfile {
                            OnboardingContainerView(profile: profile) { completedProfile in
                                authViewModel.markOnboardingComplete(profile: completedProfile, context: modelContext)
                            }
                        } else {
                            WelcomeView(
                                isLoading: authViewModel.isLoading,
                                appleSignInAction: { result in
                                    authViewModel.signInWithApple(result, context: modelContext)
                                },
                                guestAction: {
                                    authViewModel.clearError()
                                    authViewModel.continueAsGuest(context: modelContext)
                                }
                            )
                        }
                    case .main:
                        mainAppView
                    }
                }
            }

            if authViewModel.authState == .welcome, let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(AppFont.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(AppColor.softRed, in: Capsule())
                    .padding(.top, Spacing.large)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authViewModel.authState)
        .onAppear {
            hasCompletedSession = AppPreferenceKeys.hasCompletedSession
            #if DEBUG
            print("[AuthGateView] \(AppPreferenceKeys.completedSession)=\(hasCompletedSession)")
            #endif
            authViewModel.checkExistingSession(context: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .authSignOutRequested)) { _ in
            authViewModel.signOut(context: modelContext)
            hasCompletedSession = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .authResetOnboardingRequested)) { _ in
            authViewModel.resetOnboarding(context: modelContext)
            hasCompletedSession = false
        }
    }

    private var mainAppView: some View {
        AppRootView(isAppLockAllowed: true)
            .fullScreenCover(isPresented: Binding(
                get: { !hasSeenQuickStartGuide },
                set: { if !$0 { hasSeenQuickStartGuide = true } }
            )) {
                QuickStartGuideView()
            }
    }
}
