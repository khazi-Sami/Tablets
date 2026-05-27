import SwiftUI

struct QuickStartGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private let cards: [QuickStartCard] = [
        .init(icon: "rectangle.grid.2x2.fill", title: "Dashboard overview", message: "Your dashboard becomes smarter as you log medicines and health readings.", actionTitle: "Open dashboard", notification: nil),
        .init(icon: "pills.fill", title: "Add your first medicine", message: "Start reminders by saving one tablet, capsule, or syrup.", actionTitle: "Try now", notification: .quickStartOpenAddMedicine),
        .init(icon: "mic.circle.fill", title: "Try the voice assistant", message: "Tap the floating mic and ask: What medicine is next?", actionTitle: "Highlight mic", notification: .quickStartHighlightVoice),
        .init(icon: "heart.text.square.fill", title: "Log BP or sugar", message: "Add readings to build trends and safety alerts.", actionTitle: "Log BP", notification: .quickStartOpenBPLog),
        .init(icon: "heart.fill", title: "Connect Apple Health", message: "Optional: show steps, sleep, and heart insights from Apple Health.", actionTitle: "Open Apple Health", notification: .quickStartOpenHealthKit),
        .init(icon: "doc.text.magnifyingglass", title: "Generate doctor report later", message: "After logging data, create a local PDF for appointments.", actionTitle: "Open report", notification: .quickStartOpenHealthReport)
    ]

    var body: some View {
        ZStack {
            AppGradient.background.ignoresSafeArea()
            VStack(spacing: Spacing.large) {
                HStack {
                    Spacer()
                    Button("Skip guide") { finish() }
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                }

                Spacer()

                let card = cards[page]
                PillCardContainer(style: .highlighted, padding: Spacing.large) {
                    VStack(spacing: Spacing.large) {
                        Image(systemName: card.icon)
                            .font(.system(size: 54, weight: .bold))
                            .foregroundStyle(AppColor.medicalBlue)
                            .frame(width: 104, height: 104)
                            .background(AppColor.medicalBlue.opacity(0.10), in: Circle())

                        VStack(spacing: Spacing.small) {
                            Text(card.title)
                                .font(AppFont.title)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AppColor.ink)
                            Text(card.message)
                                .font(AppFont.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AppColor.secondaryInk)
                        }

                        CapsuleButton(card.actionTitle, systemImage: "arrow.right.circle.fill") {
                            run(card)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                HStack {
                    ForEach(cards.indices, id: \.self) { index in
                        Circle()
                            .fill(index == page ? AppColor.medicalBlue : AppColor.medicalBlue.opacity(0.18))
                            .frame(width: 8, height: 8)
                    }
                }

                HStack {
                    if page > 0 {
                        CapsuleButton("Back", systemImage: "chevron.left", style: .secondary) {
                            page -= 1
                        }
                    }
                    CapsuleButton(page == cards.count - 1 ? "Finish setup" : "Next", systemImage: page == cards.count - 1 ? "checkmark" : "chevron.right") {
                        if page == cards.count - 1 {
                            finish()
                        } else {
                            page += 1
                        }
                    }
                }

                Spacer()
            }
            .padding(Spacing.medium)
        }
    }

    private func run(_ card: QuickStartCard) {
        if let notification = card.notification {
            NotificationCenter.default.post(name: notification, object: nil)
            finish()
        } else {
            finish()
        }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: AppPreferenceKeys.hasSeenQuickStartGuide)
        dismiss()
    }
}

private struct QuickStartCard {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let notification: Notification.Name?
}

extension Notification.Name {
    static let quickStartOpenAddMedicine = Notification.Name("QuickStartOpenAddMedicine")
    static let quickStartHighlightVoice = Notification.Name("QuickStartHighlightVoice")
    static let quickStartOpenBPLog = Notification.Name("QuickStartOpenBPLog")
    static let quickStartOpenHealthKit = Notification.Name("QuickStartOpenHealthKit")
    static let quickStartOpenHealthReport = Notification.Name("QuickStartOpenHealthReport")
}
