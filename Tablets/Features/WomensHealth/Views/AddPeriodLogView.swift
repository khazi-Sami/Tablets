import SwiftData
import SwiftUI

struct AddPeriodLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = AddPeriodLogViewModel()

    var body: some View {
        NavigationStack {
            WomensHealthBackground {
                ZStack(alignment: .bottom) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: Spacing.large) {
                            WomensHealthSection(title: "Period dates") {
                                VStack(spacing: Spacing.small) {
                                    dateRow("Start date", date: $viewModel.startDate, icon: "calendar")

                                    Toggle(isOn: $viewModel.hasEndDate.animation(.spring(response: 0.32, dampingFraction: 0.84))) {
                                        Label("Add end date", systemImage: "calendar.badge.checkmark")
                                            .font(AppFont.bodyStrong)
                                            .foregroundStyle(AppColor.ink)
                                    }
                                    .tint(WomensHealthTheme.blush)
                                    .padding(Spacing.medium)
                                    .background(AppColor.cream.opacity(0.80))
                                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))

                                    if viewModel.hasEndDate {
                                        dateRow("End date", date: $viewModel.endDate, icon: "calendar.badge.clock")
                                            .transition(.move(edge: .top).combined(with: .opacity))
                                    }
                                }
                            }

                            WomensHealthSection(title: "Flow and pain") {
                                VStack(alignment: .leading, spacing: Spacing.medium) {
                                    WomensHealthFlowLayout {
                                        ForEach(WomensFlowLevel.allCases) { flow in
                                            WomensHealthChip(title: flow.title, isSelected: viewModel.flowLevel == flow) {
                                                viewModel.flowLevel = flow
                                            }
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                                        Text("Pain level: \(Int(viewModel.painLevel.rounded())) / 10")
                                            .font(AppFont.bodyStrong)
                                            .foregroundStyle(AppColor.ink)

                                        Slider(value: $viewModel.painLevel, in: 0...10, step: 1)
                                            .tint(WomensHealthTheme.blush)
                                    }
                                }
                            }

                            WomensHealthSection(title: "Mood") {
                                WomensHealthFlowLayout {
                                    ForEach(WomensMood.allCases) { mood in
                                        WomensHealthChip(title: mood.title, isSelected: viewModel.mood == mood) {
                                            viewModel.mood = mood
                                        }
                                    }
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

                            notesSection

                            Color.clear.frame(height: 92)
                        }
                        .padding(Spacing.medium)
                    }

                    saveBar
                }
            }
            .navigationTitle("Add Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Unable to save", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var notesSection: some View {
        WomensHealthSection(title: "Notes") {
            TextField("Anything you want to remember?", text: $viewModel.notes, axis: .vertical)
                .font(AppFont.body)
                .lineLimit(4...7)
                .padding(Spacing.medium)
                .background(AppColor.cream.opacity(0.80))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
        }
    }

    private var saveBar: some View {
        VStack {
            CapsuleButton("Save Period Log", systemImage: "checkmark.circle.fill") {
                if viewModel.save(modelContext: modelContext) {
                    dismiss()
                }
            }
            .disabled(!viewModel.canSave)
            .opacity(viewModel.canSave ? 1 : 0.6)
        }
        .padding(Spacing.medium)
        .background(WomensHealthTheme.warm.opacity(0.90).ignoresSafeArea(edges: .bottom))
    }

    private func dateRow(_ title: String, date: Binding<Date>, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.ink)

            Spacer()

            DatePicker("", selection: date, displayedComponents: .date)
                .labelsHidden()
                .tint(WomensHealthTheme.blush)
        }
        .padding(Spacing.medium)
        .background(AppColor.cream.opacity(0.80))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
    }
}

#Preview {
    AddPeriodLogView()
        .modelContainer(SampleData.previewContainer)
}
