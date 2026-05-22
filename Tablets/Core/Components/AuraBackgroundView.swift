import SwiftUI

struct AuraBackgroundView: View {
    let style: HealthAuraStyle

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate

                ZStack {
                    LinearGradient(
                        colors: style.colors,
                        startPoint: UnitPoint(x: 0.08 + 0.08 * sin(time * 0.08), y: 0.02),
                        endPoint: UnitPoint(x: 0.94, y: 0.96 + 0.04 * cos(time * 0.06))
                    )

                    FloatingParticleSystem(style: style)

                    auraGlow(color: style.accent, time: time, size: proxy.size, x: 0.18, y: 0.18, phase: 0)
                    auraGlow(color: style.secondaryAccent, time: time, size: proxy.size, x: 0.82, y: 0.78, phase: 1.6)

                    Canvas { context, size in
                        let sweep = CGFloat((sin(time * 0.16) + 1) / 2)
                        let rect = CGRect(x: size.width * (sweep - 0.18), y: -size.height * 0.10, width: size.width * 0.34, height: size.height * 1.24)
                        var beam = Path(roundedRect: rect, cornerRadius: rect.width / 2)
                        beam = beam.applying(.init(rotationAngle: -0.24))
                        context.addFilter(.blur(radius: 36))
                        context.fill(beam, with: .color(Color.white.opacity(style.lightingOpacity * 0.34)))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func auraGlow(color: Color, time: TimeInterval, size: CGSize, x: CGFloat, y: CGFloat, phase: Double) -> some View {
        Circle()
            .fill(color.opacity(style.glowIntensity))
            .frame(width: 260 + CGFloat(sin(time * 0.55 + phase)) * 34, height: 260 + CGFloat(cos(time * 0.48 + phase)) * 34)
            .blur(radius: 40)
            .position(x: size.width * x, y: size.height * y)
            .allowsHitTesting(false)
    }
}
