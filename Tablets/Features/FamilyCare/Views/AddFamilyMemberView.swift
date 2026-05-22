import SwiftData
import SwiftUI
import UIKit

struct AddFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = AddFamilyMemberViewModel()

    private let avatarSymbols = ["person.fill", "heart.fill", "cross.case.fill", "figure.wave", "house.fill", "star.fill"]

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.large) {
                        FamilyPreviewAvatar(
                            symbol: viewModel.avatarSymbol,
                            gradient: viewModel.gradient
                        )

                        familyTextField("Name", text: $viewModel.name, systemImage: "person.fill")
                        familyTextField("Age", text: $viewModel.age, systemImage: "calendar", keyboard: .numberPad)

                        selectorSection("Relationship") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.small) {
                                ForEach(FamilyRelationship.allCases) { relationship in
                                    FamilyChoiceChip(
                                        title: relationship.title,
                                        isSelected: viewModel.relationship == relationship
                                    ) {
                                        HapticsManager.selection()
                                        viewModel.relationship = relationship
                                    }
                                }
                            }
                        }

                        selectorSection("Avatar") {
                            HStack(spacing: Spacing.small) {
                                ForEach(avatarSymbols, id: \.self) { symbol in
                                    Button {
                                        HapticsManager.selection()
                                        viewModel.avatarSymbol = symbol
                                    } label: {
                                        Image(systemName: symbol)
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundStyle(viewModel.avatarSymbol == symbol ? .white : AppColor.medicalBlue)
                                            .frame(width: 50, height: 50)
                                            .background {
                                                if viewModel.avatarSymbol == symbol {
                                                    AppGradient.primaryButton
                                                } else {
                                                    AppGradient.card
                                                }
                                            }
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        selectorSection("Profile color") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.small) {
                                ForEach(FamilyAvatarGradient.allCases) { gradient in
                                    FamilyChoiceChip(
                                        title: gradient.rawValue.capitalized,
                                        isSelected: viewModel.gradient == gradient
                                    ) {
                                        HapticsManager.selection()
                                        viewModel.gradient = gradient
                                    }
                                }
                            }
                        }

                        familyTextField("Care notes", text: $viewModel.notes, systemImage: "note.text")

                        CapsuleButton("Save Family Member", systemImage: "checkmark.circle.fill") {
                            viewModel.save(modelContext: modelContext)
                        }
                    }
                    .padding(Spacing.medium)
                }
            }
            .navigationTitle("Add Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Almost there", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: viewModel.didSave) { _, didSave in
                if didSave { dismiss() }
            }
        }
    }

    private func familyTextField(_ title: String, text: Binding<String>, systemImage: String, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: systemImage)
                .foregroundStyle(AppColor.medicalBlue)
                .frame(width: 34)

            TextField(title, text: text)
                .font(AppFont.body)
                .keyboardType(keyboard)
        }
        .padding(Spacing.medium)
        .background(AppGradient.card)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
        .appShadow(AppShadow.soft)
    }

    private func selectorSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(title)
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)
                content()
            }
        }
    }
}

private struct FamilyPreviewAvatar: View {
    let symbol: String
    let gradient: FamilyAvatarGradient

    var body: some View {
        ZStack {
            Circle()
                .fill(AppGradient.lavenderWash)
                .frame(width: 124, height: 124)
            Image(systemName: symbol)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(AppColor.medicalBlue)
        }
        .appShadow(AppShadow.soft)
    }
}

private struct FamilyChoiceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.bodyStrong)
                .foregroundStyle(isSelected ? .white : AppColor.ink)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background {
                    if isSelected {
                        AppGradient.primaryButton
                    } else {
                        AppColor.warmWhite.opacity(0.74)
                    }
                }
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddFamilyMemberView()
        .modelContainer(SampleData.previewContainer)
}
