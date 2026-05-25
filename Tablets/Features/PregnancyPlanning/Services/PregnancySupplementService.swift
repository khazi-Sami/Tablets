import Foundation
import SwiftData

struct PregnancySupplementService {
    func getPregnancySupplements(context: ModelContext) -> [Medicine] {
        let medicines = (try? context.fetch(FetchDescriptor<Medicine>(sortBy: [SortDescriptor(\.name)]))) ?? []
        return medicines.filter { medicine in
            medicine.isActive && supplementKeywords.contains { keyword in
                medicine.name.lowercased().contains(keyword) || medicine.notes.lowercased().contains(keyword)
            }
        }
    }

    func getSuggestedSupplements(for week: Int) -> [SupplementSuggestion] {
        suggestions.filter { $0.weekRange.contains(week) }
    }

    func suggestionResponse(for week: Int) -> String {
        let current = getSuggestedSupplements(for: week)
        guard !current.isEmpty else {
            return "I do not have pregnancy supplement suggestions for this week. Please follow your doctor's guidance before starting any supplement."
        }
        let list = current.prefix(4).map { "\($0.name): \($0.reason)" }.joined(separator: " ")
        return "For week \(week), common pregnancy supplement topics include \(list) Please confirm with your doctor before starting or changing any supplement."
    }

    private let supplementKeywords = ["folic", "prenatal", "iron", "calcium", "omega", "dha", "vitamin d", "vitamin"]

    private let suggestions: [SupplementSuggestion] = [
        SupplementSuggestion(name: "Folic Acid", reason: "Supports neural tube development in early pregnancy.", weekRange: 1...12, importanceLevel: .essential),
        SupplementSuggestion(name: "Prenatal Vitamins", reason: "Provides essential nutrients for baby's development.", weekRange: 1...40, importanceLevel: .essential),
        SupplementSuggestion(name: "Iron", reason: "Supports increased blood volume during pregnancy.", weekRange: 14...40, importanceLevel: .recommended),
        SupplementSuggestion(name: "Calcium", reason: "Supports baby's bone and teeth development.", weekRange: 14...40, importanceLevel: .recommended),
        SupplementSuggestion(name: "Omega-3 / DHA", reason: "Supports baby's brain and eye development.", weekRange: 12...40, importanceLevel: .recommended),
        SupplementSuggestion(name: "Vitamin D", reason: "Supports calcium absorption and immune health.", weekRange: 1...40, importanceLevel: .recommended)
    ]
}

struct SupplementSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let reason: String
    let weekRange: ClosedRange<Int>
    let importanceLevel: SupplementImportance
}

enum SupplementImportance: String {
    case essential = "Essential"
    case recommended = "Recommended"
    case optional = "Optional"
}
