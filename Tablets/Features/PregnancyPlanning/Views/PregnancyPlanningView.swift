import SwiftData
import SwiftUI

struct PregnancyPlanningView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PregnancyProfile.createdAt, order: .reverse) private var profiles: [PregnancyProfile]
    @State private var destination: PregnancyPlanningDestination?
    @State private var setupCompletedProfile: PregnancyProfile?

    private var activeProfile: PregnancyProfile? {
        setupCompletedProfile ?? profiles.first(where: \.isActive)
    }

    var body: some View {
        Group {
            if let activeProfile {
                PregnancyDashboardView(profile: activeProfile, destination: $destination)
            } else {
                PregnancySetupView { profile in
                    setupCompletedProfile = profile
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .voiceOpenPregnancySymptomLog)) { _ in destination = .symptoms }
        .onReceive(NotificationCenter.default.publisher(for: .voiceOpenPregnancyWeightLog)) { _ in destination = .weight }
        .onReceive(NotificationCenter.default.publisher(for: .voiceOpenBabyKickCounter)) { _ in destination = .kicks }
        .onReceive(NotificationCenter.default.publisher(for: .voiceOpenPregnancyAppointments)) { _ in destination = .appointments }
        .onReceive(NotificationCenter.default.publisher(for: .voiceOpenPregnancyWeekGuide)) { _ in destination = .weekGuide }
        .onReceive(NotificationCenter.default.publisher(for: .voiceOpenPregnancyMilestones)) { _ in destination = .milestones }
        .onReceive(NotificationCenter.default.publisher(for: .voiceOpenContractionTimer)) { _ in destination = .contractions }
        .onReceive(NotificationCenter.default.publisher(for: .voiceOpenPregnancyMoodLog)) { _ in destination = .mood }
        .onReceive(NotificationCenter.default.publisher(for: .voiceOpenPregnancyTimeline)) { _ in destination = .timeline }
        .onReceive(NotificationCenter.default.publisher(for: .voiceOpenPregnancyWeightChart)) { _ in destination = .weightChart }
        .onReceive(NotificationCenter.default.publisher(for: .voiceOpenBirthPlan)) { _ in destination = .birthPlan }
        .onReceive(NotificationCenter.default.publisher(for: .voiceOpenPregnancyNotes)) { _ in destination = .notes }
    }
}

enum PregnancyPlanningDestination: Identifiable {
    case symptoms, weight, kicks, appointments, weekGuide, milestones, contractions, mood, timeline, weightChart, birthPlan, notes
    var id: String { String(describing: self) }
}

extension Notification.Name {
    static let voiceOpenPregnancyPlanning = Notification.Name("VoiceOpenPregnancyPlanning")
    static let voiceOpenPregnancySymptomLog = Notification.Name("VoiceOpenPregnancySymptomLog")
    static let voiceOpenPregnancyWeightLog = Notification.Name("VoiceOpenPregnancyWeightLog")
    static let voiceOpenBabyKickCounter = Notification.Name("VoiceOpenBabyKickCounter")
    static let voiceOpenPregnancyAppointments = Notification.Name("VoiceOpenPregnancyAppointments")
    static let voiceOpenPregnancyWeekGuide = Notification.Name("VoiceOpenPregnancyWeekGuide")
    static let voiceOpenPregnancyMilestones = Notification.Name("VoiceOpenPregnancyMilestones")
    static let voiceOpenContractionTimer = Notification.Name("VoiceOpenContractionTimer")
    static let voiceOpenPregnancyMoodLog = Notification.Name("VoiceOpenPregnancyMoodLog")
    static let voiceOpenPregnancyTimeline = Notification.Name("VoiceOpenPregnancyTimeline")
    static let voiceOpenPregnancyWeightChart = Notification.Name("VoiceOpenPregnancyWeightChart")
    static let voiceOpenBirthPlan = Notification.Name("VoiceOpenBirthPlan")
    static let voiceOpenPregnancyNotes = Notification.Name("VoiceOpenPregnancyNotes")
}
