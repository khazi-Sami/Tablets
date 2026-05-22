import Foundation
import SwiftData

@MainActor
protocol HealthRecordRepositoryProtocol {
    func fetchRecentMetrics(limit: Int) throws -> [HealthRecord]
    func fetchRecords(type: HealthRecordType, limit: Int) throws -> [HealthRecord]
    func add(_ metric: HealthRecord) throws
}

@MainActor
final class HealthRecordRepository: HealthRecordRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchRecentMetrics(limit: Int = 20) throws -> [HealthRecord] {
        var descriptor = FetchDescriptor<HealthRecord>(
            sortBy: [SortDescriptor(\.measuredAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func fetchRecords(type: HealthRecordType, limit: Int = 30) throws -> [HealthRecord] {
        var descriptor = FetchDescriptor<HealthRecord>(
            predicate: #Predicate { $0.typeRawValue == type.rawValue },
            sortBy: [SortDescriptor(\.measuredAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func add(_ metric: HealthRecord) throws {
        modelContext.insert(metric)
        try modelContext.save()
    }
}
