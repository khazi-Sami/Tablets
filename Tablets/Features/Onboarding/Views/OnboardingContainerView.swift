import SwiftUI

struct OnboardingContainerView: View {
    let profile: UserProfile
    let complete: (UserProfile) -> Void

    @State private var step = 0
    @State private var name = ""
    @State private var age = ""
    @State private var gender = Gender.preferNotToSay
    @State private var selectedConditions = Set<String>()
    @State private var selectedFeatures = Set<String>()

    private let conditions = ["Blood Pressure", "Diabetes", "Heart Health", "Medicine Routine", "Women's Health"]
    private let features = ["Medicine reminders", "BP/sugar logging", "Voice assistant", "Doctor reports", "Apple Health"]

    var body: some View {
        ZStack {
            AppGradient.background.ignoresSafeArea()
            VStack(spacing: Spacing.large) {
                ProgressView(value: Double(step + 1), total: 5)
                    .tint(AppColor.medicalBlue)

                PillCardContainer(style: .highlighted, padding: Spacing.large) {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Label(title, systemImage: icon)
                            .font(AppFont.title)
                            .foregroundStyle(AppColor.ink)
                        content
                    }
                }

                Spacer()

                HStack {
                    if step > 0 {
                        CapsuleButton("Back", systemImage: "chevron.left", style: .secondary) {
                            step -= 1
                        }
                    }
                    CapsuleButton(step == 4 ? "Finish setup" : "Continue", systemImage: step == 4 ? "checkmark" : "chevron.right") {
                        if step == 4 {
                            save()
                        } else {
                            step += 1
                        }
                    }
                }
            }
            .padding(Spacing.medium)
        }
        .onAppear {
            name = profile.displayName ?? profile.name
            age = profile.age.map(String.init) ?? ""
            gender = profile.gender ?? .preferNotToSay
            selectedConditions = Set(profile.healthConditions)
            selectedFeatures = Set(profile.selectedFeatures)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            Text("Tell BanyAI what to call you.")
                .font(AppFont.body)
                .foregroundStyle(AppColor.secondaryInk)
            TextField("Your name", text: $name)
                .font(AppFont.bodyStrong)
                .padding(Spacing.medium)
                .background(AppColor.cream.opacity(0.82), in: RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
        case 1:
            TextField("Age", text: $age)
                .keyboardType(.numberPad)
                .font(AppFont.bodyStrong)
                .padding(Spacing.medium)
                .background(AppColor.cream.opacity(0.82), in: RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
            Picker("Gender", selection: $gender) {
                ForEach(Gender.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
        case 2:
            chipGrid(conditions, selected: $selectedConditions)
        case 3:
            chipGrid(features, selected: $selectedFeatures)
        default:
            VStack(alignment: .leading, spacing: Spacing.small) {
                permissionLine("Microphone", "For offline voice commands.")
                permissionLine("Notifications", "For medicine reminders.")
                Text("You can choose Maybe Later whenever a permission appears.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }
        }
    }

    private var title: String {
        ["Your name", "Basics", "Health focus", "Choose features", "Permissions"][step]
    }

    private var icon: String {
        ["person.fill", "heart.text.square.fill", "cross.case.fill", "sparkles", "lock.shield.fill"][step]
    }

    private func chipGrid(_ items: [String], selected: Binding<Set<String>>) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.small) {
            ForEach(items, id: \.self) { item in
                Button {
                    if selected.wrappedValue.contains(item) {
                        selected.wrappedValue.remove(item)
                    } else {
                        selected.wrappedValue.insert(item)
                    }
                } label: {
                    Text(item)
                        .font(AppFont.caption)
                        .foregroundStyle(selected.wrappedValue.contains(item) ? .white : AppColor.medicalBlueDeep)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(selected.wrappedValue.contains(item) ? AppColor.medicalBlue : AppColor.medicalBlue.opacity(0.10), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func permissionLine(_ title: String, _ subtitle: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                Text(title).font(AppFont.bodyStrong)
                Text(subtitle).font(AppFont.caption).foregroundStyle(AppColor.secondaryInk)
            }
        } icon: {
            Image(systemName: "checkmark.shield.fill").foregroundStyle(AppColor.medicalBlue)
        }
    }

    private func save() {
        profile.name = name
        profile.displayName = name.isEmpty ? nil : name
        profile.age = Int(age)
        profile.gender = gender
        profile.healthConditions = Array(selectedConditions)
        profile.selectedFeatures = Array(selectedFeatures)
        profile.preferredLanguage = "english"
        complete(profile)
    }
}
