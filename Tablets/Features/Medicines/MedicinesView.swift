import SwiftData
import SwiftUI

struct MedicinesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Medicine.name) private var medicines: [Medicine]
    @StateObject private var viewModel = MedicinesViewModel()
    @State private var reminderMedicine: Medicine?

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                Group {
                    if medicines.isEmpty {
                        EmptyStateView(
                            title: "No medicines",
                            message: "Create your medicine list and reminders.",
                            systemImage: "pills",
                            actionTitle: "Add Medicine"
                        ) {
                            viewModel.isPresentingAddMedicine = true
                        }
                        .padding(Spacing.medium)
                    } else {
                        List {
                            ForEach(medicines) { medicine in
                                MedicineRowView(medicine: medicine)
                                    .onTapGesture {
                                        HapticsManager.selection()
                                        reminderMedicine = medicine
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            viewModel.delete(medicine, modelContext: modelContext)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .contentMargins(.vertical, Spacing.small, for: .scrollContent)
                    }
                }
            }
            .navigationTitle("Medicines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isPresentingAddMedicine = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Medicine")
                }
            }
            .sheet(isPresented: $viewModel.isPresentingAddMedicine) {
                AddMedicineView()
            }
            .sheet(item: $reminderMedicine) { medicine in
                MedicineReminderView(medicine: medicine)
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openAddMedicine)) { _ in
                viewModel.isPresentingAddMedicine = true
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openMedicineReminder)) { _ in
                reminderMedicine = medicines.first(where: \.isActive) ?? medicines.first
            }
            .alert("Something went wrong", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

private struct MedicineRowView: View {
    let medicine: Medicine

    var body: some View {
        PillCardContainer {
            HStack(spacing: Spacing.medium) {
                MedicineBottleBadge()

                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(medicine.name)
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)

                    Text(medicine.dosage)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)

                    if !medicine.notes.isEmpty {
                        Text(medicine.notes)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.tertiaryInk)
                    }
                }

                Spacer()

                HealthStatusBadge(status: medicine.isActive ? .good : .attention)
            }
        }
        .padding(.vertical, Spacing.xxSmall)
    }
}

private struct MedicineBottleBadge: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(AppGradient.lavenderWash)
                .frame(width: 54, height: 64)

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(AppColor.medicalBlue.opacity(0.20))
                .frame(width: 24, height: 8)
                .offset(y: -29)

            Image(systemName: "cross.vial.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColor.medicalBlue)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    MedicinesView()
        .modelContainer(SampleData.previewContainer)
}
