import SwiftData
import SwiftUI

struct PregnancyAppointmentView: View {
    @Environment(\.modelContext) private var modelContext
    let profile: PregnancyProfile
    @StateObject private var viewModel = PregnancyAppointmentViewModel()
    @State private var title = "OB Checkup"
    @State private var scheduledAt = Date()
    @State private var doctorName = ""
    @State private var location = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Appointments 📅").font(PregnancyTheme.titleFont)
                        PregnancyCard {
                            VStack {
                                TextField("Title", text: $title)
                                DatePicker("Date", selection: $scheduledAt)
                                TextField("Doctor name", text: $doctorName)
                                TextField("Location", text: $location)
                                TextField("Notes", text: $notes, axis: .vertical)
                                Button("Save Appointment") {
                                    viewModel.save(context: modelContext, appointment: PregnancyAppointment(pregnancyProfileId: profile.id, title: title, scheduledAt: scheduledAt, location: location, doctorName: doctorName, notes: notes))
                                }
                            }
                        }
                        ForEach(viewModel.upcoming) { appointment in
                            PregnancyCard {
                                VStack(alignment: .leading) {
                                    Text(appointment.title).font(PregnancyTheme.headingFont)
                                    Text(appointment.scheduledAt.formatted(date: .abbreviated, time: .shortened))
                                    Button("Mark complete") { viewModel.markComplete(context: modelContext, appointment: appointment) }
                                }
                            }
                        }
                    }
                    .padding(PregnancyTheme.pagePadding)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .task { viewModel.load(context: modelContext, profileId: profile.id) }
            .navigationTitle("Appointments")
        }
        .dismissKeyboardOnTap()
    }
}
