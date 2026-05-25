import Foundation
import SwiftData

enum AppModelContainerState {
    case loaded(ModelContainer)
    case failed(AppModelContainerLoadError)
}

struct AppModelContainerLoadError: Identifiable, Equatable {
    let id = UUID()
    let userMessage: String
    let debugDescription: String

    static func from(_ error: Error) -> AppModelContainerLoadError {
        AppModelContainerLoadError(
            userMessage: "We couldn't open your local health data safely.",
            debugDescription: String(describing: error)
        )
    }
}
