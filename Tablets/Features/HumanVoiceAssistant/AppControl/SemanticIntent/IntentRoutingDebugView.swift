import SwiftUI

#if DEBUG
struct IntentRoutingDebugView: View {
    let transcript: String
    let selectedIntent: String
    let confidence: Double
    let needsConfirmation: Bool
    let matchedExample: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("Intent Debug").font(AppFont.sectionTitle)
            Text("Transcript: \(transcript)")
            Text("Intent: \(selectedIntent)")
            Text("Confidence: \(confidence.formatted(.number.precision(.fractionLength(2))))")
            Text("Confirmation: \(needsConfirmation ? "Yes" : "No")")
            Text("Matched: \(matchedExample ?? "--")")
        }
        .font(AppFont.caption)
        .padding()
    }
}
#endif
