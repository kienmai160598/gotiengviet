/// Finds the sentence that just ended, in document text read back from right before the caret.
/// Grammar is checked only on whole sentences: a fragment starting mid-sentence makes the checker
/// report errors that are not there.
public enum SentenceFinder {
    public static let terminators: Set<Character> = [".", "?", "!"]

    /// - Parameters:
    ///   - before: document text ending at the caret, which sits right after a terminator.
    ///   - reachesDocumentStart: whether `before` starts at the beginning of the document.
    /// - Returns: the sentence and its UTF-16 offset in `before`, or nil when the sentence start
    ///   is not inside `before`.
    public static func lastSentence(in before: String, reachesDocumentStart: Bool) -> (text: String, offset: Int)? {
        let chars = Array(before)
        var end = chars.count
        while end > 0, terminators.contains(chars[end - 1]) { end -= 1 }
        guard end > 0, end < chars.count else { return nil }
        var start = end
        while start > 0, !isBoundary(chars, at: start) { start -= 1 }
        guard start > 0 || reachesDocumentStart else { return nil }
        while start < end, chars[start].isWhitespace { start += 1 }
        guard start < end else { return nil }
        let offset = String(chars[..<start]).utf16.count
        return (String(chars[start...]), offset)
    }

    /// A sentence starts after a newline, or after a terminator followed by whitespace.
    private static func isBoundary(_ chars: [Character], at index: Int) -> Bool {
        let previous = chars[index - 1]
        if previous.isNewline { return true }
        return previous.isWhitespace && index >= 2 && terminators.contains(chars[index - 2])
    }
}
