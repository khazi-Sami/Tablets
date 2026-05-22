import SwiftUI

enum AppFont {
    static let display = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let title = Font.system(.title2, design: .rounded).weight(.bold)
    static let sectionTitle = Font.system(.title3, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .rounded).weight(.regular)
    static let bodyStrong = Font.system(.body, design: .rounded).weight(.semibold)
    static let caption = Font.system(.callout, design: .rounded).weight(.regular)
    static let badge = Font.system(.caption, design: .rounded).weight(.bold)
    static let button = Font.system(.headline, design: .rounded).weight(.bold)
}
