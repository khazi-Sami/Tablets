import Foundation

enum HealthQueryType {
    case bpLatest
    case bpAverage
    case bpComparison
    case bpRangeCheck(systolic: Double?, diastolic: Double?)
    case sugarLatest
    case sugarAverage
    case sugarComparison
    case sugarRangeCheck(value: Double?, testType: SugarTestType?)
    case medicinePending
    case medicineNext
    case medicineTakenStatus
    case periodLast
    case periodNext
    case periodCycle
    case doctorNext
    case babyStatus
    case pregnancy
    case pregnancyHydrationReminder(minutes: Int)
    case pregnancySupplements
    case pregnancyNutrition
    case healthSummary
    case unknown
}

final class HealthQueryTypeDetector {
    func detect(_ transcript: String) -> HealthQueryType {
        let text = normalize(transcript)
        let numbers = extractNumbers(text)
        let hasBP = containsAny(text, ["bp", "blood pressure", "pressure", "systolic", "diastolic", "tension", "hypertension", "is my bp okay", "how is my bp doing", "my pressure these days", "is my bp stable", "has my bp improved", "bp better or worse", "highest bp", "lowest bp", "bp reading last week", "bp this month", "tension kaisa hai", "bp kaisa hai", "tension kitna tha", "was my bp high yesterday", "is my blood pressure normal", "how has my bp been", "bp under control"])
        let hasSugar = containsAny(text, ["sugar", "blood sugar", "glucose", "diabetes", "diabetic", "hba1c", "is my sugar under control", "how is my diabetes doing", "sugar kitna tha", "sugar kaisa hai", "sugar this month", "was my sugar high today", "fasting sugar average", "after food sugar average", "sugar before meal average", "sugar getting better", "diabetes in control", "sugar comparison", "highest sugar recorded", "lowest sugar recorded", "sugar trend this week", "sugar trend this month", "how has my sugar been"])
        let hasMedicine = containsAny(text, ["medicine", "tablet", "pill", "dose", "pending", "taken", "goli", "dawa", "dawai", "which tablet should i take now", "tablet abhi kaunsa", "kya tablet lena hai abhi", "medicine time kya hai", "tablet schedule today", "did i miss any tablet", "which medicine for morning", "which medicine for night", "tablet for this afternoon", "medicine for this evening", "koi tablet pending hai kya", "have i taken all tablets today", "medicine log for today", "todays dose", "did i take all my tablets", "how many tablets left today", "tablet history today", "medicine history today"])
        let hasPeriod = containsAny(text, ["period", "cycle", "monthly", "menstrual", "mahwari", "masik", "period kab aaya tha", "last period kab tha", "period kitne din baad", "cycle kitna lamba hai", "agla period kab aayega", "period late hai kya", "am i late this month", "how many days since my last period", "is my period regular", "cycle length average", "when did my last period end", "how long did my last period last", "period ke kitne din baad", "ovulation kab tha", "fertile window kab hai", "next fertile window", "is my cycle regular"])
        let hasBabyStatus = containsAny(text, ["how is baby doing", "how is my baby", "baby status", "baby update", "how is baby today", "what is baby doing", "baby doing okay", "check on baby", "baby check in", "baby ki khabar", "baby kaisa hai", "baby theek hai", "how is little one"])
        let hasPregnancy = containsAny(text, ["how many weeks pregnant", "what week am i on", "when is my due date", "how long until my due date", "how far along am i", "baby size this week", "what is baby doing this week", "pregnancy week", "pregnancy", "pregnant", "due date", "delivery", "kitne hafte", "baby size", "baby development"])
        let hasSupplement = containsAny(text, ["what supplements should i take", "pregnancy vitamins", "folic acid reminder", "prenatal vitamin", "prenatal vitamins", "pregnancy supplements", "pregnancy supplement"])
        let hasNutrition = containsAny(text, ["what should i eat", "pregnancy food", "what to eat during pregnancy", "healthy food for pregnancy", "pregnancy diet", "what is good to eat", "food for baby", "nutrients for pregnancy", "pregnancy nutrition", "kya khana chahiye", "pregnancy mein kya khaye", "baby ke liye kya khaye"])
        let hasDoctor = containsAny(text, ["doctor", "clinic", "checkup", "appointment", "next appointment kab hai", "doctor appointment kab hai", "when do i see doctor next", "when was my last doctor visit", "doctor se kab mila tha", "hospital kab jana hai", "clinic appointment kab hai", "medical checkup kab hai", "upcoming appointment", "past appointments"])
        let hasAverage = containsAny(text, ["average", "weekly", "this week", "last week", "this month"])
        let hasComparison = containsAny(text, ["compare", "compared", "better than", "worse", "improved", "stable", "yesterday", "last time", "last week", "this week"])
        let hasRangeCheck = containsAny(text, ["okay", " ok ", "normal", "high", "low", "under control", "control", "kaisa"]) || text.hasPrefix("is ")

        if hasBP || looksLikeBPRange(text, numbers: numbers) {
            if hasRangeCheck || looksLikeBPRange(text, numbers: numbers) {
                return .bpRangeCheck(systolic: numbers.first, diastolic: numbers.dropFirst().first)
            }
            if hasAverage { return .bpAverage }
            if hasComparison { return .bpComparison }
            return .bpLatest
        }

        if hasSugar {
            if hasRangeCheck || !numbers.isEmpty {
                return .sugarRangeCheck(value: numbers.first, testType: sugarTestType(in: text))
            }
            if hasAverage { return .sugarAverage }
            if hasComparison { return .sugarComparison }
            return .sugarLatest
        }

        if hasMedicine {
            if containsAny(text, ["did i", "taken", "took", "have i taken all", "medicine log today"]) { return .medicineTakenStatus }
            if containsAny(text, ["next", "when", "which tablet now", "tablet abhi kaunsa", "kya tablet lena hai", "medicine time kya hai", "which medicine morning", "which medicine night", "tablet for afternoon", "medicine for evening"]) { return .medicineNext }
            if containsAny(text, ["pending", "should i take", "miss", "koi tablet pending hai", "did i miss my tablet", "tablet schedule today", "dose today"]) { return .medicinePending }
            return .medicinePending
        }

        if containsAny(text, ["remind me to drink water in", "water reminder in", "remind me to hydrate in"]) {
            return .pregnancyHydrationReminder(minutes: Int(numbers.first ?? 20))
        }

        if hasBabyStatus {
            return .babyStatus
        }

        if hasSupplement {
            return .pregnancySupplements
        }

        if hasNutrition {
            return .pregnancyNutrition
        }

        if hasPregnancy {
            return .pregnancy
        }

        if hasPeriod {
            if containsAny(text, ["next", "late", "am i", "agla", "kab aayega", "period kitne din baad"]) { return .periodNext }
            if containsAny(text, ["cycle", "length", "lamba", "regular", "average"]) { return .periodCycle }
            return .periodLast
        }

        if hasDoctor {
            return .doctorNext
        }

        if containsAny(text, ["how am i doing", "how is my health", "give me summary", "health status", "what happened this week", "how have i been", "health summary batao", "overall health kaisa hai", "this week ka health", "health report today", "tell me about my health", "give me a health summary", "health update do", "health update", "how is everything health wise", "recent health", "health this week", "health this month", "give me an overview of my health", "how is my overall wellbeing", "how have i been this week", "how am i doing overall"]) {
            return .healthSummary
        }

        return .unknown
    }

    private func normalize(_ transcript: String) -> String {
        var text = transcript.lowercased()
        let replacements: [(String, String)] = [
            ("tension kaisa hai", "how is my bp"),
            ("tension kitna tha", "what was my bp"),
            ("bp kaisa hai", "how is my bp"),
            ("sugar kitna hai", "how is my sugar"),
            ("sugar kitna tha", "what was my sugar"),
            ("sugar kaisa hai", "how is my sugar"),
            ("period kab aaya tha", "when was my last period"),
            ("last period kab tha", "when was my last period"),
            ("agla period kab aayega", "when is my next period"),
            ("period late hai kya", "is my period late"),
            ("cycle kitna lamba hai", "cycle length average"),
            ("next appointment kab hai", "when is my next doctor appointment"),
            ("doctor appointment kab hai", "when is my next doctor appointment"),
            ("doctor se kab mila tha", "when was my last doctor visit"),
            ("hospital kab jana hai", "when is my next doctor appointment"),
            ("clinic appointment kab hai", "when is my next doctor appointment"),
            ("medical checkup kab hai", "when is my next doctor appointment"),
            ("due date kab hai", "when is my due date"),
            ("delivery kab hai", "when is my due date"),
            ("kitne hafte ho gaye", "how many weeks pregnant"),
            ("baby kitna bada hai", "baby size this week"),
            ("baby ki khabar", "how is baby doing"),
            ("baby kaisa hai", "how is baby doing"),
            ("baby theek hai", "how is baby doing"),
            ("health summary batao", "give me health summary"),
            ("health update do", "health update"),
            ("overall health kaisa hai", "how is my health"),
            ("one twenty", "120"),
            ("one forty five", "145"),
            ("one forty", "140"),
            ("one fifty", "150"),
            ("one ten", "110"),
            ("one hundred and ten", "110"),
            ("one hundred ten", "110"),
            ("eighty", "80"),
            ("ninety", "90"),
            ("seventy", "70"),
            ("sixty", "60")
        ]
        replacements.forEach { text = text.replacingOccurrences(of: $0.0, with: $0.1) }
        text = text.replacingOccurrences(of: #"[^a-z0-9/\s\.]"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractNumbers(_ text: String) -> [Double] {
        guard let regex = try? NSRegularExpression(pattern: #"(?<!\w)\d+(\.\d+)?(?!\w)"#) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap {
            Range($0.range, in: text).flatMap { Double(text[$0]) }
        }
    }

    private func looksLikeBPRange(_ text: String, numbers: [Double]) -> Bool {
        numbers.count >= 2 && (text.contains(" over ") || text.contains("/") || text.contains("pressure") || text.contains("bp"))
    }

    private func sugarTestType(in text: String) -> SugarTestType? {
        if containsAny(text, ["fasting"]) { return .fasting }
        if containsAny(text, ["after food", "after meal", "post meal", "after lunch", "after dinner", "after breakfast"]) { return .afterMeal }
        if containsAny(text, ["before food", "before meal"]) { return .beforeMeal }
        if containsAny(text, ["random"]) { return .random }
        return nil
    }

    private func containsAny(_ text: String, _ terms: [String]) -> Bool {
        terms.contains { text.contains($0) }
    }
}
