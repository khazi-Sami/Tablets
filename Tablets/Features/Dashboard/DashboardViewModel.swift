import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class DashboardViewModel {
    private(set) var dataProvider: DashboardDataProvider?
    private let insightEngine = DashboardInsightEngine()

    private(set) var userName = ""
    private(set) var greetingText = "Good morning"
    private(set) var statusLine = "Loading your care plan..."
    private(set) var insightCards: [DashboardInsightCardModel] = []
    private(set) var voiceSuggestionText = "Try: 'What medicine is pending'"
    private(set) var upcomingMedicines: [DashboardUpcomingMedicineItem] = []

    func configure(dataProvider: DashboardDataProvider) {
        if self.dataProvider == nil {
            self.dataProvider = dataProvider
        }
    }

    func refresh(modelContext: ModelContext) async {
        await dataProvider?.refresh()
        let profile = insightEngine.activeUserProfile(context: modelContext)
        let fallbackName = UserHealthProfile.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let profileDisplayName = profile?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let profileName = profile?.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = (profileDisplayName?.isEmpty == false ? profileDisplayName : profileName) ?? fallbackName

        userName = resolvedName.trimmingCharacters(in: .whitespacesAndNewlines)
        greetingText = insightEngine.morningGreeting(name: userName)
        voiceSuggestionText = insightEngine.voiceSuggestion(profile: profile, context: modelContext)
        upcomingMedicines = insightEngine.upcomingMedicines(context: modelContext)

        let medicineSummary = insightEngine.medicinesSummary(context: modelContext)
        let bpSummary = insightEngine.bpSummary(context: modelContext)
        let sugarSummary = insightEngine.sugarSummary(context: modelContext)
        let periodSummary = insightEngine.periodSummary(context: modelContext)
        let pregnancySummary = insightEngine.pregnancySummary(context: modelContext)

        statusLine = bpSummary ?? sugarSummary ?? medicineSummary

        var cards = [
            DashboardInsightCardModel(
                kind: .medicines,
                title: "Today's routine",
                summary: medicineSummary,
                icon: "pills.fill"
            )
        ]

        if let bpSummary {
            cards.append(
                DashboardInsightCardModel(
                    kind: .bloodPressure,
                    title: "Blood pressure",
                    summary: bpSummary,
                    icon: HealthRecordType.bloodPressure.icon
                )
            )
        }

        if let sugarSummary {
            cards.append(
                DashboardInsightCardModel(
                    kind: .sugar,
                    title: "Blood sugar",
                    summary: sugarSummary,
                    icon: HealthRecordType.bloodSugar.icon
                )
            )
        }

        if let periodSummary {
            cards.append(
                DashboardInsightCardModel(
                    kind: .period,
                    title: "Women's health",
                    summary: periodSummary,
                    icon: "calendar.badge.clock"
                )
            )
        }

        if let pregnancySummary {
            cards.append(
                DashboardInsightCardModel(
                    kind: .pregnancy,
                    title: "Pregnancy",
                    summary: pregnancySummary,
                    icon: "figure.maternity"
                )
            )
        }

        insightCards = cards
    }
}
