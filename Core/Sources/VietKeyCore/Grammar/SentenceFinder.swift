/// Finds the sentence at the caret, in document text read back from right before it.
/// Grammar is checked only from a sentence start: a fragment starting mid-sentence makes the
/// checker report errors that are not there. The sentence may still be unfinished.
public enum SentenceFinder {
    private static let terminators: Set<Character> = [".", "?", "!"]

    /// - Parameters:
    ///   - before: document text ending at the caret.
    ///   - reachesDocumentStart: whether `before` starts at the beginning of the document.
    /// - Returns: the last sentence in `before`, finished or not, without trailing whitespace,
    ///   and its UTF-16 offset in `before`; nil when it has no letters or its start was not read.
    public static func lastSentence(in before: String, reachesDocumentStart: Bool) -> (text: String, offset: Int)? {
        let chars = Array(before)
        var end = chars.count
        while end > 0, chars[end - 1].isWhitespace { end -= 1 }
        var start = end
        while start > 0, !isBoundary(chars, at: start) { start -= 1 }
        guard start > 0 || reachesDocumentStart else { return nil }
        while start < end, chars[start].isWhitespace { start += 1 }
        guard chars[start..<end].contains(where: \.isLetter) else { return nil }
        let offset = String(chars[..<start]).utf16.count
        return (String(chars[start..<end]), offset)
    }

    /// A sentence starts after a newline, or after a terminator followed by whitespace, so
    /// "example.com" and "3.14" do not end one.
    private static func isBoundary(_ chars: [Character], at index: Int) -> Bool {
        let previous = chars[index - 1]
        if previous.isNewline { return true }
        return previous.isWhitespace && index >= 2 && terminators.contains(chars[index - 2])
    }
}
