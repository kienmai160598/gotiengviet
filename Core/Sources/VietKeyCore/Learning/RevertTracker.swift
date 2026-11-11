/// Follows one Backspace revert from offer to lesson:
/// 1. A boundary replaced the shown Vietnamese with the raw keys, so a revert is offered.
/// 2. Backspace as the very next key hands it to the adapter.
/// 3. The adapter confirms it could apply it.
/// 4. The key after that decides. Another Backspace means the word is being deleted, so
///    nothing is learned; any other key keeps the Vietnamese for those keys from then on.
struct RevertTracker: Sendable {
    private var offered: Revertible?
    private var handedOver: Revertible?
    private var applied: Revertible?

    mutating func offer(_ revert: Revertible) {
        offered = revert
    }

    /// Call first for every key. `handOver` is the revert to give the adapter when the key is
    /// Backspace; `kept` is an applied revert this key confirmed as the user's choice.
    mutating func take(for key: InputKey) -> (handOver: Revertible?, kept: Revertible?) {
        let kept = key == .backspace ? nil : applied
        handedOver = key == .backspace ? offered : nil
        offered = nil
        applied = nil
        return (handedOver, kept)
    }

    mutating func confirm() {
        applied = handedOver
        handedOver = nil
    }

    mutating func cancelOffer() {
        offered = nil
    }
}

struct Revertible: Sendable {
    let keys: String
    /// The committed word plus the boundary the app inserted after it.
    let inserted: String
    let shown: String
}
