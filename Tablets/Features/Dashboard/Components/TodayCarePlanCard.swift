import SwiftData
import SwiftUI

struct TodayCarePlanCard: View {
    let dataProvider: DashboardDataProvider
    let isSaving: Bool
    let errorText: String?
    let isElderlyMode: Bool
    let todaySnapshot: HKDailySnapshot?
    let markTaken: () -> Void
    let addMedicine: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                if shouldShowProgress {
                    circularProgress
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's care plan")
                        .font(.headline)
                        .foregroundStyle(AppColor.ink)

                    if let next = dataProvider.nextPendingMedicine {
                        Text(next.medicine.name)
                            .font((isElderlyMode ? Font.title2 : Font.title3).weight(.bold))
                            .foregroundStyle(AppColor.ink)
                            .elderlyScaled(isElderlyMode)
                        Text("\(next.medicine.dosage) · \(next.scheduledAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    } else if dataProvider.activeMedicines.isEmpty {
                        Text("No medicines added yet")
                            .font((isElderlyMode ? Font.title2 : Font.title3).weight(.bold))
                            .foregroundStyle(AppColor.ink)
                            .elderlyScaled(isElderlyMode)
                    } else if dataProvider.todayMedicineLogs.isEmpty {
                        Text("No medicines scheduled for today")
                            .font((isElderlyMode ? Font.title2 : Font.title3).weight(.bold))
                            .foregroundStyle(AppColor.ink)
                            .elderlyScaled(isElderlyMode)
                        Text("Enjoy your day")
                            .font(.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    } else {
                        Text("All medicines taken today ✓")
                            .font((isElderlyMode ? Font.title2 : Font.title3).weight(.bold))
                            .foregroundStyle(AppColor.ink)
                            .elderlyScaled(isElderlyMode)
                    }
                }
                Spacer(minLength: 0)
            }

            if shouldShowProgress {
                HStack(spacing: 8) {
                    countChip("Taken", dataProvider.takenCountToday, AppColor.mintGreenDeep)
                    countChip("Pending", dataProvider.pendingCountToday, AppColor.medicalBlue)
                    countChip("Missed", dataProvider.missedCountToday, AppColor.softRed)
                }
            }

            if dataProvider.nextPendingMedicine != nil {
                CapsuleButton(isSaving ? "Saving..." : "Mark Taken", systemImage: "checkmark.circle.fill", action: markTaken)
                    .frame(minHeight: isElderlyMode ? 56 : 52)
                    .disabled(isSaving)
            } else if dataProvider.activeMedicines.isEmpty {
                CapsuleButton("Add your first medicine →", systemImage: "plus.circle.fill", action: addMedicine)
                    .frame(minHeight: isElderlyMode ? 56 : 52)
            }

            if let errorText {
                Text(errorText)
                    .font(.caption)
                    .foregroundStyle(AppColor.softRed)
            }

            if let todaySnapshot, todaySnapshot.steps != nil || todaySnapshot.sleepDurationHours != nil {
                HStack(spacing: 12) {
                    if let steps = todaySnapshot.steps {
                        Label("\(Int(steps)) steps", systemImage: "figure.walk")
                    }
                    if let sleep = todaySnapshot.sleepDurationHours {
                        Label("\(String(format: "%.1f", sleep)) hrs sleep", systemImage: "bed.double.fill")
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.secondaryInk)
            }
        }
        .padding(isElderlyMode ? 20 : 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(dataProvider.pendingCountToday > 0 ? AppColor.medicalBlue.opacity(0.45) : .clear, lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    private var circularProgress: some View {
        ZStack {
            Circle().stroke(AppColor.medicalBlue.opacity(0.14), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(progressValue >= 1 ? AppColor.mintGreenDeep : AppColor.medicalBlue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progressValue)
            Text("\(Int(progressValue * 100))%")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppColor.ink)
        }
        .frame(width: 82, height: 82)
    }

    private var shouldShowProgress: Bool {
        !dataProvider.activeMedicines.isEmpty
    }

    private var progressValue: Double {
        if dataProvider.activeMedicines.isEmpty { return 0 }
        if dataProvider.todayMedicineLogs.isEmpty { return 1 }
        return dataProvider.medicineProgressToday
    }

    private func countChip(_ title: String, _ count: Int, _ color: Color) -> some View {
        Text("\(title) \(count)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
