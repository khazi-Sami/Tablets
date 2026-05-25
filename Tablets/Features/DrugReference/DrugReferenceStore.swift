import Foundation

struct DrugReferenceCatalog: Codable, Sendable {
    let version: String
    let lastUpdated: String
    let sourceNote: String
    let sourceFiles: [DrugReferenceSourceFile]
    let medicines: [DrugReferenceEntry]

    static let empty = DrugReferenceCatalog(
        version: "0",
        lastUpdated: "",
        sourceNote: "Offline drug reference is not available.",
        sourceFiles: [],
        medicines: []
    )

    var entryCount: Int {
        medicines.count
    }
}

struct DrugReferenceSourceFile: Codable, Sendable {
    let name: String
    let url: String?
    let downloadedAt: String?
}

struct DrugReferenceEntry: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let genericName: String
    let brandNames: [String]
    let synonyms: [String]
    let dosageForms: [String]
    let commonUses: [String]
    let safetyNotes: [String]
    let source: String
    let lastUpdated: String

    var searchTerms: [String] {
        ([displayName, genericName] + brandNames + synonyms)
            .map { DrugAutocompleteService.normalize($0) }
            .filter { !$0.isEmpty }
    }
}

@MainActor
enum DrugReferenceStore {
    static func loadBundledCatalog() async -> DrugReferenceCatalog {
        await Task.yield()
        return loadBundledCatalogSync()
    }

    static func loadBundledCatalogSync() -> DrugReferenceCatalog {
        let candidateURLs = [
            Bundle.main.url(forResource: "drug_reference_starter", withExtension: "json", subdirectory: "DrugReference"),
            Bundle.main.url(forResource: "drug_reference_starter", withExtension: "json", subdirectory: "Resources/DrugReference"),
            Bundle.main.url(forResource: "drug_reference_starter", withExtension: "json")
        ]

        guard let url = candidateURLs.compactMap({ $0 }).first else {
            #if DEBUG
            print("[DrugReferenceStore] Missing bundled drug_reference_starter.json")
            #endif
            return .empty
        }

        do {
            let data = try Data(contentsOf: url)
            let catalog = try JSONDecoder().decode(DrugReferenceCatalog.self, from: data)
            #if DEBUG
            print("[DrugReferenceStore] Loaded \(catalog.entryCount) offline drug entries")
            #endif
            return catalog
        } catch {
            #if DEBUG
            print("[DrugReferenceStore] Failed to load drug reference: \(error.localizedDescription)")
            #endif
            return .empty
        }
    }
}
