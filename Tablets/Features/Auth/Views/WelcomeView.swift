import AuthenticationServices
import SwiftUI

struct WelcomeView: View {
    let isLoading: Bool
    let appleSignInAction: (Result<ASAuthorization, Error>) -> Void
    let guestAction: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppColor.medicalBlue.opacity(0.18),
                    AppColor.mintGreen.opacity(0.14),
                    AppColor.warmWhite
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.large) {
                Spacer()

                VStack(spacing: Spacing.medium) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.76))
                            .frame(width: 104, height: 104)
                            .shadow(color: AppColor.medicalBlue.opacity(0.18), radius: 24, x: 0, y: 12)

                        Image(systemName: "pills.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(AppColor.medicalBlue)
                    }

                    Text("Tablets")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundColor(AppColor.ink)

                    Text("Your personal health companion")
                        .font(AppFont.sectionTitle)
                        .foregroundColor(AppColor.secondaryInk)

                    Text("Private. Offline. Always with you.")
                        .font(AppFont.body)
                        .foregroundColor(AppColor.tertiaryInk)
                }

                VStack(spacing: Spacing.medium) {
                    WelcomeFeatureRow(icon: "bell.badge.fill", title: "Medicine reminders")
                    WelcomeFeatureRow(icon: "heart.text.square.fill", title: "BP and sugar tracking")
                    WelcomeFeatureRow(icon: "mic.circle.fill", title: "Offline voice assistant")
                }
                .padding(Spacing.large)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 28, style: .continuous))

                Spacer()

                VStack(spacing: Spacing.medium) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName]
                    } onCompletion: { result in
                        appleSignInAction(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .disabled(isLoading)

                    Button(action: guestAction) {
                        Text("Continue without account")
                            .font(AppFont.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColor.medicalBlue, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(isLoading)

                    Text("Your data stays on your device.")
                        .font(AppFont.caption)
                        .foregroundColor(AppColor.tertiaryInk)
                }
            }
            .padding(Spacing.large)
        }
    }
}

private struct WelcomeFeatureRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppColor.medicalBlue)
                .frame(width: 34, height: 34)
                .background(AppColor.medicalBlue.opacity(0.12), in: Circle())

            Text(title)
                .font(AppFont.body)
                .foregroundColor(AppColor.ink)

            Spacer()
        }
    }
}
