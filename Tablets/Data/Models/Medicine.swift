import Foundation
import SwiftData

@Model
final class Medicine {
    @Attribute(.unique) var id: UUID
    var name: String
    var dosage: String
    var medicineTypeRawValue: String
    var instructionRawValue: String
    var frequencyTypeRawValue: String
    var times: [Date]
    var startDate: Date
    var endDate: Date?
    var stockCount: Int
    var lowStockAlertCount: Int
    var notes: String
    var createdAt: Date
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \MedicineLog.medicine)
    var logs: [MedicineLog] = []

    var medicineType: MedicineType {
        get { MedicineType(rawValue: medicineTypeRawValue) ?? .tablet }
        set { medicineTypeRawValue = newValue.rawValue }
    }

    var instruction: MedicineInstruction {
        get { MedicineInstruction(rawValue: instructionRawValue) ?? .afterFood }
        set { instructionRawValue = newValue.rawValue }
    }

    var frequencyType: MedicineFrequencyType {
        get { MedicineFrequencyType(rawValue: frequencyTypeRawValue) ?? .daily }
        set { frequencyTypeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        dosage: String,
        medicineType: MedicineType = .tablet,
        instruction: MedicineInstruction = .afterFood,
        frequencyType: MedicineFrequencyType = .daily,
        times: [Date] = [],
        startDate: Date = .now,
        endDate: Date? = nil,
        stockCount: Int = 0,
        lowStockAlertCount: Int = 5,
        notes: String = "",
        createdAt: Date = .now,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.medicineTypeRawValue = medicineType.rawValue
        self.instructionRawValue = instruction.rawValue
        self.frequencyTypeRawValue = frequencyType.rawValue
        self.times = times
        self.startDate = startDate
        self.endDate = endDate
        self.stockCount = stockCount
        self.lowStockAlertCount = lowStockAlertCount
        self.notes = notes
        self.createdAt = createdAt
        self.isActive = isActive
    }
}

enum MedicineType: String, Codable, CaseIterable, Identifiable {
    case tablet
    case capsule
    case syrup
    case injection
    case drops
    case powder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tablet:
            return "Tablet"
        case .capsule:
            return "Capsule"
        case .syrup:
            return "Syrup"
        case .injection:
            return "Injection"
        case .drops:
            return "Drops"
        case .powder:
            return "Powder"
        }
    }
}

enum MedicineInstruction: String, Codable, CaseIterable, Identifiable {
    case beforeFood
    case afterFood
    case withFood
    case emptyStomach

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beforeFood:
            return "Before food"
        case .afterFood:
            return "After food"
        case .withFood:
            return "With food"
        case .emptyStomach:
            return "Empty stomach"
        }
    }
}

enum MedicineFrequencyType: String, Codable, CaseIterable, Identifiable {
    case daily
    case alternateDays
    case weekly
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily:
            return "Daily"
        case .alternateDays:
            return "Alternate days"
        case .weekly:
            return "Weekly"
        case .custom:
            return "Custom"
        }
    }
}
