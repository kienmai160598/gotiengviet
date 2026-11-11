import Cocoa
import InputMethodKit
import VietKeyCore

/// IMKit adapter: one controller per client text view. The word being typed lives in
/// marked text, so restoring English on commit never needs synthetic backspaces.
@objc(VietKeyInputController)
final class VietKeyInputController: IMKInputController {
    private var session = InputSession(lexicon: SpellCheckerLexicon())
    private static let noReplacement = NSRange(location: NSNotFound, length: 0)

    override func recognizedEvents(_ sender: Any!) -> Int {
        Int(NSEvent.EventTypeMask.keyDown.rawValue)
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event, event.type == .keyDown, let client = sender as? IMKTextInput else { return false }
        let action = KeyEventMapper.action(for: event)
        let consumed = Trace.measure(
            "key \(event.keyCode) \(action) repeat=\(event.isARepeat) t=\(event.timestamp) in \(client.bundleIdentifier() ?? "?")"
        ) {
            switch action {
            case .session(let key):
                return render(session.handle(key), to: client, consumesKey: key == .escape)
            case .commitThenPassthrough:
                render(session.commit(), to: client, consumesKey: false)
                return false
            }
        }
        Trace.log("  consumed=\(consumed) marked=\(client.markedRange()) selected=\(client.selectedRange())")
        return consumed
    }

    override func commitComposition(_ sender: Any!) {
        guard let client = sender as? IMKTextInput else { return }
        Trace.log("commitComposition requested by \(client.bundleIdentifier() ?? "?")")
        render(session.commit(), to: client, consumesKey: false)
    }

    override func deactivateServer(_ sender: Any!) {
        commitComposition(sender)
        super.deactivateServer(sender)
    }

    /// Returns whether the key event was consumed. After a commit, boundary keys
    /// (space, punctuation) still reach the app so it inserts them itself.
    @discardableResult
    private func render(_ update: CompositionUpdate, to client: IMKTextInput, consumesKey: Bool) -> Bool {
        Trace.log("  render \(update)")
        switch update {
        case .composing(let display, _):
            let caret = NSRange(location: display.utf16.count, length: 0)
            client.setMarkedText(display, selectionRange: caret, replacementRange: Self.noReplacement)
            return true
        case .commit(let text, _):
            client.insertText(text, replacementRange: Self.noReplacement)
            return consumesKey
        case .revert(let expected, let replacement):
            return TextReplacer.replace(expected, with: replacement, in: client)
        case .passthrough:
            return false
        }
    }
}
