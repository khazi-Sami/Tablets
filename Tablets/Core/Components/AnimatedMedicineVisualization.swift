import SwiftUI

struct AnimatedMedicineVisualization: View {
    let type: MedicineType
    var isActive: Bool = true
    var size: CGFloat = 118

    @State private var pressed = false

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                MedicineGlowCanvas(type: type, time: time)
                    .frame(width: size * 1.42, height: size * 1.42)
                    .opacity(isActive ? 1 : 0.62)

                MedicineObjectCanvas(type: type, time: time, isActive: isActive)
                    .frame(width: size, height: size)
                    .offset(y: isActive ? CGFloat(sin(time * 1.25)) * 5 : 0)
                    .rotation3DEffect(
                        .degrees(isActive ? sin(time * 0.9) * 8 : 0),
                        axis: (x: 0.18, y: 0.74, z: 0.08),
                        perspective: 0.62
                    )
                    .scaleEffect(pressed ? 0.94 : 1)
            }
        }
        .frame(width: size * 1.42, height: size * 1.42)
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: 0.01, pressing: { isPressing in
            pressed = isPressing
            if isPressing {
                HapticsManager.impact(.soft)
            }
        }, perform: {})
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: pressed)
        .accessibilityLabel(type.title)
    }
}

private struct MedicineGlowCanvas: View {
    let type: MedicineType
    let time: TimeInterval

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let pulse = 0.74 + sin(time * 1.5) * 0.12
            let radius = min(size.width, size.height) * pulse

            var glow = Path()
            glow.addEllipse(in: CGRect(
                x: center.x - radius / 2,
                y: center.y - radius / 2,
                width: radius,
                height: radius
            ))

            context.addFilter(.blur(radius: 18))
            context.fill(
                glow,
                with: .radialGradient(
                    Gradient(colors: [primaryColor.opacity(0.34), primaryColor.opacity(0.02)]),
                    center: center,
                    startRadius: 4,
                    endRadius: radius / 2
                )
            )

            for index in 0..<3 {
                let ringScale = 0.44 + Double(index) * 0.18 + (time.truncatingRemainder(dividingBy: 2.4) / 2.4) * 0.16
                let ringRadius = min(size.width, size.height) * ringScale
                var ring = Path()
                ring.addEllipse(in: CGRect(
                    x: center.x - ringRadius / 2,
                    y: center.y - ringRadius / 2,
                    width: ringRadius,
                    height: ringRadius
                ))
                context.stroke(ring, with: .color(primaryColor.opacity(0.08)), lineWidth: 1.2)
            }
        }
    }

    private var primaryColor: Color {
        switch type {
        case .tablet, .injection: return AppColor.medicalBlue
        case .capsule, .powder: return AppColor.mintGreenDeep
        case .syrup, .drops: return AppColor.lavenderDeep
        }
    }
}

private struct MedicineObjectCanvas: View {
    let type: MedicineType
    let time: TimeInterval
    let isActive: Bool

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)

            switch type {
            case .tablet:
                drawTablet(in: rect, context: &context)
            case .capsule:
                drawCapsule(in: rect, context: &context)
            case .syrup:
                drawSyrup(in: rect, context: &context)
            case .injection:
                drawInjection(in: rect, context: &context)
            case .drops:
                drawDrops(in: rect, context: &context)
            case .powder:
                drawPowder(in: rect, context: &context)
            }
        }
    }

    private func drawTablet(in rect: CGRect, context: inout GraphicsContext) {
        let rotation = Angle.degrees(time * 9)
        let tabletRect = rect.insetBy(dx: rect.width * 0.15, dy: rect.height * 0.28)
        var tablet = Path(roundedRect: tabletRect, cornerRadius: tabletRect.height / 2)
        tablet = tablet.applying(.init(translationX: -rect.midX, y: -rect.midY))
            .applying(.init(rotationAngle: rotation.radians))
            .applying(.init(translationX: rect.midX, y: rect.midY))

        context.fill(tablet, with: .linearGradient(
            Gradient(colors: [AppColor.warmWhite, AppColor.medicalBlue.opacity(0.58), AppColor.medicalBlueDeep.opacity(0.72)]),
            startPoint: CGPoint(x: tabletRect.minX, y: tabletRect.minY),
            endPoint: CGPoint(x: tabletRect.maxX, y: tabletRect.maxY)
        ))
        context.stroke(tablet, with: .color(Color.white.opacity(0.62)), lineWidth: 2)

        var groove = Path()
        groove.move(to: CGPoint(x: rect.midX, y: tabletRect.minY + 8))
        groove.addLine(to: CGPoint(x: rect.midX, y: tabletRect.maxY - 8))
        context.stroke(groove, with: .color(Color.white.opacity(0.42)), lineWidth: 2)
    }

    private func drawCapsule(in rect: CGRect, context: inout GraphicsContext) {
        let split = CGFloat(sin(time * 1.8)) * 5
        let capsuleRect = rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.31)
        let leftRect = CGRect(x: capsuleRect.minX - split, y: capsuleRect.minY, width: capsuleRect.width / 2 + 7, height: capsuleRect.height)
        let rightRect = CGRect(x: capsuleRect.midX - 7 + split, y: capsuleRect.minY, width: capsuleRect.width / 2 + 7, height: capsuleRect.height)

        let left = Path(roundedRect: leftRect, cornerRadius: capsuleRect.height / 2)
        let right = Path(roundedRect: rightRect, cornerRadius: capsuleRect.height / 2)

        context.fill(left, with: .linearGradient(
            Gradient(colors: [AppColor.medicalBlueDeep, AppColor.medicalBlue]),
            startPoint: leftRect.origin,
            endPoint: CGPoint(x: leftRect.maxX, y: leftRect.maxY)
        ))
        context.fill(right, with: .linearGradient(
            Gradient(colors: [AppColor.mintGreen, AppColor.mintGreenDeep]),
            startPoint: rightRect.origin,
            endPoint: CGPoint(x: rightRect.maxX, y: rightRect.maxY)
        ))
        context.stroke(left, with: .color(Color.white.opacity(0.58)), lineWidth: 2)
        context.stroke(right, with: .color(Color.white.opacity(0.48)), lineWidth: 2)

        var seam = Path()
        seam.move(to: CGPoint(x: rect.midX, y: capsuleRect.minY + 5))
        seam.addLine(to: CGPoint(x: rect.midX, y: capsuleRect.maxY - 5))
        context.stroke(seam, with: .color(Color.white.opacity(0.36)), lineWidth: 1.4)
    }

    private func drawSyrup(in rect: CGRect, context: inout GraphicsContext) {
        let bottle = CGRect(x: rect.midX - rect.width * 0.24, y: rect.minY + rect.height * 0.2, width: rect.width * 0.48, height: rect.height * 0.66)
        let cap = CGRect(x: rect.midX - rect.width * 0.15, y: rect.minY + rect.height * 0.09, width: rect.width * 0.3, height: rect.height * 0.16)
        let bottlePath = Path(roundedRect: bottle, cornerRadius: rect.width * 0.11)
        let capPath = Path(roundedRect: cap, cornerRadius: rect.width * 0.05)

        context.fill(bottlePath, with: .linearGradient(
            Gradient(colors: [AppColor.lavender.opacity(0.88), AppColor.medicalBlue.opacity(0.36), AppColor.lavenderDeep.opacity(0.72)]),
            startPoint: bottle.origin,
            endPoint: CGPoint(x: bottle.maxX, y: bottle.maxY)
        ))
        context.fill(capPath, with: .color(AppColor.medicalBlueDeep.opacity(0.76)))
        context.stroke(bottlePath, with: .color(Color.white.opacity(0.55)), lineWidth: 2)

        var liquid = Path()
        let baseY = bottle.maxY - bottle.height * 0.36
        liquid.move(to: CGPoint(x: bottle.minX + 5, y: bottle.maxY - 8))
        liquid.addLine(to: CGPoint(x: bottle.minX + 5, y: baseY))
        for step in 0...8 {
            let x = bottle.minX + 5 + CGFloat(step) * (bottle.width - 10) / 8
            let y = baseY + CGFloat(sin(time * 2.0 + Double(step) * 0.8)) * 4
            liquid.addLine(to: CGPoint(x: x, y: y))
        }
        liquid.addLine(to: CGPoint(x: bottle.maxX - 5, y: bottle.maxY - 8))
        liquid.closeSubpath()
        context.fill(liquid, with: .linearGradient(
            Gradient(colors: [AppColor.mintGreen.opacity(0.72), AppColor.medicalBlue.opacity(0.44)]),
            startPoint: CGPoint(x: bottle.minX, y: baseY),
            endPoint: CGPoint(x: bottle.maxX, y: bottle.maxY)
        ))

        let label = Path(roundedRect: bottle.insetBy(dx: 12, dy: 28), cornerRadius: 8)
        context.fill(label, with: .color(AppColor.warmWhite.opacity(0.78)))
    }

    private func drawInjection(in rect: CGRect, context: inout GraphicsContext) {
        let pulse = CGFloat(0.5 + sin(time * 2.2) * 0.5)
        context.translateBy(x: rect.midX, y: rect.midY)
        context.rotate(by: .degrees(-32))
        context.translateBy(x: -rect.midX, y: -rect.midY)

        let barrel = CGRect(x: rect.midX - rect.width * 0.28, y: rect.midY - rect.height * 0.12, width: rect.width * 0.56, height: rect.height * 0.24)
        let barrelPath = Path(roundedRect: barrel, cornerRadius: 8)
        context.fill(barrelPath, with: .linearGradient(
            Gradient(colors: [AppColor.warmWhite.opacity(0.95), AppColor.medicalBlue.opacity(0.35)]),
            startPoint: barrel.origin,
            endPoint: CGPoint(x: barrel.maxX, y: barrel.maxY)
        ))
        context.stroke(barrelPath, with: .color(AppColor.medicalBlue.opacity(0.52)), lineWidth: 2)

        var needle = Path()
        needle.move(to: CGPoint(x: barrel.maxX, y: rect.midY))
        needle.addLine(to: CGPoint(x: rect.maxX - 8, y: rect.midY))
        context.stroke(needle, with: .color(AppColor.medicalBlueDeep.opacity(0.78)), lineWidth: 2 + pulse)

        var plunger = Path()
        plunger.move(to: CGPoint(x: barrel.minX - 24, y: rect.midY))
        plunger.addLine(to: CGPoint(x: barrel.minX, y: rect.midY))
        context.stroke(plunger, with: .color(AppColor.lavenderDeep.opacity(0.82)), lineWidth: 6)
    }

    private func drawDrops(in rect: CGRect, context: inout GraphicsContext) {
        let center = CGPoint(x: rect.midX, y: rect.midY - 4)
        let ripple = CGFloat(time.truncatingRemainder(dividingBy: 1.8) / 1.8)
        for index in 0..<3 {
            let radius = rect.width * (0.18 + ripple * 0.28 + CGFloat(index) * 0.08)
            var ring = Path()
            ring.addEllipse(in: CGRect(x: center.x - radius, y: center.y + rect.height * 0.18 - radius * 0.38, width: radius * 2, height: radius * 0.76))
            context.stroke(ring, with: .color(AppColor.medicalBlue.opacity(0.18 - Double(index) * 0.04)), lineWidth: 1.5)
        }

        var drop = Path()
        drop.move(to: CGPoint(x: center.x, y: rect.minY + rect.height * 0.12))
        drop.addCurve(to: CGPoint(x: center.x - rect.width * 0.2, y: center.y + rect.height * 0.12), control1: CGPoint(x: center.x - rect.width * 0.22, y: center.y - rect.height * 0.1), control2: CGPoint(x: center.x - rect.width * 0.28, y: center.y + rect.height * 0.08))
        drop.addCurve(to: CGPoint(x: center.x + rect.width * 0.2, y: center.y + rect.height * 0.12), control1: CGPoint(x: center.x - rect.width * 0.04, y: center.y + rect.height * 0.32), control2: CGPoint(x: center.x + rect.width * 0.28, y: center.y + rect.height * 0.08))
        drop.addCurve(to: CGPoint(x: center.x, y: rect.minY + rect.height * 0.12), control1: CGPoint(x: center.x + rect.width * 0.28, y: center.y - rect.height * 0.1), control2: CGPoint(x: center.x + rect.width * 0.08, y: rect.minY + rect.height * 0.2))
        context.fill(drop, with: .linearGradient(
            Gradient(colors: [AppColor.warmWhite.opacity(0.86), AppColor.medicalBlue.opacity(0.58), AppColor.lavenderDeep.opacity(0.72)]),
            startPoint: CGPoint(x: center.x, y: rect.minY),
            endPoint: CGPoint(x: center.x, y: rect.maxY)
        ))
        context.stroke(drop, with: .color(Color.white.opacity(0.55)), lineWidth: 2)
    }

    private func drawPowder(in rect: CGRect, context: inout GraphicsContext) {
        let sachet = CGRect(x: rect.midX - rect.width * 0.22, y: rect.midY - rect.height * 0.34, width: rect.width * 0.44, height: rect.height * 0.62)
        let sachetPath = Path(roundedRect: sachet, cornerRadius: rect.width * 0.08)
        context.fill(sachetPath, with: .linearGradient(
            Gradient(colors: [AppColor.warmWhite, AppColor.mintGreen.opacity(0.5)]),
            startPoint: sachet.origin,
            endPoint: CGPoint(x: sachet.maxX, y: sachet.maxY)
        ))
        context.stroke(sachetPath, with: .color(AppColor.mintGreenDeep.opacity(0.52)), lineWidth: 2)

        for index in 0..<16 {
            let angle = Double(index) * 0.68 + time
            let distance = CGFloat(14 + (index % 5) * 5)
            let point = CGPoint(
                x: rect.midX + cos(angle) * distance,
                y: rect.midY + rect.height * 0.16 + sin(angle * 1.2) * distance * 0.45
            )
            var particle = Path()
            particle.addEllipse(in: CGRect(x: point.x, y: point.y, width: 3.2, height: 3.2))
            context.fill(particle, with: .color(AppColor.mintGreenDeep.opacity(0.42)))
        }
    }
}

struct AnimatedMedicineVisualizationGallery: View {
    private let columns = [
        GridItem(.flexible(), spacing: Spacing.small),
        GridItem(.flexible(), spacing: Spacing.small)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.medium) {
            ForEach(MedicineType.allCases) { type in
                PillCardContainer {
                    VStack(spacing: Spacing.small) {
                        AnimatedMedicineVisualization(type: type, size: 112)
                        Text(type.title)
                            .font(AppFont.bodyStrong)
                            .foregroundStyle(AppColor.ink)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        AnimatedMedicineVisualizationGallery()
            .padding()
    }
    .background(AppGradient.background)
}
