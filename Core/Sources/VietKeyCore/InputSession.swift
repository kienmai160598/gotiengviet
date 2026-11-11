/// Platform-agnostic typing session. Adapters (IMKit on macOS, keyboard extension on iOS)
/// feed keys in and render the returned updates. Every call is synchronous and cheap.
public struct InputSession: Sendable {
    private var composition: Composition
    private let style: ToneStyle
    private let lexicon: any EnglishLexicon
    /// Set when a boundary key changed the shown word, valid only for the very next key.
    private var revertible: Revertible?

    public init(style: ToneStyle = .traditional, lexicon: any EnglishLexicon) {
        self.style = style
        self.lexicon = lexicon
        composition = Composition(style: style)
        SyllablePrefixes.warmUp()
    }

    public var isComposing: Bool { !composition.isEmpty }

    public mutating func handle(_ key: InputKey) -> CompositionUpdate {
        let pendingRevert = revertible
        revertible = nil
        switch key {
        case .character(let char) where char.isASCII && char.isLetter:
            composition.type(char)
            return composingUpdate
        case .character(let boundary):
            return finishWord(boundary: boundary)
        case .backspace:
            guard isComposing else {
                return pendingRevert.map { .revert(expected: $0.inserted, replacement: $0.shown) } ?? .passthrough
            }
            deleteBackward()
            return composingUpdate
        case .escape:
            guard isComposing else { return .passthrough }
            let raw = composition.raw
            reset()
            return .commit(text: raw, raw: raw)
        }
    }

    /// Ends the current word without a boundary key, e.g. on Return, a focus change or a
    /// caret jump. Nothing typed afterwards can revert it.
    public mutating func commit() -> CompositionUpdate {
        revertible = nil
        return finishWord(boundary: nil)
    }

    /// Commits the word. When the shown Vietnamese gave way to the raw keys ("Đắk" became
    /// "DDawks"), Backspace right after the boundary brings back what was shown.
    private mutating func finishWord(boundary: Character?) -> CompositionUpdate {
        guard isComposing else { return .passthrough }
        let raw = composition.raw
        let text = resolve(composition, isFinal: true)
        let wasShowingVietnamese = resolve(composition, isFinal: false) != raw
        if let boundary, wasShowingVietnamese, text == raw {
            revertible = Revertible(inserted: text + String(boundary), shown: composition.spelledText)
        }
        reset()
        return .commit(text: text, raw: raw)
    }

    /// Decides what the user sees, on every key, so the marked text always shows what a
    /// word boundary would insert.
    /// - While typing, Vietnamese stays as long as more keys could still make a real syllable;
    ///   once that is impossible the keys as typed are shown ("goog", not "gôg").
    /// - On commit, Vietnamese is kept only when it is a real syllable ("tẽt" becomes "text").
    /// - After a double-key undo the user has taken manual control, so the shown text stands
    ///   ("tesst" gives "test"), unless the raw keys are an English word ("class", "coffee").
    private func resolve(_ composition: Composition, isFinal: Bool) -> String {
        let display = isFinal ? composition.spelledText : composition.text
        let raw = composition.raw
        if display == raw { return display }
        if composition.isLiteral { return isEnglishWord(raw) ? raw : display }
        let isVietnamese = isFinal ? composition.isValidVietnamese : composition.canBecomeVietnamese
        return isVietnamese ? display : raw
    }

    /// When the typed keys are on screen, Backspace removes the last key and re-decides, so
    /// "googl" goes back to "goog". Otherwise it removes the last letter and keeps the tone.
    private mutating func deleteBackward() {
        let isShowingRaw = composition.text != composition.raw
            && resolve(composition, isFinal: false) == composition.raw
        if isShowingRaw {
            composition = Composition(style: style, keys: composition.raw.dropLast())
        } else {
            composition.deleteBackward()
        }
    }

    /// Spell checkers accept any all-caps string as an acronym, so "CASSE" is judged as "casse".
    private func isEnglishWord(_ word: String) -> Bool {
        let isAllCaps = word == word.uppercased() && word != word.lowercased()
        return lexicon.contains(isAllCaps ? word.lowercased() : word)
    }

    private var composingUpdate: CompositionUpdate {
        .composing(display: resolve(composition, isFinal: false), raw: composition.raw)
    }

    private mutating func reset() {
        composition = Composition(style: style)
    }
}

private struct Revertible: Sendable {
    /// The committed word plus the boundary the app inserted after it.
    let inserted: String
    let shown: String
}
