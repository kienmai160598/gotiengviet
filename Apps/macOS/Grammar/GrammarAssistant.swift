import Cocoa
import InputMethodKit
import os
import VietKeyCore
import VietKeyGrammar

/// Checks each English sentence the user finishes and offers fixes in a panel under it.
/// The sentence is read back from the document, and read again before a fix is written,
/// because apps rewrite what they receive (smart quotes, autocorrect) and the input method
/// never sees mouse clicks or edits made elsewhere.
@MainActor
final class GrammarAssistant {
    private static let lookBehind = 600
    private static let logger = Logger(subsystem: "dev.vietkey.inputmethod", category: "grammar")
    private var followsTerminator = false
    private var pendingCheck: Task<Void, Never>?
    private var suggestions: [GrammarSuggestion] = []
    private weak var controller: VietKeyInputController?

    nonisolated init() {}

    /// Call after each key with the character it put into the document, or nil when it put in
    /// none or something unknown (Backspace, a shortcut, a consumed key). The app has not
    /// inserted the character yet, so the caret still sits right after the previous one.
    func keyReachedDocument(_ char: Character?, client: IMKTextInput, controller: VietKeyInputController) {
        defer { followsTerminator = char.map(SentenceFinder.terminators.contains) ?? false }
        // Whitespace after the terminator, so "example.com" and "3.14" do not end a sentence.
        guard followsTerminator, let char, char.isWhitespace, GrammarService.isEnabled else { return }
        checkSentence(endingAtCaretOf: client, controller: controller)
    }

    /// The text view lost focus. Clicking the card can cause that too, so the card stays while
    /// the pointer is on it.
    func focusLeft() {
        guard !SuggestionPanel.shared.containsMouse else { return }
        dismiss()
    }

    /// Drops every suggestion, e.g. when checking is turned off.
    func dismiss() {
        pendingCheck?.cancel()
        suggestions = []
        SuggestionPanel.shared.hide()
    }

    private func checkSentence(endingAtCaretOf client: IMKTextInput, controller: VietKeyInputController) {
        let caret = client.selectedRange()
        guard caret.location != NSNotFound, caret.length == 0 else { return }
        let start = max(0, caret.location - Self.lookBehind)
        let before = TextReplacer.read(NSRange(location: start, length: caret.location - start), from: client)
        let found = before.flatMap { SentenceFinder.lastSentence(in: $0, reachesDocumentStart: start == 0) }
        Trace.log("  grammar trigger sentence=\(found?.text ?? "nil")")
        guard let found, SharedModels.frequencies.looksEnglish(found.text) else { return }
        self.controller = controller
        pendingCheck?.cancel()
        pendingCheck = Task { await check(found.text, at: start + found.offset) }
    }

    private func check(_ sentence: String, at sentenceStart: Int) async {
        let issues: [GrammarIssue]
        do {
            issues = try await GrammarService.check(sentence)
        } catch {
            // Only the type: a Rust panic message could quote the sentence.
            Self.logger.error("Grammar check failed: \(String(describing: type(of: error)), privacy: .public)")
            return
        }
        guard !Task.isCancelled else { return }
        Trace.log("  grammar \(issues.count) issues in \"\(sentence)\"")
        suggestions = issues.compactMap {
            GrammarSuggestion(in: sentence, sentenceStart: sentenceStart, offset: Int($0.location),
                              length: Int($0.length), replacements: $0.replacements, message: $0.message,
                              category: $0.category)
        }
        let range = NSRange(location: sentenceStart, length: sentence.utf16.count)
        guard let client = controller?.client(), TextReplacer.read(range, from: client) == sentence else {
            Trace.log("  grammar sentence moved before results arrived")
            return dismiss()
        }
        show(in: client)
    }

    private func show(in client: IMKTextInput) {
        guard let first = suggestions.first else { return SuggestionPanel.shared.hide() }
        let line = TextGeometry.rect(of: NSRange(location: first.location, length: first.length), in: client)
        Trace.log("  grammar card under \(line)")
        guard line != .zero else { return SuggestionPanel.shared.hide() }
        SuggestionPanel.shared.show(
            suggestions, below: line,
            choose: { [weak self] in self?.apply($0, $1) },
            ignore: { [weak self] in self?.ignore($0) },
            close: { [weak self] in self?.dismiss() }
        )
    }

    private func ignore(_ suggestion: GrammarSuggestion) {
        suggestions.removeAll { $0 == suggestion }
        guard let client = controller?.client() else { return dismiss() }
        show(in: client)
    }

    /// Writes the fix only if the original text is still where it was checked.
    private func apply(_ suggestion: GrammarSuggestion, _ replacement: String) {
        guard let controller, let client = controller.client() else {
            Trace.log("  grammar fix dropped: no client")
            return dismiss()
        }
        Trace.log("  grammar fix \(suggestion.original) -> \(replacement)")
        controller.commitComposition(client)
        guard TextReplacer.replace(suggestion.original, at: suggestion.location, with: replacement, in: client) else {
            Trace.log("  grammar fix refused: text changed")
            return dismiss()
        }
        suggestions = suggestions.applying(suggestion, replacement: replacement)
        show(in: client)
    }
}
