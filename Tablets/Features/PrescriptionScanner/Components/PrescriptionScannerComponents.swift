import SwiftUI

struct PrescriptionScanFrameView: View {
    @State private var scanLine = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous)
                .stroke(AppColor.medicalBlue.opacity(0.46), lineWidth: 2)
                .background(AppColor.cream.opacity(0.42))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.large, style: .continuous))

            VStack {
                Capsule()
                    .fill(AppGradient.primaryButton)
                    .frame(height: 4)
                    .shadow(color: AppColor.medicalBlue.opacity(0.40), radius: 10)
                    .offset(y: scanLine ? 86 : -86)
                    .animation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true), value: scanLine)
            }
            .padding(.horizontal, Spacing.large)

            VStack(spacing: Spacing.small) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(AppColor.medicalBlue)
                Text("Place prescription inside frame")
                    .font(AppFont.bodyStrong)
                    .foregroundStyle(AppColor.ink)
                Text("You can adjust in the camera scanner before confirming.")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryInk)
            }
        }
        .frame(height: 230)
        .onAppear { scanLine = true }
    }
}

struct PrescriptionConfidenceBadge: View {
    let confidence: PrescriptionMedicineDraft.Confidence

    var body: some View {
        Text(confidence.title)
            .font(AppFont.badge)
            .foregroundStyle(confidence.color)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(confidence.color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct PrescriptionDraftCard: View {
    @Binding var draft: PrescriptionMedicineDraft

    var body: some View {
        PillCardContainer {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack {
                    Text("Medicine draft")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(AppColor.ink)
                    Spacer()
                    PrescriptionConfidenceBadge(confidence: draft.confidence)
                }

                draftField("Medicine name", text: $draft.name)
                draftField("Dosage", text: $draft.dosage)
                draftField("Timing", text: $draft.timing)
                draftField("Duration", text: $draft.duration)

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Food instruction")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.secondaryInk)
                    HStack {
                        ForEach(MedicineInstruction.allCases) { instruction in
                            Button {
                                draft.instruction = instruction
                            } label: {
                                Text(instruction.title)
                                    .font(AppFont.badge)
                                    .foregroundStyle(draft.instruction == instruction ? .white : AppColor.medicalBlueDeep)
                                    .padding(.horizontal, Spacing.small)
                                    .frame(minHeight: 36)
                                    .background(draft.instruction == instruction ? AppColor.medicalBlue : AppColor.medicalBlue.opacity(0.10))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Text("Original line: \(draft.notes)")
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.tertiaryInk)
                    .lineLimit(3)
            }
        }
    }

    private func draftField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(AppColor.secondaryInk)
            TextField(title, text: text)
                .font(AppFont.bodyStrong)
                .padding(Spacing.small)
                .background(AppColor.cream.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous))
        }
    }
}
