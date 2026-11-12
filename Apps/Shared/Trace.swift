import os

/// Diagnostic trace for input method and keyboard behaviour. Compiled only into Debug builds, so release builds
/// never log keystrokes. Read live with:
/// log stream --level debug --predicate 'subsystem == "dev.vietkey.inputmethod"'
enum Trace {
    private static let logger = Logger(subsystem: "dev.vietkey.inputmethod", category: "trace")

    static func log(_ message: @autoclosure () -> String) {
        #if DEBUG
        let text = message()
        logger.debug("\(text, privacy: .public)")
        #endif
    }

    /// Runs `work` and logs how long it took.
    static func measure<T>(_ label: @autoclosure () -> String, _ work: () -> T) -> T {
        #if DEBUG
        let start = ContinuousClock.now
        let result = work()
        let elapsed = start.duration(to: .now)
        log("\(label()) took \(elapsed.formatted(.units(allowed: [.milliseconds], fractionalPart: .show(length: 2))))")
        return result
        #else
        return work()
        #endif
    }
}
