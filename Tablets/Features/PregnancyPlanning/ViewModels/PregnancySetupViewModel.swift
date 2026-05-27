import Combine
import Foundation
import SwiftData

@MainActor
final class PregnancySetupViewModel: ObservableObject {
    enum SetupMode: String, CaseIterable, Identifiable {
        case lmp
        case dueDate
        case planning
        var id: String { rawValue }
    }

    @Published var setupMode: SetupMode = .lmp
    @Published var lmpDate = Calendar.current.date(byAdding: .day, value: -56, to: .now) ?? .now
    @Published var dueDate = Calendar.current.date(byAdding: .day, value: 224, to: .now) ?? .now
    @Published var babyNickname = ""
    @Published var validationMessage: String?
    @Published var saveErrorMessage: String?
    @Published var isSaving = false

    func calculateDueDate(from lmp: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: 280, to: lmp) ?? lmp
    }

    func calculateLMP(from dueDate: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: -280, to: dueDate) ?? dueDate
    }

    func validateCurrentStep(_ step: Int) -> Bool {
        validationMessage = nil
        saveErrorMessage = nil

        if step == 0 {
            let finalDue = setupMode == .dueDate ? dueDate : calculateDueDate(from: lmpDate)
            let finalLMP = setupMode == .dueDate ? calculateLMP(from: dueDate) : lmpDate
            let currentWeek = currentWeekNumber(from: finalLMP)

            if setupMode == .lmp && finalLMP > Date() {
                validationMessage = "Please choose a last period date that has already passed."
                log("Validation failed: LMP is in the future")
                return false
            }

            guard finalDue >= Calendar.current.startOfDay(for: .now) else {
                validationMessage = "Please choose a future due date."
                log("Validation failed: due date is in the past")
                return false
            }

            guard (1...42).contains(currentWeek) else {
                validationMessage = "Please check your dates and try again."
                log("Validation failed: impossible week \(currentWeek)")
                return false
            }
        }

        log("Validation passed for step \(step)")
        return true
    }

    @discardableResult
    func saveProfile(context: ModelContext) -> PregnancyProfile? {
        validationMessage = nil
        saveErrorMessage = nil
        isSaving = true
        defer { isSaving = false }

        let finalDue = setupMode == .dueDate ? dueDate : calculateDueDate(from: lmpDate)
        let finalLMP = setupMode == .dueDate ? calculateLMP(from: dueDate) : lmpDate
        let trimmedNickname = babyNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentWeek = currentWeekNumber(from: finalLMP)

        log("""
        Preparing profile save:
          mode=\(setupMode.rawValue)
          lmp=\(finalLMP)
          dueDate=\(finalDue)
          dueDateIsManual=\(setupMode == .dueDate)
          week=\(currentWeek)
          nickname=\(trimmedNickname.isEmpty ? "<empty>" : trimmedNickname)
          pregnancyStartedAt=\(Date())
          isActive=true
          hydrationRemindersEnabled=true
          supplementRemindersEnabled=true
        """)

        let profile: PregnancyProfile
        let insertedNewProfile: Bool

        if let existingProfile = existingProfileForSetup(context: context) {
            log("Updating existing pregnancy profile. id=\(existingProfile.id), wasActive=\(existingProfile.isActive)")
            existingProfile.lastMenstrualPeriodDate = finalLMP
            existingProfile.dueDate = finalDue
            existingProfile.dueDateIsManual = setupMode == .dueDate
            existingProfile.pregnancyStartedAt = .now
            existingProfile.isActive = true
            existingProfile.babyNickname = trimmedNickname.isEmpty ? nil : trimmedNickname
            existingProfile.hydrationRemindersEnabled = existingProfile.hydrationRemindersEnabled ?? true
            existingProfile.supplementRemindersEnabled = existingProfile.supplementRemindersEnabled ?? true
            existingProfile.lastOpenedAt = .now
            profile = existingProfile
            insertedNewProfile = false
        } else {
            profile = PregnancyProfile(
                lastMenstrualPeriodDate: finalLMP,
                dueDate: finalDue,
                dueDateIsManual: setupMode == .dueDate,
                babyNickname: trimmedNickname.isEmpty ? nil : trimmedNickname,
                hydrationRemindersEnabled: true,
                supplementRemindersEnabled: true,
                lastOpenedAt: .now
            )
            context.insert(profile)
            insertedNewProfile = true
            log("Inserted new pregnancy profile. id=\(profile.id)")
        }

        deactivateDuplicateActiveProfiles(except: profile, context: context)

        do {
            try context.save()
            log("[PregnancySetup] Save success")
            log("Pregnancy profile saved. id=\(profile.id), insertedNewProfile=\(insertedNewProfile)")
            return profile
        } catch {
            if insertedNewProfile {
                context.delete(profile)
            }
            saveErrorMessage = "We couldn't save your pregnancy profile. Please try again."
            logSaveFailure(error)
            return nil
        }
    }

    private func existingProfileForSetup(context: ModelContext) -> PregnancyProfile? {
        do {
            let descriptor = FetchDescriptor<PregnancyProfile>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let profiles = try context.fetch(descriptor)
            log("Fetched \(profiles.count) pregnancy profile(s); active count=\(profiles.filter(\.isActive).count)")
            return profiles.first(where: \.isActive) ?? profiles.first
        } catch {
            log("Existing profile fetch failed before save: \(error)")
            return nil
        }
    }

    private func deactivateDuplicateActiveProfiles(except selectedProfile: PregnancyProfile, context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<PregnancyProfile>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let profiles = try context.fetch(descriptor)
            for profile in profiles where profile.isActive && profile.id != selectedProfile.id {
                profile.isActive = false
                log("Deactivated duplicate active pregnancy profile. id=\(profile.id)")
            }
        } catch {
            log("Duplicate active profile cleanup failed: \(error)")
        }
    }

    private func currentWeekNumber(from lmpDate: Date) -> Int {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: lmpDate),
            to: Calendar.current.startOfDay(for: .now)
        ).day ?? 0
        return (days / 7) + 1
    }

    private func logSaveFailure(_ error: Error) {
        log("[PregnancySetup] Save failed: \(error)")
        let nsError = error as NSError
        log("Save failed domain=\(nsError.domain), code=\(nsError.code), userInfo=\(nsError.userInfo)")
        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] {
            log("Underlying error: \(underlyingError)")
        }
    }

    private func log(_ message: String) {
        #if DEBUG
        print("[PregnancySetup] \(message)")
        #endif
    }
}
