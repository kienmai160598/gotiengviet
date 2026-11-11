import Foundation
import VietKeyGrammar

/// Owns the Harper checker, shared by every input controller. Loading takes a few hundred ms,
/// so it starts at launch on a background thread, and checks never run on the main thread.
enum GrammarService {
    private static let checker = Task.detached(priority: .utility) { GrammarChecker() }
    private static let enabledKey = "VietKey.grammarEnabled"

    /// Harper takes about 200 MB of RAM, so it loads only when grammar checking is on.
    static func warmUp() {
        guard isEnabled else { return }
        _ = checker
    }

    @concurrent
    static func check(_ sentence: String) async throws -> [GrammarIssue] {
        try await checker.value.check(text: sentence)
    }

    /// Toggled from the input menu. On unless the user turned it off.
    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }
}
