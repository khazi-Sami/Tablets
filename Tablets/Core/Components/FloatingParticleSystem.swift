import SwiftUI

struct FloatingParticleSystem: View {
    let style: HealthAuraStyle
    var particleCount: Int = 28

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for index in 0..<particleCount {
                    let seed = Double(index + 1)
                    let progress = (time * (0.018 + seed.truncatingRemainder(dividingBy: 5) * 0.004) + seed * 0.137)
                        .truncatingRemainder(dividingBy: 1)
                    let xWave = sin(time * 0.28 + seed) * 22
                    let x = size.width * CGFloat((seed * 0.618).truncatingRemainder(dividingBy: 1)) + CGFloat(xWave)
                    let y = size.height * CGFloat(1 - progress)
                    let radius = CGFloat(2.4 + seed.truncatingRemainder(dividingBy: 4))
                    let alpha = style.particleOpacity * (0.35 + 0.65 * sin(progress * .pi))

                    var particle = Path()
                    particle.addEllipse(in: CGRect(x: x, y: y, width: radius, height: radius))
                    context.fill(
                        particle,
                        with: .color((index.isMultiple(of: 2) ? style.accent : style.secondaryAccent).opacity(alpha))
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
