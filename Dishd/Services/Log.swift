import Foundation
import OSLog

/// `print` ships in release builds and lands in the device console, where it
/// can be read over a cable or scooped up in a sysdiagnose. Supabase errors
/// embed response bodies, so that's user data leaking into system logs.
///
/// `Logger` interpolation is `.private` by default — redacted as `<private>`
/// in release, still readable when debugging locally.
enum Log {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.noahtakashima.Dishd",
        category: "dishd"
    )

    /// Context is public so crash triage still tells you *where* it broke;
    /// the error body stays private.
    static func error(_ context: String, _ error: Error) {
        logger.error("\(context, privacy: .public): \(String(describing: error), privacy: .private)")
    }
}
