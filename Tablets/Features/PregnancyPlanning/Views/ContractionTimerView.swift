import SwiftData
import SwiftUI

struct ContractionTimerView: View {
    @Environment(\.modelContext) private var modelContext
    let profile: PregnancyProfile
    @StateObject private var viewModel = ContractionViewModel()
    @State private var selectedIntensity: ContractionIntensity = .mild

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        Text("Contraction Timer")
                            .font(PregnancyTheme.titleFont)
                        Text("Track the frequency and duration of contractions")
                            .font(PregnancyTheme.bodyFont)
                            .foregroundStyle(AppColor.secondaryInk)

                        PregnancyCard {
                            VStack(spacing: 18) {
                                Image(systemName: "timer")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundStyle(viewModel.isContrationActive ? .red : PregnancyTheme.deepRose)
                                Text(timeText(viewModel.currentDurationSeconds))
                                    .font(.system(size: 54, weight: .bold, design: .rounded))
                                Button(viewModel.isContrationActive ? "Stop Contraction" : "Start Contraction") {
                                    if viewModel.isContrationActive {
                                        viewModel.stopContraction(intensity: selectedIntensity, context: modelContext, profileId: profile.id)
                                    } else {
                                        viewModel.startContraction()
                                    }
                                }
                                .font(PregnancyTheme.bodyFont.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 58)
                                .background(viewModel.isContrationActive ? Color.red.opacity(0.85) : PregnancyTheme.deepRose, in: RoundedRectangle(cornerRadius: PregnancyTheme.buttonRadius))
                                Picker("Intensity", selection: $selectedIntensity) {
                                    ForEach(ContractionIntensity.allCases) { Text($0.rawValue).tag($0) }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        if viewModel.pattern == .callDoctor {
                            PregnancyCard {
                                Text("Your contraction pattern may indicate active labour. Please contact your doctor or midwife now, or go to your hospital.")
                                    .font(PregnancyTheme.bodyFont.weight(.semibold))
                                    .foregroundStyle(.red)
                            }
                        }

                        PregnancyCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Summary")
                                    .font(PregnancyTheme.headingFont)
                                Text("Average duration: \(viewModel.averageDuration) seconds")
                                Text("Average interval: \(viewModel.averageInterval / 60) minutes")
                                Text("Always contact your doctor or midwife if you are unsure or concerned.")
                                    .font(PregnancyTheme.captionFont)
                                    .foregroundStyle(AppColor.secondaryInk)
                            }
                        }

                        PregnancyCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("History")
                                        .font(PregnancyTheme.headingFont)
                                    Spacer()
                                    Button("Clear") { viewModel.clearHistory(context: modelContext) }
                                }
                                ForEach(viewModel.contractions.prefix(10)) { log in
                                    Text("\(log.startedAt.formatted(date: .omitted, time: .shortened)) · \(log.durationSeconds ?? 0)s · \(log.intensity.rawValue)")
                                        .font(PregnancyTheme.bodyFont)
                                }
                            }
                        }
                    }
                    .padding(PregnancyTheme.pagePadding)
                }
            }
            .navigationTitle("Contractions")
            .navigationBarTitleDisplayMode(.inline)
            .task { viewModel.loadHistory(context: modelContext, profileId: profile.id) }
        }
    }

    private func timeText(_ seconds: Int) -> String {
        "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}
