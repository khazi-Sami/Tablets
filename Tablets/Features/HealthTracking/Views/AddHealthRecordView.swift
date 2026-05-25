import SwiftData
import SwiftUI

struct AddHealthRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: AddHealthRecordViewModel

    init(type: HealthRecordType = .bloodPressure) {
        _viewModel = StateObject(wrappedValue: AddHealthRecordViewModel(type: type))
    }

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ZStack(alignment: .bottom) {
                    ScrollView {
                        VStack(spacing: Spacing.large) {
                            typePicker
                            inputCard
                            if let alert = viewModel.latestSafetyAlert {
                                HealthAlertView(alert: alert)
                            }
                            notesCard
                            Color.clear.frame(height: 90)
                        }
                        .padding(Spacing.medium)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .dismissKeyboardOnTap()
                    CapsuleButton("Save Record", systemImage: "checkmark.circle.fill") {
                        if viewModel.save(modelContext: modelContext) {
                            let delay = viewModel.latestSafetyAlert == nil ? 0.6 : 3.0
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { dismiss() }
                        }
                    }
                    .padding(Spacing.medium)
                    .background(AppColor.warmWhite.opacity(0.92).ignoresSafeArea(edges: .bottom))
                }
                .overlay {
                    if viewModel.didSave {
                        HealthSuccessOverlay(title: "Record saved")
                    }
                }
            }
            .navigationTitle("Add Record")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var typePicker: some View {
        HealthGlassCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("What are you recording?")
                    .font(AppFont.sectionTitle)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.small) {
                    ForEach(HealthRecordType.allCases) { type in
                        Button {
                            viewModel.type = type
                            viewModel.singleValue = AddHealthRecordViewModel.defaultValue(for: type)
                            HapticsManager.selection()
                        } label: {
                            Label(type.title, systemImage: type.icon)
                                .font(AppFont.badge)
                                .foregroundStyle(viewModel.type == type ? .white : AppColor.medicalBlueDeep)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(viewModel.type == type ? AppColor.medicalBlue : AppColor.cream.opacity(0.78))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var inputCard: some View {
        HealthGlassCard {
            VStack(spacing: Spacing.medium) {
                if viewModel.type == .bloodPressure {
                    numericField("Systolic", text: $viewModel.systolic, unit: "mmHg")
                    numericField("Diastolic", text: $viewModel.diastolic, unit: "mmHg")
                    numericField("Pulse", text: $viewModel.pulse, unit: "bpm")
                } else {
                    numericField(viewModel.type.title, text: $viewModel.singleValue, unit: viewModel.type.unit)
                    if viewModel.type == .bloodSugar {
                        Picker("Test type", selection: $viewModel.sugarTestType) {
                            ForEach(SugarTestType.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                DatePicker("Measured at", selection: $viewModel.measuredAt)
                    .font(AppFont.bodyStrong)
                    .tint(AppColor.medicalBlue)
            }
        }
    }

    private var notesCard: some View {
        HealthGlassCard {
            VStack(spacing: Spacing.small) {
                TextField("Mood", text: $viewModel.mood)
                    .padding(Spacing.medium)
                    .background(AppColor.cream.opacity(0.74))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large))
                TextField("Notes", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(Spacing.medium)
                    .background(AppColor.cream.opacity(0.74))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large))
            }
        }
    }

    private func numericField(_ title: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(AppFont.bodyStrong)
                Text(unit)
                    .font(AppFont.badge)
                    .foregroundStyle(AppColor.secondaryInk)
            }
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .font(AppFont.title)
                .multilineTextAlignment(.trailing)
                .frame(width: 110)
        }
        .padding(Spacing.medium)
        .background(AppColor.cream.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large))
    }
}
