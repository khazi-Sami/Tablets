import SwiftUI

struct PeriodCalendarView: View {
    let cycles: [PeriodCycle]
    let prediction: CyclePredictionSummary

    private var days: [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        return (-6...14).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        WomensHealthSection(title: "Cycle calendar", subtitle: "Calendar marks are estimated from previous logs.") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xSmall) {
                    ForEach(days, id: \.self) { day in
                        dayCell(day)
                    }
                }
                .padding(.vertical, Spacing.xxSmall)
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(date)
        let isEstimatedPeriod = Calendar.current.isDate(date, inSameDayAs: prediction.nextPeriodDate)
        let isOvulation = Calendar.current.isDate(date, inSameDayAs: prediction.ovulationDate)

        return VStack(spacing: Spacing.xxSmall) {
            Text(date.formatted(.dateTime.weekday(.narrow)))
                .font(AppFont.badge)
                .foregroundStyle(AppColor.secondaryInk)

            Text(date.formatted(.dateTime.day()))
                .font(AppFont.bodyStrong)
                .foregroundStyle(isToday ? .white : AppColor.ink)
                .frame(width: 42, height: 42)
                .background(isToday ? WomensHealthTheme.blush : cellColor(isEstimatedPeriod: isEstimatedPeriod, isOvulation: isOvulation))
                .clipShape(Circle())

            Circle()
                .fill(isEstimatedPeriod || isOvulation ? WomensHealthTheme.blush : Color.clear)
                .frame(width: 6, height: 6)
        }
        .frame(width: 54)
        .accessibilityElement(children: .combine)
    }

    private func cellColor(isEstimatedPeriod: Bool, isOvulation: Bool) -> Color {
        if isEstimatedPeriod { return WomensHealthTheme.blushSoft }
        if isOvulation { return WomensHealthTheme.mint.opacity(0.32) }
        return AppColor.cream.opacity(0.72)
    }
}
