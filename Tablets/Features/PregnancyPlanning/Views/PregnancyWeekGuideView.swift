import SwiftUI

struct PregnancyWeekGuideView: View {
    let currentWeek: Int
    @State private var expandedWeek: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Your Pregnancy Journey 📖").font(PregnancyTheme.titleFont)
                        ForEach(PregnancyWeekGuide.weeks) { info in
                            PregnancyCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Button {
                                        withAnimation { expandedWeek = expandedWeek == info.week ? nil : info.week }
                                    } label: {
                                        HStack {
                                            Text("\(info.week < currentWeek ? "✅" : info.week == currentWeek ? "💛" : "○") Week \(info.week)")
                                                .font(PregnancyTheme.headingFont)
                                            Spacer()
                                            Text(info.emoji)
                                        }
                                    }.buttonStyle(.plain)
                                    Text("Baby size: \(info.fruitComparison)")
                                        .font(PregnancyTheme.captionFont)
                                        .foregroundStyle(AppColor.secondaryInk)
                                    if expandedWeek == info.week || info.week == currentWeek {
                                        Text(info.babyDevelopment)
                                        Text(info.momChanges)
                                        Text("Tip: \(info.tipOfWeek)")
                                            .foregroundStyle(PregnancyTheme.deepRose)
                                    }
                                }
                                .font(PregnancyTheme.bodyFont)
                            }
                        }
                    }.padding(PregnancyTheme.pagePadding)
                }
            }
            .navigationTitle("Week Guide")
        }
    }
}

