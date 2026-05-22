import Foundation
import SwiftData

@MainActor
protocol MedicineRepositoryProtocol {
    func fetchActiveMedicines() throws -> [Medicine]
    func add(_ medicine: Medicine) throws
    func delete(_ medicine: Medicine) throws
    func save() throws
}

@MainActor
final class MedicineRepository: MedicineRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchActiveMedicines() throws -> [Medicine] {
        let descriptor = FetchDescriptor<Medicine>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func add(_ medicine: Medicine) throws {
        modelContext.insert(medicine)
        try save()
    }

    func delete(_ medicine: Medicine) throws {
        modelContext.delete(medicine)
        try save()
    }

    func save() throws {
        try modelContext.save()
    }
}
