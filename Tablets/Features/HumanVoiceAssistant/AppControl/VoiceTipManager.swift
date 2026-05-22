import Combine
import Foundation

struct VoiceTip: Codable, Identifiable, Equatable {
    let id: String
    let text: String
}

final class VoiceTipManager: ObservableObject {
    private enum Keys {
        static let shownTipIDs = "voiceTipManager.shownTipIDs"
        static let interactionCount = "voiceTipManager.interactionCount"
    }

    private let userDefaults: UserDefaults
    private lazy var tips: [VoiceTip] = loadTips()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func nextTipAfterInteraction() -> VoiceTip? {
        let nextCount = userDefaults.integer(forKey: Keys.interactionCount) + 1
        userDefaults.set(nextCount, forKey: Keys.interactionCount)

        guard nextCount.isMultiple(of: 4) else { return nil }
        return nextUnshownTip()
    }

    private func nextUnshownTip() -> VoiceTip? {
        guard !tips.isEmpty else { return nil }

        var shownIDs = Set(userDefaults.stringArray(forKey: Keys.shownTipIDs) ?? [])
        if shownIDs.count >= tips.count {
            shownIDs.removeAll()
        }

        guard let tip = tips.first(where: { !shownIDs.contains($0.id) }) else { return nil }
        shownIDs.insert(tip.id)
        userDefaults.set(Array(shownIDs), forKey: Keys.shownTipIDs)
        return tip
    }

    private func loadTips() -> [VoiceTip] {
        guard let url = Bundle.main.url(forResource: "VoiceTips", withExtension: "json") else {
            return fallbackTips
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([VoiceTip].self, from: data)
        } catch {
            return fallbackTips
        }
    }

    private var fallbackTips: [VoiceTip] {
        [
            VoiceTip(id: "tip_001", text: "Tip: Say 'How is my BP this week' to get a 7-day summary."),
            VoiceTip(id: "tip_002", text: "Tip: Say 'My BP is 120 over 80' to save a pressure reading."),
            VoiceTip(id: "tip_003", text: "Tip: Say 'My sugar is 145 after food' to log sugar quickly."),
            VoiceTip(id: "tip_004", text: "Tip: Say 'Open medicines' to see your tablet list."),
            VoiceTip(id: "tip_005", text: "Tip: Say 'Add medicine' when you get a new prescription."),
            VoiceTip(id: "tip_006", text: "Tip: Say 'What medicine is pending?' to check today's doses."),
            VoiceTip(id: "tip_007", text: "Tip: Say 'Did I take my tablet?' to ask about medicine status."),
            VoiceTip(id: "tip_008", text: "Tip: Say 'Open periods' to go to women’s health tracking."),
            VoiceTip(id: "tip_009", text: "Tip: Say 'My period started today' to log a period start."),
            VoiceTip(id: "tip_010", text: "Tip: Say 'When was my last period?' to check saved logs."),
            VoiceTip(id: "tip_011", text: "Tip: Say 'Scan prescription' to open the prescription scanner."),
            VoiceTip(id: "tip_012", text: "Tip: Say 'Open doctor visit' to prepare a doctor summary."),
            VoiceTip(id: "tip_013", text: "Tip: Say 'Health summary' to hear a short saved-log overview."),
            VoiceTip(id: "tip_014", text: "Tip: Say 'Open family care' to manage family medicines."),
            VoiceTip(id: "tip_015", text: "Tip: Say 'Family medicines' to jump to family care."),
            VoiceTip(id: "tip_016", text: "Tip: Say 'Open settings' to change app preferences."),
            VoiceTip(id: "tip_017", text: "Tip: Say 'Health journey' to open your progress timeline."),
            VoiceTip(id: "tip_018", text: "Tip: Say 'Check-in today' to open the daily wellness check-in."),
            VoiceTip(id: "tip_019", text: "Tip: You can say 'sar dard hai' to log headache."),
            VoiceTip(id: "tip_020", text: "Tip: You can say 'tension kaisa hai' to ask about BP."),
            VoiceTip(id: "tip_021", text: "Tip: You can say 'goli kaunsa lena hai' to ask medicine timing."),
            VoiceTip(id: "tip_022", text: "Tip: Say 'How was my week?' for a gentle health recap."),
            VoiceTip(id: "tip_023", text: "Tip: Say 'Doctor visit' before an appointment."),
            VoiceTip(id: "tip_024", text: "Tip: Say 'Medicine schedule' to ask about upcoming tablets."),
            VoiceTip(id: "tip_025", text: "Tip: Say 'Help' anytime to hear what I can do.")
        ]
    }
}
