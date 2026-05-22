import Foundation
import UIKit

struct WhisperModelSelector {
    func selectedModelName(preferAccuracy: Bool = true) -> String {
        let physicalMemoryGB = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
        let processorCount = ProcessInfo.processInfo.processorCount
        let isCapable = physicalMemoryGB >= 5.5 && processorCount >= 6

        if preferAccuracy && isCapable {
            return "openai/whisper-base"
        }

        return "openai/whisper-tiny"
    }
}

