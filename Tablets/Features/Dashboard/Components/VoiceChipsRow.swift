import SwiftUI

struct VoiceChipsRow: View {
    let chips: [VoiceChip]
    let isElderlyMode: Bool
    let onTap: (VoiceChip) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(chips) { chip in
                    Button {
                        onTap(chip)
                    } label: {
                        Label(chip.label, systemImage: "mic.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColor.medicalBlueDeep)
                            .padding(.horizontal, 14)
                            .frame(minHeight: isElderlyMode ? 52 : 44)
                            .background(AppColor.medicalBlue.opacity(0.10))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Voice command \(chip.label)")
                }
            }
            .padding(.vertical, 2)
        }
    }
}
