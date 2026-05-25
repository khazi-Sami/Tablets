import Combine
import Foundation
import SwiftData

@MainActor
final class PregnancyDashboardViewModel: ObservableObject {
    @Published var activeProfile: PregnancyProfile?
    @Published var currentWeek: Int = 1
    @Published var daysUntilDueDate: Int = 0
    @Published var currentWeekInfo: PregnancyWeekInfo?
    @Published var recentSymptoms: [PregnancySymptomLog] = []
    @Published var recentWeights: [PregnancyWeightLog] = []
    @Published var upcomingAppointments: [PregnancyAppointment] = []
    @Published var milestones: [PregnancyMilestone] = []
    @Published var trackedSupplements: [Medicine] = []
    @Published var supplementSuggestions: [SupplementSuggestion] = []
    @Published var recentMoods: [PregnancyMoodLog] = []
    @Published var recentKicks: [BabyKickLog] = []
    @Published var notesForDoctorCount = 0

    func loadDashboard(context: ModelContext) {
        let profiles = (try? context.fetch(FetchDescriptor<PregnancyProfile>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
        activeProfile = profiles.first(where: \.isActive)
        guard let profile = activeProfile else { return }
        currentWeek = currentWeekNumber(from: profile)
        daysUntilDueDate = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: profile.dueDate)).day ?? 0
        currentWeekInfo = PregnancyWeekGuide.info(for: currentWeek)
        recentSymptoms = ((try? context.fetch(FetchDescriptor<PregnancySymptomLog>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]))) ?? []).filter { $0.pregnancyProfileId == profile.id }.prefix(3).map { $0 }
        recentWeights = ((try? context.fetch(FetchDescriptor<PregnancyWeightLog>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]))) ?? []).filter { $0.pregnancyProfileId == profile.id }.prefix(5).map { $0 }
        upcomingAppointments = ((try? context.fetch(FetchDescriptor<PregnancyAppointment>(sortBy: [SortDescriptor(\.scheduledAt)]))) ?? []).filter { $0.pregnancyProfileId == profile.id && !$0.isCompleted && $0.scheduledAt >= .now }
        milestones = (try? context.fetch(FetchDescriptor<PregnancyMilestone>(sortBy: [SortDescriptor(\.weekNumber)]))) ?? []
        let supplementService = PregnancySupplementService()
        trackedSupplements = supplementService.getPregnancySupplements(context: context)
        supplementSuggestions = supplementService.getSuggestedSupplements(for: currentWeek)
        recentMoods = ((try? context.fetch(FetchDescriptor<PregnancyMoodLog>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]))) ?? []).filter { $0.pregnancyProfileId == profile.id }.prefix(3).map { $0 }
        recentKicks = ((try? context.fetch(FetchDescriptor<BabyKickLog>(sortBy: [SortDescriptor(\.sessionStartedAt, order: .reverse)]))) ?? []).filter { $0.pregnancyProfileId == profile.id }.prefix(3).map { $0 }
        let notes = ((try? context.fetch(FetchDescriptor<PregnancyNote>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]))) ?? []).filter { $0.pregnancyProfileId == profile.id }
        notesForDoctorCount = notes.filter { $0.category == .forDoctor || $0.category == .question }.count
    }

    func currentWeekNumber(from profile: PregnancyProfile) -> Int {
        profile.currentWeek
    }
}
