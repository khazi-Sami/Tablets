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
            let medicineID = medicine.id.uuidString
            let medicineName = medicine.name
            let followUpManager = MissedDoseFollowUpManager(modelContext: modelContext)
            await MedicineNotificationScheduler().cancelNotifications(forMedicineID: medicineID, medicineName: medicineName)
            await followUpManager.cancelAllFollowUps(for: medicineID)
            do {
                try MedicineRepository(modelContext: modelContext).delete(medicine)
                let activeIDs = try MedicineRepository(modelContext: modelContext)
                    .fetchActiveMedicines()
                    .map { $0.id.uuidString }
                _ = await MedicineNotificationScheduler().cleanupOrphanedMedicineNotifications(activeMedicineIDs: Set(activeIDs))
                WidgetMedicineSnapshotWriter.writeAndReload(context: modelContext)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
