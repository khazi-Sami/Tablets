import SwiftUI

struct FamilyAvatarView: View {
    let member: FamilyMember
    @State private var float = false

    var body: some View {
        ZStack {
            Circle()
                .fill(gradient)
                .frame(width: 74, height: 74)
                .appShadow(AppShadow.soft)

            Image(systemName: member.avatarSymbol)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(float ? 1.04 : 0.96)
        }
        .offset(y: float ? -2 : 2)
        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: float)
        .onAppear { float = true }
        .accessibilityHidden(true)
    }

    private var gradient: LinearGradient {
        switch member.gradient {
        case .sunrise:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.62, blue: 0.48), Color(red: 1.0, green: 0.82, blue: 0.58)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mint:
            return LinearGradient(colors: [AppColor.mintGreenDeep, AppColor.mintGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .lavender:
            return LinearGradient(colors: [AppColor.lavenderDeep, AppColor.lavender], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blush:
            return LinearGradient(colors: [AppColor.softRed.opacity(0.86), AppColor.lavender], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blue:
            return LinearGradient(colors: [AppColor.medicalBlueDeep, AppColor.medicalBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .warm:
            return LinearGradient(colors: [Color(red: 0.98, green: 0.72, blue: 0.44), AppColor.warmWhite], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct FamilyStatusIndicator: View {
    enum Status {
        case cared
        case upcoming
        case missed

        var title: String {
            switch self {
            case .cared: return "Cared for"
            case .upcoming: return "Upcoming"
            case .missed: return "Needs attention"
            }
        }

        var color: Color {
            switch self {
            case .cared: return AppColor.mintGreenDeep
            case .upcoming: return AppColor.medicalBlue
            case .missed: return AppColor.softRed
            }
        }

        var icon: String {
            switch self {
            case .cared: return "checkmark.circle.fill"
            case .upcoming: return "clock.fill"
            case .missed: return "exclamationmark.circle.fill"
            }
        }
    }

    let status: Status

    var body: some View {
        Label(status.title, systemImage: status.icon)
            .font(AppFont.badge)
            .foregroundStyle(status.color)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(status.color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct FamilyMemberCard: View {
    let member: FamilyMember
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            PillCardContainer(padding: Spacing.medium) {
                HStack(spacing: Spacing.medium) {
                    FamilyAvatarView(member: member)

                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        HStack {
                            Text(member.name)
                                .font(AppFont.sectionTitle)
                                .foregroundStyle(AppColor.ink)
                            Spacer()
                            FamilyStatusIndicator(status: status)
                        }

                        Text(member.relationship.title + (member.age > 0 ? " • \(member.age)" : ""))
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.secondaryInk)

                        Text(summary)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.tertiaryInk)
                            .lineLimit(2)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var status: FamilyStatusIndicator.Status {
        member.medicineAssignments.isEmpty ? .upcoming : .cared
    }

    private var summary: String {
        if member.medicineAssignments.isEmpty {
            return "No medicines assigned yet. Tap to add care details."
        }

        return "\(member.medicineAssignments.count) medicines being watched with care."
    }
}

struct FamilyDashboardHero: View {
    let memberCount: Int
    let addAction: () -> Void

    var body: some View {
        PillCardContainer(style: .highlighted, padding: Spacing.large) {
            HStack(spacing: Spacing.large) {
                ZStack {
                    Circle()
                        .fill(AppColor.softRed.opacity(0.14))
                        .frame(width: 96, height: 96)
                    Image(systemName: "figure.2.and.child.holdinghands")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(AppColor.softRed)
                }

                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Family Care")
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.ink)

                    Text(memberCount == 0 ? "Add loved ones and keep their medicine routines close." : "\(memberCount) loved ones are in your care circle.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)

                    CapsuleButton("Add Member", systemImage: "person.badge.plus.fill", action: addAction)
                }
            }
        }
    }
}
