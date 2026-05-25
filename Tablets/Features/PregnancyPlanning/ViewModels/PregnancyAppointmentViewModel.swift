import Combine
import Foundation
import SwiftData

@MainActor
final class PregnancyAppointmentViewModel: ObservableObject {
    @Published var upcoming: [PregnancyAppointment] = []
    @Published var past: [PregnancyAppointment] = []
    @Published var isAddingAppointment = false

    func load(context: ModelContext, profileId: UUID) {
        let all = ((try? context.fetch(FetchDescriptor<PregnancyAppointment>(sortBy: [SortDescriptor(\.scheduledAt)]))) ?? []).filter { $0.pregnancyProfileId == profileId }
        upcoming = all.filter { !$0.isCompleted && $0.scheduledAt >= .now }
        past = all.filter { $0.isCompleted || $0.scheduledAt < .now }
    }

    func save(context: ModelContext, appointment: PregnancyAppointment) {
        context.insert(appointment)
        try? context.save()
        load(context: context, profileId: appointment.pregnancyProfileId)
    }

    func markComplete(context: ModelContext, appointment: PregnancyAppointment) {
        appointment.isCompleted = true
        try? context.save()
        load(context: context, profileId: appointment.pregnancyProfileId)
    }
}
