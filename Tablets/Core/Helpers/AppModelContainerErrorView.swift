import SwiftUI
import UIKit

struct AppModelContainerErrorView: View {
    let error: AppModelContainerLoadError
    let retry: () -> Void
    let resetLocalData: () -> Void

    @State private var isShowingResetConfirmation = false
    @State private var didCopyError = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text(error.userMessage)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text("Your saved data has not been changed. You can retry opening it, copy error info for support, or reset local data only if you choose to.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button(action: retry) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    UIPasteboard.general.string = error.debugDescription
                    didCopyError = true
                } label: {
                    Label(didCopyError ? "Error Info Copied" : "Contact Support / Copy Error Info", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    isShowingResetConfirmation = true
                } label: {
                    Label("Reset Local Data", systemImage: "trash")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .confirmationDialog(
            "Reset local data?",
            isPresented: $isShowingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Local Data", role: .destructive, action: resetLocalData)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes local Tablets data stored on this device. Use this only if retry does not work and you understand the data may not be recoverable.")
        }
    }
}
