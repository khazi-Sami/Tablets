import Foundation
import NaturalLanguage

struct HealthIntentParser {
    func parse(_ text: String) -> ParsedHealthCommand {
        let normalized = normalizeNumberWords(in: HinglishNormalizer().normalize(text))
        let numbers = extractNumbers(normalized)
        let symptoms = extractSymptoms(normalized)
        let entities = extractEntities(normalized)

        let intent: HealthVoiceIntent
        let confidence: Double

        if (normalized.contains("pregnancy weight") ||
            normalized.contains("pregnant weight") ||
            (normalized.contains("weight") &&
             normalized.contains("week") &&
             normalized.contains("pregnant"))) && !numbers.isEmpty {
            return ParsedHealthCommand(intent: .logPregnancyWeight, originalText: text, numbers: numbers, symptoms: [], entities: entities, confidence: 0.88)
        }

        if normalized.contains("baby kick") ||
            normalized.contains("kick count") ||
            normalized.contains("baby moved") ||
            normalized.contains("baby kicked") ||
            normalized.contains("felt kick") ||
            normalized.contains("baby is moving") {
            return ParsedHealthCommand(intent: .logBabyKick, originalText: text, numbers: numbers, symptoms: [], entities: entities, confidence: 0.87)
        }

        if normalized.contains("start contraction") || normalized.contains("contraction started") {
            return ParsedHealthCommand(intent: .startContraction, originalText: text, numbers: [], symptoms: [], entities: entities, confidence: 0.88)
        }

        if normalized.contains("stop contraction") || normalized.contains("contraction ended") {
            return ParsedHealthCommand(intent: .stopContraction, originalText: text, numbers: [], symptoms: [], entities: entities, confidence: 0.88)
        }

        if let note = pregnancyNoteText(from: normalized) {
            var noteEntities = entities
            noteEntities["pregnancyNote"] = note.text
            noteEntities["pregnancyNoteCategory"] = note.category.rawValue
            return ParsedHealthCommand(intent: .logPregnancyNote, originalText: text, numbers: [], symptoms: [], entities: noteEntities, confidence: 0.88)
        }

        if let mood = pregnancyMood(in: normalized), normalized.contains("pregnancy") || normalized.contains("feeling") || normalized.contains("feel ") || normalized.contains("mood") {
            var moodEntities = entities
            moodEntities["pregnancyMood"] = mood.rawValue
            return ParsedHealthCommand(intent: .logPregnancyMood, originalText: text, numbers: [], symptoms: [], entities: moodEntities, confidence: 0.86)
        }

        if (normalized.contains("pregnancy") ||
            normalized.contains("pregnant")) && !symptoms.isEmpty {
            return ParsedHealthCommand(intent: .logPregnancySymptom, originalText: text, numbers: [], symptoms: symptoms, entities: entities, confidence: 0.86)
        }

        if normalized.contains("tension") && (
            normalized.contains("record") || normalized.contains("log") ||
            normalized.contains("add") || normalized.contains("enter") ||
            normalized.contains("is") || normalized.contains("kitna")
        ) {
            let intent: HealthVoiceIntent = numbers.count >= 2 ? .logBloodPressure : .askBloodPressure
            return ParsedHealthCommand(intent: intent, originalText: text, numbers: numbers, symptoms: symptoms, entities: entities, confidence: numbers.count >= 2 ? 0.85 : 0.76)
        }

        if numbers.count >= 2, looksLikeBloodPressureNumbers(numbers) {
            return ParsedHealthCommand(intent: .logBloodPressure, originalText: text, numbers: numbers, symptoms: symptoms, entities: entities, confidence: 0.74)
        }

        if numbers.count == 1 && (normalized.contains("after food") || normalized.contains("after meal") || normalized.contains("before food") || normalized.contains("before meal") || normalized.contains("fasting")) {
            return ParsedHealthCommand(intent: .logSugar, originalText: text, numbers: numbers, symptoms: symptoms, entities: entities, confidence: 0.76)
        }

        if numbers.count >= 1 && (normalized.contains("weight") || normalized.contains("weigh") || normalized.contains("kg") || normalized.contains("kilo")) {
            return ParsedHealthCommand(intent: .logWeight, originalText: text, numbers: [numbers[0]], symptoms: symptoms, entities: entities, confidence: 0.84)
        }

        if normalized.contains("how am i doing") ||
            normalized.contains("how have i been") ||
            normalized.contains("how is my health") ||
            normalized.contains("health this week") ||
            normalized.contains("overall health") ||
            normalized.contains("health summary") ||
            normalized.contains("give me a summary") ||
            normalized.contains("health update") {
            return ParsedHealthCommand(intent: .weeklyHealth, originalText: text, numbers: [], symptoms: [], entities: [:], confidence: 0.82)
        }

        if (normalized.contains("took") || normalized.contains("taken") ||
            normalized.contains("had my") || normalized.contains("finished my")) &&
            (normalized.contains("tablet") || normalized.contains("medicine") ||
             normalized.contains("pill") || normalized.contains("dose") ||
             normalized.contains("capsule")) {
            return ParsedHealthCommand(intent: .medicineTaken, originalText: text, numbers: numbers, symptoms: [], entities: entities, confidence: 0.85)
        }

        if normalized.contains("pending") || normalized.contains("missed") ||
            normalized.contains("left to take") || normalized.contains("not taken") ||
            normalized.contains("did i take") || normalized.contains("have i taken") ||
            normalized.contains("which medicine") || normalized.contains("what tablet") ||
            normalized.contains("which tablet should") || normalized.contains("what pill") {
            return ParsedHealthCommand(intent: .pendingMedicine, originalText: text, numbers: [], symptoms: [], entities: [:], confidence: 0.83)
        }

        if normalized.contains("period") && (
            normalized.contains("start") || normalized.contains("started") ||
            normalized.contains("began") || normalized.contains("today") ||
            normalized.contains("got my")
        ) {
            intent = .startPeriod
            confidence = 0.88
        } else if normalized.contains("when did i") || normalized.contains("how many") || normalized.contains("show my sugar trend") {
            intent = .memorySearch
            confidence = 0.82
        } else if normalized.contains("did i take") || normalized.contains("have i taken") {
            intent = .askMedicineTaken
            confidence = 0.83
        } else if normalized.contains("start") && normalized.contains("period") {
            intent = .startPeriod
            confidence = 0.84
        } else if (normalized.contains("sugar") || normalized.contains("glucose")) && (normalized.contains("how") || normalized.contains("compare") || normalized.contains("compared")) {
            intent = .askSugar
            confidence = 0.80
        } else if normalized.contains("sugar") || normalized.contains("glucose") {
            intent = .logSugar
            confidence = numbers.isEmpty ? 0.45 : 0.88
        } else if normalized.contains("bp") || normalized.contains("blood pressure") {
            intent = numbers.count >= 2 ? .logBloodPressure : .askBloodPressure
            confidence = numbers.count >= 2 ? 0.9 : 0.78
        } else if normalized.contains("how is my bp") {
            intent = .askBloodPressure
            confidence = 0.82
        } else if !symptoms.isEmpty || normalized.contains("symptom") {
            intent = .logSymptoms
            confidence = symptoms.isEmpty ? 0.52 : 0.86
        } else if normalized.contains("i took") || normalized.contains("taken") {
            intent = .medicineTaken
            confidence = 0.78
        } else if normalized.contains("pending") || normalized.contains("medicine left") || normalized.contains("what medicine") {
            intent = .pendingMedicine
            confidence = 0.80
        } else if normalized.contains("remind me") {
            intent = .reminderRequest
            confidence = entities["time"] == nil ? 0.58 : 0.82
        } else if normalized.contains("this week") || normalized.contains("health") {
            intent = .weeklyHealth
            confidence = 0.72
        } else {
            intent = .unknown
            confidence = 0.30
        }

        return ParsedHealthCommand(intent: intent, originalText: text, numbers: numbers, symptoms: symptoms, entities: entities, confidence: confidence)
    }

    private func extractNumbers(_ text: String) -> [Double] {
        let pattern = #"(?<!\w)\d+(\.\d+)?(?!\w)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap {
            Range($0.range, in: text).flatMap { Double(text[$0]) }
        }
    }

    private func extractSymptoms(_ text: String) -> [String] {
        let symptomKeywords: [String] = [
            // Head
            "headache", "head pain", "head ache", "migraine",
            "head is paining", "my head hurts", "head hurting",
            "head spinning",

            // Dizziness
            "dizziness", "dizzy", "giddiness", "giddy",
            "feeling dizzy", "spinning",

            // Tiredness
            "fatigue", "tired", "tiredness", "exhausted",
            "weakness", "weak", "no energy", "lethargy", "lethargic",
            "low energy", "feeling weak",

            // Stomach
            "nausea", "nauseous", "vomiting", "vomit", "throwing up",
            "morning sickness", "food aversion", "heartburn", "cravings",
            "stomach pain", "stomach ache", "stomach is paining",
            "tummy pain", "acidity", "gas", "bloating", "indigestion",
            "stomach upset", "upset stomach", "loose motion",
            "constipation", "abdominal pain",

            // Body pain
            "body pain", "body ache", "back pain", "back ache",
            "back is paining", "leg pain", "leg cramp", "cramps",
            "round ligament pain", "pelvic pressure", "braxton hicks",
            "joint pain", "knee pain", "knee hurts", "shoulder pain",
            "neck pain", "wrist pain", "hip pain", "muscle pain",
            "muscle ache", "body is paining",

            // Chest
            "chest pain", "chest tightness", "chest pressure",
            "chest discomfort", "heart pain", "palpitation",
            "heart racing", "heart beating fast",

            // Breathing
            "breathless", "breathing problem", "short of breath",
            "difficulty breathing", "cant breathe", "breathlessness",
            "wheezing",

            // Fever / Cold
            "fever", "temperature", "cold", "cough", "sore throat",
            "throat pain", "throat hurts", "throat infection",
            "runny nose", "blocked nose", "stuffy nose",
            "chills", "shivering",

            // Skin
            "swelling", "rash", "itching", "burning", "redness",
            "skin rash", "skin itching", "hives",

            // Neuro
            "numbness", "tingling", "anxiety", "stress", "depression",
            "pins and needles", "blurred vision", "vision problem",
            "eye pain", "hearing problem", "ringing in ears",

            // Mental
            "sadness", "feeling sad", "feeling anxious",
            "feeling stressed", "panic", "worry", "mood swings",

            // Sleep
            "sleep problem", "cant sleep", "insomnia",
            "not sleeping", "waking up at night",
            "poor sleep", "sleep disturbance",

            // General
            "feeling unwell", "not feeling well", "feeling sick",
            "feeling bad", "not well", "ill", "unwell",
            "feeling off", "feeling strange", "something is wrong",
            "not feeling good"
        ]
        return symptomKeywords.filter { text.contains($0) }
    }

    private func extractEntities(_ text: String) -> [String: String] {
        var entities: [String: String] = [:]
        if text.contains("after food") || text.contains("after meal") {
            entities["sugarTestType"] = SugarTestType.afterMeal.rawValue
        } else if text.contains("after lunch") || text.contains("after dinner") || text.contains("after breakfast") {
            entities["sugarTestType"] = SugarTestType.afterMeal.rawValue
            entities["mealContext"] = text.contains("lunch") ? "lunch" : text.contains("dinner") ? "dinner" : "breakfast"
        } else if text.contains("before food") || text.contains("before meal") {
            entities["sugarTestType"] = SugarTestType.beforeMeal.rawValue
        } else if text.contains("fasting") {
            entities["sugarTestType"] = SugarTestType.fasting.rawValue
        }
        if text.contains("diabetes tablet") {
            entities["medicineHint"] = "diabetes"
        } else if text.contains("night tablet") {
            entities["medicineHint"] = "night"
        }
        if let time = firstMatch(text, pattern: #"(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)"#) {
            entities["time"] = time
        }
        return entities
    }

    private func pregnancyMood(in text: String) -> PregnancyMood? {
        let moods: [(String, PregnancyMood)] = [
            ("happy", .happy), ("sad", .emotional), ("anxious", .anxious), ("worried", .worried),
            ("tired", .tired), ("excited", .excited), ("emotional", .emotional), ("calm", .calm),
            ("uncomfortable", .uncomfortable), ("overwhelmed", .anxious), ("nervous", .anxious),
            ("joyful", .happy), ("exhausted", .tired), ("fearful", .worried), ("hopeful", .excited)
        ]
        return moods.first { text.contains($0.0) }?.1
    }

    private func pregnancyNoteText(from text: String) -> (text: String, category: NoteCategory)? {
        let triggers: [(String, NoteCategory)] = [
            ("quick note", .general),
            ("note for doctor", .forDoctor),
            ("pregnancy note", .general),
            ("save note", .general),
            ("remember this", .reminder),
            ("remember", .reminder),
            ("add note", .general),
            ("add to pregnancy notes", .general)
        ]
        guard let trigger = triggers.first(where: { text.contains($0.0) }) else { return nil }
        let note = text.components(separatedBy: trigger.0).dropFirst().joined(separator: trigger.0).trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard !note.isEmpty else { return nil }
        return (note, trigger.1)
    }

    private func normalizeNumberWords(in text: String) -> String {
        var normalized = text
        let phrases: [(String, String)] = [
            ("one twenty over eighty", "120 80"),
            ("one thirty over eighty", "130 80"),
            ("one thirty over ninety", "130 90"),
            ("one forty over ninety", "140 90"),
            ("one ten over seventy", "110 70"),
            ("one fifty over hundred", "150 100"),
            ("one twenty over seventy", "120 70"),
            ("one hundred over seventy", "100 70"),
            ("one hundred and forty five", "145"),
            ("one hundred forty five", "145"),
            ("one hundred and twenty", "120"),
            ("one hundred and thirty", "130"),
            ("one hundred and fifty", "150"),
            ("one hundred and eighty", "180"),
            ("one hundred and ten", "110"),
            ("one hundred ten", "110"),
            ("one twenty", "120"),
            ("one thirty", "130"),
            ("one forty five", "145"),
            ("one forty", "140"),
            ("one fifty", "150"),
            ("one sixty", "160"),
            ("one seventy", "170"),
            ("one eighty", "180"),
            ("one ninety", "190"),
            ("two hundred", "200"),
            ("two fifty", "250"),
            ("two twenty", "220"),
            ("two thirty", "230"),
            ("two forty", "240"),
            ("three hundred", "300"),
            ("three fifty", "350"),
            ("one hundred", "100"),
            ("hundred and twenty", "120"),
            ("hundred and eighty", "180"),
            ("hundred and forty", "140"),
            ("hundred and fifty", "150"),
            ("ek sau bis assi", "120 80"),
            ("ek sau tees nabbe", "130 90"),
            ("ek sau chalis nabbe", "140 90"),
            ("one forty five point two", "145.2"),
            ("one ten point five", "110.5"),
            ("ninety eight point six", "98.6"),
            ("six point five", "6.5"),
            ("seven point two", "7.2"),
            ("eighty", "80"),
            ("ninety", "90"),
            ("seventy", "70"),
            ("sixty", "60"),
            ("one ten", "110")
        ]

        for (phrase, value) in phrases {
            normalized = normalized.replacingOccurrences(of: phrase, with: value)
        }

        let smallNumbers: [String: String] = [
            "zero": "0", "one": "1", "two": "2", "three": "3", "four": "4",
            "five": "5", "six": "6", "seven": "7", "eight": "8", "nine": "9",
            "ten": "10"
        ]
        for (word, value) in smallNumbers {
            normalized = normalized.replacingOccurrences(of: " \(word) ", with: " \(value) ")
        }

        return normalized
    }

    private func firstMatch(_ text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), let swiftRange = Range(match.range, in: text) else { return nil }
        return String(text[swiftRange])
    }

    private func looksLikeBloodPressureNumbers(_ numbers: [Double]) -> Bool {
        guard numbers.count >= 2 else { return false }
        let systolic = numbers[0]
        let diastolic = numbers[1]
        return systolic >= 80 && systolic <= 220 && diastolic >= 40 && diastolic <= 140 && systolic > diastolic
    }
}
