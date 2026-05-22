import SwiftUI

enum AppShadow {
    static let soft = ShadowStyle(color: AppColor.medicalBlue.opacity(0.10), radius: 18, x: 0, y: 8)
    static let pill = ShadowStyle(color: AppColor.medicalBlue.opacity(0.14), radius: 14, x: 0, y: 7)
    static let button = ShadowStyle(color: AppColor.mintGreenDeep.opacity(0.26), radius: 16, x: 0, y: 8)
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    func appShadow(_ style: ShadowStyle = AppShadow.soft) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
