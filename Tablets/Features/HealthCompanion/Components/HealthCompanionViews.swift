import SwiftData
import SwiftUI

struct FloatingHealthCompanionIcon: View {
    @State private var float = false
    @State private var glow = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColor.medicalBlue.opacity(glow ? 0.26 : 0.12))
                .frame(width: glow ? 82 : 62, height: glow ? 82 : 62)
                .blur(radius: 12)

            Circle()
                .fill(AppGradient.primaryButton)
                .frame(width: 62, height: 62)
                .overlay(
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                )
                .appShadow(AppShadow.button)
        }
        .offset(y: float ? -5 : 5)
        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: float)
        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: glow)
        .onAppear {
            float = true
            glow = true
        }
        .accessibilityHidden(true)
    }
}

struct AssistantTypingDots: View {
    @State private var activeIndex = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(AppColor.medicalBlue.opacity(activeIndex == index ? 0.95 : 0.32))
                    .frame(width: 6, height: 6)
                    .scaleEffect(activeIndex == index ? 1.24 : 0.9)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.28, repeats: true) { _ in
                activeIndex = (activeIndex + 1) % 3
            }
        }
        .accessibilityLabel("Assistant is typing")
    }
}

struct HealthCompanionBubble: View {
    let message: HealthCompanionMessage
    let visibleText: String
    let isTyping: Bool
    let streak: Int
    let nextAction: () -> Void

    var body: some View {
        PillCardContainer(style: .highlighted, padding: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(alignment: .top, spacing: Spacing.medium) {
                    FloatingHealthCompanionIcon()

                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        HStack(spacing: Spacing.xSmall) {
                            Image(systemName: message.tone.icon)
                                .foregroundStyle(message.tone.color)
                            Text("BanyAI Companion")
                                .font(AppFont.sectionTitle)
                                .foregroundStyle(AppColor.ink)
                        }

                        Text(visibleText.isEmpty ? message.text : visibleText)
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .contentTransition(.opacity)

                        if isTyping {
                            AssistantTypingDots()
                                .padding(.top, Spacing.xxxSmall)
                        }
                    }
                }

                HStack(spacing: Spacing.small) {
                    HealthStatusPill(title: streak > 0 ? "\(streak)-day streak" : "Start today", color: AppColor.mintGreenDeep)

                    Spacer()

                    Button(action: nextAction) {
                        Label("Next", systemImage: "arrow.right.circle.fill")
                            .font(AppFont.bodyStrong)
                            .foregroundStyle(AppColor.medicalBlueDeep)
                            .padding(.horizontal, Spacing.medium)
                            .frame(minHeight: 44)
                            .background(AppColor.warmWhite.opacity(0.78))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct HealthCompanionCard: View {
    @Query(sort: \Medicine.name) private var medicines: [Medicine]
    @Query(sort: \MedicineLog.scheduledTime, order: .reverse) private var medicineLogs: [MedicineLog]
    @Query(sort: \HealthRecord.measuredAt, order: .reverse) private var healthRecords: [HealthRecord]
    @StateObject private var viewModel = HealthCompanionViewModel()

    let userName: String

    private var companionMessages: [HealthCompanionMessage] {
        viewModel.messages(
            userName: userName,
            medicines: medicines,
            medicineLogs: medicineLogs,
            healthRecords: healthRecords
        )
    }

    private var currentMessage: HealthCompanionMessage {
        let messages = companionMessages
        guard messages.indices.contains(viewModel.selectedMessageIndex) else {
            return messages.first ?? HealthCompanionMessage(text: "Your health journey matters.", tone: .encouragement)
        }
        return messages[viewModel.selectedMessageIndex]
    }

    var body: some View {
        HealthCompanionBubble(
            message: currentMessage,
            visibleText: viewModel.visibleText,
            isTyping: viewModel.isTyping,
            streak: viewModel.healthStreak(from: healthRecords, medicineLogs: medicineLogs)
        ) {
            viewModel.advance(totalMessages: companionMessages.count)
        }
        .onAppear {
            viewModel.show(currentMessage)
        }
        .onChange(of: viewModel.selectedMessageIndex) { _, _ in
            viewModel.show(currentMessage)
        }
    }
}
