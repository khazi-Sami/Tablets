import SwiftUI

struct PregnancyTheme {
    static let blushPink = Color(red: 1.0, green: 0.88, blue: 0.90)
    static let softLavender = Color(red: 0.88, green: 0.85, blue: 0.97)
    static let warmCream = Color(red: 1.0, green: 0.97, blue: 0.93)
    static let gentleMint = Color(red: 0.88, green: 0.97, blue: 0.93)
    static let deepRose = Color(red: 0.85, green: 0.35, blue: 0.50)
    static let softGold = Color(red: 0.95, green: 0.80, blue: 0.50)
    static let lilac = Color(red: 0.78, green: 0.70, blue: 0.95)
    static let peach = Color(red: 1.0, green: 0.85, blue: 0.75)

    static let mainGradient = LinearGradient(colors: [blushPink, softLavender, warmCream], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardGradient = LinearGradient(colors: [warmCream, blushPink.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let heroGradient = LinearGradient(colors: [deepRose.opacity(0.8), lilac, softLavender], startPoint: .topLeading, endPoint: .bottomTrailing)

    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headingFont = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 17, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 14, weight: .medium, design: .rounded)
    static let largeFont = Font.system(size: 34, weight: .bold, design: .rounded)

    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 16
    static let chipRadius: CGFloat = 12
    static let pagePadding: CGFloat = 20
    static let cardPadding: CGFloat = 18
    static let itemSpacing: CGFloat = 14

    static let iconBaby = "figure.2.and.child.holdinghands"
    static let iconHeart = "heart.fill"
    static let iconPregnant = "figure.maternity"
    static let iconKick = "hand.tap.fill"
    static let iconWeight = "scalemass.fill"
    static let iconCalendar = "calendar.badge.plus"
    static let iconSymptom = "cross.case.fill"
    static let iconMilestone = "star.fill"
    static let iconAppointment = "stethoscope"
    static let iconWeekGuide = "book.pages.fill"
    static let iconDueDate = "gift.fill"
    static let iconGrowth = "chart.line.uptrend.xyaxis"
    static let iconNotes = "note.text"
    static let iconMood = "face.smiling.fill"
}

