import Foundation
import InputMethodKit

/// Replaces text the app has already inserted, for Backspace-to-revert, reopening a word and
/// grammar fixes. Only acts when the app proves the exact text is where it is expected, so a
/// failure leaves the document untouched instead of corrupting it.
enum TextReplacer {
    /// Terminals hand typed text to the shell at once; it cannot be edited afterwards.
    private static let unsupportedClients: Set<String> = ["com.apple.Terminal"]

    static func replace(_ expected: String, with replacement: String, in client: IMKTextInput) -> Bool {
        guard !unsupportedClients.contains(client.bundleIdentifier() ?? ""),
              let range = rangeBeforeCaret(matching: expected, in: client)
        else { return false }
        client.insertText(replacement, replacementRange: range)
        let written = NSRange(location: range.location, length: replacement.utf16.count)
        Trace.log("  revert verified=\(read(written, from: client) == replacement)")
        return true
    }

    /// Turns `expected`, right before the caret, back into marked text showing `display`.
    static func mark(_ expected: String, as display: String, in client: IMKTextInput) -> Bool {
        guard !unsupportedClients.contains(client.bundleIdentifier() ?? ""),
              let range = rangeBeforeCaret(matching: expected, in: client)
        else { return false }
        let caret = NSRange(location: display.utf16.count, length: 0)
        client.setMarkedText(display, selectionRange: caret, replacementRange: range)
        Trace.log("  reopen marked=\(client.markedRange()) selected=\(client.selectedRange())")
        return true
    }

    /// Replaces `expected` at `location`, before the caret. NSTextView keeps the caret where it
    /// was (shifted by the change in length); other apps are not checked yet.
    static func replace(_ expected: String, at location: Int, with replacement: String, in client: IMKTextInput) -> Bool {
        let range = NSRange(location: location, length: expected.utf16.count)
        let caret = client.selectedRange()
        guard !unsupportedClients.contains(client.bundleIdentifier() ?? ""),
              caret.location != NSNotFound, caret.location >= NSMaxRange(range),
              read(range, from: client) == expected
        else { return false }
        client.insertText(replacement, replacementRange: range)
        Trace.log("  fix caret before=\(caret) after=\(client.selectedRange())")
        return true
    }

    private static func rangeBeforeCaret(matching expected: String, in client: IMKTextInput) -> NSRange? {
        let caret = client.selectedRange()
        let length = expected.utf16.count
        guard caret.location != NSNotFound, caret.length == 0, caret.location >= length else { return nil }
        let range = NSRange(location: caret.location - length, length: length)
        return read(range, from: client) == expected ? range : nil
    }

    static func read(_ range: NSRange, from client: IMKTextInput) -> String? {
        var actual = NSRange(location: NSNotFound, length: 0)
        guard let text = client.string(from: range, actualRange: &actual), actual == range else { return nil }
        return text
    }
}
