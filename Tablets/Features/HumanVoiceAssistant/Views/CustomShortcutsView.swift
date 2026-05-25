import SwiftData
import SwiftUI

struct CustomShortcutsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomVoiceShortcut.createdAt, order: .reverse) private var shortcuts: [CustomVoiceShortcut]

    @State private var triggerPhrase = ""
    @State private var responseText = ""
    @State private var actionType = "speak"
    @State private var navigationTarget = "openDashboard"
    @State private var validationMessage = ""
    @State private var isShowingConflictWarning = false

    private let navigationTargets = [
        "openDashboard", "openMedicines", "openAddMedicine", "openHealthTracking",
        "openSugarTracking", "openSugarLog", "openBPTracking", "openBPLog",
        "openPeriods", "openAddPeriodLog", "openCyclePrediction", "openDoctorVisit",
        "openPrescriptionScanner", "openFamilyCare", "openProfile", "openHealthMemory",
        "openMedicineReminder", "openDailyCheckIn", "openSettings", "openHealthJourney"
    ]

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.large) {
                        shortcutsList
                        addShortcutForm
                        if shortcuts.isEmpty {
                            starterShortcuts
                        }
                    }
                    .padding(Spacing.medium)
                    .padding(.bottom, 80)
                }
                .scrollDismissesKeyboard(.interactively)
                .dismissKeyboardOnTap()
            }
            .navigationTitle("My Voice Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var shortcutsList: some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("My Shortcuts")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                if shortcuts.isEmpty {
                    Text("No shortcuts yet. Add one below.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                } else {
                    ForEach(shortcuts) { shortcut in
                        CustomShortcutRow(shortcut: shortcut) {
                            modelContext.delete(shortcut)
                            try? modelContext.save()
                        }
                    }
                }
            }
        }
    }

    private var addShortcutForm: some View {
        PillCardContainer(style: .highlighted) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Add New Shortcut")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                shortcutGuidance

                shortcutTextField("When I say...", text: $triggerPhrase)
                shortcutTextField("Assistant should say...", text: $responseText, axis: .vertical)

                Picker("Action type", selection: $actionType) {
                    Text("Just speak response").tag("speak")
                    Text("Also navigate to...").tag("navigate")
                }
                .pickerStyle(.segmented)

                if actionType == "navigate" {
                    Picker("Navigation target", selection: $navigationTarget) {
                        ForEach(navigationTargets, id: \.self) { target in
                            Text(target.replacingOccurrences(of: "open", with: ""))
                                .tag(target)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(AppFont.body)
                }

                if !validationMessage.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text(validationMessage)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.softRed)

                        if isShowingConflictWarning {
                            HStack(spacing: Spacing.small) {
                                Button("Edit phrase") {
                                    isShowingConflictWarning = false
                                    validationMessage = ""
                                }
                                .font(AppFont.badge)
                                .foregroundStyle(AppColor.medicalBlueDeep)

                                Button("Save anyway") {
                                    saveShortcut(allowConflict: true)
                                }
                                .font(AppFont.badge)
                                .foregroundStyle(AppColor.softRed)
                            }
                        }
                    }
                }

                CapsuleButton("Save Shortcut", systemImage: "plus.circle.fill") {
                    saveShortcut()
                }
            }
        }
    }

    private var shortcutGuidance: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("Use personal phrases like “Good morning” or “Start my routine”. Avoid broad health phrases like “BP” or “sugar”.")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)

            HStack(alignment: .top, spacing: Spacing.small) {
                shortcutExampleColumn(title: "Good", examples: ["Good morning", "Start my routine", "Open my favorite page"], color: AppColor.mintGreenDeep)
                shortcutExampleColumn(title: "Avoid", examples: ["BP", "Sugar", "Medicine", "How is my health"], color: AppColor.softRed)
            }
        }
        .padding(Spacing.small)
        .background(.white.opacity(0.54), in: RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
    }

    private func shortcutExampleColumn(title: String, examples: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
            Text(title)
                .font(AppFont.badge)
                .foregroundStyle(color)
            ForEach(examples, id: \.self) { example in
                Text(example)
                    .font(AppFont.badge)
                    .foregroundStyle(AppColor.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var starterShortcuts: some View {
        PillCardContainer(style: .lavender) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text("Starter Shortcuts")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.ink)

                ForEach(starterTemplates, id: \.trigger) { template in
                    Button {
                        triggerPhrase = template.trigger
                        responseText = template.response
                        actionType = "speak"
                        validationMessage = ""
                    } label: {
                        VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                            Text(template.trigger)
                                .font(AppFont.bodyStrong)
                                .foregroundStyle(AppColor.ink)
                            Text(template.response.isEmpty ? "Add your own response" : template.response)
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.secondaryInk)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Spacing.small)
                        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func shortcutTextField(_ title: String, text: Binding<String>, axis: Axis = .horizontal) -> some View {
        TextField(title, text: text, axis: axis)
            .font(AppFont.body)
            .lineLimit(axis == .vertical ? 3...5 : 1...1)
            .padding(Spacing.medium)
            .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))
    }

    private func saveShortcut(allowConflict: Bool = false) {
        let trigger = triggerPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        var response = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
        isShowingConflictWarning = false

        guard shortcuts.count < 50 else {
            validationMessage = "You can save up to 50 shortcuts."
            return
        }
        guard !trigger.isEmpty else {
            validationMessage = "Please enter what you want to say."
            return
        }
        guard !response.isEmpty else {
            validationMessage = "Please enter what the assistant should say."
            return
        }
        guard response.count <= 300 else {
            validationMessage = "Response is too long. Keep it under 300 characters."
            return
        }
        guard !shortcuts.contains(where: { normalized($0.triggerPhrase) == normalized(trigger) }) else {
            validationMessage = "That trigger phrase already exists."
            return
        }
        guard !CustomShortcutSafety.isReservedTrigger(trigger) else {
            validationMessage = CustomShortcutSafety.reservedPhraseMessage
            return
        }
        if actionType == "navigate", !CustomShortcutSafety.safeNavigationIntentIds.contains(navigationTarget) {
            validationMessage = "This shortcut can only navigate to safe app sections."
            return
        }
        if !allowConflict, CustomShortcutSafety.conflictsWithBuiltInCommand(trigger) {
            validationMessage = CustomShortcutSafety.conflictWarningMessage
            isShowingConflictWarning = true
            return
        }

        response = safeCustomResponse(response)
        let shortcut = CustomVoiceShortcut(
            triggerPhrase: trigger,
            responseText: response,
            actionType: actionType,
            navigationTarget: actionType == "navigate" ? navigationTarget : nil
        )
        modelContext.insert(shortcut)
        try? modelContext.save()

        triggerPhrase = ""
        responseText = ""
        actionType = "speak"
        navigationTarget = "openDashboard"
        validationMessage = ""
        isShowingConflictWarning = false
        HapticsManager.notification(.success)
    }

    private func normalized(_ text: String) -> String {
        text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func safeCustomResponse(_ text: String) -> String {
        let unsafePhrases = [
            "you are fine",
            "no need to worry",
            "you are healthy",
            "this is normal",
            "everything is okay"
        ]
        let lowercased = text.lowercased()
        if unsafePhrases.contains(where: { lowercased.contains($0) }) {
            return "Based on your logs, things look stable. Please consult your doctor for medical advice."
        }
        return text
    }

    private var starterTemplates: [(trigger: String, response: String)] {
        [
            ("Good morning", "Good morning! Your first tablet of the day is due. Wishing you a steady day."),
            ("How am I today", "Based on your recent logs, you have been logging regularly. Keep it up."),
            ("Reminder check", "Checking your pending medicines now."),
            ("My name is", "Hello! I remember you. How can I help with your health today?"),
            ("Emergency", "Please call emergency services or your doctor immediately if you feel unwell."),
            ("Daily prayer", "")
        ]
    }
}

private struct CustomShortcutRow: View {
    @Bindable var shortcut: CustomVoiceShortcut
    let deleteAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                    Text(shortcut.triggerPhrase)
                        .font(AppFont.bodyStrong)
                        .foregroundStyle(AppColor.ink)
                    Text(shortcut.responseText)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                        .lineLimit(2)
                    Text("Triggered \(shortcut.triggerCount) times")
                        .font(AppFont.badge)
                        .foregroundStyle(AppColor.tertiaryInk)
                }

                Spacer()

                Button(role: .destructive, action: deleteAction) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                .buttonStyle(.plain)
            }

            Toggle("Enabled", isOn: $shortcut.isEnabled)
                .font(AppFont.caption)
                .tint(AppColor.medicalBlue)
        }
        .padding(Spacing.small)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
    }
}

#Preview {
    CustomShortcutsView()
        .modelContainer(SampleData.previewContainer)
}
