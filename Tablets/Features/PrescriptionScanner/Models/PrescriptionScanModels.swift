import Foundation
import SwiftUI

struct PrescriptionMedicineDraft: Identifiable, Hashable {
    enum Confidence: String {
        case high
        case needsReview
        case unclear

        var title: String {
            switch self {
            case .high: return "High confidence"
            case .needsReview: return "Needs review"
            case .unclear: return "Unclear text"
            }
        }

        var color: Color {
            switch self {
            case .high: return AppColor.mintGreenDeep
            case .needsReview: return AppColor.lavenderDeep
            case .unclear: return AppColor.softRed
            }
        }
    }

    var id = UUID()
    var name: String
    var dosage: String
    var timing: String
    var instruction: MedicineInstruction
    var duration: String
    var notes: String
    var confidence: Confidence

    static let empty = PrescriptionMedicineDraft(
        name: "",
        dosage: "",
        timing: "",
        instruction: .afterFood,
        duration: "",
        notes: "",
        confidence: .unclear
    )
}

struct PrescriptionScanResult {
    let rawText: String
    let drafts: [PrescriptionMedicineDraft]
}
