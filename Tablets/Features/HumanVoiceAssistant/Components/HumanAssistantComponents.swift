import SwiftUI

enum FloatingVoiceState: Equatable {
    case idle
    case preparing
    case listening
    case userSpeaking
    case processing
    case speaking
    case success
    case error(String)
}

struct HumanAssistantFloatingButton: View {
    let voiceState: FloatingVoiceState
    let bubbleText: String
    let audioLevel: Double
    let action: () -> Void
    var doubleTapAction: (() -> Void)?
    var longPressAction: (() -> Void)?
    @State private var glow = false
    @State private var offset: CGSize = .zero
    @State private var suppressNextTap = false

    var body: some View {
        VStack(alignment: .trailing, spacing: Spacing.xSmall) {
            if !bubbleText.isEmpty {
                Text(bubbleText)
                    .font(AppFont.caption)
                    .foregroundStyle(bubbleForeground)
                    .lineLimit(3)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .frame(maxWidth: 260, alignment: .trailing)
                    .background(bubbleBackground, in: RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
                    .appShadow(AppShadow.soft)
                    .transition(.scale.combined(with: .opacity))
            }

            ZStack {
                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .stroke(stateColor.opacity(isActive ? 0.28 : 0.08), lineWidth: 2)
                        .frame(width: activePulseWidth(index), height: activePulseWidth(index))
                        .opacity(glow ? 0.16 : 0.42)
                }

                Circle()
                    .fill(stateColor.opacity(glow ? 0.20 : 0.08))
                    .frame(width: glow ? 86 : 68, height: glow ? 86 : 68)
                    .blur(radius: 10)

                Circle()
                    .fill(buttonFill)
                    .frame(width: 62, height: 62)
                    .overlay(
                        Image(systemName: symbolName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(voiceState == .processing ? 16 : 0))
                    )
                    .overlay(alignment: .bottomTrailing) {
                        if voiceState == .success {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(AppColor.mintGreenDeep)
                                .background(.white, in: Circle())
                                .offset(x: 4, y: 4)
                        }
                    }
                    .appShadow(AppShadow.button)
            }
            .contentShape(Circle())
        }
        .offset(offset)
        .gesture(DragGesture().onChanged { offset = $0.translation })
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    suppressNextTap = true
                    HapticsManager.selection()
                    longPressAction?()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        suppressNextTap = false
                    }
                }
        )
        .highPriorityGesture(
            TapGesture(count: 2)
                .exclusively(before: TapGesture(count: 1))
                .onEnded { value in
                    guard !suppressNextTap else { return }
                    switch value {
                    case .first:
                        doubleTapAction?()
                    case .second:
                        action()
                    }
                }
        )
        .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: glow)
        .animation(.easeInOut(duration: 0.7), value: voiceState)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: bubbleText)
        .animation(.easeInOut(duration: 0.18), value: audioLevel)
        .onAppear { glow = true }
        .accessibilityLabel("Voice assistant. Single tap for quick voice. Double tap for full assistant. Long press for options.")
    }

    private var isActive: Bool {
        switch voiceState {
        case .listening, .userSpeaking, .processing, .speaking:
            return true
        default:
            return false
        }
    }

    private func activePulseWidth(_ index: Int) -> CGFloat {
        let base = CGFloat(74 + index * 18)
        let voiceBoost = voiceState == .userSpeaking ? CGFloat(audioLevel * 42) : 0
        let glowBoost = glow ? CGFloat(14 + index * 8) : 0
        return base + voiceBoost + glowBoost
    }

    private var symbolName: String {
        switch voiceState {
        case .idle: return "mic.fill"
        case .preparing: return "sparkles"
        case .listening, .userSpeaking: return "waveform"
        case .processing: return "heart.text.square.fill"
        case .speaking: return "speaker.wave.2.fill"
        case .success: return "checkmark"
        case .error: return "exclamationmark"
        }
    }

    private var stateColor: Color {
        switch voiceState {
        case .idle, .preparing: return AppColor.medicalBlue
        case .listening, .userSpeaking: return AppColor.mintGreenDeep
        case .processing, .speaking: return AppColor.lavenderDeep
        case .success: return AppColor.mintGreenDeep
        case .error: return AppColor.softRed
        }
    }

    private var buttonFill: some ShapeStyle {
        switch voiceState {
        case .error:
            return AnyShapeStyle(AppColor.softRed)
        default:
            return AnyShapeStyle(AppGradient.primaryButton)
        }
    }

    private var bubbleForeground: Color {
        if case .error = voiceState { return AppColor.softRed }
        return AppColor.ink
    }

    private var bubbleBackground: Color {
        if case .error = voiceState { return AppColor.softRed.opacity(0.12) }
        return AppColor.cream.opacity(0.96)
    }
}

struct HumanAssistantOrbView: View {
    let isListening: Bool
    let isSpeaking: Bool
    let isProcessing: Bool
    let audioLevel: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke((isListening ? AppColor.mintGreenDeep : AppColor.medicalBlue).opacity(isListening ? 0.24 : 0.10), lineWidth: 2)
                    .frame(width: pulse ? CGFloat(150 + index * 24) + CGFloat(audioLevel * 26) : CGFloat(116 + index * 12))
                    .opacity(pulse ? 0.1 : 0.5)
            }
            Circle()
                .fill((isListening ? AppColor.mintGreenDeep : AppColor.medicalBlue).opacity(0.14))
                .frame(width: 190, height: 190)
                .blur(radius: 18)
            Circle()
                .fill(AppGradient.primaryButton)
                .frame(width: 128, height: 128)
                .overlay(
                    Image(systemName: isSpeaking ? "speaker.wave.2.fill" : isListening ? "waveform" : "mic.fill")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(.white)
                )
                .appShadow(AppShadow.button)

            if isProcessing {
                ThinkingDotsView()
                    .offset(y: 88)
            } else if isSpeaking {
                AssistantWaveformView()
                    .offset(y: 88)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = true }
        .accessibilityLabel(isListening ? "Listening" : "Voice assistant")
    }
}

struct HumanAssistantMessageCard: View {
    let transcript: String
    let partialTranscript: String
    let response: String

    var body: some View {
        PillCardContainer(style: .highlighted, padding: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Label("You said", systemImage: "person.fill")
                    .font(AppFont.badge)
                    .foregroundStyle(AppColor.secondaryInk)
                Text(displayTranscript)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.ink)
                Divider()
                Label("Assistant", systemImage: "heart.text.square.fill")
                    .font(AppFont.badge)
                    .foregroundStyle(AppColor.medicalBlue)
                Text(response)
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var displayTranscript: String {
        if !transcript.isEmpty { return transcript }
        if !partialTranscript.isEmpty { return partialTranscript }
        return "Tap Start listening and speak naturally."
    }
}

struct AssistantMicControlButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isActive: Bool
    let highContrast: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.medium) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(isActive ? AppColor.softRed : highContrast ? AppColor.medicalBlueDeep : AppColor.medicalBlue, in: Circle())

                VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                    Text(title)
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(Spacing.medium)
            .background((highContrast ? AppColor.cream : .white).opacity(isDisabled ? 0.58 : 0.92), in: Capsule())
            .overlay(
                Capsule()
                    .stroke((isActive ? AppColor.softRed : AppColor.medicalBlue).opacity(0.18), lineWidth: 1)
            )
            .appShadow(AppShadow.pill)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.65 : 1)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

struct AIModelDownloadCard: View {
    let modelTitle: String
    let estimatedSize: String
    let estimatedSetupTime: String
    let progress: Double
    let isInstalling: Bool
    let isLoading: Bool
    let isInstalled: Bool
    let storageUsage: String
    let statusText: String
    let downloadedText: String
    let totalText: String
    let modelState: WhisperModelState
    let errorMessage: String?
    let action: () -> Void

    var body: some View {
        PillCardContainer(style: .lavender, padding: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(spacing: Spacing.medium) {
                    CircularModelProgressView(progress: progress, isActive: isInstalling || isLoading)

                    VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                        Text("Set up offline AI")
                            .font(AppFont.sectionTitle)
                            .foregroundStyle(AppColor.ink)
                        Text("The model downloads once, then voice understanding runs on this device.")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    setupRow("Model", value: modelTitle)
                    setupRow("Estimated size", value: estimatedSize)
                    setupRow("Setup time", value: estimatedSetupTime)
                    setupRow("Cloud recording", value: "Never")
                }

                if isInstalled {
                    ModelInstalledBadge(modelTitle: modelTitle)
                    StorageUsageView(storageUsage: storageUsage)
                }

                if isInstalling || isLoading || progress > 0 {
                    DownloadProgressView(progress: progress, statusText: statusText, downloadedText: downloadedText, totalText: totalText)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.softRed)
                }

                if !isInstalled {
                    CapsuleButton(buttonTitle, systemImage: "arrow.down.circle.fill") {
                        action()
                    }
                    .disabled(isInstalling || isLoading)
                }
            }
        }
    }

    private var buttonTitle: String {
        if isInstalling { return "Downloading..." }
        if isLoading { return "Loading..." }
        if case .failed = modelState { return "Retry Download" }
        return "Download AI Model"
    }

    private func setupRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
            Spacer()
            Text(value)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.ink)
        }
    }
}

typealias WhisperModelSetupCard = AIModelDownloadCard

struct DownloadProgressView: View {
    let progress: Double
    let statusText: String
    let downloadedText: String
    let totalText: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack {
                Text(statusText)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.ink)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(AppFont.badge)
                    .foregroundStyle(AppColor.medicalBlueDeep)
            }
            ProgressView(value: progress)
                .tint(AppColor.medicalBlue)
            Text("\(downloadedText) of \(totalText) • \(Int((1 - min(max(progress, 0), 1)) * 100))% pending")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
        }
        .padding(Spacing.small)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
    }
}

struct CircularModelProgressView: View {
    let progress: Double
    let isActive: Bool
    @State private var glow = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColor.medicalBlue.opacity(glow ? 0.16 : 0.08))
                .frame(width: 78, height: 78)
                .blur(radius: 8)
            Circle()
                .stroke(AppColor.medicalBlue.opacity(0.16), lineWidth: 7)
                .frame(width: 62, height: 62)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(AppColor.medicalBlue, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .frame(width: 62, height: 62)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)
            Text("\(Int(progress * 100))%")
                .font(AppFont.badge)
                .foregroundStyle(AppColor.ink)
        }
        .animation(isActive ? .easeInOut(duration: 1.6).repeatForever(autoreverses: true) : .default, value: glow)
        .onAppear { glow = true }
    }
}

struct ModelInstalledBadge: View {
    let modelTitle: String

    var body: some View {
        Label("\(modelTitle) installed", systemImage: "checkmark.seal.fill")
            .font(AppFont.badge)
            .foregroundStyle(AppColor.mintGreenDeep)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(AppColor.mintGreen.opacity(0.14), in: Capsule())
    }
}

struct StorageUsageView: View {
    let storageUsage: String

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            Image(systemName: "internaldrive.fill")
                .foregroundStyle(AppColor.medicalBlue)
            Text("Model storage: \(storageUsage)")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
            Spacer()
        }
    }
}

struct LiveTranscriptionCard: View {
    let partialTranscript: String
    let audioLevel: Double

    var body: some View {
        PillCardContainer(padding: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Label("Live listening", systemImage: "waveform")
                    .font(AppFont.badge)
                    .foregroundStyle(AppColor.medicalBlue)
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<14, id: \.self) { index in
                        Capsule()
                            .fill(AppColor.medicalBlue.opacity(0.35 + min(audioLevel, 0.65)))
                            .frame(width: 5, height: max(8, CGFloat((Double(index % 5) + 1) * 5) * CGFloat(0.45 + audioLevel)))
                    }
                }
                Text(partialTranscript.isEmpty ? "Speak naturally. I’ll process after a short pause." : partialTranscript)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.ink)
            }
        }
    }
}

struct AssistantWaveformView: View {
    @State private var animate = false
    private let heights: [CGFloat] = [10, 18, 28, 16, 24, 12]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(heights.indices, id: \.self) { index in
                Capsule()
                    .fill(AppColor.medicalBlue)
                    .frame(width: 5, height: animate ? heights[index] : 8)
                    .animation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(Double(index) * 0.06), value: animate)
            }
        }
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.xSmall)
        .background(.white.opacity(0.82), in: Capsule())
        .onAppear { animate = true }
    }
}

struct ThinkingDotsView: View {
    @State private var active = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(AppColor.medicalBlue)
                    .frame(width: 7, height: 7)
                    .opacity(active ? 1 : 0.35)
                    .scaleEffect(active ? 1.15 : 0.8)
                    .animation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(Double(index) * 0.12), value: active)
            }
        }
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.xSmall)
        .background(.white.opacity(0.82), in: Capsule())
        .onAppear { active = true }
    }
}
