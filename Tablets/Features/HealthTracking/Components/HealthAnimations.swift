import SwiftUI

struct BeatingHeartView: View {
    var size: CGFloat = 42
    @State private var beat = false

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(AppColor.softRed)
            .scaleEffect(beat ? 1.12 : 0.94)
            .animation(.easeInOut(duration: 0.78).repeatForever(autoreverses: true), value: beat)
            .onAppear { beat = true }
    }
}

struct PulseWaveView: View {
    var color: Color = AppColor.medicalBlue
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(color.opacity(0.28), lineWidth: 2)
                    .scaleEffect(animate ? 1.8 : 0.5)
                    .opacity(animate ? 0 : 0.8)
                    .animation(.easeOut(duration: 1.8).repeatForever().delay(Double(index) * 0.38), value: animate)
            }
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(color)
        }
        .onAppear { animate = true }
    }
}

struct GlucoseDropAnimationView: View {
    @State private var offset: CGFloat = -4
    var body: some View {
        Image(systemName: "drop.fill")
            .font(.system(size: 38, weight: .bold))
            .foregroundStyle(AppColor.lavenderDeep)
            .offset(y: offset)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: offset)
            .onAppear { offset = 5 }
    }
}

struct BPMonitorAnimationView: View {
    @State private var pulse = false
    var body: some View {
        Image(systemName: "heart.text.square.fill")
            .font(.system(size: 38, weight: .bold))
            .foregroundStyle(AppColor.mintGreenDeep)
            .symbolEffect(.pulse, value: pulse)
            .onAppear { pulse.toggle() }
    }
}

struct OxygenBubbleAnimationView: View {
    @State private var rise = false
    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(AppColor.medicalBlue.opacity(0.20))
                    .frame(width: CGFloat(8 + index * 3), height: CGFloat(8 + index * 3))
                    .offset(x: CGFloat(index * 8 - 12), y: rise ? -24 : 18)
                    .opacity(rise ? 0.25 : 0.85)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(Double(index) * 0.12), value: rise)
            }
            Image(systemName: "lungs.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(AppColor.medicalBlue)
        }
        .onAppear { rise = true }
    }
}

struct ThermometerFillAnimationView: View {
    @State private var fill = false
    var body: some View {
        Image(systemName: fill ? "thermometer.high" : "thermometer.medium")
            .font(.system(size: 38, weight: .bold))
            .foregroundStyle(AppColor.softRed)
            .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: fill)
            .onAppear { fill = true }
    }
}

struct WeightScaleAnimationView: View {
    @State private var tilt = false
    var body: some View {
        Image(systemName: "scalemass.fill")
            .font(.system(size: 38, weight: .bold))
            .foregroundStyle(AppColor.mintGreenDeep)
            .rotationEffect(.degrees(tilt ? 2 : -2))
            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: tilt)
            .onAppear { tilt = true }
    }
}
