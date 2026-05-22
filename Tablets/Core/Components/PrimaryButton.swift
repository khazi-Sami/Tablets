import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        CapsuleButton(title, systemImage: systemImage, isLoading: isLoading) {
            action()
        }
    }
}

#Preview {
    PrimaryButton("Add Medicine", systemImage: "plus") {}
        .padding()
}
