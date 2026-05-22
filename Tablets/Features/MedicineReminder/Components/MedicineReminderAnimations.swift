import SwiftUI

struct FloatingMedicineAnimationView: View {
    let medicineType: MedicineType
    let isHeartMedicine: Bool
    @State private var float = false
    @State private var rotate = false
    @State private var swing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(glowColor.opacity(float ? 0.24 : 0.10))
                .frame(width: 230, height: 230)
                .blur(radius: 18)
                .scaleEffect(float ? 1.08 : 0.9)

            if isHeartMedicine {
                heartMedicine
            } else {
                medicineShape
            }
        }
        .offset(y: float ? -10 : 10)
        .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: float)
        .animation(.linear(duration: 16).repeatForever(autoreverses: false), value: rotate)
        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: swing)
        .onAppear {
            float = true
            rotate = true
            swing = true
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var medicineShape: some View {
        switch medicineType {
        case .tablet:
            ZStack {
                Capsule()
                    .fill(AppGradient.primaryButton)
                    .frame(width: 156, height: 76)
                Capsule()
                    .stroke(Color.white.opacity(0.62), lineWidth: 3)
                    .frame(width: 138, height: 58)
                Image(systemName: "cross.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
            .rotationEffect(.degrees(rotate ? 360 : 0))

        case .capsule:
            HStack(spacing: 0) {
                Capsule()
                    .fill(AppColor.medicalBlue)
                Capsule()
                    .fill(AppColor.mintGreenDeep)
            }
            .frame(width: 166, height: 74)
            .overlay(Capsule().stroke(Color.white.opacity(0.62), lineWidth: 3))
            .rotationEffect(.degrees(rotate ? 360 : 0))

        case .syrup:
            syrupBottle
                .rotationEffect(.degrees(swing ? 5 : -5), anchor: .top)

        case .injection:
            Image(systemName: "syringe.fill")
                .font(.system(size: 108, weight: .bold))
                .foregroundStyle(AppColor.medicalBlue)
                .rotationEffect(.degrees(swing ? -10 : 8))

        case .drops:
            Image(systemName: "drop.fill")
                .font(.system(size: 122, weight: .bold))
                .foregroundStyle(AppColor.lavenderDeep)
                .scaleEffect(float ? 1.04 : 0.94)

        case .powder:
            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                .font(.system(size: 104, weight: .bold))
                .foregroundStyle(AppColor.mintGreenDeep)
                .rotationEffect(.degrees(swing ? 3 : -3))
        }
    }

    private var syrupBottle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppGradient.lavenderWash)
                .frame(width: 108, height: 150)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppColor.medicalBlue.opacity(0.24))
                .frame(width: 52, height: 18)
                .offset(y: -84)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColor.warmWhite.opacity(0.88))
                .frame(width: 76, height: 58)
            Image(systemName: "cross.case.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(AppColor.medicalBlue)
        }
    }

    private var heartMedicine: some View {
        ZStack {
            PulseWaveView(color: AppColor.softRed)
                .frame(width: 190, height: 190)
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 118, weight: .bold))
                .foregroundStyle(AppColor.softRed)
                .scaleEffect(float ? 1.05 : 0.94)
        }
    }

    private var glowColor: Color {
        isHeartMedicine ? AppColor.softRed : AppColor.medicalBlue
    }
}

struct BreathingGlowView: View {
    let color: Color
    @State private var breathe = false

    var body: some View {
        Circle()
            .fill(color.opacity(breathe ? 0.22 : 0.08))
            .frame(width: breathe ? 320 : 240, height: breathe ? 320 : 240)
            .blur(radius: 34)
            .animation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true), value: breathe)
            .onAppear { breathe = true }
            .accessibilityHidden(true)
    }
}

struct ReminderSuccessAnimationView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColor.mintGreenDeep.opacity(animate ? 0 : 0.42), lineWidth: 12)
                .frame(width: animate ? 170 : 68, height: animate ? 170 : 68)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 86, weight: .bold))
                .foregroundStyle(AppColor.mintGreenDeep)
                .scaleEffect(animate ? 1 : 0.72)
        }
        .animation(.spring(response: 0.52, dampingFraction: 0.7), value: animate)
        .onAppear { animate = true }
        .accessibilityLabel("Medicine marked as taken")
    }
}
