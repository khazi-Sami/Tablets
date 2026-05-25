import Combine
import Foundation
import SwiftData
import WidgetKit

@MainActor
final class MedicinesViewModel: ObservableObject {
    @Published var isPresentingAddMedicine = false
    @Published var errorMessage: String?

    func delete(_ medicine: Medicine, modelContext: ModelContext) {
        Task {
            await MedicineNotificationScheduler().cancelNotifications(for: medicine)
            do {
                try MedicineRepository(modelContext: modelContext).delete(medicine)
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
