import Foundation

enum DiscoveryDiagnostics {
    /// Local debug console only; never logs credentials or full library records.
    static func log(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("[HomeDiscovery] \(message())")
        #endif
    }
}
