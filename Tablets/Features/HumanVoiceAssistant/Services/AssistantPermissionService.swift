import AVFoundation
import Foundation

@MainActor
struct AssistantPermissionService {
    func microphoneStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }

    func requestMicrophoneAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    var permissionMessage: String {
        "Microphone access lets Tablets understand health commands you speak. Audio is processed locally for the voice assistant, and your health data is saved only on this device."
    }
}
