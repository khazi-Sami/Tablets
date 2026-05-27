import Foundation

struct IntentRouterFallback {

    func route(_ transcript: String) -> RouteResult {
        let text = transcript.lowercased()
        let intent = detect(text)
        let confidence = intent == .unknown ? 0.0 : 0.65
        return RouteResult(
            intent: intent,
            confidence: confidence,
            rawTranscript: transcript,
            matchedExample: nil,
            needsConfirmation: confidence < 0.72 && intent != .unknown
        )
    }

    private func detect(_ text: String) -> AppNavigationIntent {

        // Add Medicine (check before openMedicines)
        if has(text, [
            "add medicine", "new tablet", "new pill", "add tablet",
            "add a medicine", "new medicine", "start medicine",
            "add capsule", "add syrup", "add new tablet",
            "put new medicine", "create medicine", "add my tablet",
            "add medication", "naya tablet", "nai dawa", "nayi dawa",
            "add new medicine", "new dose", "add dose",
            "save new tablet", "save new medicine"
        ]) { return .openAddMedicine }

        // Medicines
        if has(text, [
            "medicine", "tablet", "pill", "medication", "dawa",
            "dawai", "drug", "tablets", "medicines", "pills",
            "capsule", "syrup", "dose", "dawaiyan", "goli",
            "tablet section", "medicine section", "tablet list",
            "medicine list", "my tablet", "my medicine",
            "which tablet", "which medicine", "tablet tracker",
            "medicine tracker", "dose tracker", "pill tracker",
            "medicine schedule", "tablet schedule", "daily medicine",
            "daily tablet", "dose list", "pill list", "what am i taking",
            "medicine routine", "tablet routine", "dose routine",
            "adherence", "pending tablet", "overdue medicine",
            "low stock", "pills left", "goli schedule"
        ]) { return .openMedicines }

        // Sugar Log (check before openSugarTracking)
        if has(text, [
            "record sugar", "log sugar", "enter glucose", "sugar entry",
            "add sugar", "put sugar", "save sugar", "note sugar",
            "sugar add", "glucose entry", "log glucose", "add glucose",
            "record glucose", "enter sugar", "sugar input",
            "sugar reading add", "add my sugar", "record my sugar",
            "log my sugar", "enter my sugar", "sugar log",
            "glucose log", "put my sugar", "save my sugar reading"
        ]) { return .openSugarLog }

        // Sugar Tracking
        if has(text, [
            "sugar", "glucose", "diabetes", "diabetic", "blood sugar",
            "sugar level", "sugar reading", "sugar history",
            "sugar chart", "sugar section", "sugar tab",
            "sugar page", "sugar monitoring", "diabetes section",
            "diabetes tracking", "sugar records", "sugar trend",
            "blood glucose", "glucose chart", "glucose section",
            "glucose records", "meetha", "diabetic section",
            "my sugar", "my glucose", "my diabetes"
        ]) { return .openSugarTracking }

        // BP Log (check before openBPTracking)
        if has(text, [
            "record bp", "add blood pressure", "enter bp",
            "log pressure", "add bp", "put bp", "save bp",
            "note bp", "bp entry", "blood pressure entry",
            "log bp", "enter blood pressure", "pressure entry",
            "record blood pressure", "add pressure",
            "record pressure", "enter pressure", "log blood pressure",
            "add my bp", "record my bp", "save my bp",
            "put my bp", "enter my pressure", "save pressure reading"
        ]) { return .openBPLog }

        // BP Tracking
        if has(text, [
            "bp", "blood pressure", "pressure", "systolic",
            "diastolic", "bp section", "bp page", "bp chart",
            "pressure section", "pressure chart",
            "blood pressure section", "bp history",
            "blood pressure history", "pressure history",
            "bp tracking", "bp records", "bp reading",
            "tension", "tension section", "tension page",
            "tension reading", "tension records",
            "hypertension", "high bp", "bp monitoring",
            "pressure monitoring", "blood tension",
            "my bp", "my pressure", "my tension"
        ]) { return .openBPTracking }

        // Pregnancy & Planning
        if has(text, [
            "contraction timer", "track contractions", "start contraction timer",
            "open contraction tracker", "labour timer", "contraction tracker",
            "start contraction", "contraction started", "contraction ended"
        ]) { return .openContractionTimer }

        if has(text, [
            "log my mood", "pregnancy mood", "how am i feeling",
            "mood tracker pregnancy", "i am feeling anxious", "i feel tired",
            "mood log"
        ]) { return .openPregnancyMoodLog }

        if has(text, [
            "pregnancy timeline", "my pregnancy history",
            "show my pregnancy journey", "pregnancy log history",
            "pregnancy history"
        ]) { return .openPregnancyTimeline }

        if has(text, [
            "pregnancy weight chart", "weight chart pregnancy",
            "pregnancy weight graph", "show pregnancy weight"
        ]) { return .openPregnancyWeightChart }

        if has(text, [
            "birth plan", "open birth plan", "create birth plan",
            "my birth plan", "delivery plan", "birth preferences"
        ]) { return .openBirthPlan }

        if has(text, [
            "pregnancy notes", "quick note", "note for doctor",
            "my pregnancy notes", "saved notes", "questions for doctor"
        ]) { return .openPregnancyNotes }

        if has(text, [
            "pregnancy", "pregnant", "expecting", "maternity",
            "baby tracker", "baby section", "baby kick",
            "kick counter", "count kick", "baby development",
            "pregnancy planning", "pregnancy tracker",
            "pregnancy weight", "pregnancy symptom",
            "pregnancy appointment", "how many weeks",
            "what week pregnant", "week guide pregnancy",
            "pregnancy journey", "pregnancy milestone",
            "baby size", "due date", "garbh",
            "pregnancy ka", "baby ka section",
            "pregnant hoon", "baby aa raha",
            "baby aa rahi", "pregnancy track"
        ]) { return .openPregnancyPlanning }

        // Add Period Log
        if has(text, [
            "start period", "period started", "period today",
            "log period", "add period", "record period",
            "period start", "i got my period", "period began",
            "period log", "cycle started", "flow started",
            "period aa gaya", "period aaya", "mahwari aayi",
            "masik aaya", "period shuru", "period shuru hua"
        ]) { return .openAddPeriodLog }

        // Cycle Prediction
        if has(text, [
            "next period", "cycle prediction", "period prediction",
            "when is my period", "predict period", "period estimate",
            "cycle estimate", "fertile window", "ovulation estimate",
            "next cycle", "period forecast", "when will period come",
            "agla period", "next mahwari", "period kab aayega"
        ]) { return .openCyclePrediction }

        // Periods / Womens Health
        if has(text, [
            "period", "periods", "cycle", "menstrual", "menstruation",
            "women", "womens", "woman", "ladies", "lady",
            "monthly", "mahwari", "masik", "periods section",
            "period tracker", "cycle tracker", "women health",
            "womens health", "woman health", "ladies health",
            "wellbeing", "well being", "female health", "girl health",
            "women wellbeing", "ladies section", "period section",
            "cycle section", "monthly cycle", "female section",
            "women section", "reproductive health", "flow tracking",
            "ovulation", "fertile", "period date", "my cycle",
            "female care", "ladies care", "womens care",
            "women care", "ladies wellbeing", "female wellbeing",
            "monthly health", "period health", "menstrual health"
        ]) { return .openPeriods }

        // Health Report PDF
        if has(text, [
            "generate health report", "create health report",
            "export my health data", "make my report",
            "make health report", "open health report",
            "personal health report", "full health report"
        ]) { return .openHealthReport }

        // Doctor Report PDF
        if has(text, [
            "generate doctor report", "create my health report",
            "share doctor summary", "doctor pdf",
            "last 30 days report", "doctor report pdf",
            "create doctor report", "medical report pdf",
            "health report for doctor", "prepare doctor report"
        ]) { return .openDoctorReport }

        // Doctor Visit
        if has(text, [
            "doctor", "clinic", "appointment", "hospital",
            "doctor visit", "doctor appointment", "clinic visit",
            "hospital visit", "medical appointment", "checkup",
            "check up", "doctor report", "doctor notes",
            "visit doctor", "see doctor", "doctor section",
            "doctor page", "medical visit", "consultant",
            "doc visit", "doctor tab", "appointment section",
            "my appointments", "clinic section", "hospital section",
            "doctor checklist", "doctor preparation",
            "before doctor", "prepare for doctor"
        ]) { return .openDoctorVisit }

        // Prescription Scanner
        if has(text, [
            "scan", "prescription", "doctor paper", "scanner",
            "camera scan", "scan medicine", "scan tablet",
            "prescription scan", "medicine paper", "doctor slip",
            "rx scan", "scan rx", "doctor note scan",
            "prescription reader", "read prescription",
            "scan my paper", "medical paper", "scan slip",
            "scan medical", "photo prescription", "camera prescription",
            "ocr", "prescription photo", "open camera for medicine"
        ]) { return .openPrescriptionScanner }

        // Family Care
        if has(text, [
            "family", "caretaker", "caregiver", "mother medicine",
            "father medicine", "parents medicine", "family care",
            "family health", "loved ones", "elderly care",
            "parent care", "family member", "shared care",
            "my mother", "my father", "my parent", "family tab",
            "family section", "parents section", "mother section",
            "father section", "parents health", "parents tablets",
            "old age care", "elderly section", "dependents",
            "shared medicines", "family tablet", "family medicine"
        ]) { return .openFamilyCare }

        // Health Memory
        if has(text, [
            "health memory", "memory", "patterns", "habits",
            "my patterns", "health patterns", "assistant memory",
            "habit memory", "health intelligence", "memory timeline",
            "saved patterns", "routine memory", "health insights",
            "learned habits", "pattern page", "habit page",
            "my habits", "habit insights", "memory insights"
        ]) { return .openHealthMemory }

        // Health Journey
        if has(text, [
            "journey", "progress", "health journey", "health progress",
            "my progress", "health story", "health history",
            "timeline", "health timeline", "wellness journey",
            "health streak", "streak", "check in", "checkin",
            "daily check", "daily log", "daily checkin",
            "daily check in", "wellness timeline", "achievements",
            "health achievements", "routine progress"
        ]) { return .openHealthJourney }

        // Health Tracking (generic)
        if has(text, [
            "health tracking", "health records", "vitals",
            "health section", "health page", "monitoring",
            "health logs", "my health", "health data",
            "open health", "health dashboard", "my readings",
            "health readings", "body readings", "health monitoring",
            "records section", "health record section",
            "medical records", "vital signs", "body vitals",
            "oxygen section", "heart rate section", "weight section",
            "temperature section"
        ]) { return .openHealthTracking }

        // Dashboard
        if has(text, [
            "dashboard", "home", "main screen", "home screen",
            "main page", "start page", "overview", "go home",
            "take me home", "open home", "home page",
            "first screen", "main dashboard", "health overview",
            "today screen", "today overview", "today summary"
        ]) { return .openDashboard }

        // Medicine Reminder
        if has(text, [
            "medicine reminder", "tablet reminder", "pill reminder",
            "dose reminder", "medicine alarm", "tablet alarm",
            "pill alarm", "dose alarm", "reminder screen",
            "reminder section", "open reminder", "medicine alert",
            "tablet alert", "dose alert", "medication reminder",
            "take medicine reminder", "medicine notification"
        ]) { return .openMedicineReminder }

        // Daily Check-In
        if has(text, [
            "daily check in", "check in", "checkin", "mood log",
            "record mood", "log mood", "log sleep", "sleep log",
            "energy level", "stress level", "log stress",
            "wellness check", "daily log", "daily feeling",
            "how i feel", "feeling log", "how am i feeling today",
            "open mood", "mood section", "daily wellness"
        ]) { return .openDailyCheckIn }

        // Profile
        if has(text, [
            "profile", "my profile", "account", "my account",
            "personal details", "user profile", "profile page",
            "edit profile", "my details", "profile section",
            "account details", "personal info", "my information"
        ]) { return .openProfile }

        // Settings
        if has(text, [
            "settings", "setting", "preferences", "configure",
            "app settings", "configuration", "privacy settings",
            "accessibility", "haptic settings", "voice settings",
            "notification settings", "change settings",
            "app preferences", "app options"
        ]) { return .openSettings }

        // Go Back
        if has(text, [
            "go back", "back", "previous", "return",
            "close this", "cancel", "dismiss", "exit",
            "leave", "done", "finish", "never mind",
            "wapas", "wapas jao", "band karo", "close",
            "go to previous", "previous screen", "back screen"
        ]) { return .goBack }

        // Help
        if has(text, [
            "help", "confused", "what can you do", "guide",
            "what can i do", "how do i use this app", "where do i start",
            "i'm confused", "im confused", "start using app",
            "i dont know", "i am lost", "lost", "what do i say",
            "how does this work", "teach me", "show commands",
            "what can i ask", "guide me", "i need help",
            "what should i say", "explain app", "assistant help",
            "voice help", "mujhe help chahiye", "kya kar sakte ho",
            "kaise use karein", "guide karo", "help karo",
            "samajh nahi aaya", "kya bolun", "kya kahun"
        ]) { return .helpGeneral }

        return .unknown
    }

    private func has(_ text: String, _ phrases: [String]) -> Bool {
        phrases.contains { text.contains($0) }
    }
}
