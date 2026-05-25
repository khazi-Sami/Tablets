import Charts
import SwiftData
import SwiftUI

struct PregnancyWeightChartView: View {
    @Query(sort: \PregnancyWeightLog.weekNumber) private var allLogs: [PregnancyWeightLog]
    let profile: PregnancyProfile

    private var logs: [PregnancyWeightLog] { allLogs.filter { $0.pregnancyProfileId == profile.id } }

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Weight Chart")
                        .font(PregnancyTheme.titleFont)
                    PregnancyCard {
                        if logs.count < 2 {
                            Text("Log two or more weights to see your trend.")
                                .foregroundStyle(AppColor.secondaryInk)
                        } else {
                            Chart(logs) { log in
                                LineMark(x: .value("Week", log.weekNumber), y: .value("Weight", log.weight))
                                PointMark(x: .value("Week", log.weekNumber), y: .value("Weight", log.weight))
                            }
                            .frame(height: 240)
                        }
                    }
                    PregnancyCard {
                        VStack(alignment: .leading) {
                            Text("Reference range only — follow your doctor's guidance.")
                                .font(PregnancyTheme.captionFont)
                            Text("Weight gain varies for every pregnancy. Please follow your doctor's personal guidance.")
                                .font(PregnancyTheme.captionFont)
                        }
                    }
                    Spacer()
                }
                .padding(PregnancyTheme.pagePadding)
            }
            .navigationTitle("Weight Chart")
        }
    }
}
