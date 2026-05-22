import SwiftData
import SwiftUI
import UIKit

struct AddMedicineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = AddMedicineViewModel()
    @FocusState private var focusedField: Field?
    @State private var showAdvancedOptions = false

    private let typeColumns = [
        GridItem(.flexible(), spacing: Spacing.small),
        GridItem(.flexible(), spacing: Spacing.small),
        GridItem(.flexible(), spacing: Spacing.small)
    ]

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ZStack(alignment: .bottom) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: Spacing.large) {
                            header

                            inputSection

                            scheduleSection

                            instructionSection

                            advancedSection

                            Color.clear.frame(height: 98)
                        }
                        .padding(Spacing.medium)
                    }

                    saveBar
                }
                .overlay {
                    if viewModel.didSave {
                        SuccessOverlay()
                            .transition(.scale(scale: 0.86).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.40, dampingFraction: 0.82), value: viewModel.didSave)
            }
            .navigationTitle("Add Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Unable to save", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var header: some View {
        PillCardContainer(style: .highlighted, padding: Spacing.large) {
            HStack(spacing: Spacing.medium) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppColor.medicalBlue)
                    .frame(width: 66, height: 66)
                    .background(AppColor.cream.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))

                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text("New medicine")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.ink)

                    Text("Add the basics now. You can open advanced options only if you need them.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var inputSection: some View {
        AddMedicineSection(title: "Medicine details") {
            VStack(spacing: Spacing.small) {
                ThemedTextField(
                    title: "Medicine name",
                    placeholder: "Example: Vitamin D",
                    text: $viewModel.name,
                    systemImage: "pills.fill"
                )
                .focused($focusedField, equals: .name)

                ThemedTextField(
                    title: "Dosage",
                    placeholder: "Example: 1000 IU",
                    text: $viewModel.dosage,
                    systemImage: "cross.circle.fill"
                )
                .focused($focusedField, equals: .dosage)
            }
        }
    }

    private var medicineTypeSection: some View {
        AddMedicineSection(title: "Medicine type") {
            LazyVGrid(columns: typeColumns, spacing: Spacing.small) {
                ForEach(MedicineType.allCases) { type in
                    MedicineTypeCard(
                        type: type,
                        isSelected: viewModel.medicineType == type
                    ) {
                        viewModel.medicineType = type
                    }
                }
            }
        }
    }

    private var instructionSection: some View {
        AddMedicineSection(title: "How to take it") {
            VStack(spacing: Spacing.medium) {
                PickerChipGroup(
                    selection: $viewModel.instruction,
                    values: MedicineInstruction.allCases
                ) { $0.title }
            }
        }
    }

    private var scheduleSection: some View {
        AddMedicineSection(title: "Reminder time") {
            VStack(spacing: Spacing.small) {
                ForEach(viewModel.reminderTimes.indices, id: \.self) { index in
                    ThemedDateRow(
                        title: index == 0 ? "Reminder time" : "Reminder \(index + 1)",
                        systemImage: "clock.fill"
                    ) {
                        HStack(spacing: Spacing.xSmall) {
                            DatePicker("", selection: $viewModel.reminderTimes[index], displayedComponents: .hourAndMinute)
                                .labelsHidden()

                            if viewModel.reminderTimes.count > 1 {
                                Button {
                                    viewModel.removeReminderTime(at: IndexSet(integer: index))
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(AppColor.softRed)
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Button {
                    viewModel.addReminderTime()
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

    private var advancedSection: some View {
        DisclosureGroup(isExpanded: $showAdvancedOptions) {
            VStack(spacing: Spacing.large) {
                medicineTypeSection

                AddMedicineSection(title: "Frequency") {
                    PickerChipGroup(
                        selection: $viewModel.frequencyType,
                        values: MedicineFrequencyType.allCases
                    ) { $0.title }
                }

                AddMedicineSection(title: "Dates") {
                    VStack(spacing: Spacing.small) {
                        ThemedDateRow(
                            title: "Start date",
                            systemImage: "calendar"
                        ) {
                            DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                                .labelsHidden()
                        }

                        Toggle(isOn: $viewModel.hasEndDate.animation(.spring(response: 0.32, dampingFraction: 0.84))) {
                            Label("Set end date", systemImage: "calendar.badge.clock")
                                .font(AppFont.bodyStrong)
                                .foregroundStyle(AppColor.ink)
                        }
                        .tint(AppColor.medicalBlue)
                        .padding(Spacing.medium)
                        .background(AppColor.cream.opacity(0.82))
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))

                        if viewModel.hasEndDate {
                            ThemedDateRow(
                                title: "End date",
                                systemImage: "calendar.badge.checkmark"
                            ) {
                                DatePicker("", selection: $viewModel.endDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }

                stockSection
                notesSection
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

    private var stockSection: some View {
        AddMedicineSection(title: "Stock alerts") {
            VStack(spacing: Spacing.small) {
                StepperCard(
                    title: "Stock count",
                    subtitle: "How many doses you have now",
                    value: $viewModel.stockCount,
                    range: 0...999,
                    systemImage: "shippingbox.fill"
                )

                StepperCard(
                    title: "Low stock reminder",
                    subtitle: "Alert when stock reaches this count",
                    value: $viewModel.lowStockAlertCount,
                    range: 0...999,
                    systemImage: "bell.badge.fill"
                )
            }
        }
    }

    private var notesSection: some View {
        AddMedicineSection(title: "Notes") {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Label("Care notes", systemImage: "note.text")
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.secondaryInk)

                TextField("Optional notes", text: $viewModel.notes, axis: .vertical)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.ink)
                    .lineLimit(4...7)
                    .padding(Spacing.medium)
                    .background(AppColor.cream.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
                    .focused($focusedField, equals: .notes)
            }
        }
    }

    private var saveBar: some View {
        VStack(spacing: Spacing.xSmall) {
            if let notificationMessage = viewModel.notificationMessage {
                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "bell.slash.fill")
                    Text(notificationMessage)
                        .lineLimit(2)
                    Button("Settings") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                    .font(AppFont.badge)
                }
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
                .padding(.horizontal, Spacing.small)
            }

            CapsuleButton("Save Medicine", systemImage: "checkmark.circle.fill") {
                focusedField = nil

                if let medicine = viewModel.saveMedicine(modelContext: modelContext) {
                    Task {
                        let scheduled = await MedicineNotificationScheduler().scheduleNotifications(for: medicine)
                        if !scheduled {
                            viewModel.notificationMessage = "Notifications are off. Turn them on to receive medicine reminders."
                            return
                        }
                        let engine = AdaptiveReminderEngine(modelContext: modelContext)
                        let scheduler = AdaptiveReminderScheduler(engine: engine, modelContext: modelContext)
                        _ = await scheduler.applyAdaptiveShifts()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
                            dismiss()
                        }
                    }
                }
            }
            .disabled(!viewModel.canSave)
            .opacity(viewModel.canSave ? 1 : 0.56)
        }
        .padding(Spacing.medium)
        .background(
            LinearGradient(
                colors: [
                    AppColor.warmWhite.opacity(0.08),
                    AppColor.warmWhite.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

private enum Field {
    case name
    case dosage
    case notes
}

private struct AddMedicineSection<Content: View>: View {
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

            PillCardContainer {
                content
            }
        }
    }
}

private struct ThemedTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Label(title, systemImage: systemImage)
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.secondaryInk)

            TextField(placeholder, text: $text)
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.ink)
                .textInputAutocapitalization(.words)
                .padding(Spacing.medium)
                .background(AppColor.cream.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
        }
    }
}

private struct MedicineTypeCard: View {
    let type: MedicineType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xSmall) {
                AnimatedMedicineVisualization(type: type, isActive: isSelected, size: 58)
                    .frame(height: 64)

                Text(type.title)
                    .font(AppFont.badge)
                    .foregroundStyle(isSelected ? AppColor.medicalBlueDeep : AppColor.secondaryInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 124)
            .padding(Spacing.xSmall)
            .background(isSelected ? AppColor.medicalBlue.opacity(0.12) : AppColor.cream.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                    .stroke(isSelected ? AppColor.medicalBlue.opacity(0.55) : AppColor.hairline.opacity(0.44), lineWidth: isSelected ? 1.4 : 1)
            )
            .shadow(color: isSelected ? AppColor.medicalBlue.opacity(0.24) : .clear, radius: 14, x: 0, y: 6)
            .scaleEffect(isSelected ? 1.04 : 1)
            .animation(.spring(response: 0.32, dampingFraction: 0.76), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(type.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct MedicineTypeShape: View {
    let type: MedicineType
    let isSelected: Bool

    private var color: Color {
        isSelected ? AppColor.medicalBlue : AppColor.mintGreenDeep
    }

    var body: some View {
        ZStack {
            switch type {
            case .tablet:
                Circle()
                    .fill(color.opacity(0.18))
                    .overlay(Circle().stroke(color.opacity(0.52), lineWidth: 2))
                    .overlay(Rectangle().fill(color.opacity(0.40)).frame(width: 2).rotationEffect(.degrees(35)))
                    .frame(width: 46, height: 46)
            case .capsule:
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.82), AppColor.lavender.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(Rectangle().fill(Color.white.opacity(0.7)).frame(width: 2))
                    .frame(width: 68, height: 30)
                    .rotationEffect(.degrees(-18))
            case .syrup:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.16))
                    .frame(width: 38, height: 50)
                    .overlay(
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.52)).frame(width: 20, height: 7)
                            RoundedRectangle(cornerRadius: 5).fill(color.opacity(0.36)).frame(width: 24, height: 18)
                        }
                    )
            case .injection:
                Image(systemName: "syringe.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(color)
                    .rotationEffect(.degrees(-35))
            case .drops:
                Image(systemName: "drop.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(color)
            case .powder:
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 50)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(color)
                    )
            }
        }
    }
}

private struct PickerChipGroup<Value: Identifiable & Hashable>: View {
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
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ThemedDateRow<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content

    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(AppFont.bodyStrong)
                .foregroundStyle(AppColor.ink)

            Spacer()

            content
                .tint(AppColor.medicalBlue)
        }
        .padding(Spacing.medium)
        .frame(minHeight: 62)
        .background(AppColor.cream.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
    }
}

private struct StepperCard: View {
    let title: String
    let subtitle: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let systemImage: String

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColor.medicalBlue)
                .frame(width: 46, height: 46)
                .background(AppColor.medicalBlue.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                Text(title)
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.ink)

                Text(subtitle)
                    .font(AppFont.badge)
                    .foregroundStyle(AppColor.secondaryInk)
            }

            Spacer()

            Stepper(value: $value, in: range) {
                Text("\(value)")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.medicalBlueDeep)
                    .frame(minWidth: 34, alignment: .trailing)
            }
            .labelsHidden()
        }
        .padding(Spacing.medium)
        .frame(minHeight: 76)
        .background(AppColor.cream.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
    }
}

private struct SuccessOverlay: View {
    var body: some View {
        VStack(spacing: Spacing.medium) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 74, weight: .bold))
                .foregroundStyle(AppColor.mintGreenDeep)

            Text("Medicine saved")
                .font(AppFont.title)
                .foregroundStyle(AppColor.ink)
        }
        .padding(Spacing.xLarge)
        .background(AppColor.cream.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
        .appShadow(AppShadow.button)
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat) {
        self.spacing = spacing
    }

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
                element.subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(element.size)
                )
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

#Preview {
    AddMedicineView()
        .modelContainer(SampleData.previewContainer)
}
