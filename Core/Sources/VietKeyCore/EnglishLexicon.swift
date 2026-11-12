/// Answers whether a string is an English word. Platforms supply it (system spell checker
/// on macOS, UITextChecker on iOS) so Core stays free of AppKit/UIKit.
public protocol EnglishLexicon: Sendable {
    func contains(_ word: String) -> Bool
}

extension EnglishLexicon {
    /// Checks the frequency table first, then the spell checker. Spell checkers accept any
    /// all-caps string as an acronym, so "CASSE" is judged as "casse". The Mac's also accepts
    /// "ww" and "aaa", which are double-key undos, not words.
    func isEnglishWord(_ word: String, frequencies: some WordFrequencies) -> Bool {
        if word.count > 1, Set(word.lowercased()).count == 1 { return false }
        if frequencies.english(word.lowercased()) > 0 { return true }
        let isAllCaps = word == word.uppercased() && word != word.lowercased()
        return contains(isAllCaps ? word.lowercased() : word)
    }
}
