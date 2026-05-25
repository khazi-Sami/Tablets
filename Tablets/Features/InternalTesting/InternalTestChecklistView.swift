#if DEBUG
import SwiftUI
import UIKit

struct InternalTestChecklistView: View {
    @State private var itemStates: [String: InternalChecklistItemState] = [:]
    @State private var showingResetConfirmation = false
    @State private var copiedReport = false

    private let storageKey = "internal_testflight_checklist_v1"
    private let sections = InternalChecklistData.sections

    var body: some View {
        MedicalBackgroundView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    header
                    progressCard
                    checklistSections
                    actionButtons
                }
                .padding(Spacing.medium)
                .padding(.bottom, 120)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Internal Test Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadStates)
        .confirmationDialog("Reset checklist?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Reset Checklist", role: .destructive) {
                itemStates = [:]
                saveStates()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears all checks, notes, and timestamps on this device.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("Internal TestFlight Checklist")
                .font(AppFont.display)
                .foregroundStyle(AppColor.ink)

            Text("Use this on real iPhones before sharing a small internal build. Notes and timestamps stay only on this device.")
                .font(AppFont.body)
                .foregroundStyle(AppColor.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var progressCard: some View {
        let progress = completionProgress

        return PillCardContainer(padding: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                        Text("\(progress.checked) of \(progress.total) checks complete")
                            .font(AppFont.sectionTitle)
                            .foregroundStyle(AppColor.ink)

                        Text("Generated report includes device, iOS, app build, checks, notes, and timestamps.")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    }

                    Spacer()

                    Text("\(Int(progress.percent * 100))%")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.medicalBlue)
                }

                ProgressView(value: progress.percent)
                    .tint(AppColor.medicalBlue)
            }
        }
    }

    private var checklistSections: some View {
        VStack(spacing: Spacing.medium) {
            ForEach(sections) { section in
                ChecklistSectionView(
                    section: section,
                    stateProvider: { itemStates[$0] ?? InternalChecklistItemState() },
                    checkedBinding: checkedBinding(for:),
                    noteBinding: noteBinding(for:)
                )
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: Spacing.small) {
            Button {
                copyReport()
            } label: {
                Label(copiedReport ? "Report Copied" : "Copy Report", systemImage: copiedReport ? "checkmark.circle.fill" : "doc.on.doc.fill")
                    .font(AppFont.button)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(role: .destructive) {
                showingResetConfirmation = true
            } label: {
                Label("Reset Checklist", systemImage: "arrow.counterclockwise")
                    .font(AppFont.button)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var completionProgress: (checked: Int, total: Int, percent: Double) {
        let total = sections.reduce(0) { $0 + $1.items.count }
        let checked = sections.flatMap(\.items).filter { itemStates[$0.id]?.isChecked == true }.count
        let percent = total == 0 ? 0 : Double(checked) / Double(total)
        return (checked, total, percent)
    }

    private func checkedBinding(for itemId: String) -> Binding<Bool> {
        Binding {
            itemStates[itemId]?.isChecked ?? false
        } set: { newValue in
            var state = itemStates[itemId] ?? InternalChecklistItemState()
            state.isChecked = newValue
            state.checkedAt = newValue ? Date() : nil
            itemStates[itemId] = state
            saveStates()
        }
    }

    private func noteBinding(for itemId: String) -> Binding<String> {
        Binding {
            itemStates[itemId]?.note ?? ""
        } set: { newValue in
            var state = itemStates[itemId] ?? InternalChecklistItemState()
            state.note = newValue
            itemStates[itemId] = state
            saveStates()
        }
    }

    private func loadStates() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: InternalChecklistItemState].self, from: data) else {
            itemStates = [:]
            return
        }
        itemStates = decoded
    }

    private func saveStates() {
        guard let data = try? JSONEncoder().encode(itemStates) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func copyReport() {
        UIPasteboard.general.string = buildReport()
        copiedReport = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedReport = false
        }
    }

    private func buildReport() -> String {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        let progress = completionProgress

        var lines: [String] = [
            "Tablets Internal TestFlight Checklist",
            "Generated: \(Date().formatted(date: .abbreviated, time: .shortened))",
            "Device: \(UIDevice.current.name)",
            "iOS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
            "App: \(appVersion) (\(buildNumber))",
            "Completed: \(progress.checked)/\(progress.total)",
            ""
        ]

        for section in sections {
            lines.append(section.title)
            for item in section.items {
                let state = itemStates[item.id] ?? InternalChecklistItemState()
                let marker = state.isChecked ? "[x]" : "[ ]"
                var itemLine = "\(marker) \(item.title)"
                if let checkedAt = state.checkedAt {
                    itemLine += " - \(checkedAt.formatted(date: .abbreviated, time: .shortened))"
                }
                lines.append(itemLine)

                let trimmedNote = state.note.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedNote.isEmpty {
                    lines.append("    Note: \(trimmedNote)")
                }
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}

private struct ChecklistSectionView: View {
    let section: InternalChecklistSection
    let stateProvider: (String) -> InternalChecklistItemState
    let checkedBinding: (String) -> Binding<Bool>
    let noteBinding: (String) -> Binding<String>

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(section.title)
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.ink)
                .padding(.horizontal, Spacing.xSmall)

            PillCardContainer(padding: Spacing.medium) {
                VStack(spacing: Spacing.small) {
                    ForEach(section.items) { item in
                        ChecklistItemRow(
                            item: item,
                            state: stateProvider(item.id),
                            isChecked: checkedBinding(item.id),
                            note: noteBinding(item.id)
                        )

                        if item.id != section.items.last?.id {
                            Divider()
                                .background(AppColor.tertiaryInk.opacity(0.25))
                        }
                    }
                }
            }
        }
    }
}

private struct ChecklistItemRow: View {
    let item: InternalChecklistItem
    let state: InternalChecklistItemState
    @Binding var isChecked: Bool
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Button {
                isChecked.toggle()
            } label: {
                HStack(alignment: .top, spacing: Spacing.small) {
                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isChecked ? AppColor.medicalBlue : AppColor.secondaryInk)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                        Text(item.title)
                            .font(AppFont.body.weight(.semibold))
                            .foregroundStyle(AppColor.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        if let checkedAt = state.checkedAt {
                            Text("Checked \(checkedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(AppFont.caption)
                                .foregroundStyle(AppColor.secondaryInk)
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

            TextField("Optional tester note", text: $note, axis: .vertical)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.ink)
                .lineLimit(1...3)
                .textFieldStyle(.plain)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, Spacing.xSmall)
                .background(ColorPalette.surface.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))
        }
        .padding(.vertical, Spacing.xxSmall)
    }
}

private struct InternalChecklistSection: Identifiable {
    let id: String
    let title: String
    let items: [InternalChecklistItem]
}

private struct InternalChecklistItem: Identifiable {
    let id: String
    let title: String
}

private struct InternalChecklistItemState: Codable {
    var isChecked = false
    var note = ""
    var checkedAt: Date?
}

private enum InternalChecklistData {
    static let sections: [InternalChecklistSection] = [
        InternalChecklistSection(
            id: "first_launch",
            title: "1. First launch",
            items: [
                item("fresh_install_opens", "Fresh install opens"),
                item("existing_install_opens", "Existing install opens or recovery screen appears"),
                item("empty_dashboard", "Empty dashboard does not crash")
            ]
        ),
        InternalChecklistSection(
            id: "medicine_reminders",
            title: "2. Medicine reminders",
            items: [
                item("add_test_tablet", "Add Test Tablet"),
                item("set_one_minute_reminder", "Set reminder 1 minute from now"),
                item("pending_notification_appears", "Pending notification appears"),
                item("notification_fires_sound", "Notification fires with sound"),
                item("notification_tap_safe", "Tapping notification opens app safely"),
                item("mark_taken_works", "Mark Taken works"),
                item("edit_time_reschedules", "Edit time cancels old notification and schedules new one"),
                item("delete_cancels_notification", "Delete medicine cancels notification")
            ]
        ),
        InternalChecklistSection(
            id: "voice_assistant",
            title: "3. Voice assistant",
            items: [
                item("tap_floating_button", "Tap floating button"),
                item("voice_open_medicines", "Say \"Open medicines\""),
                item("voice_bp_log", "Say \"My BP is 120 over 80\""),
                item("voice_next_medicine", "Say \"What medicine is next?\""),
                item("no_blank_audio", "No blank audio"),
                item("tts_loudspeaker", "TTS speaks from loudspeaker")
            ]
        ),
        InternalChecklistSection(
            id: "health_safety",
            title: "4. Health safety",
            items: [
                item("bp_190_110", "Log BP 190 over 110"),
                item("sugar_55", "Log sugar 55"),
                item("alert_appears", "Alert appears"),
                item("safe_wording", "Wording is safe and not diagnostic")
            ]
        ),
        InternalChecklistSection(
            id: "healthkit",
            title: "5. HealthKit",
            items: [
                item("healthkit_not_connected", "HealthKit not connected state works"),
                item("healthkit_denied", "Permission denied does not crash"),
                item("healthkit_connected", "Connected state shows steps/sleep if available")
            ]
        ),
        InternalChecklistSection(
            id: "widget",
            title: "6. Widget",
            items: [
                item("add_widget", "Add widget to Home Screen"),
                item("widget_loads", "Widget loads empty state or real data"),
                item("widget_tap_opens", "Tap widget opens app")
            ]
        ),
        InternalChecklistSection(
            id: "forms",
            title: "7. Forms",
            items: [
                item("add_autocomplete", "Add medicine autocomplete works"),
                item("edit_autocomplete", "Edit medicine autocomplete works"),
                item("keyboard_hides", "Keyboard hides on outside tap"),
                item("save_buttons_visible", "Save buttons visible")
            ]
        ),
        InternalChecklistSection(
            id: "pregnancy_womens_health",
            title: "8. Pregnancy/women health if enabled",
            items: [
                item("hydration_off_no_reminders", "Hydration OFF does not schedule reminders"),
                item("permission_denied_friendly", "Permission denied shows friendly error"),
                item("period_log_works", "Period log works")
            ]
        )
    ]

    private static func item(_ id: String, _ title: String) -> InternalChecklistItem {
        InternalChecklistItem(id: id, title: title)
    }
}

#Preview {
    NavigationStack {
        InternalTestChecklistView()
    }
}
#endif
