import Combine
import Foundation
import SwiftData

@MainActor
final class MedicinesViewModel: ObservableObject {
    @Published var isPresentingAddMedicine = false
    @Published var errorMessage: String?

    func delete(_ medicine: Medicine, modelContext: ModelContext) {
        do {
            try MedicineRepository(modelContext: modelContext).delete(medicine)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
