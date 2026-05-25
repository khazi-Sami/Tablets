import Combine
import Foundation
import SwiftData

@MainActor
final class PregnancyWeightViewModel: ObservableObject {
    @Published var weight = ""
    @Published var unit: WeightUnit = .kg
    @Published var recentLogs: [PregnancyWeightLog] = []

    func save(context: ModelContext, profileId: UUID, week: Int) {
        guard let value = Double(weight) else { return }
        context.insert(PregnancyWeightLog(pregnancyProfileId: profileId, weight: value, unit: unit, weekNumber: week))
        try? context.save()
        loadRecent(context: context, profileId: profileId)
    }

    func loadRecent(context: ModelContext, profileId: UUID) {
        recentLogs = ((try? context.fetch(FetchDescriptor<PregnancyWeightLog>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]))) ?? []).filter { $0.pregnancyProfileId == profileId }.prefix(5).map { $0 }
    }
}
