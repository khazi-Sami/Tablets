import SwiftUI

struct NeumorphicNotificationView: View {
    @Environment(\.colorScheme) private var colorScheme

    let medicineName: String
    let dosage: String
    let instruction: String
    let progressPercent: Double
    let takenCount: Int
    let pendingCount: Int
    let skippedCount: Int
    let isOverdue: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Time for your medicine", systemImage: "bell.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(notificationText)

            VStack(alignment: .leading, spacing: 10) {
                Label(medicineName, systemImage: "pills.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(notificationText)

                Text([dosage, instruction].filter { !$0.isEmpty }.joined(separator: " • "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(isOverdue ? "Overdue" : "Due now")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isOverdue ? Color.red : Color.green)

                ProgressView(value: progressPercent, total: 100)
                    .tint(Color(red: 0.20, green: 0.78, blue: 0.35))

                Text("\(takenCount) taken | \(pendingCount) pending | \(skippedCount) skipped")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(notificationBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: shadowColor, radius: 14, x: 6, y: 6)
            .shadow(color: highlightColor, radius: 9, x: -3, y: -3)

            HStack(spacing: 10) {
                notificationButton("Taken", systemImage: "checkmark.circle.fill", tint: .green)
                notificationButton("Snooze", systemImage: "pause.circle.fill", tint: .orange)
                notificationButton("Skip", systemImage: "xmark.circle.fill", tint: .gray)
            }
        }
        .padding(18)
        .background(notificationBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Medicine reminder for \(medicineName), \(isOverdue ? "overdue" : "due now")")
    }

    private var notificationBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.10, green: 0.17, blue: 0.14)
            : Color(red: 0.93, green: 0.95, blue: 0.94)
    }

    private var notificationText: Color {
        colorScheme == .dark
            ? Color(red: 0.77, green: 0.91, blue: 0.84)
            : Color(red: 0.23, green: 0.36, blue: 0.29)
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.34)
            : Color(red: 0.56, green: 0.69, blue: 0.60).opacity(0.16)
    }

    private var highlightColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color.white.opacity(0.35)
    }

    private func notificationButton(_ title: String, systemImage: String, tint: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(notificationBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: shadowColor, radius: 10, x: 5, y: 5)
            .shadow(color: highlightColor, radius: 7, x: -3, y: -3)
    }
}

#Preview {
    NeumorphicNotificationView(
        medicineName: "Aspirin",
        dosage: "500 mg",
        instruction: "With food",
        progressPercent: 33,
        takenCount: 1,
        pendingCount: 1,
        skippedCount: 0,
        isOverdue: true
    )
}
