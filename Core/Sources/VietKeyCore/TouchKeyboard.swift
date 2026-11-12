/// What a touch keyboard can do to the document it types into. Mirrors UITextDocumentProxy,
/// which, unlike a Mac input method, cannot replace a range: it only deletes backward.
public protocol TextDocument {
    /// Committed text before the caret, as much as the app shares; nil when it shares none.
    var textBeforeCaret: String? { get }
    func setMarkedText(_ text: String)
    func unmarkText()
    func insertText(_ text: String)
    func deleteBackward()
}

public enum TouchKey: Sendable, Equatable {
    case character(Character)
    case backspace
    case newline
    /// Commits the keys as typed instead of the Vietnamese shown, like Esc on a Mac.
    case keepAsTyped
}

/// Feeds touch keys to an `InputSession` and applies its updates to a document. On a Mac the
/// app types every key the session lets through; a touch keyboard is the only source of keys,
/// so it types them itself.
public struct TouchKeyboard: Sendable {
    private var session: InputSession
    /// The word being typed, as shown and as typed: "cả" from "car".
    public private(set) var word: (shown: String, keys: String)?

    /// The keys as typed while the word on screen shows something else ("car" while "cả"
    /// shows), so the keyboard can offer to keep them.
    public var typedKeys: String? {
        word.flatMap { $0.shown == $0.keys ? nil : $0.keys }
    }

    public init(session: InputSession) {
        self.session = session
    }

    public var isComposing: Bool { session.isComposing }

    public mutating func press(_ key: TouchKey, in document: some TextDocument) {
        let typeKey = { Self.type(key, in: document) }
        switch key {
        case .character(let char): apply(session.handle(.character(char)), in: document, then: typeKey)
        case .backspace: apply(session.handle(.backspace), in: document, then: typeKey)
        case .newline: apply(session.commit(), in: document, then: typeKey)
        case .keepAsTyped: apply(session.handle(.escape), in: document) {}
        }
    }

    /// Ends the word being typed, e.g. when the keyboard hides or the caret moves.
    public mutating func endWord(in document: some TextDocument) {
        apply(session.commit(), in: document) {}
    }

    /// Forgets the word being typed without writing it, when the app changed the document
    /// itself (a chat app sent and cleared it), so the next key does not bring the word back.
    public mutating func dropWord() {
        _ = session.commit()
        word = nil
    }

    /// Puts a marked word chosen from the bar, and a space, in place of the word being typed.
    public mutating func replaceWord(with chosen: String, in document: some TextDocument) {
        guard word != nil else { return }
        session.replaceWithVietnamese()
        word = nil
        document.insertText(chosen + " ") // Replaces the marked text.
    }

    /// `typeKey` runs when the key itself must reach the document: after a word is committed
    /// by a boundary key, and whenever the session does not handle the key.
    private mutating func apply(_ update: CompositionUpdate, in document: some TextDocument, then typeKey: () -> Void) {
        word = nil
        switch update {
        case .composing(let display, let raw):
            word = display.isEmpty ? nil : (display, raw)
            document.setMarkedText(display)
            if display.isEmpty { document.unmarkText() }
        case .commit(let text, _):
            document.insertText(text) // Replaces the marked text.
            typeKey()
        case .revert(let expected, let replacement):
            guard document.textBeforeCaret?.hasSuffix(expected) == true else { return typeKey() }
            expected.forEach { _ in document.deleteBackward() }
            document.insertText(replacement)
            session.confirmRevert()
        case .resume(let expected, let display, let raw):
            guard document.textBeforeCaret?.hasSuffix(expected) == true else { return typeKey() }
            expected.forEach { _ in document.deleteBackward() }
            word = (display, raw)
            document.setMarkedText(display)
            session.confirmResume()
        case .passthrough:
            typeKey()
        }
    }

    private static func type(_ key: TouchKey, in document: some TextDocument) {
        switch key {
        case .character(let char): document.insertText(String(char))
        case .backspace: document.deleteBackward()
        case .newline: document.insertText("\n")
        case .keepAsTyped: break
        }
    }
}
