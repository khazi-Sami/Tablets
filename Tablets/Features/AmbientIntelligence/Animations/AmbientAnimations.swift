import SwiftUI

struct AmbientAdaptiveGradientView: View {
    let state: AmbientIntelligenceState

    var body: some View {
        LinearGradient(
            colors: colors.map { $0.opacity(state.brightness) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var colors: [Color] {
        switch state.timeMode {
        case .morning:
            return [Color(red: 1, green: 0.88, blue: 0.68), AppColor.warmWhite, AppColor.mintGreen.opacity(0.42)]
        case .afternoon:
            return [AppColor.warmWhite, Color(red: 0.88, green: 0.97, blue: 1), AppColor.medicalBlue.opacity(0.24)]
        case .night:
            return [Color(red: 0.08, green: 0.11, blue: 0.18), Color(red: 0.12, green: 0.18, blue: 0.28), AppColor.lavenderDeep.opacity(0.36)]
        }
    }
}

struct AmbientBreathingGlow: View {
    let state: AmbientIntelligenceState
    @State private var breathe = false

    var body: some View {
        Circle()
            .fill(accent.opacity(0.14))
            .frame(width: breathe ? 170 : 146, height: breathe ? 170 : 146)
            .blur(radius: 26)
            .opacity(state.animationSpeed == 0 ? 0.42 : 1)
            .animation(state.animationSpeed == 0 ? nil : .easeInOut(duration: 4.8 / state.animationSpeed).repeatForever(autoreverses: true), value: breathe)
            .onAppear { breathe = true }
            .accessibilityHidden(true)
    }

    private var accent: Color {
        switch state.emotionalMode {
        case .calm, .simplified: return AppColor.medicalBlue
        case .focused: return Color.orange
        case .healing: return AppColor.lavenderDeep
        case .celebratory: return AppColor.mintGreenDeep
        }
    }
}

struct AmbientPulseWaveView: View {
    let state: AmbientIntelligenceState

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard state.animationSpeed > 0 else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate * state.animationSpeed
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                for index in 0..<3 {
                    let progress = (time * 0.16 + Double(index) * 0.28).truncatingRemainder(dividingBy: 1)
                    let radius = min(size.width, size.height) * CGFloat(0.18 + progress * 0.32)
                    var path = Path()
                    path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                    context.stroke(path, with: .color(AppColor.medicalBlue.opacity((1 - progress) * 0.12)), lineWidth: 1)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

