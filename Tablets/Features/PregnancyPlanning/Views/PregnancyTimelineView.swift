import SwiftData
import SwiftUI

struct PregnancyTimelineView: View {
    @Query(sort: \PregnancySymptomLog.loggedAt, order: .reverse) private var symptoms: [PregnancySymptomLog]
    @Query(sort: \PregnancyWeightLog.loggedAt, order: .reverse) private var weights: [PregnancyWeightLog]
    @Query(sort: \BabyKickLog.sessionStartedAt, order: .reverse) private var kicks: [BabyKickLog]
    @Query(sort: \PregnancyAppointment.scheduledAt, order: .reverse) private var appointments: [PregnancyAppointment]
    @Query(sort: \PregnancyMoodLog.loggedAt, order: .reverse) private var moods: [PregnancyMoodLog]
    @Query(sort: \PregnancyNote.loggedAt, order: .reverse) private var notes: [PregnancyNote]
    @Query(sort: \ContractionLog.startedAt, order: .reverse) private var contractions: [ContractionLog]
    let profile: PregnancyProfile
    @State private var filter = "All"

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        filterRow
                        let items = timelineItems
                        if items.isEmpty {
                            PregnancyCard { Text("Your journey is just beginning. Start logging to build your timeline.") }
                        } else {
                            ForEach(items) { item in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle().fill(item.color).frame(width: 14, height: 14).padding(.top, 18)
                                    PregnancyCard {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title).font(PregnancyTheme.bodyFont.weight(.semibold))
                                            Text(item.subtitle).font(PregnancyTheme.captionFont).foregroundStyle(AppColor.secondaryInk)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(PregnancyTheme.pagePadding)
                }
            }
            .navigationTitle("Pregnancy Timeline")
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(["All", "Symptoms", "Weight", "Kicks", "Appointments", "Milestones"], id: \.self) { value in
                    PregnancyChip(title: value, isSelected: filter == value) { filter = value }
                }
            }
        }
    }

    private var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []
        if filter == "All" || filter == "Symptoms" {
            items += symptoms.filter { $0.pregnancyProfileId == profile.id }.map { TimelineItem(date: $0.loggedAt, title: "Symptom Log", subtitle: $0.symptoms.joined(separator: ", "), color: PregnancyTheme.deepRose) }
        }
        if filter == "All" || filter == "Weight" {
            items += weights.filter { $0.pregnancyProfileId == profile.id }.map {
                TimelineItem(date: $0.loggedAt, title: "Weight Log", subtitle: "\(String(format: "%.1f", $0.weight)) \($0.unit.rawValue) · Week \($0.weekNumber)", color: .green)
            }
        }
        if filter == "All" || filter == "Kicks" {
            items += kicks.filter { $0.pregnancyProfileId == profile.id }.map { TimelineItem(date: $0.sessionStartedAt, title: "Kick Session", subtitle: "\($0.kickCount) kicks · \($0.durationMinutes ?? 0) min", color: PregnancyTheme.lilac) }
        }
        if filter == "All" || filter == "Appointments" {
            items += appointments.filter { $0.pregnancyProfileId == profile.id }.map { TimelineItem(date: $0.scheduledAt, title: "Appointment", subtitle: $0.title, color: .blue) }
        }
        if filter == "All" {
            items += moods.filter { $0.pregnancyProfileId == profile.id }.map { TimelineItem(date: $0.loggedAt, title: "Mood", subtitle: "\($0.mood.rawValue) · Energy \($0.energyLevel)/5", color: PregnancyTheme.softGold) }
            items += notes.filter { $0.pregnancyProfileId == profile.id }.map { TimelineItem(date: $0.loggedAt, title: "Note", subtitle: $0.text, color: .white) }
            items += contractions.filter { $0.pregnancyProfileId == profile.id }.map { TimelineItem(date: $0.startedAt, title: "Contraction", subtitle: "\($0.durationSeconds ?? 0)s · \($0.intensity.rawValue)", color: .red.opacity(0.6)) }
        }
        return items.sorted { $0.date > $1.date }
    }
}

private struct TimelineItem: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let subtitle: String
    let color: Color
}
