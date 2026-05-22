import SwiftData
import SwiftUI

struct DailyCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DailyCheckInViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                EmotionalGradientView(mode: .healing)
                JourneyWaveBackground(mode: .healing)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.large) {
                        VStack(spacing: Spacing.medium) {
                            FloatingHealthOrb(mode: .healing)
                            Text("How are you feeling today?")
                                .font(AppFont.display)
                                .foregroundStyle(AppColor.ink)
                                .multilineTextAlignment(.center)
                            Text("A gentle check-in helps your journey feel more personal.")
                                .font(AppFont.body)
                                .foregroundStyle(AppColor.secondaryInk)
                                .multilineTextAlignment(.center)
                        }

                        HealingGlowCard(color: AppColor.medicalBlue) {
                            VStack(alignment: .leading, spacing: Spacing.medium) {
                                Text("Mood")
                                    .font(AppFont.sectionTitle)
                                    .foregroundStyle(AppColor.ink)
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.small) {
                                    ForEach(JourneyMood.allCases) { mood in
                                        choice(title: mood.title, symbol: mood.symbol, isSelected: viewModel.mood == mood) {
                                            viewModel.mood = mood
                                            HapticsManager.selection()
                                        }
                                    }
                                }
                            }
                        }

                        sliderCard(title: "Stress level", value: $viewModel.stressLevel, color: AppColor.softRed)
                        sliderCard(title: "Energy level", value: $viewModel.energyLevel, color: AppColor.mintGreenDeep)

                        HealingGlowCard(color: AppColor.lavenderDeep) {
                            VStack(alignment: .leading, spacing: Spacing.medium) {
                                Text("Sleep quality")
                                    .font(AppFont.sectionTitle)
                                    .foregroundStyle(AppColor.ink)
                                JourneyFlowLayout(spacing: Spacing.xSmall) {
                                    ForEach(SleepQuality.allCases) { quality in
                                        Button {
                                            viewModel.sleepQuality = quality
                                            HapticsManager.selection()
                                        } label: {
                                            Text(quality.title)
                                                .font(AppFont.badge)
                                                .foregroundStyle(viewModel.sleepQuality == quality ? .white : AppColor.ink)
                                                .padding(.horizontal, Spacing.small)
                                                .padding(.vertical, Spacing.xSmall)
                                                .background(viewModel.sleepQuality == quality ? AppColor.lavenderDeep : AppColor.cream.opacity(0.78))
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        HealingGlowCard(color: AppColor.softRed) {
                            VStack(alignment: .leading, spacing: Spacing.medium) {
                                Text("Symptoms")
                                    .font(AppFont.sectionTitle)
                                    .foregroundStyle(AppColor.ink)
                                JourneyFlowLayout(spacing: Spacing.xSmall) {
                                    ForEach(viewModel.symptomOptions, id: \.self) { symptom in
                                        Button {
                                            viewModel.toggleSymptom(symptom)
                                        } label: {
                                            Text(symptom)
                                                .font(AppFont.badge)
                                                .foregroundStyle(viewModel.symptoms.contains(symptom) ? .white : AppColor.ink)
                                                .padding(.horizontal, Spacing.small)
                                                .padding(.vertical, Spacing.xSmall)
                                                .background(viewModel.symptoms.contains(symptom) ? AppColor.medicalBlue : AppColor.cream.opacity(0.78))
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        TextField("Anything you want to remember?", text: $viewModel.notes, axis: .vertical)
                            .font(AppFont.body)
                            .padding(Spacing.medium)
                            .background(AppGradient.card)
                            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
                            .appShadow(AppShadow.soft)

                        CapsuleButton("Save Check-In", systemImage: "checkmark.circle.fill") {
                            viewModel.save(modelContext: modelContext)
                        }
                    }
                    .padding(Spacing.medium)
                    .padding(.bottom, Spacing.large)
                }
            }
            .navigationTitle("Daily Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onChange(of: viewModel.didSave) { _, didSave in
                if didSave { dismiss() }
            }
        }
    }

    private func choice(title: String, symbol: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(AppFont.bodyStrong)
                .foregroundStyle(isSelected ? .white : AppColor.ink)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background {
                    if isSelected {
                        AppGradient.primaryButton
                    } else {
                        AppColor.cream.opacity(0.78)
                    }
                }
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func sliderCard(title: String, value: Binding<Double>, color: Color) -> some View {
        HealingGlowCard(color: color) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack {
                    Text(title)
                        .font(AppFont.sectionTitle)
                    Spacer()
                    Text("\(Int(value.wrappedValue.rounded()))/10")
                        .font(AppFont.bodyStrong)
                        .foregroundStyle(color)
                }
                Slider(value: value, in: 0...10, step: 1)
                    .tint(color)
            }
            .foregroundStyle(AppColor.ink)
        }
    }
}

struct JourneyFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 320
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    DailyCheckInView()
        .modelContainer(SampleData.previewContainer)
}
