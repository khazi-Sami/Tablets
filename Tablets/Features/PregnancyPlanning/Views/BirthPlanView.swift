import SwiftData
import SwiftUI

struct BirthPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BirthPlan.lastUpdated, order: .reverse) private var plans: [BirthPlan]
    let profile: PregnancyProfile
    @State private var location = "Hospital"
    @State private var partner = ""
    @State private var painOptions: Set<String> = []
    @State private var deliveryOptions: Set<String> = []
    @State private var babyOptions: Set<String> = []
    @State private var feeding = "Undecided"
    @State private var notes = ""
    @State private var saved = false

    private let pain = ["Epidural", "Gas and Air", "TENS Machine", "Water Birth", "Massage", "Breathing Techniques", "Open to Options"]
    private let delivery = ["Dim lighting", "Quiet environment", "Music playing", "Minimal people", "Partner to cut cord", "Open to doctor's guidance"]
    private let baby = ["Immediate skin to skin", "Delayed cord clamping", "Partner holds baby first", "Vitamin K injection", "Newborn screening", "Photos immediately"]

    var body: some View {
        NavigationStack {
            ZStack {
                PregnancyTheme.mainGradient.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Birth Plan")
                            .font(PregnancyTheme.titleFont)
                        PregnancyCard {
                            Picker("Birth location", selection: $location) {
                                ForEach(["Hospital", "Home", "Birthing Centre", "Not decided"], id: \.self) { Text($0) }
                            }
                            TextField("Support person", text: $partner)
                        }
                        chipSection("Pain management", items: pain, selected: $painOptions)
                        chipSection("Delivery", items: delivery, selected: $deliveryOptions)
                        chipSection("After birth", items: baby, selected: $babyOptions)
                        PregnancyCard {
                            Picker("Feeding preference", selection: $feeding) {
                                ForEach(["Breastfeeding", "Formula", "Both", "Undecided"], id: \.self) { Text($0) }
                            }
                            TextField("Notes for doctor", text: $notes, axis: .vertical)
                        }
                        Button("Save Birth Plan") { save() }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(PregnancyTheme.deepRose, in: RoundedRectangle(cornerRadius: 16))
                        if saved {
                            PregnancyCard { Text("Birth plan saved. Share with your doctor or midwife at your next appointment.") }
                        }
                    }
                    .padding(PregnancyTheme.pagePadding)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Birth Plan")
            .task { loadExisting() }
        }
        .dismissKeyboardOnTap()
    }

    private func chipSection(_ title: String, items: [String], selected: Binding<Set<String>>) -> some View {
        PregnancyCard {
            VStack(alignment: .leading) {
                Text(title).font(PregnancyTheme.headingFont)
                PregnancyFlowLayout {
                    ForEach(items, id: \.self) { item in
                        PregnancyChip(title: item, isSelected: selected.wrappedValue.contains(item)) {
                            if selected.wrappedValue.contains(item) { selected.wrappedValue.remove(item) } else { selected.wrappedValue.insert(item) }
                        }
                    }
                }
            }
        }
    }

    private func loadExisting() {
        guard let plan = plans.first(where: { $0.pregnancyProfileId == profile.id }) else { return }
        location = plan.birthLocation ?? location
        partner = plan.birthPartner ?? ""
        painOptions = Set(plan.painManagement)
        deliveryOptions = Set((plan.deliveryPreferences ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
        babyOptions = Set(plan.babyAfterBirth)
        feeding = plan.feedingPreference ?? feeding
        notes = plan.specialRequests ?? ""
    }

    private func save() {
        let plan = plans.first(where: { $0.pregnancyProfileId == profile.id }) ?? BirthPlan(pregnancyProfileId: profile.id)
        plan.birthLocation = location
        plan.birthPartner = partner
        plan.painManagement = Array(painOptions)
        plan.deliveryPreferences = Array(deliveryOptions).joined(separator: ", ")
        plan.babyAfterBirth = Array(babyOptions)
        plan.feedingPreference = feeding
        plan.specialRequests = notes
        plan.lastUpdated = .now
        if !plans.contains(where: { $0.id == plan.id }) { modelContext.insert(plan) }
        try? modelContext.save()
        saved = true
    }
}
