import Foundation
import SwiftData

@MainActor
struct BabyStatusEngine {
    func getBabyStatusSummary(context: ModelContext) -> String {
        guard let profile = activeProfile(context: context) else {
            return "I don't have pregnancy information saved yet. Say Open pregnancy to set up your journey."
        }

        let week = max(1, min(42, profile.currentWeek))
        let weekInfo = PregnancyWeekGuide.info(for: week)
        let daysUntilDue = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: profile.dueDate)).day ?? 0)

        return [
            "You are in week \(week) of your pregnancy.",
            "Your baby is about the size of a \(weekInfo.fruitComparison) this week.",
            firstSentence(from: weekInfo.babyDevelopment),
            kickSummary(context: context, profileID: profile.id),
            weightSummary(context: context, profileID: profile.id),
            appointmentSummary(context: context, profileID: profile.id),
            "\(daysUntilDue) days until your due date.",
            "This is informational only — please follow your doctor's guidance throughout your pregnancy."
        ].joined(separator: " ")
    }

    private func activeProfile(context: ModelContext) -> PregnancyProfile? {
        let descriptor = FetchDescriptor<PregnancyProfile>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return (try? context.fetch(descriptor))?.first(where: \.isActive)
    }

    private func kickSummary(context: ModelContext, profileID: UUID) -> String {
        let descriptor = FetchDescriptor<BabyKickLog>(sortBy: [SortDescriptor(\.sessionStartedAt, order: .reverse)])
        let dayAgo = Calendar.current.date(byAdding: .hour, value: -24, to: .now) ?? .now
        let logs = (try? context.fetch(descriptor)) ?? []
        guard let latest = logs.first(where: { $0.pregnancyProfileId == profileID && $0.sessionStartedAt >= dayAgo }) else {
            return "No kick session logged recently."
        }
        return "You logged \(latest.kickCount) kicks \(relativeTime(from: latest.sessionStartedAt))."
    }

    private func weightSummary(context: ModelContext, profileID: UUID) -> String {
        let descriptor = FetchDescriptor<PregnancyWeightLog>(sortBy: [SortDescriptor(\.loggedAt, order: .reverse)])
        let logs = (try? context.fetch(descriptor)) ?? []
        guard let latest = logs.first(where: { $0.pregnancyProfileId == profileID }) else {
            return "No weight logged recently."
        }
        let daysAgo = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: latest.loggedAt), to: Calendar.current.startOfDay(for: .now)).day ?? 0)
        return "Your last weight was \(String(format: "%.1f", latest.weight))\(latest.unit.rawValue), logged \(daysAgo) day\(daysAgo == 1 ? "" : "s") ago."
    }

    private func appointmentSummary(context: ModelContext, profileID: UUID) -> String {
        let descriptor = FetchDescriptor<PregnancyAppointment>(sortBy: [SortDescriptor(\.scheduledAt)])
        let appointments = (try? context.fetch(descriptor)) ?? []
        guard let next = appointments.first(where: { $0.pregnancyProfileId == profileID && !$0.isCompleted && $0.scheduledAt >= .now }) else {
            return "No upcoming appointments saved."
        }
        let days = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: next.scheduledAt)).day ?? 0)
        return "Your next appointment is \(next.title) on \(next.scheduledAt.formatted(date: .abbreviated, time: .omitted)), \(days) day\(days == 1 ? "" : "s") away."
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    private func firstSentence(from text: String) -> String {
        text.split(separator: ".").first.map { "\($0)." } ?? text
    }
}
