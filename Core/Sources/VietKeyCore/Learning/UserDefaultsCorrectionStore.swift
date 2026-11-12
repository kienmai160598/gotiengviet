import Foundation
import Synchronization

/// Persists corrections in UserDefaults. Reads come from an in-memory copy loaded once.
public final class UserDefaultsCorrectionStore: CorrectionStore {
    private static let key = "VietKey.corrections"
    /// Apple documents UserDefaults as thread-safe; the SDK just doesn't mark it Sendable.
    private nonisolated(unsafe) let defaults: UserDefaults
    private let cache: Mutex<[String: CorrectionPreference]>

    public init(defaults: UserDefaults) {
        self.defaults = defaults
        let stored = defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:]
        cache = Mutex(stored.compactMapValues(CorrectionPreference.init(rawValue:)))
    }

    public func preference(for keys: String) -> CorrectionPreference? {
        cache.withLock { $0[keys.lowercased()] }
    }

    public func record(_ preference: CorrectionPreference, for keys: String) {
        let snapshot = cache.withLock { entries in
            entries[keys.lowercased()] = preference
            return entries
        }
        defaults.set(snapshot.mapValues(\.rawValue), forKey: Self.key)
    }

    public func forgetAll() {
        cache.withLock { $0.removeAll() }
        defaults.removeObject(forKey: Self.key)
    }
}
