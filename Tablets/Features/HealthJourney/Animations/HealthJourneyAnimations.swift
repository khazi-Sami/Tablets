import SwiftUI

struct EmotionalGradientView: View {
    let mode: EmotionalWellnessMode

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var colors: [Color] {
        switch mode {
        case .calm:
            return [AppColor.warmWhite, Color(red: 0.86, green: 0.96, blue: 1), AppColor.mintGreen.opacity(0.42)]
        case .energetic:
            return [Color(red: 1, green: 0.86, blue: 0.62), AppColor.warmWhite, AppColor.medicalBlue.opacity(0.28)]
        case .recovery:
            return [AppColor.lavender.opacity(0.86), AppColor.warmWhite, Color(red: 0.84, green: 0.94, blue: 0.98)]
        case .focus:
            return [Color(red: 1, green: 0.91, blue: 0.76), AppColor.warmWhite, AppColor.lavender.opacity(0.54)]
        case .healing:
            return [Color(red: 1, green: 0.91, blue: 0.95), AppColor.lavender.opacity(0.92), AppColor.warmWhite]
        }
    }
}

struct JourneyWaveBackground: View {
    let mode: EmotionalWellnessMode

    var body: some View {
        Canvas { context, size in
            for layer in 0..<2 {
                var path = Path()
                let baseY = size.height * (0.62 + CGFloat(layer) * 0.16)
                path.move(to: CGPoint(x: 0, y: baseY))

                for x in stride(from: 0, through: size.width, by: 12) {
                    let y = baseY + CGFloat(sin(Double(x) * 0.012 + Double(layer))) * CGFloat(14 + layer * 5)
                    path.addLine(to: CGPoint(x: x, y: y))
                }

                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.closeSubpath()
                context.fill(path, with: .color(color.opacity(0.045 + Double(layer) * 0.025)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var color: Color {
        switch mode {
        case .calm: return AppColor.medicalBlue
        case .energetic: return Color.orange
        case .recovery, .healing: return AppColor.lavenderDeep
        case .focus: return AppColor.softRed
        }
    }
}

struct FloatingHealthOrb: View {
    let mode: EmotionalWellnessMode

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.10))
                .frame(width: 76, height: 76)
                .blur(radius: 12)

            Circle()
                .fill(AppGradient.primaryButton)
                .frame(width: 62, height: 62)
                .overlay(
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                )
                .shadow(color: color.opacity(0.22), radius: 14, x: 0, y: 8)
        }
        .accessibilityHidden(true)
    }

    private var color: Color {
        switch mode {
        case .calm: return AppColor.medicalBlue
        case .energetic: return Color.orange
        case .recovery: return AppColor.lavenderDeep
        case .focus: return AppColor.softRed
        case .healing: return AppColor.mintGreenDeep
        }
    }
}

struct WellnessProgressRing: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: 12)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.ink)
        }
    }
}

struct StreakCelebrationView: View {
    let isActive: Bool

    var body: some View {
        Group {
            if isActive {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for index in 0..<34 {
                    let seed = Double(index)
                    let x = size.width * CGFloat((seed * 0.37).truncatingRemainder(dividingBy: 1))
                    let y = size.height * CGFloat((time * 0.24 + seed * 0.071).truncatingRemainder(dividingBy: 1))
                    let rect = CGRect(x: x, y: y, width: 5, height: 9)
                    var piece = Path(roundedRect: rect, cornerRadius: 2)
                    piece = piece.applying(.init(rotationAngle: time + seed))
                    context.fill(piece, with: .color([AppColor.medicalBlue, AppColor.mintGreenDeep, AppColor.lavenderDeep, Color.orange][index % 4].opacity(0.56)))
                }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
