import SwiftData
import SwiftUI

struct PregnancyMilestoneView: View {
    let profile: PregnancyProfile

    private let builtIn: [(Int, String)] = [
        (4, "Pregnancy Confirmed 🌱"), (8, "Heartbeat Detected 💗"), (12, "First Trimester Complete 🎉"),
        (16, "Halfway to Halfway 🌸"), (20, "Halfway There! 🍌"), (24, "Viability Milestone 💛"),
        (28, "Third Trimester Begins 🌟"), (32, "Baby is Practising Breathing 🫁"), (36, "Almost Full Term 🎀"), (40, "Due Date! 🎊")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Beautiful Moments 🌟").font(PregnancyTheme.titleFont)
                        ForEach(builtIn, id: \.0) { week, title in
                            let achieved = profile.currentWeek >= week
                            PregnancyCard {
                                HStack {
                                    Image(systemName: PregnancyTheme.iconMilestone)
                                        .foregroundStyle(achieved ? PregnancyTheme.softGold : AppColor.secondaryInk)
                                    VStack(alignment: .leading) {
                                        Text(title).font(PregnancyTheme.headingFont)
                                        Text("Week \(week)").font(PregnancyTheme.captionFont)
                                    }
                                }
                            }
                            .opacity(achieved ? 1 : 0.62)
                        }
                    }.padding(PregnancyTheme.pagePadding)
                }
            }
            .navigationTitle("Milestones")
        }
    }
}

