import SwiftUI

struct InlineFeatureHint: View {
    let id: String
    let message: String
    let systemImage: String
    var maxShows: Int = 3

    @AppStorage private var showCount: Int
    @AppStorage private var dismissed: Bool

    init(id: String, message: String, systemImage: String, maxShows: Int = 3) {
        self.id = id
        self.message = message
        self.systemImage = systemImage
        self.maxShows = maxShows
        _showCount = AppStorage(wrappedValue: 0, "hint_\(id)_count")
        _dismissed = AppStorage(wrappedValue: false, "hint_\(id)_dismissed")
    }

    var body: some View {
        if !dismissed && showCount < maxShows {
            HStack(spacing: Spacing.small) {
                Image(systemName: systemImage)
                    .foregroundStyle(AppColor.medicalBlue)
                    .frame(width: 28)

                Text(message)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button {
                    dismissed = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(AppColor.secondaryInk)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.medium)
            .background(AppColor.medicalBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                    .stroke(AppColor.medicalBlue.opacity(0.14), lineWidth: 1)
            )
            .onAppear {
                showCount += 1
            }
        }
    }
}
