import SwiftData
import SwiftUI

struct FamilyCareView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FamilyMember.createdAt, order: .reverse) private var members: [FamilyMember]
    @Query(sort: \Medicine.name) private var medicines: [Medicine]
    @StateObject private var viewModel = FamilyCareViewModel()

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.large) {
                        FamilyDashboardHero(memberCount: members.count) {
                            HapticsManager.selection()
                            viewModel.isShowingAddMember = true
                        }

                        if members.isEmpty {
                            EmptyStateView(
                                title: "Your care circle is empty",
                                message: "Add family members and gently monitor medicine routines together.",
                                systemImage: "figure.2.and.child.holdinghands",
                                actionTitle: "Add Family Member"
                            ) {
                                viewModel.isShowingAddMember = true
                            }

                            CapsuleButton("Add sample family", systemImage: "sparkles", style: .secondary) {
                                viewModel.addSampleFamily(modelContext: modelContext)
                            }
                        } else {
                            FamilyCareSummaryGrid(members: members)

                            DashboardSectionTitle("Care circle")

                            ForEach(members) { member in
                                FamilyMemberCard(member: member) {
                                    HapticsManager.selection()
                                    viewModel.selectedMember = member
                                }
                            }

                            DashboardSectionTitle("Shared health")

                            SharedHealthSummaryCard(members: members)
                        }
                    }
                    .padding(Spacing.medium)
                    .padding(.bottom, Spacing.large)
                }
            }
            .navigationTitle("Family")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.selection()
                        viewModel.isShowingAddMember = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .accessibilityLabel("Add Family Member")
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddMember) {
                AddFamilyMemberView()
            }
            .sheet(item: $viewModel.selectedMember) { member in
                FamilyMemberDetailView(member: member, medicines: medicines)
            }
        }
    }
}

private struct FamilyCareSummaryGrid: View {
    let members: [FamilyMember]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.small) {
            FamilySummaryTile(title: "Members", value: "\(members.count)", icon: "person.2.fill", color: AppColor.medicalBlue)
            FamilySummaryTile(title: "Medicines", value: "\(assignedMedicineCount)", icon: "pills.fill", color: AppColor.mintGreenDeep)
            FamilySummaryTile(title: "Alerts", value: "\(attentionCount)", icon: "bell.badge.fill", color: attentionCount > 0 ? AppColor.softRed : AppColor.lavenderDeep)
            FamilySummaryTile(title: "Caretaker", value: "On", icon: "heart.text.square.fill", color: AppColor.softRed)
        }
    }

    private var assignedMedicineCount: Int {
        members.reduce(0) { $0 + $1.medicineAssignments.filter(\.isActive).count }
    }

    private var attentionCount: Int {
        members.filter { $0.medicineAssignments.isEmpty }.count
    }
}

private struct FamilySummaryTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HealthGlassCard {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(color)
                    .frame(width: 46, height: 46)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())

                Text(value)
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.ink)

                Text(title)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }
        }
    }
}

private struct SharedHealthSummaryCard: View {
    let members: [FamilyMember]

    var body: some View {
        PillCardContainer(style: .lavender) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(AppColor.softRed)
                    Text("Shared family overview")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)
                }

                Text("Caretaker monitoring is local on this device for now. Missed medicine alerts and summaries are based on saved family profiles and assigned medicines.")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(members.prefix(3)) { member in
                    HStack {
                        Text(member.name)
                            .font(AppFont.bodyStrong)
                            .foregroundStyle(AppColor.ink)
                        Spacer()
                        FamilyStatusIndicator(status: member.medicineAssignments.isEmpty ? .missed : .cared)
                    }
                }
            }
        }
    }
}

private struct FamilyMemberDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var member: FamilyMember
    let medicines: [Medicine]

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.large) {
                        PillCardContainer(style: .highlighted, padding: Spacing.large) {
                            VStack(spacing: Spacing.medium) {
                                FamilyAvatarView(member: member)
                                Text(member.name)
                                    .font(AppFont.display)
                                    .foregroundStyle(AppColor.ink)
                                    .multilineTextAlignment(.center)
                                FamilyStatusIndicator(status: member.medicineAssignments.isEmpty ? .missed : .cared)
                                if !member.notes.isEmpty {
                                    Text(member.notes)
                                        .font(AppFont.body)
                                        .foregroundStyle(AppColor.secondaryInk)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }

                        PillCardContainer {
                            VStack(alignment: .leading, spacing: Spacing.medium) {
                                Text("Assigned medicines")
                                    .font(AppFont.sectionTitle)
                                    .foregroundStyle(AppColor.ink)

                                if member.medicineAssignments.isEmpty {
                                    Text("No medicines assigned yet.")
                                        .font(AppFont.body)
                                        .foregroundStyle(AppColor.secondaryInk)
                                } else {
                                    ForEach(member.medicineAssignments.filter(\.isActive)) { assignment in
                                        HStack {
                                            Image(systemName: assignment.medicine?.medicineType == .syrup ? "cross.vial.fill" : "pills.fill")
                                                .foregroundStyle(AppColor.medicalBlue)
                                            VStack(alignment: .leading) {
                                                Text(assignment.medicine?.name ?? "Medicine")
                                                    .font(AppFont.bodyStrong)
                                                    .foregroundStyle(AppColor.ink)
                                                Text(assignment.medicine?.dosage ?? "")
                                                    .font(AppFont.caption)
                                                    .foregroundStyle(AppColor.secondaryInk)
                                            }
                                            Spacer()
                                            FamilyStatusIndicator(status: .upcoming)
                                        }
                                    }
                                }
                            }
                        }

                        PillCardContainer {
                            VStack(alignment: .leading, spacing: Spacing.medium) {
                                Text("Assign medicine")
                                    .font(AppFont.sectionTitle)
                                    .foregroundStyle(AppColor.ink)

                                if medicines.isEmpty {
                                    Text("Add medicines first, then assign them to family members.")
                                        .font(AppFont.body)
                                        .foregroundStyle(AppColor.secondaryInk)
                                } else {
                                    ForEach(medicines) { medicine in
                                        Button {
                                            assign(medicine)
                                        } label: {
                                            HStack {
                                                Text(medicine.name)
                                                    .font(AppFont.bodyStrong)
                                                    .foregroundStyle(AppColor.ink)
                                                Spacer()
                                                Image(systemName: isAssigned(medicine) ? "checkmark.circle.fill" : "plus.circle")
                                                    .foregroundStyle(isAssigned(medicine) ? AppColor.mintGreenDeep : AppColor.medicalBlue)
                                            }
                                            .padding(Spacing.small)
                                            .background(AppColor.warmWhite.opacity(0.72))
                                            .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(Spacing.medium)
                }
            }
            .navigationTitle("Care Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func isAssigned(_ medicine: Medicine) -> Bool {
        member.medicineAssignments.contains { $0.medicine?.id == medicine.id && $0.isActive }
    }

    private func assign(_ medicine: Medicine) {
        HapticsManager.selection()

        guard !isAssigned(medicine) else { return }
        let assignment = FamilyMedicineAssignment(
            member: member,
            medicine: medicine,
            reminderNote: "Watch with care",
            caretakerNote: "Local caretaker monitoring"
        )
        modelContext.insert(assignment)

        do {
            try modelContext.save()
            HapticsManager.notification(.success)
        } catch {
            HapticsManager.notification(.error)
        }
    }
}

#Preview {
    FamilyCareView()
        .modelContainer(SampleData.previewContainer)
}
