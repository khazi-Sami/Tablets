import Foundation
import Observation
import SwiftData
import UIKit
import WidgetKit

@MainActor
@Observable
final class MedicineReminderViewModel {
    var didTakeMedicine = false
    var isSpeaking = false
    var caringMessage = "Your health matters. Take a calm breath, then take your medicine when you are ready."

    private let ttsService: TTSServiceProtocol = TTSService()

    func markTaken(medicine: Medicine?, modelContext: ModelContext) {
        saveLog(medicine: medicine, status: .taken, modelContext: modelContext)
        didTakeMedicine = true
        caringMessage = "Beautifully done. One small caring step is complete."
        HapticsManager.notification(.success)
    }

    func snooze(medicine: Medicine?, modelContext: ModelContext) {
        saveLog(medicine: medicine, status: .snoozed, modelContext: modelContext)
        caringMessage = "No hurry. I will remind you again soon."
        HapticsManager.impact(.soft)
    }

    func skip(medicine: Medicine?, modelContext: ModelContext) {
        saveLog(medicine: medicine, status: .skipped, modelContext: modelContext)
        caringMessage = "Skipped for now. Your care history is updated."
        HapticsManager.impact(.medium)
    }

    func speakReminder(medicineName: String, dosage: String, instruction: String) {
        if ttsService.isSpeaking {
            ttsService.stop()
            isSpeaking = false
            return
        }

        let phrase = "Gentle reminder. It is time for \(medicineName), \(dosage). \(instruction)."
        ttsService.speak(phrase, preferredVoiceIdentifier: "com.apple.ttsbundle.Samantha-compact")
        isSpeaking = true
        HapticsManager.selection()
    }

    func stopVoice() {
        ttsService.stop()
        isSpeaking = false
    }

    private func saveLog(medicine: Medicine?, status: MedicineLogStatus, modelContext: ModelContext) {
        guard let medicine else { return }

        let log = MedicineLog(
            medicine: medicine,
            scheduledTime: medicine.times.first ?? .now,
            takenTime: status == .taken ? .now : nil,
            status: status
        )
        modelContext.insert(log)

        do {
            try modelContext.save()
            cancelFollowUpIfNeeded(for: medicine, scheduledAt: log.scheduledTime, status: status, modelContext: modelContext)
            WidgetMedicineSnapshotWriter.writeAndReload(context: modelContext)
        } catch {
            caringMessage = "I could not save this reminder just now. Please try again."
            HapticsManager.notification(.error)
        }
    }

    private func cancelFollowUpIfNeeded(
        for medicine: Medicine,
        scheduledAt: Date,
        status: MedicineLogStatus,
        modelContext: ModelContext
    ) {
        guard status == .taken || status == .skipped || status == .snoozed else { return }
        let followUpManager = MissedDoseFollowUpManager(modelContext: modelContext)
        followUpManager.cancelFollowUp(for: medicine, scheduledAt: scheduledAt)
    }
}
