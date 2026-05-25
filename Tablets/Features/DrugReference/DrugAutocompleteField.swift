import SwiftUI

struct DrugAutocompleteField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Binding var selectedEntry: DrugReferenceEntry?
    var onSelect: ((DrugReferenceEntry) -> Void)?

    @State private var catalog = DrugReferenceCatalog.empty
    @State private var suggestions: [DrugReferenceEntry] = []
    @State private var isShowingDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Label(title, systemImage: "pills.fill")
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.secondaryInk)

            TextField(placeholder, text: $text)
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.ink)
                .textInputAutocapitalization(.words)
                .padding(Spacing.medium)
                .background(AppColor.cream.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))

            if let selectedEntry {
                selectedReferencePreview(selectedEntry)
            }

            if !suggestions.isEmpty {
                suggestionsList
            }
        }
        .task {
            catalog = await DrugReferenceStore.loadBundledCatalog()
            syncSelectedEntryIfNeeded()
            updateSuggestions(for: text)
        }
        .onChange(of: text) { _, newValue in
            if selectedEntry?.displayName.caseInsensitiveCompare(newValue.trimmingCharacters(in: .whitespacesAndNewlines)) != .orderedSame {
                selectedEntry = nil
            }
            updateSuggestions(for: newValue)
        }
        .sheet(isPresented: $isShowingDetail) {
            if let selectedEntry {
                DrugReferenceDetailView(entry: selectedEntry, sourceNote: catalog.sourceNote)
            }
        }
    }

    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(spacing: Spacing.xSmall) {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(AppColor.medicalBlue)
                Text("Offline reference suggestions")
                    .font(AppFont.badge)
                    .foregroundStyle(AppColor.secondaryInk)
                Spacer()
            }

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(suggestions) { suggestion in
                        DrugAutocompleteSuggestionRow(entry: suggestion) {
                            select(suggestion)
                        }

                        if suggestion.id != suggestions.last?.id {
                            Divider()
                                .background(AppColor.hairline.opacity(0.55))
                        }
                    }
                }
            }
            .frame(maxHeight: 260)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(AppColor.cream.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))

            Text("Reference only. Follow your doctor or pharmacist advice.")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
                .lineLimit(2)
        }
    }

    private func selectedReferencePreview(_ entry: DrugReferenceEntry) -> some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(AppColor.mintGreenDeep)

            VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                Text(entry.displayName)
                    .font(AppFont.badge)
                    .foregroundStyle(AppColor.ink)

                Text(referenceSubtitle(for: entry))
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                isShowingDetail = true
            } label: {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColor.medicalBlue)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open medicine reference details")
        }
        .padding(.leading, Spacing.small)
        .padding(.vertical, Spacing.xxSmall)
        .padding(.trailing, Spacing.xxSmall)
        .background(AppColor.mintGreen.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
    }

    private func select(_ entry: DrugReferenceEntry) {
        selectedEntry = entry
        text = entry.displayName
        suggestions = []
        onSelect?(entry)
    }

    private func updateSuggestions(for query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard selectedEntry == nil else {
            suggestions = []
            return
        }
        suggestions = DrugAutocompleteService.search(query: trimmed, in: catalog, limit: 8)
        #if DEBUG
        if trimmed.count >= 2 {
            print("[DrugAutocompleteField] query=\"\(trimmed)\" results=\(suggestions.count)")
        }
        #endif
    }

    private func syncSelectedEntryIfNeeded() {
        guard selectedEntry == nil else { return }
        let normalizedText = DrugAutocompleteService.normalize(text)
        guard !normalizedText.isEmpty else { return }
        selectedEntry = catalog.medicines.first { entry in
            entry.searchTerms.contains(normalizedText)
        }
    }
}

struct DrugAutocompleteSuggestionRow: View {
    let entry: DrugReferenceEntry
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: Spacing.small) {
                Image(systemName: "pills.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColor.medicalBlue)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                    Text(entry.displayName)
                        .font(AppFont.bodyStrong)
                        .foregroundStyle(AppColor.ink)
                        .lineLimit(1)

                    Text(referenceSubtitle(for: entry))
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.vertical, Spacing.xSmall)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct DrugReferenceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: DrugReferenceEntry
    let sourceNote: String

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        PillCardContainer(style: .highlighted) {
                            VStack(alignment: .leading, spacing: Spacing.small) {
                                Text(entry.displayName)
                                    .font(AppFont.title)
                                    .foregroundStyle(AppColor.ink)

                                Text(entry.genericName)
                                    .font(AppFont.body)
                                    .foregroundStyle(AppColor.secondaryInk)
                            }
                        }

                        detailSection("Brand names", values: entry.brandNames)
                        detailSection("Synonyms", values: entry.synonyms)
                        detailSection("Dosage forms", values: entry.dosageForms)
                        detailSection("Reference use", values: entry.commonUses)
                        detailSection("Safety notes", values: entry.safetyNotes)

                        Text(sourceNote)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                            .padding(.top, Spacing.small)
                    }
                    .padding(Spacing.medium)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func detailSection(_ title: String, values: [String]) -> some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(title)
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                if values.isEmpty {
                    Text("No reference details available.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                } else {
                    ForEach(values, id: \.self) { value in
                        Text(value)
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private func referenceSubtitle(for entry: DrugReferenceEntry) -> String {
    var parts: [String] = []
    if entry.genericName.caseInsensitiveCompare(entry.displayName) != .orderedSame {
        parts.append(entry.genericName)
    }
    if let brand = entry.brandNames.first {
        parts.append("Brand: \(brand)")
    }
    if let form = entry.dosageForms.first {
        parts.append(form.capitalized)
    }
    return parts.isEmpty ? "Reference only" : parts.joined(separator: " • ")
}
