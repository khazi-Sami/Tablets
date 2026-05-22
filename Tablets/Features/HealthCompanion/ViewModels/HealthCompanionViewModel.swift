import Combine
import Foundation

@MainActor
final class HealthCompanionViewModel: ObservableObject {
    @Published var selectedMessageIndex = 0
    @Published var visibleText = ""
    @Published var isTyping = false

    private var typingTask: Task<Void, Never>?

    func messages(
        userName: String,
        medicines: [Medicine],
        medicineLogs: [MedicineLog],
        healthRecords: [HealthRecord]
    ) -> [HealthCompanionMessage] {
        var generated: [HealthCompanionMessage] = [
            HealthCompanionMessage(text: "\(greeting), \(userName). Your health journey matters.", tone: .greeting),
            HealthCompanionMessage(text: "A small check-in today can make your routine feel lighter.", tone: .checkIn)
        ]

        if sugarLogCountThisWeek(in: healthRecords) >= 3 {
            generated.append(
                HealthCompanionMessage(text: "You tracked your sugar consistently this week. That is a caring habit.", tone: .encouragement)
            )
        } else {
            generated.append(
                HealthCompanionMessage(text: "A sugar or BP entry today would help your weekly picture feel clearer.", tone: .checkIn)
            )
        }

        if let upcomingMedicine = medicines.first(where: { $0.isActive }) {
            generated.append(
                HealthCompanionMessage(text: "Do not forget \(upcomingMedicine.name). I am here to help you stay on track.", tone: .reminder)
            )
        } else {
            generated.append(
                HealthCompanionMessage(text: "Your medicine list is quiet right now. Add reminders whenever you need support.", tone: .reminder)
            )
        }

        let streak = healthStreak(from: healthRecords, medicineLogs: medicineLogs)
        generated.append(
            HealthCompanionMessage(text: streak > 0 ? "You have a \(streak)-day care streak based on saved logs." : "Start a care streak with one gentle health action today.", tone: .streak)
        )

        generated.append(
            HealthCompanionMessage(text: "These notes are based only on your saved activity, not medical advice.", tone: .checkIn)
        )

        return generated
    }

    func show(_ message: HealthCompanionMessage) {
        typingTask?.cancel()
        visibleText = ""
        isTyping = true

        typingTask = Task { [weak self] in
            for character in message.text {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .milliseconds(22))
                await MainActor.run {
                    self?.visibleText.append(character)
                }
            }

            await MainActor.run {
                self?.isTyping = false
            }
        }
    }

    func advance(totalMessages: Int) {
        guard totalMessages > 0 else { return }
        selectedMessageIndex = (selectedMessageIndex + 1) % totalMessages
        HapticsManager.selection()
    }

    func healthStreak(from healthRecords: [HealthRecord], medicineLogs: [MedicineLog]) -> Int {
        let calendar = Calendar.current
        var streak = 0

        for dayOffset in 0..<30 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: .now) else { continue }
            let hasHealthRecord = healthRecords.contains { calendar.isDate($0.measuredAt, inSameDayAs: day) }
            let hasMedicineLog = medicineLogs.contains { calendar.isDate($0.scheduledTime, inSameDayAs: day) }

            if hasHealthRecord || hasMedicineLog {
                streak += 1
            } else if dayOffset == 0 {
                continue
            } else {
                break
            }
        }

        return streak
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func sugarLogCountThisWeek(in records: [HealthRecord]) -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return records.filter { $0.type == .bloodSugar && $0.measuredAt >= weekAgo }.count
    }
}
