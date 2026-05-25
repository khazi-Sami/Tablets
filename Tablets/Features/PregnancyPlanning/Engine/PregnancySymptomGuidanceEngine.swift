import Foundation

struct PregnancySymptomGuidanceEngine {
    func getGuidance(for symptoms: [String], week: Int) -> String {
        let normalized = symptoms.map { $0.lowercased() }
        let guidance = normalized.compactMap { symptom in
            entries.first { key, _ in symptom.contains(key) || key.contains(symptom) }?.value
        }

        let core = guidance.first ?? "I've saved your symptoms in your pregnancy log. Please mention any symptoms to your doctor or midwife at your next appointment, or sooner if anything feels severe or unusual."
        return "\(core) This is informational only. Please consult your doctor or midwife for personal medical advice."
    }

    private let entries: [String: String] = [
        "morning sickness": "Nausea is very common in early pregnancy, especially before week 14. Try eating small frequent meals and staying hydrated. Ginger tea or crackers may help. Please contact your doctor if vomiting is severe or you cannot keep fluids down.",
        "nausea": "Nausea is very common in early pregnancy, especially before week 14. Try eating small frequent meals and staying hydrated. Ginger tea or crackers may help. Please contact your doctor if vomiting is severe or you cannot keep fluids down.",
        "heartburn": "Heartburn often increases as your baby grows and presses on your stomach. Try smaller meals, avoid spicy food, and do not lie down immediately after eating. Please speak to your doctor or midwife for advice.",
        "back pain": "Back pain is very common as your centre of gravity shifts during pregnancy. Gentle stretching and supportive footwear may help. Please consult your doctor if pain is severe or sudden.",
        "headache": "Headaches can occur during pregnancy due to hormonal changes and dehydration. Stay hydrated and rest in a quiet space. Please contact your doctor if headaches are severe, frequent, or accompanied by vision changes.",
        "swelling": "Mild swelling in feet and ankles is common in pregnancy, especially in later weeks. Elevate your feet when resting and stay hydrated. Contact your doctor if swelling is sudden, severe, or in your face or hands.",
        "fatigue": "Fatigue is very common throughout pregnancy. Rest when you can and accept help when offered. If fatigue feels extreme, please mention it to your doctor.",
        "dizziness": "Dizziness during pregnancy can be caused by low blood pressure or blood sugar. Sit or lie down if you feel dizzy. Stay hydrated and avoid standing for long periods. Contact your doctor if dizziness is frequent or severe.",
        "leg cramps": "Leg cramps are common in pregnancy, especially at night. Gentle calf stretches before bed may help. Stay hydrated and make sure you are getting enough calcium and magnesium. Mention persistent cramps to your doctor.",
        "braxton hicks": "Braxton Hicks contractions are practice contractions that are common from mid-pregnancy. They are usually irregular and go away with movement or rest. Contact your doctor if contractions become regular, painful, or increase in frequency.",
        "spotting": "Please contact your doctor or midwife promptly if you notice any spotting or bleeding during pregnancy. Do not wait — always get this checked by a professional.",
        "shortness of breath": "Mild shortness of breath is common as your uterus grows and presses on your diaphragm. Rest when needed. Contact your doctor immediately if you have sudden or severe difficulty breathing.",
        "insomnia": "Sleep difficulties are common during pregnancy. Try sleeping on your left side with a pillow between your knees. Avoid screens before bed. Mention persistent insomnia to your doctor."
    ]
}
