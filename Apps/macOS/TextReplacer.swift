import Foundation
import InputMethodKit

/// Replaces text the app has already inserted, for Backspace-to-revert. Only acts when the
/// app proves the exact text sits right before the caret, so a failure falls back to a
/// normal Backspace instead of corrupting the document.
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

    private static func rangeBeforeCaret(matching expected: String, in client: IMKTextInput) -> NSRange? {
        let caret = client.selectedRange()
        let length = expected.utf16.count
        guard caret.location != NSNotFound, caret.length == 0, caret.location >= length else { return nil }
        let range = NSRange(location: caret.location - length, length: length)
        return read(range, from: client) == expected ? range : nil
    }

    private static func read(_ range: NSRange, from client: IMKTextInput) -> String? {
        var actual = NSRange(location: NSNotFound, length: 0)
        guard let text = client.string(from: range, actualRange: &actual), actual == range else { return nil }
        return text
    }
}
