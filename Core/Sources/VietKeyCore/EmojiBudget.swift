/// Says which emoji the touch keyboard may still draw. Drawing an emoji left about 50 KB in
/// the keyboard process that never came back (Debug simulator, leaving the page included),
/// and iOS ends a keyboard that passes its memory limit. So once little memory is left, only
/// emoji that were already drawn are shown.
public final class EmojiBudget {
    /// Bytes to keep free for typing. A guess: the limit on a device is not measured.
    public static let floor = 16 * 1024 * 1024

    private var drawn: Set<Character> = []
    private let available: () -> Int

    /// `available` gives the bytes left before the process's limit, 0 when it has none (what
    /// `os_proc_available_memory` returns in the simulator).
    public init(available: @escaping () -> Int) {
        self.available = available
    }

    public func allows(_ emoji: Character) -> Bool {
        if drawn.contains(emoji) { return true }
        let left = available()
        guard left == 0 || left > Self.floor else { return false }
        drawn.insert(emoji)
        return true
    }
}
