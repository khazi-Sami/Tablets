import SwiftUI
import UIKit

extension View {
    func dismissKeyboardOnTap() -> some View {
        background(KeyboardDismissTapCatcher())
    }
}

private struct KeyboardDismissTapCatcher: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.attachIfNeeded(from: uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var window: UIWindow?
        private var recognizer: UITapGestureRecognizer?

        func attachIfNeeded(from view: UIView) {
            guard let window = view.window, self.window !== window else { return }
            detach()

            let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            window.addGestureRecognizer(recognizer)

            self.window = window
            self.recognizer = recognizer
        }

        func detach() {
            if let recognizer, let window {
                window.removeGestureRecognizer(recognizer)
            }
            recognizer = nil
            window = nil
        }

        @objc func handleTap() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let touchedView = touch.view else { return true }
            return touchedView.isKeyboardDismissCandidate
        }
    }
}

private extension UIView {
    var isKeyboardDismissCandidate: Bool {
        if self is UIControl || self is UITextField || self is UITextView {
            return false
        }
        if String(describing: type(of: self)).contains("TextField") {
            return false
        }
        return superview?.isKeyboardDismissCandidate ?? true
    }
}
