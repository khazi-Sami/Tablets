import AVFoundation
import SwiftData
import SwiftUI

enum QuickVoiceOverlayState {
    case preparing
    case listening
    case userSpeaking
    case processing
    case speaking
    case completed
    case error
}

struct QuickVoiceOverlayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var preferences: [HumanAssistantPreference]
    @StateObject private var speechService = WhisperKitSpeechToTextService()
    @StateObject private var ttsService = TTSService()
    @State private var sessionManager: VoiceSessionManager?
    @State private var overlayState: QuickVoiceOverlayState = .preparing
    @State private var transcript = ""
    @State private var response = "Listening on device"
    @State private var errorMessage = ""
    @State private var pulse = false
    @State private var autoStopTask: Task<Void, Never>?
    @State private var lifecycleTask: Task<Void, Never>?

    let appRouter: AppRouter
    let openFullAssistant: () -> Void

    var body: some View {
        ZStack {
            background

            VStack(spacing: Spacing.large) {
                header

                Spacer(minLength: 24)

                orb

                VStack(spacing: Spacing.small) {
                    Text(statusTitle)
                        .font(AppFont.title)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(displayText)
                        .font(AppFont.body)
                        .foregroundStyle(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .lineLimit(5)
                        .padding(.horizontal, Spacing.large)
                }

                if overlayState == .listening || overlayState == .userSpeaking || overlayState == .speaking {
                    QuickAssistantWaveform(audioLevel: speechService.audioLevel, isSpeaking: overlayState == .speaking)
                        .frame(height: 54)
                        .padding(.horizontal, Spacing.large)
                }

                if overlayState == .error {
                    errorActions
                } else if overlayState == .completed {
                    completedActions
                }

                Spacer(minLength: 24)

                Text("Listening on device")
                    .font(AppFont.caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .accessibilityLabel("Listening on device. Voice processing is local.")
            }
            .padding(Spacing.large)
        }
        .onAppear { startFlow() }
        .onDisappear {
            autoStopTask?.cancel()
            lifecycleTask?.cancel()
            ttsService.stop()
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.06, blue: 0.14),
                    AppColor.medicalBlueDeep.opacity(0.88),
                    AppColor.lavenderDeep.opacity(0.74)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.35))
                .ignoresSafeArea()

            ForEach(0..<18, id: \.self) { index in
                Circle()
                    .fill((index.isMultiple(of: 2) ? AppColor.mintGreen : AppColor.medicalBlue).opacity(0.16))
                    .frame(width: CGFloat(4 + (index % 4) * 3), height: CGFloat(4 + (index % 4) * 3))
                    .offset(x: CGFloat((index * 37) % 280) - 140, y: pulse ? CGFloat((index * 53) % 640) - 320 : CGFloat((index * 47) % 640) - 320)
                    .blur(radius: 0.5)
                    .animation(reduceMotion ? nil : .easeInOut(duration: Double(5 + index % 4)).repeatForever(autoreverses: true), value: pulse)
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                cancel()
            } label: {
                Label("Cancel", systemImage: "xmark")
                    .labelStyle(.titleAndIcon)
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(.white.opacity(0.16), in: Capsule())
            }
            .accessibilityLabel("Cancel voice assistant")

            Spacer()
        }
    }

    private var orb: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(.white.opacity(overlayState == .listening || overlayState == .userSpeaking ? 0.20 : 0.08), lineWidth: 2)
                    .frame(width: pulse ? CGFloat(180 + index * 46) : CGFloat(126 + index * 24))
                    .opacity(pulse ? 0.05 : 0.35)
            }

            Circle()
                .fill(AppColor.medicalBlue.opacity(0.28))
                .frame(width: 182, height: 182)
                .blur(radius: 26)

            Circle()
                .fill(AppGradient.primaryButton)
                .frame(width: overlayState == .userSpeaking ? 138 + CGFloat(speechService.audioLevel * 26) : 132)
                .overlay {
                    Image(systemName: orbSymbol)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(overlayState == .processing && !reduceMotion ? 12 : 0))
                }
                .appShadow(AppShadow.button)

            if overlayState == .processing {
                ThinkingDotsView()
                    .offset(y: 100)
            }
        }
        .frame(height: 260)
        .animation(reduceMotion ? nil : .easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: speechService.audioLevel)
        .onAppear { pulse = true }
        .accessibilityLabel(statusTitle)
    }

    private var errorActions: some View {
        HStack(spacing: Spacing.small) {
            Button("Try again") {
                startFlow()
            }
            .buttonStyle(.borderedProminent)

            Button("Open full assistant") {
                dismiss()
                openFullAssistant()
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
    }

    private var completedActions: some View {
        HStack(spacing: Spacing.small) {
            Button("Ask another question") {
                startFlow()
            }
            .buttonStyle(.borderedProminent)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
    }

    private var statusTitle: String {
        switch overlayState {
        case .preparing: return "Preparing..."
        case .listening: return "Listening..."
        case .userSpeaking: return "I hear you"
        case .processing: return "Thinking..."
        case .speaking: return "Answering..."
        case .completed: return "Done"
        case .error: return "Please try again"
        }
    }

    private var displayText: String {
        if !errorMessage.isEmpty { return errorMessage }
        if !response.isEmpty && overlayState != .listening && overlayState != .userSpeaking { return response }
        if !transcript.isEmpty { return transcript }
        if !speechService.partialTranscript.isEmpty { return speechService.partialTranscript }
        return "Speak naturally after the sound."
    }

    private var orbSymbol: String {
        switch overlayState {
        case .preparing: return "sparkles"
        case .listening, .userSpeaking: return "mic.fill"
        case .processing: return "heart.text.square.fill"
        case .speaking: return "speaker.wave.2.fill"
        case .completed: return "checkmark"
        case .error: return "exclamationmark"
        }
    }

    private func startFlow() {
        autoStopTask?.cancel()
        lifecycleTask?.cancel()
        errorMessage = ""
        transcript = ""
        response = ""
        overlayState = .preparing

        guard WhisperModelManager.shared.isReady else {
            overlayState = .error
            errorMessage = "Offline voice model is not ready yet."
            return
        }

        lifecycleTask = Task {
            let permission = AssistantPermissionService()
            if permission.microphoneStatus() != .authorized {
                let granted = await permission.requestMicrophoneAccess()
                guard granted else {
                    overlayState = .error
                    errorMessage = permission.permissionMessage
                    return
                }
            }

            do {
                setupSessionIfNeeded()
                ttsService.stop()
                try await speechService.startListening()
                overlayState = .listening
                watchForStop()
                HapticsManager.impact(.soft)
            } catch {
                overlayState = .error
                errorMessage = "I could not start listening. Please try again."
                HapticsManager.notification(.error)
            }
        }
    }

    private func setupSessionIfNeeded() {
        if sessionManager == nil {
            let manager = VoiceSessionManager(modelContext: modelContext, ttsService: ttsService) {
                preferences.first
            }
            manager.configureNavigation(appRouter: appRouter, dismissAssistant: nil)
            sessionManager = manager
        }
    }

    private func watchForStop() {
        autoStopTask?.cancel()
        autoStopTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(160))
                if speechService.audioLevel > 0.18 && speechService.isListening {
                    overlayState = .userSpeaking
                } else if speechService.isListening && overlayState == .userSpeaking {
                    overlayState = .listening
                }

                guard speechService.autoStopRequested && speechService.isListening else { continue }
                await stopAndProcess()
                return
            }
        }
    }

    private func stopAndProcess() async {
        overlayState = .processing
        do {
            let text = try await speechService.stopListening().trimmingCharacters(in: .whitespacesAndNewlines)
            transcript = text
            guard !text.isEmpty else {
                overlayState = .error
                errorMessage = "I didn't hear anything. Please try again."
                return
            }

            setupSessionIfNeeded()
            guard let sessionManager else { return }
            let result = await sessionManager.process(transcript: text)
            response = result.response
            overlayState = (preferences.first?.prefersSpokenResponses ?? true) ? .speaking : .completed
            scheduleCompletion(for: result)
        } catch {
            overlayState = .error
            errorMessage = "I could not understand that clearly. Please try again."
        }
    }

    private func scheduleCompletion(for result: VoiceSessionResult) {
        lifecycleTask?.cancel()
        lifecycleTask = Task {
            if result.shouldAutoDismiss {
                try? await Task.sleep(for: .milliseconds(600))
                dismiss()
            } else {
                try? await Task.sleep(for: .seconds(3))
                if !Task.isCancelled {
                    overlayState = .completed
                }
            }
        }
    }

    private func cancel() {
        autoStopTask?.cancel()
        lifecycleTask?.cancel()
        ttsService.stop()
        if speechService.isListening {
            Task { _ = try? await speechService.stopListening() }
        }
        dismiss()
    }
}

private struct QuickAssistantWaveform: View {
    let audioLevel: Double
    let isSpeaking: Bool
    @State private var animate = false

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<28, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.82))
                    .frame(width: 4, height: barHeight(index))
                    .animation(.easeInOut(duration: 0.28), value: audioLevel)
            }
        }
        .onAppear { animate = true }
    }

    private func barHeight(_ index: Int) -> CGFloat {
        let base = CGFloat((index % 7) + 1) * 5
        let reactive = CGFloat(audioLevel) * 46
        let speaking = isSpeaking && animate ? CGFloat((index % 5) * 4) : 0
        return max(10, base + reactive + speaking)
    }
}
