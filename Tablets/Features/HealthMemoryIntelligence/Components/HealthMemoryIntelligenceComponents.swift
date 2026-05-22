import SwiftUI

struct EmotionalStatusOrb: View {
    let tone: AssistantTone
    @State private var glow = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(glow ? 0.22 : 0.12))
                .frame(width: glow ? 116 : 96, height: glow ? 116 : 96)
                .blur(radius: 12)
            Circle()
                .fill(LinearGradient(colors: [color, AppColor.medicalBlue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 74, height: 74)
                .overlay(Image(systemName: "brain.head.profile").font(.title).foregroundStyle(.white))
                .appShadow(AppShadow.button)
        }
        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: glow)
        .onAppear { glow = true }
        .accessibilityLabel("Assistant emotional status")
    }

    private var color: Color {
        switch tone {
        case .calm: return AppColor.lavender
        case .encouraging: return AppColor.mintGreen
        case .supportive: return AppColor.softRed
        case .balanced: return AppColor.medicalBlue
        }
    }
}

struct AdaptiveAssistantBubble: View {
    let text: String

    var body: some View {
        PillCardContainer(style: .highlighted, padding: Spacing.large) {
            Text(text)
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PersonalizedGreetingView: View {
    let habits: [UserHealthHabit]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(greeting)
                .font(AppFont.title)
                .foregroundStyle(AppColor.ink)
            Text("Your assistant uses only saved on-device logs to personalize suggestions.")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greeting: String {
        if let habit = habits.first(where: { $0.habitType == .interaction }) {
            return "Welcome back. \(habit.title)"
        }
        return "Your private health memory"
    }
}

struct HabitInsightCards: View {
    let cards: [HealthInsightCard]

    var body: some View {
        VStack(spacing: Spacing.small) {
            ForEach(cards) { card in
                PillCardContainer {
                    HStack(spacing: Spacing.medium) {
                        Image(systemName: card.icon)
                            .foregroundStyle(AppColor.medicalBlue)
                            .frame(width: 42, height: 42)
                            .background(AppColor.medicalBlue.opacity(0.10), in: Circle())
                        VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                            Text(card.title)
                                .font(AppFont.bodyStrong)
                                .foregroundStyle(AppColor.ink)
                            Text(card.message)
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.secondaryInk)
                        }
                        Spacer()
                    }
                }
            }
        }
    }
}
