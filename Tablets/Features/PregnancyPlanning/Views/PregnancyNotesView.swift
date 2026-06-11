import SwiftData
import SwiftUI

struct PregnancyNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PregnancyNote.loggedAt, order: .reverse) private var allNotes: [PregnancyNote]
    let profile: PregnancyProfile
    @State private var text = ""
    @State private var category: NoteCategory = .general

    private var notes: [PregnancyNote] {
        allNotes.filter { $0.pregnancyProfileId == profile.id }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: PregnancyTheme.itemSpacing) {
                        header
                        addNoteCard
                        notesContent
                    }
                    .padding(PregnancyTheme.pagePadding)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Pregnancy Notes")
            .navigationBarTitleDisplayMode(.inline)
        }
        .dismissKeyboardOnTap()
    }

    private var header: some View {
        PregnancyCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: PregnancyTheme.iconNotes)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(PregnancyTheme.deepRose, in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text("Quick notes for your journey")
                        .font(PregnancyTheme.headingFont)
                        .foregroundStyle(AppColor.ink)
                    Text("Save questions, reminders, feelings, or small details you want to discuss later.")
                        .font(PregnancyTheme.captionFont)
                        .foregroundStyle(AppColor.secondaryInk)
                }
            }
        }
    }

    private var addNoteCard: some View {
        PregnancyCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Add a note", systemImage: "square.and.pencil")
                    .font(PregnancyTheme.headingFont)
                    .foregroundStyle(PregnancyTheme.deepRose)

                TextField("Ask doctor about iron levels...", text: $text, axis: .vertical)
                    .font(PregnancyTheme.bodyFont)
                    .lineLimit(3...6)
                    .padding(14)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: PregnancyTheme.buttonRadius, style: .continuous))

                PregnancyFlowLayout {
                    ForEach(NoteCategory.allCases) { item in
                        PregnancyChip(title: item.rawValue, isSelected: category == item) {
                            category = item
                        }
                    }
                }

                Button(action: save) {
                    Label(category == .forDoctor ? "Save for Doctor" : "Save Note", systemImage: "checkmark.circle.fill")
                        .font(PregnancyTheme.bodyFont.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(canSave ? PregnancyTheme.deepRose : AppColor.secondaryInk.opacity(0.35), in: RoundedRectangle(cornerRadius: PregnancyTheme.buttonRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
        }
    }

    @ViewBuilder
    private var notesContent: some View {
        if notes.isEmpty {
            PregnancyCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No notes yet")
                        .font(PregnancyTheme.headingFont)
                        .foregroundStyle(AppColor.ink)
                    Text("Add a quick note when something comes to mind. BanyAI will keep it here for you.")
                        .font(PregnancyTheme.bodyFont)
                        .foregroundStyle(AppColor.secondaryInk)
                }
            }
        } else {
            ForEach(NoteCategory.allCases) { item in
                let group = notes.filter { $0.category == item }
                if !group.isEmpty {
                    notesGroup(title: item.rawValue, notes: group)
                }
            }
        }
    }

    private func notesGroup(title: String, notes: [PregnancyNote]) -> some View {
        PregnancyCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(PregnancyTheme.headingFont)
                    .foregroundStyle(PregnancyTheme.deepRose)

                ForEach(notes) { note in
                    noteRow(note)
                }
            }
        }
    }

    private func noteRow(_ note: PregnancyNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: note.category == .forDoctor ? "stethoscope" : PregnancyTheme.iconNotes)
                    .foregroundStyle(PregnancyTheme.deepRose)
                    .frame(width: 32, height: 32)
                    .background(PregnancyTheme.blushPink.opacity(0.65), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(note.text)
                        .font(PregnancyTheme.bodyFont)
                        .foregroundStyle(AppColor.ink)
                    Text("Week \(note.weekNumber) · \(note.loggedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(PregnancyTheme.captionFont)
                        .foregroundStyle(AppColor.secondaryInk)
                }

                Spacer()

                Button(role: .destructive) {
                    delete(note)
                } label: {
                    Image(systemName: "trash")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(AppColor.secondaryInk)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
            }

            Divider().opacity(0.45)
        }
    }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(PregnancyNote(pregnancyProfileId: profile.id, text: trimmed, category: category, weekNumber: profile.currentWeek))
        try? modelContext.save()
        text = ""
        category = .general
    }

    private func delete(_ note: PregnancyNote) {
        modelContext.delete(note)
        try? modelContext.save()
    }
}
