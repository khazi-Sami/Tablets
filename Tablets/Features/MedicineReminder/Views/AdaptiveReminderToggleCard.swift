import SwiftData
import SwiftUI

struct AdaptiveReminderToggleCard: View {
    @Environment(\.modelContext) private var modelContext

    let medicine: Medicine

    @State private var pattern: MedicineTakePattern?
    @State private var isShowingSettings = false
    private let preferenceStore = AdaptiveReminderPreferenceStore()
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColor.lavenderDeep)
                    .frame(width: 36, height: 36)
                    .background(AppColor.lavenderDeep.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                    Text("Learn my medicine timing")
                        .font(AppFont.bodyStrong)
                        .foregroundStyle(AppColor.ink)
                    Text(summaryText)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                }

                Spacer()

                Button("Details") {
                    isShowingSettings = true
                }
                .font(AppFont.caption)
                .buttonStyle(.bordered)
            }
        }
        .padding(Spacing.small)
        .background(.white.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
        .task {
            let engine = AdaptiveReminderEngine(modelContext: modelContext)
            pattern = await engine.analyzePattern(for: medicine)
        }
        .sheet(isPresented: $isShowingSettings) {
            MedicineAdaptiveSettingsView(medicine: medicine)
        }
    }

    private var summaryText: String {
        guard let pattern,
              pattern.sampleCount >= 5,
              preferenceStore.isEnabled(medicineID: pattern.medicineID, scheduledTime: pattern.scheduledTime)
        else {
            return "After a few doses, BanyAI will learn your routine."
        }

        let minutes = abs(pattern.averageActualMinuteOffset)
        if minutes == 0 {
            return "You usually take this close to the reminder time."
        }
        let direction = pattern.averageActualMinuteOffset > 0 ? "later" : "earlier"
        return "You usually take this \(minutes) mins \(direction)."
    }
}
