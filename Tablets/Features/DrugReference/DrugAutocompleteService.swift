import Foundation

enum DrugAutocompleteService {
    static func search(
        query: String,
        in catalog: DrugReferenceCatalog,
        limit: Int = 8
    ) -> [DrugReferenceEntry] {
        let normalizedQuery = normalize(query)
        guard normalizedQuery.count >= 2, !catalog.medicines.isEmpty else {
            return []
        }

        return catalog.medicines
            .compactMap { entry -> (entry: DrugReferenceEntry, score: Int)? in
                let score = bestScore(for: normalizedQuery, entry: entry)
                return score > 0 ? (entry, score) : nil
            }
            .sorted {
                if $0.score == $1.score {
                    return $0.entry.displayName.localizedCaseInsensitiveCompare($1.entry.displayName) == .orderedAscending
                }
                return $0.score > $1.score
            }
            .prefix(limit)
            .map(\.entry)
    }

    static func normalize(_ value: String) -> String {
        let lowercased = value.lowercased()
        let withoutStrength = lowercased
            .replacingOccurrences(of: #"\b\d+(\.\d+)?\s*(mg|mcg|g|ml|iu|%)\b"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        let allowed = withoutStrength.map { character in
            character.isLetter || character.isNumber ? character : " "
        }
        return String(allowed)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func bestScore(for query: String, entry: DrugReferenceEntry) -> Int {
        var best = 0

        for term in entry.searchTerms {
            if term == query {
                best = max(best, 1000)
            } else if term.hasPrefix(query) {
                best = max(best, 850 - min(term.count - query.count, 150))
            } else if term.contains(query) {
                best = max(best, 650 - min(term.count - query.count, 150))
            } else if query.count >= 4 {
                let distance = levenshtein(query, term)
                let maxLength = max(query.count, term.count)
                let similarity = maxLength == 0 ? 0 : Double(maxLength - distance) / Double(maxLength)
                if similarity >= 0.72 {
                    best = max(best, Int(similarity * 600))
                }
            }
        }

        return best
    }

    private static func levenshtein(_ lhs: String, _ rhs: String) -> Int {
        let lhsArray = Array(lhs)
        let rhsArray = Array(rhs)
        guard !lhsArray.isEmpty else { return rhsArray.count }
        guard !rhsArray.isEmpty else { return lhsArray.count }

        var previous = Array(0...rhsArray.count)
        var current = Array(repeating: 0, count: rhsArray.count + 1)

        for lhsIndex in 1...lhsArray.count {
            current[0] = lhsIndex
            for rhsIndex in 1...rhsArray.count {
                let substitutionCost = lhsArray[lhsIndex - 1] == rhsArray[rhsIndex - 1] ? 0 : 1
                current[rhsIndex] = min(
                    previous[rhsIndex] + 1,
                    current[rhsIndex - 1] + 1,
                    previous[rhsIndex - 1] + substitutionCost
                )
            }
            previous = current
        }

        return previous[rhsArray.count]
    }
}

