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

    func calculateDueDate(from lmp: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: 280, to: lmp) ?? lmp
    }

    func calculateLMP(from dueDate: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: -280, to: dueDate) ?? dueDate
    }

    func saveProfile(context: ModelContext) {
        let finalDue = setupMode == .dueDate ? dueDate : calculateDueDate(from: lmpDate)
        let finalLMP = setupMode == .dueDate ? calculateLMP(from: dueDate) : lmpDate
        let profile = PregnancyProfile(
            lastMenstrualPeriodDate: finalLMP,
            dueDate: finalDue,
            dueDateIsManual: setupMode == .dueDate,
            babyNickname: babyNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : babyNickname
        )
        context.insert(profile)
        try? context.save()
    }
}
