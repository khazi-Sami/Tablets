import SwiftData
import SwiftUI

struct PregnancyWeightLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let profile: PregnancyProfile
    @StateObject private var viewModel = PregnancyWeightViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Track Your Weight 🌿").font(PregnancyTheme.titleFont)
                        Text("Week \(profile.currentWeek)").font(PregnancyTheme.headingFont).foregroundStyle(PregnancyTheme.deepRose)
                        PregnancyCard {
                            VStack(spacing: 12) {
                                TextField("Weight", text: $viewModel.weight)
                                    .keyboardType(.decimalPad)
                                    .font(PregnancyTheme.largeFont)
                                Picker("Unit", selection: $viewModel.unit) {
                                    ForEach(WeightUnit.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                            }
                        }
                        PregnancyCard {
                            Text("General reference only — please follow your doctor's guidance for pregnancy weight gain.")
                                .font(PregnancyTheme.bodyFont)
                                .foregroundStyle(AppColor.secondaryInk)
                        }
                        PregnancyCard {
                            VStack(alignment: .leading) {
                                Text("Recent weight entries").font(PregnancyTheme.headingFont)
                                ForEach(viewModel.recentLogs) { log in
                                    Text("Week \(log.weekNumber): \(log.weight, specifier: "%.1f") \(log.unit.rawValue)")
                                }
                            }
                        }
                        Button("Save Weight 💛") {
                            viewModel.save(context: modelContext, profileId: profile.id, week: profile.currentWeek)
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
            .task { viewModel.loadRecent(context: modelContext, profileId: profile.id) }
            .navigationTitle("Weight")
        }
        .dismissKeyboardOnTap()
    }
}
