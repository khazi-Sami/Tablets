import SwiftData
import SwiftUI

struct MedicalBackgroundView<Content: View>: View {
    @Query(sort: \MedicineLog.scheduledTime, order: .reverse) private var medicineLogs: [MedicineLog]
    @Query(sort: \HealthRecord.measuredAt, order: .reverse) private var healthRecords: [HealthRecord]
    @Query(sort: \WomensHealthDailyLog.date, order: .reverse) private var womensLogs: [WomensHealthDailyLog]
    @Query(sort: \PeriodCycle.startDate, order: .reverse) private var periodCycles: [PeriodCycle]

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AuraBackgroundView(style: auraStyle)

            VStack {
                SoftMedicalShape()
                    .fill(AppColor.mintGreen.opacity(0.18))
                    .frame(width: 220, height: 96)
                    .rotationEffect(.degrees(-16))
                    .offset(x: -92, y: -24)

                Spacer()

                SoftMedicalShape()
                    .fill(AppColor.lavender.opacity(0.24))
                    .frame(width: 260, height: 104)
                    .rotationEffect(.degrees(14))
                    .offset(x: 108, y: 20)
            }
            .allowsHitTesting(false)
            .blur(radius: 18)

            content
        }
    }

    private var auraStyle: HealthAuraStyle {
        DynamicThemeEngine.style(
            for: HealthAuraManager.mood(
                medicineLogs: medicineLogs,
                healthRecords: healthRecords,
                womensLogs: womensLogs,
                periodCycles: periodCycles
            )
        )
    }
}

private struct SoftMedicalShape: Shape {
    func path(in rect: CGRect) -> Path {
        RoundedRectangle(cornerRadius: rect.height / 2, style: .continuous)
            .path(in: rect)
    }
}

#Preview {
    MedicalBackgroundView {
        Text("Medical Background")
            .font(AppFont.title)
    }
}
