import SwiftData
import SwiftUI

struct MoreView: View {
    @State private var voiceDestination: MoreVoiceDestination?
    @State private var showPregnancyPlanning = false

    var body: some View {
        NavigationStack {
            MedicalBackgroundView {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Spacing.large) {
                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text("More")
                                .font(AppFont.display)
                                .foregroundStyle(AppColor.ink)

                            Text("Family care, women’s health, and profile settings in one calm place.")
                                .font(AppFont.body)
                                .foregroundStyle(AppColor.secondaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(spacing: Spacing.small) {
                            NavigationLink {
                                WomensHealthView()
                            } label: {
                                MoreDestinationRow(title: "Women’s Health", subtitle: "Cycle, symptoms, and daily logs", systemImage: "heart.circle.fill", color: AppColor.lavenderDeep)
                            }

                            Button {
                                showPregnancyPlanning = true
                            } label: {
                                MoreDestinationRow(title: "Pregnancy & Planning", subtitle: "Track your journey week by week", systemImage: PregnancyTheme.iconPregnant, color: PregnancyTheme.deepRose)
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                FamilyCareView()
                            } label: {
                                MoreDestinationRow(title: "Family Care", subtitle: "Loved ones, medicines, and monitoring", systemImage: "figure.2.and.child.holdinghands", color: AppColor.mintGreenDeep)
                            }

                            NavigationLink {
                                ProfileView()
                            } label: {
                                MoreDestinationRow(title: "Profile", subtitle: "Preferences, privacy, and haptics", systemImage: "person.crop.circle.fill", color: AppColor.medicalBlue)
                            }

                            NavigationLink {
                                HealthKitPermissionView()
                            } label: {
                                MoreDestinationRow(title: "Apple Health", subtitle: "Steps, sleep, heart rate, and wellness insights", systemImage: "heart.fill", color: AppColor.softRed)
                            }

                            NavigationLink {
                                AmbientIntelligenceView()
                            } label: {
                                MoreDestinationRow(title: "Ambient Intelligence", subtitle: "Local habit adaptation and quiet insights", systemImage: "sparkles.rectangle.stack.fill", color: AppColor.mintGreenDeep)
                            }

                            NavigationLink {
                                HealthMemoryIntelligenceView()
                            } label: {
                                MoreDestinationRow(title: "Health Memory", subtitle: "Private patterns, habits, and gentle insights", systemImage: "brain.head.profile", color: AppColor.medicalBlue)
                            }

                            NavigationLink {
                                DoctorVisitView()
                            } label: {
                                MoreDestinationRow(title: "Doctor Visit", subtitle: "Prepare and export a local medical summary", systemImage: "stethoscope.circle.fill", color: AppColor.medicalBlue)
                            }

                            NavigationLink {
                                DoctorReportPreviewView()
                            } label: {
                                MoreDestinationRow(title: "Doctor Report PDF", subtitle: "Preview, share, save, or print a doctor-friendly report", systemImage: "doc.richtext.fill", color: AppColor.medicalBlue)
                            }

                            NavigationLink {
                                PrescriptionScannerView()
                            } label: {
                                MoreDestinationRow(title: "Prescription Scanner", subtitle: "Create medicine drafts from prescription photos", systemImage: "text.viewfinder", color: AppColor.lavenderDeep)
                            }

                            #if DEBUG
                            NavigationLink {
                                InternalTestChecklistView()
                            } label: {
                                MoreDestinationRow(title: "Internal Test Checklist", subtitle: "Run real-device TestFlight smoke checks", systemImage: "checklist.checked", color: AppColor.mintGreenDeep)
                            }

                            NavigationLink {
                                AdaptiveReminderDebugView()
                            } label: {
                                MoreDestinationRow(title: "Adaptive Reminder Debug", subtitle: "Inspect local take patterns and follow-ups", systemImage: "bell.badge.waveform.fill", color: AppColor.medicalBlue)
                            }
                            #endif
                        }
                    }
                    .padding(Spacing.medium)
                    .padding(.bottom, 140)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $voiceDestination) { destination in
                destination.view
            }
            .sheet(isPresented: $showPregnancyPlanning) {
                PregnancyPlanningView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .voiceOpenPregnancyPlanning)) { _ in
                showPregnancyPlanning = true
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openWomensHealth)) { _ in
                voiceDestination = .womensHealth
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openAddPeriodLog)) { _ in
                voiceDestination = .addPeriodLog
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openCyclePrediction)) { _ in
                voiceDestination = .womensHealth
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openDoctorVisit)) { _ in
                voiceDestination = .doctorVisit
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openDoctorReport)) { _ in
                voiceDestination = .doctorReport
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openPrescriptionScanner)) { _ in
                voiceDestination = .prescriptionScanner
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openFamilyCare)) { _ in
                voiceDestination = .familyCare
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openProfile)) { _ in
                voiceDestination = .profile
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openHealthMemory)) { _ in
                voiceDestination = .healthMemory
            }
            .onReceive(NotificationCenter.default.publisher(for: VoiceNavigationNotification.openSettings)) { _ in
                voiceDestination = .profile
            }
        }
    }
}

private enum MoreVoiceDestination: Identifiable {
    case womensHealth
    case addPeriodLog
    case doctorVisit
    case doctorReport
    case prescriptionScanner
    case familyCare
    case profile
    case healthMemory

    var id: String {
        switch self {
        case .womensHealth: return "womensHealth"
        case .addPeriodLog: return "addPeriodLog"
        case .doctorVisit: return "doctorVisit"
        case .doctorReport: return "doctorReport"
        case .prescriptionScanner: return "prescriptionScanner"
        case .familyCare: return "familyCare"
        case .profile: return "profile"
        case .healthMemory: return "healthMemory"
        }
    }

    @ViewBuilder
    var view: some View {
        switch self {
        case .womensHealth:
            WomensHealthView()
        case .addPeriodLog:
            AddPeriodLogView()
        case .doctorVisit:
            DoctorVisitView()
        case .doctorReport:
            DoctorReportPreviewView()
        case .prescriptionScanner:
            PrescriptionScannerView()
        case .familyCare:
            FamilyCareView()
        case .profile:
            ProfileView()
        case .healthMemory:
            HealthMemoryIntelligenceView()
        }
    }
}

private struct MoreDestinationRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color

    var body: some View {
        PillCardContainer(padding: Spacing.medium) {
            HStack(spacing: Spacing.medium) {
                iconView

                VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                    Text(title)
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColor.tertiaryInk)
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if title == "Pregnancy & Planning" {
            ZStack {
                // Outer circle background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.85, blue: 0.88),
                                Color(red: 0.95, green: 0.78, blue: 0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)

                // Womb / belly icon with baby inside
                ZStack {
                    Circle()
                        .fill(
                            Color.white.opacity(0.48)
                        )
                        .frame(width: 34, height: 34)

                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.92, green: 0.42, blue: 0.62),
                                    Color(red: 0.76, green: 0.46, blue: 0.86)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 25, height: 31)
                        .rotationEffect(.degrees(-10))

                    Circle()
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 8, height: 8)
                        .offset(x: -3, y: -5)

                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 12, height: 7)
                        .rotationEffect(.degrees(-24))
                        .offset(x: 3, y: 4)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.55))
                        .offset(x: 9, y: -9)
                }
            }
            .frame(width: 56, height: 56)
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 56, height: 56)
                .background(color.opacity(0.13))
                .clipShape(Circle())
        }
    }
}

#Preview {
    MoreView()
        .modelContainer(SampleData.previewContainer)
}
