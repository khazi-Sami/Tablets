import Combine
import Foundation
import SwiftData

@MainActor
final class WomensHealthViewModel: ObservableObject {
    @Published var isShowingAddPeriod = false
    @Published var isShowingDailyLog = false
    @Published var errorMessage: String?

    let predictionViewModel = CyclePredictionViewModel()

    func ensureSettings(in modelContext: ModelContext, existing settings: [CyclePredictionSettings]) {
        guard settings.isEmpty else { return }
        modelContext.insert(CyclePredictionSettings())
        try? modelContext.save()
    }
}
