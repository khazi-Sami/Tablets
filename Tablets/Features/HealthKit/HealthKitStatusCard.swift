import SwiftUI

struct HealthKitStatusCard: View {
    enum Status {
        case connected
        case notConnected
        case unavailable

        var title: String {
            switch self {
            case .connected: return "Apple Health Connected"
            case .notConnected: return "Apple Health Not Connected"
            case .unavailable: return "Apple Health Unavailable"
            }
        }

        var subtitle: String {
            switch self {
            case .connected:
                return "Steps, sleep, heart rate, oxygen, and weight can improve your dashboard and voice answers."
            case .notConnected:
                return "Connect Apple Health for steps, sleep, and heart insights."
            case .unavailable:
                return "This device does not support Apple Health. BanyAI still works with your saved logs."
            }
        }

        var color: Color {
            switch self {
            case .connected: return AppColor.mintGreenDeep
            case .notConnected: return AppColor.medicalBlue
            case .unavailable: return AppColor.secondaryInk
            }
        }
    }

    let status: Status
    let lastSyncAt: Date?
    let isWriteSyncEnabled: Bool
    let manageAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: status == .connected ? "heart.fill" : "heart")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(status.color)
                    .frame(width: 44, height: 44)
                    .background(status.color.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(status.title)
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)
                    Text(status.subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                statusLine("Reads", "Steps, sleep, heart rate, oxygen, weight")
                statusLine("Writes", isWriteSyncEnabled ? "BP, sugar, weight when you save readings" : "Off")
                statusLine("Last sync", lastSyncText)
            }

            Text("Your Apple Health data stays on your device and is only used with your permission.")
                .font(.caption)
                .foregroundStyle(AppColor.secondaryInk)

            CapsuleButton("Manage Apple Health", systemImage: "slider.horizontal.3", style: .secondary, action: manageAction)
                .frame(minHeight: 50)
                .disabled(status == .unavailable)
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    private var lastSyncText: String {
        guard let lastSyncAt else { return "Not synced yet" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastSyncAt, relativeTo: .now)
    }

    private func statusLine(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.ink)
                .frame(width: 62, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundStyle(AppColor.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
