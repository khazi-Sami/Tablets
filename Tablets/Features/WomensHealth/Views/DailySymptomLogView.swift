import SwiftData
import SwiftUI

struct DailySymptomLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DailySymptomLogViewModel()

    var body: some View {
        NavigationStack {
            WomensHealthBackground {
                ZStack(alignment: .bottom) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: Spacing.large) {
                            WomensHealthSection(title: "Today") {
                                HStack {
                                    Label("Log date", systemImage: "calendar")
                                        .font(AppFont.bodyStrong)
                                        .foregroundStyle(AppColor.ink)

                                    Spacer()

                                    DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                                        .labelsHidden()
                                        .tint(WomensHealthTheme.blush)
                                }
                            }

                            WomensHealthSection(title: "Symptoms") {
                                WomensHealthFlowLayout {
                                    ForEach(WomensHealthSymptom.allCases) { symptom in
                                        WomensHealthChip(title: symptom.title, isSelected: viewModel.selectedSymptoms.contains(symptom)) {
                                            viewModel.toggle(symptom)
                                        }
                                    }
                                }
                            }

                            WomensHealthSection(title: "Daily details") {
                                VStack(spacing: Spacing.small) {
                                    textEntry("Discharge notes", text: $viewModel.dischargeNotes, icon: "text.bubble")
                                    textEntry("Medication taken", text: $viewModel.medicationTaken, icon: "pills.fill")

                                    stepperRow("Water intake", subtitle: "\(viewModel.waterIntakeCups) cups", value: $viewModel.waterIntakeCups, icon: "drop.fill")

                                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                                        Text("Sleep quality")
                                            .font(AppFont.bodyStrong)
                                            .foregroundStyle(AppColor.ink)

                                        WomensHealthFlowLayout {
                                            ForEach(SleepQuality.allCases) { quality in
                                                WomensHealthChip(title: quality.title, isSelected: viewModel.sleepQuality == quality) {
                                                    viewModel.sleepQuality = quality
                                                }
                                            }
                                        }
                                    }
                                    .padding(Spacing.medium)
                                    .background(AppColor.cream.opacity(0.80))
                                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
                                }
                            }

                            WomensHealthSection(title: "Notes") {
                                TextField("Optional note", text: $viewModel.notes, axis: .vertical)
                                    .font(AppFont.body)
                                    .lineLimit(4...7)
                                    .padding(Spacing.medium)
                                    .background(AppColor.cream.opacity(0.80))
                                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
                            }

                            Color.clear.frame(height: 92)
                        }
                        .padding(Spacing.medium)
                    }

                    saveBar
                }
            }
            .navigationTitle("Log Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var saveBar: some View {
        VStack {
            CapsuleButton("Save Daily Log", systemImage: "checkmark.circle.fill") {
                if viewModel.save(modelContext: modelContext) {
                    dismiss()
                }
            }
        }
        .padding(Spacing.medium)
        .background(WomensHealthTheme.warm.opacity(0.90).ignoresSafeArea(edges: .bottom))
    }

    private func textEntry(_ title: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Label(title, systemImage: icon)
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.ink)

            TextField(title, text: text, axis: .vertical)
                .font(AppFont.body)
                .lineLimit(2...4)
        }
        .padding(Spacing.medium)
        .background(AppColor.cream.opacity(0.80))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
    }

    private func stepperRow(_ title: String, subtitle: String, value: Binding<Int>, icon: String) -> some View {
        Stepper(value: value, in: 0...30) {
            Label {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(AppFont.bodyStrong)
                        .foregroundStyle(AppColor.ink)
                    Text(subtitle)
                        .font(AppFont.badge)
                        .foregroundStyle(AppColor.secondaryInk)
                }
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(WomensHealthTheme.blush)
            }
        }
        .padding(Spacing.medium)
        .background(AppColor.cream.opacity(0.80))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
    }
}

#Preview {
    DailySymptomLogView()
        .modelContainer(SampleData.previewContainer)
}
