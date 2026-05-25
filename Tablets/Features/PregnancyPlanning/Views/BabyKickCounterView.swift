import SwiftData
import SwiftUI

struct BabyKickCounterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let profile: PregnancyProfile
    @StateObject private var viewModel = BabyKickViewModel()
    @State private var iconScale = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()
                ScrollView {
                VStack(spacing: 22) {
                    Text("Count Baby's Kicks 👶").font(PregnancyTheme.titleFont)
                    Text("Tap each time you feel your baby move").font(PregnancyTheme.bodyFont).foregroundStyle(AppColor.secondaryInk)
                    if !viewModel.isSessionActive {
                        Button("Start Session") { viewModel.startSession() }
                            .font(PregnancyTheme.bodyFont.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(PregnancyTheme.deepRose, in: RoundedRectangle(cornerRadius: PregnancyTheme.buttonRadius))
                    }
                    Button { viewModel.recordKick() } label: {
                        VStack {
                            Image(systemName: PregnancyTheme.iconBaby).font(.system(size: 70)).symbolEffect(.bounce, value: viewModel.kickCount)
                                .scaleEffect(iconScale)
                            Text("\(viewModel.kickCount) kicks").font(PregnancyTheme.largeFont)
                            Text(timeText(viewModel.elapsedSeconds)).font(PregnancyTheme.bodyFont)
                        }
                        .foregroundStyle(PregnancyTheme.deepRose)
                        .frame(width: 220, height: 220)
                        .background(.white.opacity(0.62), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .onChange(of: viewModel.kickCount) { _, _ in
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { iconScale = 1.12 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) { iconScale = 1.0 }
                        }
                    }
                    Toggle("Auto-stop at 10 kicks", isOn: $viewModel.autoStopEnabled)
                    if viewModel.didReachTenKicks {
                        Text("10 kicks reached! 🎉")
                            .font(PregnancyTheme.headingFont)
                            .foregroundStyle(PregnancyTheme.deepRose)
                    }
                    PregnancyCard {
                        Text("If you notice reduced movement, contact your doctor or midwife promptly.")
                            .font(PregnancyTheme.bodyFont)
                            .foregroundStyle(AppColor.secondaryInk)
                    }
                    Button("Save Session 💛") {
                        viewModel.stopSession(context: modelContext, profileId: profile.id)
                    }
                    .font(PregnancyTheme.bodyFont.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(PregnancyTheme.deepRose, in: RoundedRectangle(cornerRadius: PregnancyTheme.buttonRadius))
                    if viewModel.didSaveSession, let session = viewModel.savedSession {
                        PregnancyCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Session saved 💛").font(PregnancyTheme.headingFont)
                                Text("\(session.kickCount) kicks · \(session.durationMinutes ?? 0) minutes")
                                Text(session.sessionStartedAt.formatted(date: .abbreviated, time: .shortened))
                                Text("If you notice reduced movement, contact your doctor or midwife promptly.")
                                    .font(PregnancyTheme.captionFont)
                                Button("Done") {
                                    dismiss()
                                }
                                .font(PregnancyTheme.bodyFont.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(PregnancyTheme.deepRose, in: RoundedRectangle(cornerRadius: PregnancyTheme.buttonRadius))
                            }
                        }
                    }
                    PregnancyCard {
                        VStack(alignment: .leading) {
                            Text("Recent sessions").font(PregnancyTheme.headingFont)
                            ForEach(viewModel.recentSessions) { session in
                                Text("\(session.sessionStartedAt.formatted(date: .abbreviated, time: .shortened)) · \(session.kickCount) kicks · \(session.durationMinutes ?? 0) min")
                            }
                        }
                    }
                }
                .padding(PregnancyTheme.pagePadding)
                }
            }
            .task { viewModel.loadRecent(context: modelContext, profileId: profile.id) }
            .navigationTitle("Kick Counter")
        }
    }

    private func timeText(_ seconds: Int) -> String {
        "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}
