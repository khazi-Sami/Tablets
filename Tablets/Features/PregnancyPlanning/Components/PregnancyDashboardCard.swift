import SwiftUI

struct PregnancyDashboardCard: View {
    let profile: PregnancyProfile
    let weekInfo: PregnancyWeekInfo
    let daysUntilDue: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Week \(profile.currentWeek)")
                        .font(PregnancyTheme.largeFont)
                        .foregroundStyle(.white)
                    Text("Your baby is the size of a \(weekInfo.fruitComparison) \(weekInfo.emoji)")
                        .font(PregnancyTheme.bodyFont.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.95))
                }
                Spacer()
                Image(systemName: PregnancyTheme.iconHeart)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .symbolEffect(.pulse)
            }

            Text(profile.babyNickname.map { "Hello, \($0) 💛" } ?? "Hello, little one 💛")
                .font(PregnancyTheme.headingFont)
                .foregroundStyle(.white)

            Text("\(max(daysUntilDue, 0)) days to go • Due \(profile.dueDate.formatted(date: .abbreviated, time: .omitted))")
                .font(PregnancyTheme.captionFont)
                .foregroundStyle(.white.opacity(0.88))
        }
        .padding(22)
        .background(PregnancyTheme.heroGradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: PregnancyTheme.deepRose.opacity(0.20), radius: 18, y: 8)
    }
}

