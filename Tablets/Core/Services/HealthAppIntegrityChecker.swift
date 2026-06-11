import Foundation
import SwiftData
import UserNotifications
import WidgetKit

@MainActor
enum HealthAppIntegrityChecker {
    static let safeModeMessage = "Open BanyAI to refresh your health data."
    static let signedOutWidgetMessage = "Sign in to continue."

    struct Report {
        let hasValidProfile: Bool
        let swiftDataLoaded: Bool
        let activeMedicineIDs: Set<String>
        let invalidMedicineIDs: Set<String>
        let widgetSnapshotValid: Bool

        var isValid: Bool {
            hasValidProfile && swiftDataLoaded && invalidMedicineIDs.isEmpty && widgetSnapshotValid
        }
    }

    static func check(context: ModelContext) -> Report {
        do {
            let hasProfile = try hasActiveProfile(context: context)
            let medicines = try context.fetch(FetchDescriptor<Medicine>())
            let activeMedicines = medicines.filter(\.isActive)
            let activeIDs = Set(activeMedicines.map { $0.id.uuidString })
            let invalidIDs = Set(activeMedicines.filter { !isValidMedicine($0) }.map { $0.id.uuidString })
            let snapshotValid = WidgetMedicineSnapshotWriter.isCurrentSnapshotValid(activeMedicineIDs: activeIDs.subtracting(invalidIDs))
            let report = Report(
                hasValidProfile: hasProfile,
                swiftDataLoaded: true,
                activeMedicineIDs: activeIDs.subtracting(invalidIDs),
                invalidMedicineIDs: invalidIDs,
                widgetSnapshotValid: snapshotValid
            )

            if !report.isValid {
                WidgetMedicineSnapshotWriter.writeSafeModeAndReload(message: safeModeMessage)
            }

            return report
        } catch {
            #if DEBUG
            print("[HealthAppIntegrityChecker] SwiftData integrity check failed: \(error)")
            #endif
            WidgetMedicineSnapshotWriter.writeSafeModeAndReload(message: safeModeMessage)
            return Report(
                hasValidProfile: false,
                swiftDataLoaded: false,
                activeMedicineIDs: [],
                invalidMedicineIDs: [],
                widgetSnapshotValid: false
            )
        }
    }

    static func cleanupLaunchState(context: ModelContext) {
        let report = check(context: context)
        Task {
            let removed = await MedicineNotificationScheduler()
                .cleanupOrphanedMedicineNotifications(activeMedicineIDs: report.activeMedicineIDs)
            #if DEBUG
            print("[HealthAppIntegrityChecker] orphan notifications found/removed: \(removed)")
            #endif
        }
        if report.isValid {
            WidgetMedicineSnapshotWriter.writeAndReload(context: context)
        }
    }

    static func cleanupForAppReset() {
        Task {
            await MedicineNotificationScheduler().cancelAllMedicineNotifications()
            WidgetMedicineSnapshotWriter.clearAndReload()
        }
    }

    static func cleanupForSignOut() {
        AppPreferenceKeys.clearCompletedSession()
        Task {
            await MedicineNotificationScheduler().cancelAllMedicineNotifications()
            WidgetMedicineSnapshotWriter.writeSignedOutAndReload()
        }
    }

    static func isValidMedicine(_ medicine: Medicine) -> Bool {
        !medicine.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !medicine.dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        medicine.times.isEmpty == false
    }

    private static func hasActiveProfile(context: ModelContext) throws -> Bool {
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        return profiles.contains { profile in
            profile.hasCompletedOnboarding &&
            !profile.loginMethod.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
