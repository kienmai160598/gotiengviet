/// Lets Backspace over a word's boundary reopen the word, so "hoa ⌫f" gives "hòa":
/// 1. A boundary committed the word as it was shown, so a resume is offered.
/// 2. Backspace as the very next key hands it to the adapter, which removes the word and its
///    boundary and shows the word as composing text again.
/// 3. The adapter confirms, and only then does the session take the word back.
struct ResumeTracker: Sendable {
    private var offered: Resumable?
    private var handedOver: Resumable?

    mutating func offer(_ resume: Resumable) {
        offered = resume
    }

    /// Call first for every key; returns the resume to give the adapter when the key is Backspace.
    mutating func take(for key: InputKey) -> Resumable? {
        handedOver = key == .backspace ? offered : nil
        offered = nil
        return handedOver
    }

    mutating func confirm() -> Resumable? {
        defer { handedOver = nil }
        return handedOver
    }

    mutating func cancelOffer() {
        offered = nil
    }
}

struct Resumable: Sendable {
    let composition: Composition
    /// The context from before the word was committed, so it does not count twice.
    let context: LanguageContext
    let shown: String
    /// The committed word plus the boundary the app inserted after it.
    let inserted: String
}
