import HealthKit
import SwiftUI

struct HealthKitPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(UserHealthProfile.healthKitWriteEnabledKey) private var writeEnabled = false
    @State private var service = HealthKitService()
    @State private var isRequesting = false
    @State private var isShowingPermissionsHelp = false

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        if !service.isAvailable {
                            unavailableMessage
                        }
                        HealthKitStatusCard(
                            status: service.isAvailable ? (service.isAuthorized ? .connected : .notConnected) : .unavailable,
                            lastSyncAt: nil,
                            isWriteSyncEnabled: writeEnabled,
                            manageAction: { isShowingPermissionsHelp.toggle() }
                        )
                        privacySection
                        permissionSection(title: "What Tablets reads", rows: readRows)
                        permissionSection(title: "What Tablets can write", rows: writeRows)

                        Toggle("Automatically save readings to Apple Health", isOn: $writeEnabled)
                            .font(AppFont.bodyStrong)
                            .tint(AppColor.medicalBlue)
                            .padding(16)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .disabled(!service.isAvailable)

                        CapsuleButton(isRequesting ? "Connecting..." : "Connect Apple Health", systemImage: "heart.fill") {
                            Task { await connect() }
                        }
                        .disabled(isRequesting || !service.isAvailable)
                        .frame(minHeight: 52)

                        Button("Not now") {
                            dismiss()
                        }
                        .font(AppFont.bodyStrong)
                        .frame(maxWidth: .infinity, minHeight: 44)

                        permissionsHelpCard
                    }
                    .padding(Spacing.medium)
                }
            }
            .navigationTitle("Apple Health")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                service.refreshAuthorizationStatus()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "heart.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(AppColor.softRed)
            Text("Apple Health Connection")
                .font(AppFont.title)
                .foregroundStyle(AppColor.ink)
            Text("Tablets combines your Apple Health data with your medicine and health logs for wellness insights and clearer voice answers.")
                .font(AppFont.body)
                .foregroundStyle(AppColor.secondaryInk)
            Text("Your Apple Health data stays on your device and is only used with your permission.")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var unavailableMessage: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text("Apple Health is not available on this device.")
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.ink)
                Text("You can keep using Tablets with your saved medicine and health logs.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }
        } icon: {
            Image(systemName: "heart.slash.fill")
                .foregroundStyle(AppColor.secondaryInk)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("What stays private", systemImage: "lock.shield.fill")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.ink)
            Text("Your Apple Health data stays on your device. iOS controls every permission, and you can change access anytime in Apple Health settings.")
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var readRows: [PermissionRow] {
        [
            PermissionRow(icon: "figure.walk", name: "Steps", description: "Daily activity"),
            PermissionRow(icon: "bed.double.fill", name: "Sleep", description: "Sleep duration and quality"),
            PermissionRow(icon: "heart.text.square.fill", name: "Heart Rate", description: "Resting and active heart rate"),
            PermissionRow(icon: "lungs.fill", name: "Oxygen", description: "Blood oxygen levels"),
            PermissionRow(icon: "scalemass.fill", name: "Weight", description: "Body weight history")
        ]
    }

    private var writeRows: [PermissionRow] {
        [
            PermissionRow(icon: "waveform.path.ecg", name: "Blood Pressure", description: "Save to Apple Health"),
            PermissionRow(icon: "drop.fill", name: "Blood Sugar", description: "Save to Apple Health"),
            PermissionRow(icon: "scalemass.fill", name: "Weight", description: "Save to Apple Health"),
            PermissionRow(icon: "thermometer.medium", name: "Temperature", description: "Save to Apple Health"),
            PermissionRow(icon: "lungs.fill", name: "Oxygen", description: "Save to Apple Health"),
            PermissionRow(icon: "heart.fill", name: "Heart Rate", description: "Save to Apple Health")
        ]
    }

    private func permissionSection(title: String, rows: [PermissionRow]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.ink)
            ForEach(rows) { row in
                HStack(spacing: 12) {
                    Image(systemName: row.icon)
                        .foregroundStyle(AppColor.medicalBlue)
                        .frame(width: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.name)
                            .font(AppFont.bodyStrong)
                            .foregroundStyle(AppColor.ink)
                        Text(row.description)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryInk)
                    }
                    Spacer()
                    Text(service.isAuthorized ? "Connected" : "Not connected")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(service.isAuthorized ? AppColor.mintGreenDeep : AppColor.secondaryInk)
                }
                .frame(minHeight: 44)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var permissionsHelpCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                isShowingPermissionsHelp.toggle()
            } label: {
                Label("How to manage Apple Health permissions", systemImage: "questionmark.circle.fill")
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.medicalBlueDeep)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .buttonStyle(.plain)

            if isShowingPermissionsHelp {
                Text("Open the iOS Health app, tap your profile picture, choose Apps and Services, then Tablets. You can turn individual read and write permissions on or off there.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func connect() async {
        isRequesting = true
        let granted = await service.requestAuthorization()
        UserHealthProfile.healthKitEnabled = granted
        isRequesting = false
    }
}

private struct PermissionRow: Identifiable {
    let id = UUID()
    let icon: String
    let name: String
    let description: String
}
