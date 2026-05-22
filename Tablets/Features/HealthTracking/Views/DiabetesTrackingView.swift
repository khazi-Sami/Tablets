import SwiftData
import SwiftUI

struct DiabetesTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthRecord.measuredAt, order: .reverse) private var records: [HealthRecord]
    @StateObject private var viewModel = DiabetesTrackingViewModel()

    private var sugarRecords: [HealthRecord] { records.filter { $0.type == .bloodSugar } }

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView {
                    VStack(spacing: Spacing.medium) {
                        HealthGlassCard {
                            VStack(alignment: .leading, spacing: Spacing.small) {
                                Label("Diabetes tracking", systemImage: "drop.fill")
                                    .font(AppFont.title)
                                    .foregroundStyle(AppColor.ink)
                                Text("Based on your logs. Estimated range. Not a medical diagnosis.")
                                    .font(AppFont.caption)
                                    .foregroundStyle(AppColor.secondaryInk)
                            }
                        }
                        input("Fasting sugar", text: $viewModel.fasting, unit: "mg/dL")
                        input("After meal sugar", text: $viewModel.afterMeal, unit: "mg/dL")
                        input("HbA1c", text: $viewModel.hba1c, unit: "%")
                        input("Medicine / insulin note", text: $viewModel.medicineNote, unit: "")
                        input("Meal note", text: $viewModel.mealNote, unit: "")
                        input("Exercise note", text: $viewModel.exerciseNote, unit: "")
                        symptoms
                        summary
                        CapsuleButton("Save Diabetes Log", systemImage: "checkmark.circle.fill") {
                            _ = viewModel.save(modelContext: modelContext)
                        }
                    }
                    .padding(Spacing.medium)
                }
            }
            .navigationTitle("Diabetes")
        }
    }

    private var symptoms: some View {
        HealthGlassCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Symptoms")
                    .font(AppFont.sectionTitle)
                WomensHealthFlowLayout {
                    ForEach(viewModel.symptomOptions, id: \.self) { symptom in
                        WomensHealthChip(title: symptom, isSelected: viewModel.symptoms.contains(symptom)) {
                            viewModel.toggle(symptom)
                        }
                    }
                }
            }
        }
    }

    private var summary: some View {
        let values = sugarRecords.map(\.value1)
        let avg = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        return HealthGlassCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HealthStatusPill(title: "Estimated range", color: AppColor.lavenderDeep)
                Text("Daily sugar summary")
                    .font(AppFont.sectionTitle)
                Text("Weekly average: \(Int(avg)) mg/dL")
                Text("Highest: \(Int(values.max() ?? 0)) • Lowest: \(Int(values.min() ?? 0))")
                Text("Trend direction: \(values.count > 1 && (values.first ?? 0) > (values.last ?? 0) ? "up based on logs" : "stable based on logs")")
            }
            .font(AppFont.body)
            .foregroundStyle(AppColor.secondaryInk)
        }
    }

    private func input(_ title: String, text: Binding<String>, unit: String) -> some View {
        HealthGlassCard {
            HStack {
                Text(title).font(AppFont.bodyStrong)
                Spacer()
                TextField(title, text: text)
                    .keyboardType(unit.isEmpty ? .default : .decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(AppFont.bodyStrong)
                    .frame(minWidth: 90)
                if !unit.isEmpty { Text(unit).font(AppFont.badge).foregroundStyle(AppColor.secondaryInk) }
            }
        }
    }
}
