public enum InputKey: Sendable, Equatable {
    case character(Character)
    case backspace
    case escape
}

public enum CompositionUpdate: Sendable, Equatable {
    /// The word is still being typed; show `display` as composing (marked) text.
    case composing(display: String, raw: String)
    /// The word is final: insert `text`, then let the triggering key (if any) reach the app.
    case commit(text: String, raw: String)
    /// Undo the last boundary decision: if the text right before the caret is exactly
    /// `expected`, replace it with `replacement` and consume the key. If the adapter cannot
    /// verify or replace that text, it must treat the key as `passthrough`.
    case revert(expected: String, replacement: String)
    /// Not handled by the input method; the app should process the key itself.
    case passthrough
}
