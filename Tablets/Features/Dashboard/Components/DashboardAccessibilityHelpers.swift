import SwiftUI

extension View {
    func elderlyScaled(_ isElderly: Bool) -> some View {
        dynamicTypeSize(isElderly ? .xxLarge ... .accessibility3 : .xSmall ... .accessibility3)
    }
}
