import Cocoa
import InputMethodKit
import os
import VietKeyCore
import VietKeyGrammar

/// Checks the English sentence at the caret once typing pauses and offers fixes in a card
/// under it. Waiting for a pause keeps the card from flashing mid-typing, and still checks a
/// chat message before Return sends it. The sentence is read back from the document, and read
/// again before a fix is written, because apps rewrite what they receive (smart quotes,
/// autocorrect) and the input method never sees mouse clicks or edits made elsewhere.
@MainActor
final class GrammarAssistant {
    /// Untuned: long enough not to check every word, short enough to beat a send.
    private static let pause: Duration = .seconds(1)
    private static let lookBehind = 600
    private static let logger = Logger(subsystem: "dev.vietkey.inputmethod", category: "grammar")
    private var pendingCheck: Task<Void, Never>?
    private var suggestions: [GrammarSuggestion] = []
    /// Ignored or closed problems, so the next pause does not bring them back.
    private var ignored: Set<String> = []
    private weak var controller: VietKeyInputController?

    nonisolated init() {}

    /// Call on every key: hides the card and waits for typing to pause.
    func keyPressed(controller: VietKeyInputController) {
        hide()
        guard GrammarService.isEnabled else { return }
        self.controller = controller
        pendingCheck = Task {
            do {
                try await Task.sleep(for: Self.pause)
            } catch {
                return // Cancelled: a newer key restarted the wait.
            }
            checkSentenceAtCaret()
        }
    }

    /// The text view lost focus. Clicking the card can cause that too, so the card stays while
    /// the pointer is on it.
    func focusLeft() {
        guard !SuggestionPanel.shared.containsMouse else { return }
        dismiss()
    }

    /// Drops every suggestion, e.g. when checking is turned off.
    func dismiss() {
        hide()
        ignored = []
    }

    private func hide() {
        pendingCheck?.cancel()
        suggestions = []
        SuggestionPanel.shared.hide()
    }

    private func checkSentenceAtCaret() {
        guard let client = controller?.client(), let end = Self.committedEnd(in: client) else { return }
        let start = max(0, end - Self.lookBehind)
        let before = TextReplacer.read(NSRange(location: start, length: end - start), from: client)
        let found = before.flatMap { SentenceFinder.lastSentence(in: $0, reachesDocumentStart: start == 0) }
        Trace.log("  grammar pause sentence=\(found?.text ?? "nil")")
        guard let found, SharedModels.frequencies.looksEnglish(found.text) else { return }
        pendingCheck = Task { await check(found.text, at: start + found.offset) }
    }

    /// Where the committed text ends. The word being typed is marked text and may still turn
    /// between Vietnamese and English, so it is left out.
    private static func committedEnd(in client: IMKTextInput) -> Int? {
        let marked = client.markedRange()
        if marked.location != NSNotFound, marked.length > 0 { return marked.location }
        let caret = client.selectedRange()
        return caret.location != NSNotFound && caret.length == 0 ? caret.location : nil
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
        }.filter { !ignored.contains(Self.key($0)) }
        let range = NSRange(location: sentenceStart, length: sentence.utf16.count)
        guard let client = controller?.client(), TextReplacer.read(range, from: client) == sentence else {
            Trace.log("  grammar sentence moved before results arrived")
            return hide()
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
            close: { [weak self] in self?.close() }
        )
    }

    private func ignore(_ suggestion: GrammarSuggestion) {
        ignored.insert(Self.key(suggestion))
        suggestions.removeAll { $0 == suggestion }
        guard let client = controller?.client() else { return hide() }
        show(in: client)
    }

    private func close() {
        ignored.formUnion(suggestions.map(Self.key))
        hide()
    }

    /// Stays the same while the rest of the sentence is typed.
    private static func key(_ suggestion: GrammarSuggestion) -> String {
        "\(suggestion.location) \(suggestion.original) \(suggestion.message)"
    }

    /// Writes the fix only if the original text is still where it was checked.
    private func apply(_ suggestion: GrammarSuggestion, _ replacement: String) {
        guard let controller, let client = controller.client() else {
            Trace.log("  grammar fix dropped: no client")
            return hide()
        }
        Trace.log("  grammar fix \(suggestion.original) -> \(replacement)")
        controller.commitComposition(client)
        guard TextReplacer.replace(suggestion.original, at: suggestion.location, with: replacement, in: client) else {
            Trace.log("  grammar fix refused: text changed")
            return hide()
        }
        suggestions = suggestions.applying(suggestion, replacement: replacement)
        show(in: client)
    }
}
