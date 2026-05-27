import SwiftData
import SwiftUI
import UIKit
import WidgetKit

struct EditMedicineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let medicine: Medicine

    @State private var name: String
    @State private var dosage: String
    @State private var medicineType: MedicineType
    @State private var instruction: MedicineInstruction
    @State private var frequencyType: MedicineFrequencyType
    @State private var reminderTimes: [Date]
    @State private var stockCount: Int
    @State private var lowStockAlertCount: Int
    @State private var notes: String
    @State private var isActive: Bool
    @State private var errorMessage: String?
    @State private var notificationMessage: String?
    @State private var showAdvancedOptions = false
    @State private var selectedDrugReference: DrugReferenceEntry?

    init(medicine: Medicine) {
        self.medicine = medicine
        _name = State(initialValue: medicine.name)
        _dosage = State(initialValue: medicine.dosage)
        _medicineType = State(initialValue: medicine.medicineType)
        _instruction = State(initialValue: medicine.instruction)
        _frequencyType = State(initialValue: medicine.frequencyType)
        _reminderTimes = State(initialValue: medicine.times.isEmpty ? [Date()] : medicine.times.sorted())
        _stockCount = State(initialValue: medicine.stockCount)
        _lowStockAlertCount = State(initialValue: medicine.lowStockAlertCount)
        _notes = State(initialValue: medicine.notes)
        _isActive = State(initialValue: medicine.isActive)
    }

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        detailsSection
                        reminderSection
                        howToTakeSection
                        statusSection
                        advancedSection
                        Color.clear.frame(height: 96)
                    }
                    .padding(Spacing.medium)
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    saveBar
                }
                .dismissKeyboardOnTap()
            }
            .navigationTitle("Edit Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Unable to save", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var detailsSection: some View {
        EditSection(title: "Medicine details") {
            VStack(spacing: Spacing.small) {
                DrugAutocompleteField(
                    title: "Medicine name",
                    placeholder: "Medicine name",
                    text: $name,
                    selectedEntry: $selectedDrugReference
                )
                EditTextField(title: "Dosage", text: $dosage, systemImage: "cross.circle.fill")
            }
        }
    }

    private var reminderSection: some View {
        EditSection(title: "Reminder times") {
            VStack(spacing: Spacing.small) {
                ForEach(reminderTimes.indices, id: \.self) { index in
                    HStack {
                        Label(index == 0 ? "Reminder time" : "Reminder \(index + 1)", systemImage: "clock.fill")
                            .font(AppFont.bodyStrong)
                            .foregroundStyle(AppColor.ink)
                        Spacer()
                        DatePicker("", selection: $reminderTimes[index], displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(AppColor.medicalBlue)
                        if reminderTimes.count > 1 {
                            Button {
                                reminderTimes.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(AppColor.softRed)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Spacing.medium)
                    .background(AppColor.cream.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
                }

                Button {
                    let next = Calendar.current.date(byAdding: .hour, value: 1, to: reminderTimes.last ?? Date()) ?? Date()
                    reminderTimes.append(next)
                } label: {
                    Label("Add another time", systemImage: "plus.circle.fill")
                        .font(AppFont.bodyStrong)
                        .foregroundStyle(AppColor.medicalBlueDeep)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(AppColor.medicalBlue.opacity(0.10))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var howToTakeSection: some View {
        EditSection(title: "How to take it") {
            VStack(spacing: Spacing.medium) {
                EditPickerGroup(selection: $instruction, values: MedicineInstruction.allCases) { $0.title }
                EditPickerGroup(selection: $frequencyType, values: MedicineFrequencyType.allCases) { $0.title }
            }
        }
    }

    private var statusSection: some View {
        EditSection(title: "Status") {
            Toggle(isOn: $isActive) {
                Label(isActive ? "Active medicine" : "Inactive medicine", systemImage: isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.ink)
            }
            .tint(AppColor.mintGreenDeep)
            .padding(Spacing.medium)
            .background(AppColor.cream.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
        }
    }

    private var advancedSection: some View {
        DisclosureGroup(isExpanded: $showAdvancedOptions) {
            VStack(spacing: Spacing.medium) {
                EditSection(title: "Medicine type") {
                    EditPickerGroup(selection: $medicineType, values: MedicineType.allCases) { $0.title }
                }

                EditSection(title: "Stock") {
                    VStack(spacing: Spacing.small) {
                        EditStepperRow(title: "Stock count", value: $stockCount, range: 0...999)
                        EditStepperRow(title: "Low stock alert", value: $lowStockAlertCount, range: 0...999)
                    }
                }

                EditSection(title: "Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .font(AppFont.body)
                        .lineLimit(3...6)
                        .padding(Spacing.medium)
                        .background(AppColor.cream.opacity(0.82))
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
                }
            }
            .padding(.top, Spacing.small)
        } label: {
            Label("Advanced options", systemImage: "slider.horizontal.3")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.ink)
        }
        .padding(Spacing.medium)
        .background(AppColor.warmWhite.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
    }

    private var saveBar: some View {
        VStack(spacing: Spacing.xSmall) {
            if let notificationMessage {
                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "bell.slash.fill")
                    Text(notificationMessage)
                    Button("Settings") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                }
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
            }

            CapsuleButton("Save Changes", systemImage: "checkmark.circle.fill") {
                save()
            }
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.56)
        }
        .padding(Spacing.medium)
        .background(AppColor.warmWhite.opacity(0.94).ignoresSafeArea(edges: .bottom))
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        guard canSave else {
            errorMessage = "Please enter medicine name and dosage."
            return
        }

        medicine.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        medicine.dosage = dosage.trimmingCharacters(in: .whitespacesAndNewlines)
        medicine.medicineType = medicineType
        medicine.instruction = instruction
        medicine.frequencyType = frequencyType
        medicine.times = sanitizedTimes()
        medicine.stockCount = max(0, stockCount)
        medicine.lowStockAlertCount = max(0, lowStockAlertCount)
        medicine.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        medicine.isActive = isActive

        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        Task {
            let scheduled = await MedicineNotificationScheduler().rescheduleNotifications(for: medicine)
            await cleanupOrphanNotifications()
            WidgetMedicineSnapshotWriter.writeAndReload(context: modelContext)
            if !scheduled {
                notificationMessage = "Notifications are off. Turn them on to receive medicine reminders."
                return
            }
            dismiss()
        }
    }

    private func cleanupOrphanNotifications() async {
        do {
            let activeIDs = try MedicineRepository(modelContext: modelContext)
                .fetchActiveMedicines()
                .map { $0.id.uuidString }
            _ = await MedicineNotificationScheduler().cleanupOrphanedMedicineNotifications(activeMedicineIDs: Set(activeIDs))
        } catch {
            #if DEBUG
            print("[EditMedicineView] Orphan notification cleanup failed: \(error)")
            #endif
        }
    }

    private func sanitizedTimes() -> [Date] {
        reminderTimes
            .sorted()
            .reduce(into: [Date]()) { result, date in
                let key = AdaptiveReminderTimeKey.key(from: date)
                if result.contains(where: { AdaptiveReminderTimeKey.key(from: $0) == key }) == false {
                    result.append(date)
                }
            }
    }
}

private struct EditSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(title)
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.ink)
            PillCardContainer { content }
        }
    }
}

private struct EditTextField: View {
    let title: String
    @Binding var text: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Label(title, systemImage: systemImage)
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.secondaryInk)
            TextField(title, text: $text)
                .font(AppFont.bodyStrong)
                .padding(Spacing.medium)
                .background(AppColor.cream.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
        }
    }
}

private struct EditPickerGroup<Value: Identifiable & Hashable>: View {
    @Binding var selection: Value
    let values: [Value]
    let title: (Value) -> String

    var body: some View {
        FlowLayout(spacing: Spacing.xSmall) {
            ForEach(values) { value in
                Button {
                    selection = value
                } label: {
                    Text(title(value))
                        .font(AppFont.badge)
                        .foregroundStyle(selection == value ? .white : AppColor.medicalBlueDeep)
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, Spacing.xSmall)
                        .background(selection == value ? AppColor.medicalBlue : AppColor.medicalBlue.opacity(0.10))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct EditStepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        Stepper(value: $value, in: range) {
            HStack {
                Text(title)
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.ink)
                Spacer()
                Text("\(value)")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.medicalBlueDeep)
            }
        }
        .padding(Spacing.medium)
        .background(AppColor.cream.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(proposal: proposal, subviews: subviews)
        let height = rows.reduce(CGFloat.zero) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * spacing
        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY

        for row in rows(proposal: ProposedViewSize(width: bounds.width, height: proposal.height), subviews: subviews) {
            var x = bounds.minX
            for element in row.elements {
                element.subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(element.size))
                x += element.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func rows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var current = Row()

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if current.width + size.width > maxWidth, !current.elements.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.elements.append(Row.Element(subview: subview, size: size))
            current.width += size.width + (current.elements.count > 1 ? spacing : 0)
            current.height = max(current.height, size.height)
        }

        if !current.elements.isEmpty {
            rows.append(current)
        }

        return rows
    }

    private struct Row {
        struct Element {
            let subview: LayoutSubview
            let size: CGSize
        }

        var elements: [Element] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }
}
