import Combine
import Foundation
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

@MainActor
final class PrescriptionScannerViewModel: ObservableObject {
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var scannedImage: UIImage?
    @Published var rawText = ""
    @Published var drafts: [PrescriptionMedicineDraft] = []
    @Published var isProcessing = false
    @Published var isShowingCamera = false
    @Published var errorMessage: String?
    @Published var didSave = false

    private let ocrService = PrescriptionOCRService()
    private let parserService = PrescriptionParserService()

    func loadSelectedPhoto() {
        guard let selectedPhotoItem else { return }
        Task {
            do {
                if let data = try await selectedPhotoItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await process(image)
                }
            } catch {
                errorMessage = "Could not load this photo."
            }
        }
    }

    func processScannedImages(_ images: [UIImage]) {
        guard let image = images.first else { return }
        Task { await process(image) }
    }

    func updateDraft(_ draft: PrescriptionMedicineDraft) {
        guard let index = drafts.firstIndex(where: { $0.id == draft.id }) else { return }
        drafts[index] = draft
    }

    func saveConfirmedDrafts(modelContext: ModelContext) {
        let validDrafts = drafts.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !$0.dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !validDrafts.isEmpty else {
            errorMessage = "Please verify at least one medicine name and dosage before saving."
            HapticsManager.notification(.error)
            return
        }

        validDrafts.forEach { draft in
            let medicine = Medicine(
                name: draft.name,
                dosage: draft.dosage,
                medicineType: medicineType(from: draft.notes),
                instruction: draft.instruction,
                frequencyType: .daily,
                times: defaultTimes(from: draft.timing),
                stockCount: 0,
                lowStockAlertCount: 5,
                notes: "Prescription scan: \(draft.notes)"
            )
            modelContext.insert(medicine)
        }

        do {
            try modelContext.save()
            didSave = true
            HapticsManager.notification(.success)
        } catch {
            errorMessage = "Could not save medicine drafts."
            HapticsManager.notification(.error)
        }
    }

    private func process(_ image: UIImage) async {
        isProcessing = true
        scannedImage = image
        do {
            let text = try await ocrService.extractText(from: image)
            rawText = text
            drafts = parserService.parse(text)
            HapticsManager.notification(.success)
        } catch {
            errorMessage = "Could not read text from this prescription."
            HapticsManager.notification(.error)
        }
        isProcessing = false
    }

    private func medicineType(from text: String) -> MedicineType {
        if text.localizedCaseInsensitiveContains("syrup") { return .syrup }
        if text.localizedCaseInsensitiveContains("cap") { return .capsule }
        if text.localizedCaseInsensitiveContains("drop") { return .drops }
        if text.localizedCaseInsensitiveContains("injection") { return .injection }
        if text.localizedCaseInsensitiveContains("powder") { return .powder }
        return .tablet
    }

    private func defaultTimes(from timing: String) -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        if timing.localizedCaseInsensitiveContains("night") {
            components.hour = 20
        } else if timing.localizedCaseInsensitiveContains("afternoon") {
            components.hour = 14
        } else {
            components.hour = 8
        }
        components.minute = 0
        return [calendar.date(from: components) ?? now]
    }
}
