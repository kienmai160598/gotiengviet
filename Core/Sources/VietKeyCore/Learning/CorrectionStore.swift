import Synchronization

/// What the user chose last time they corrected a word typed with these keys.
public enum CorrectionPreference: String, Sendable {
    /// Keep the keys as typed ("is", not "í").
    case typedKeys
    /// Keep the Vietnamese rendering, even if the rules would restore the keys.
    case vietnamese
}

/// Remembers corrections per typed key sequence, case-insensitively. Lookups happen on every
/// keystroke, so implementations must answer from memory.
public protocol CorrectionStore: Sendable {
    func preference(for keys: String) -> CorrectionPreference?
    func record(_ preference: CorrectionPreference, for keys: String)
    func forgetAll()
}

/// Non-persistent store, for tests and previews.
public final class InMemoryCorrectionStore: CorrectionStore {
    private let entries = Mutex<[String: CorrectionPreference]>([:])

    public init() {}

    public func preference(for keys: String) -> CorrectionPreference? {
        entries.withLock { $0[keys.lowercased()] }
    }

    public func record(_ preference: CorrectionPreference, for keys: String) {
        entries.withLock { $0[keys.lowercased()] = preference }
    }

    public func forgetAll() {
        entries.withLock { $0.removeAll() }
    }
}
