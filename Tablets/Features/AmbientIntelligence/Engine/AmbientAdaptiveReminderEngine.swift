import Foundation

struct AmbientAdaptiveReminderEngine {
    func recommendation(from signals: [AmbientHabitSignal], elderlyMode: Bool) -> String {
        if elderlyMode {
            return "Use larger controls and one clear action per reminder."
        }

        if let delayed = signals.first(where: { $0.signalType == .medicine && $0.averageResponseDelayMinutes > 20 }) {
            return "Try a gentle reminder about \(Int(delayed.averageResponseDelayMinutes)) minutes earlier."
        }

        if let medicine = signals.first(where: { $0.signalType == .medicine }) {
            return "Keep medicine reminders near \(formattedHour(medicine.hourOfDay)); that pattern seems familiar."
        }

        return "Keep reminders simple and calm until more local habits are learned."
    }

    private func formattedHour(_ hour: Int) -> String {
        let suffix = hour >= 12 ? "PM" : "AM"
        let value = hour % 12 == 0 ? 12 : hour % 12
        return "\(value) \(suffix)"
    }
}
