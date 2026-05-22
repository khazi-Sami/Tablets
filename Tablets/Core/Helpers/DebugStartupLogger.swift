import Foundation

enum DebugStartupLogger {
    #if DEBUG
    private static let bootDate = Date()
    #endif

    static func log(_ message: String) {
        #if DEBUG
        let elapsed = Date().timeIntervalSince(bootDate)
        print("[StartupDebug +\(String(format: "%.3f", elapsed))s] \(message)")
        #endif
    }
}
