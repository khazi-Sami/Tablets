import Foundation

struct PregnancyWeekInfo: Identifiable, Hashable {
    let week: Int
    let babySize: String
    let babyLength: String
    let babyWeight: String
    let babyDevelopment: String
    let momChanges: String
    let tipOfWeek: String
    let emoji: String
    let fruitComparison: String

    var id: Int { week }
}

enum PregnancyWeekGuide {
    static let weeks: [PregnancyWeekInfo] = (4...40).map { week in
        let table = seed[week] ?? fallback(week)
        return PregnancyWeekInfo(
            week: week,
            babySize: table.size,
            babyLength: table.length,
            babyWeight: table.weight,
            babyDevelopment: table.development,
            momChanges: table.mom,
            tipOfWeek: table.tip,
            emoji: table.emoji,
            fruitComparison: table.fruit
        )
    }

    static func info(for week: Int) -> PregnancyWeekInfo {
        weeks.first(where: { $0.week == min(max(week, 4), 40) }) ?? weeks[0]
    }

    private typealias Row = (size: String, length: String, weight: String, development: String, mom: String, tip: String, emoji: String, fruit: String)

    private static let seed: [Int: Row] = [
        4: ("smaller than a poppy seed", "0.1 cm", "less than 0.5g", "The neural tube is beginning to form, which will become your baby's brain and spinal cord. Tiny cells are dividing rapidly.", "You may notice mild cramping or spotting, which is common at this stage. Fatigue may begin.", "Start taking folic acid if you haven't already. Stay hydrated and rest when you need to.", "🌱", "poppy seed"),
        8: ("size of a raspberry", "1.6 cm", "about 1g", "Tiny fingers and toes are forming. The heart is beating around 150-170 times per minute. Eyes are developing under thin skin.", "Morning sickness may be at its peak. Breasts may feel tender. Fatigue is very common.", "Eat small frequent meals to manage nausea. Keep crackers nearby for morning relief.", "🫐", "raspberry"),
        12: ("size of a lime", "5.4 cm", "about 14g", "Reflexes are developing and tiny facial features are becoming more defined.", "Nausea may start easing for some people, while tiredness can still come and go.", "Book or review your first trimester checkups and keep questions ready for your doctor.", "🍋", "lime"),
        16: ("size of an avocado", "11.6 cm", "about 100g", "Baby's muscles are getting stronger and movements are becoming more coordinated.", "You may feel more energetic. Gentle stretching may help with aches.", "Ask your doctor what movement and nutrition guidance is right for you.", "🥑", "avocado"),
        20: ("size of a banana", "25 cm", "about 300g", "Your baby can hear your voice now. The anatomy scan can be done this week. Baby is swallowing amniotic fluid and practising breathing.", "You may start feeling kicks and flutters. Your belly is clearly visible now. Energy often improves.", "Talk and sing to your baby. Book your 20-week anatomy scan if not already done.", "🍌", "banana"),
        24: ("size of a corn cob", "30 cm", "about 600g", "Lungs are developing and baby may respond to sound and touch.", "You may notice stronger kicks, back aches, or heartburn, which are common during this stage.", "Track patterns gently and contact your doctor if movement feels reduced.", "🌽", "corn cob"),
        28: ("size of an eggplant", "37 cm", "about 1 kg", "The third trimester begins. Baby's eyes can open and brain growth is active.", "Sleep may be harder and you may feel heavier. Rest breaks can help.", "Discuss third-trimester visits, birth planning, and warning signs with your doctor.", "🍆", "eggplant"),
        32: ("size of a squash", "42 cm", "about 1.7 kg", "Baby is practising breathing movements and gaining more body fat.", "Pelvic pressure and breathlessness may be more noticeable.", "Prepare appointment notes and ask about movement, swelling, or any concerning symptoms.", "🎀", "squash"),
        36: ("size of a papaya", "47 cm", "about 2.6 kg", "Baby is getting ready for birth and may settle lower in the pelvis.", "Braxton Hicks and pelvic pressure may increase.", "Pack your hospital bag and confirm your birth support plan.", "🧸", "papaya"),
        40: ("size of a small pumpkin", "about 51 cm", "about 3.4 kg", "Your baby is fully developed and ready to meet you. All organs are functioning. The lungs are mature and ready for that first breath.", "You may feel very heavy and uncomfortable. Braxton Hicks may be frequent. Signs of labour may begin.", "Your bag should be packed and ready. Rest as much as possible. Trust your body.", "🎃", "small pumpkin")
    ]

    private static func fallback(_ week: Int) -> Row {
        let fruits = ["sesame seed", "blueberry", "grape", "fig", "lemon", "peach", "orange", "mango", "coconut", "melon"]
        let fruit = fruits[min(max((week - 4) / 4, 0), fruits.count - 1)]
        let length = week < 12 ? "\(max(1, week - 3)) cm" : "\(min(51, week + 5)) cm"
        let weight = week < 14 ? "a few grams" : "about \(max(50, (week - 10) * 90))g"
        return (
            "size of a \(fruit)",
            length,
            weight,
            "Your baby is growing steadily this week. Organs, muscles, and senses continue developing in small but important ways.",
            "You may notice changes in energy, appetite, sleep, or comfort, which are common during this stage.",
            "Keep hydration, rest, and your appointment questions in mind. Please follow your doctor's guidance.",
            "💛",
            fruit
        )
    }
}

