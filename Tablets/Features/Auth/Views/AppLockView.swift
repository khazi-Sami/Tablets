import SwiftUI

struct AppLockView: View {
    let errorMessage: String?
    let unlock: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: Spacing.large) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(.regularMaterial)
                        .frame(width: 116, height: 116)
                    Image(systemName: "pills.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(AppColor.medicalBlue)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(AppColor.medicalBlue, in: Circle())
                        .offset(x: 36, y: 36)
                }

                VStack(spacing: Spacing.xSmall) {
                    Text("Unlock Tablets")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.ink)
                    Text("Use Face ID, Touch ID, or your device passcode.")
                        .font(AppFont.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppColor.secondaryInk)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.softRed)
                        .multilineTextAlignment(.center)
                }

                Button(action: unlock) {
                    Label("Unlock", systemImage: "faceid")
                        .font(AppFont.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: 260, minHeight: 56)
                        .background(AppGradient.primaryButton, in: Capsule())
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(Spacing.large)
        }
    }
}
