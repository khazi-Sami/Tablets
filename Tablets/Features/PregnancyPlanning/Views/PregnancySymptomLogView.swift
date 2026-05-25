import SwiftData
import SwiftUI

struct PregnancySymptomLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let profile: PregnancyProfile
    @StateObject private var viewModel = PregnancySymptomViewModel()
    @State private var otherSymptom = ""

    private let symptoms = ["Morning Sickness 🤢", "Fatigue 😴", "Headache 🤕", "Back Pain 🔙", "Heartburn 🔥", "Swelling 💧", "Mood Swings 💭", "Breast Tenderness 💗", "Cravings 🍎", "Food Aversion 🚫", "Constipation 🌿", "Frequent Urination 🚿", "Dizziness 💫", "Leg Cramps 🦵", "Shortness of Breath 🫁", "Round Ligament Pain ⚡", "Insomnia 🌙", "Braxton Hicks ⏱️", "Pelvic Pressure ⬇️", "Spotting 🩸"]

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How are you feeling today? 🌸")
                            .font(PregnancyTheme.titleFont)
                        Text("Log your symptoms to track your wellbeing.")
                            .font(PregnancyTheme.bodyFont)
                            .foregroundStyle(AppColor.secondaryInk)
                        PregnancyCard {
                            PregnancyFlowLayout {
                                ForEach(symptoms, id: \.self) { symptom in
                                    PregnancyChip(title: symptom, isSelected: viewModel.selectedSymptoms.contains(symptom)) {
                                        if viewModel.selectedSymptoms.contains(symptom) { viewModel.selectedSymptoms.remove(symptom) } else { viewModel.selectedSymptoms.insert(symptom) }
                                    }
                                }
                            }
                        }
                        PregnancyCard {
                            VStack(alignment: .leading) {
                                TextField("Other symptom", text: $otherSymptom)
                                Picker("Severity", selection: $viewModel.severity) {
                                    ForEach(SymptomSeverity.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                                Picker("Mood", selection: $viewModel.mood) {
                                    ForEach(PregnancyMood.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.menu)
                                TextField("Notes", text: $viewModel.notes, axis: .vertical).lineLimit(3...5)
                            }
                        }
                        Button("Save How I Feel 💛") {
                            if !otherSymptom.isEmpty { viewModel.selectedSymptoms.insert(otherSymptom) }
                            viewModel.save(context: modelContext, profileId: profile.id)
                            dismiss()
                        }
                        .font(PregnancyTheme.bodyFont.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(PregnancyTheme.deepRose, in: RoundedRectangle(cornerRadius: PregnancyTheme.buttonRadius))
                    }
                    .padding(PregnancyTheme.pagePadding)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Symptoms")
        }
        .dismissKeyboardOnTap()
    }
}
