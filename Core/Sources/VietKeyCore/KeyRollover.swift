/// Keeps keys in the order the fingers touched them. A touch keyboard types a key when the
/// finger lifts, but two thumbs overlap: "n" down, "j" down, "j" up, "n" up must type "nj".
/// So a finger landing on any key first types the key still held, as on iOS.
public struct KeyRollover<Key: Equatable> {
    private var held: Key?

    public init() {}

    /// A finger went down on a key that types when it lifts.
    public mutating func hold(_ key: Key) {
        held = key
    }

    /// A finger went down somewhere: the key still held, to be typed now.
    public mutating func interrupt() -> Key? {
        defer { held = nil }
        return held
    }

    /// The finger left `key`: false when the key was already typed by a later touch.
    public mutating func lift(_ key: Key) -> Bool {
        guard held == key else { return false }
        held = nil
        return true
    }
}
