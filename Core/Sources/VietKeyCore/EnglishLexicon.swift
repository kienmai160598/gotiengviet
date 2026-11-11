/// Answers whether a string is an English word. Platforms supply it (system spell checker
/// on macOS, UITextChecker on iOS) so Core stays free of AppKit/UIKit.
public protocol EnglishLexicon: Sendable {
    func contains(_ word: String) -> Bool
}
