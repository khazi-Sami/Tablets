import SwiftData
import SwiftUI

struct MoodTrackingView: View {
    @Environment(\.modelContext) private var modelContext
    let profile: PregnancyProfile
    @StateObject private var viewModel = MoodTrackingViewModel()
    private let emotions = ["Grateful", "Overwhelmed", "Hopeful", "Nervous", "Loved", "Lonely", "Strong", "Fragile", "Peaceful", "Irritable", "Joyful", "Exhausted", "Confident", "Fearful"]

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("How are you feeling?")
                            .font(PregnancyTheme.titleFont)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(PregnancyMood.allCases) { mood in
                                Button("\(emoji(for: mood)) \(mood.rawValue)") { viewModel.selectedMood = mood }
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .background((viewModel.selectedMood == mood ? PregnancyTheme.blushPink : .white.opacity(0.7)), in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        PregnancyFlowLayout {
                            ForEach(emotions, id: \.self) { emotion in
                                PregnancyChip(title: emotion, isSelected: viewModel.selectedEmotions.contains(emotion)) {
                                    if viewModel.selectedEmotions.contains(emotion) {
                                        viewModel.selectedEmotions.remove(emotion)
                                    } else {
                                        viewModel.selectedEmotions.insert(emotion)
                                    }
                                }
                            }
                        }
                        Stepper("Energy level: \(viewModel.energyLevel)", value: $viewModel.energyLevel, in: 1...5)
                        TextField("Optional note", text: $viewModel.note, axis: .vertical)
                            .padding()
                            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16))
                        Button("Save My Mood") {
                            viewModel.save(context: modelContext, profileId: profile.id, week: profile.currentWeek)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(PregnancyTheme.deepRose, in: RoundedRectangle(cornerRadius: 16))
                        if let message = viewModel.savedMessage {
                            PregnancyCard { Text(message).font(PregnancyTheme.bodyFont) }
                        }
                        PregnancyCard {
                            VStack(alignment: .leading) {
                                Text("Last 14 days")
                                    .font(PregnancyTheme.headingFont)
                                ForEach(viewModel.moodTrend) { log in
                                    Text("\(emoji(for: log.mood)) \(log.mood.rawValue) · \(log.loggedAt.formatted(date: .abbreviated, time: .omitted))")
                                }
                            }
                        }
                    }
                    .padding(PregnancyTheme.pagePadding)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Mood")
            .task { viewModel.loadRecent(context: modelContext, profileId: profile.id) }
        }
        .dismissKeyboardOnTap()
    }

    private func emoji(for mood: PregnancyMood) -> String {
        switch mood {
        case .happy: return "😊"
        case .anxious: return "😰"
        case .tired: return "😴"
        case .emotional: return "😢"
        case .calm: return "😌"
        case .uncomfortable: return "😣"
        case .excited: return "🤩"
        case .worried: return "😟"
        }
    }
}
