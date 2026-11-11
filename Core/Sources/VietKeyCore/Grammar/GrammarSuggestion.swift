import Foundation

/// A grammar problem in a checked sentence, placed in the document. Offsets are UTF-16, matching
/// NSRange. The sentence is kept so the problem can be shown in context.
public struct GrammarSuggestion: Sendable, Equatable {
    public fileprivate(set) var sentence: String
    public let sentenceStart: Int
    /// Where `original` starts inside `sentence`.
    public fileprivate(set) var offset: Int
    public let original: String
    /// Text to put in place of `original`, best first. An empty string means remove it.
    public let replacements: [String]
    public let message: String
    public let category: String

    public var location: Int { sentenceStart + offset }
    public var length: Int { original.utf16.count }

    public init?(
        in sentence: String, sentenceStart: Int, offset: Int, length: Int,
        replacements: [String], message: String, category: String
    ) {
        let utf16 = sentence.utf16
        guard offset >= 0, length >= 0, offset + length <= utf16.count,
              let lower = utf16.index(utf16.startIndex, offsetBy: offset).samePosition(in: sentence),
              let upper = utf16.index(utf16.startIndex, offsetBy: offset + length).samePosition(in: sentence)
        else { return nil }
        self.sentence = sentence
        self.sentenceStart = sentenceStart
        self.offset = offset
        original = String(sentence[lower..<upper])
        self.replacements = replacements
        self.message = message
        self.category = category
    }
}

extension [GrammarSuggestion] {
    /// The suggestions left after `applied` was replaced by `replacement`: it is gone, its
    /// sentence carries the fix, and problems after it move by the change in length.
    public func applying(_ applied: GrammarSuggestion, replacement: String) -> [GrammarSuggestion] {
        let range = NSRange(location: applied.offset, length: applied.length)
        let shift = replacement.utf16.count - applied.length
        return filter { $0 != applied }.map { suggestion in
            guard suggestion.sentenceStart == applied.sentenceStart else { return suggestion }
            var moved = suggestion
            moved.sentence = (suggestion.sentence as NSString).replacingCharacters(in: range, with: replacement)
            if suggestion.offset > applied.offset { moved.offset += shift }
            return moved
        }
    }
}
