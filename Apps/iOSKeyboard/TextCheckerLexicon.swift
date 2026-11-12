import UIKit
import VietKeyCore

/// English word check backed by the system spell checker, like NSSpellChecker on the Mac. Core
/// calls it only when a word is committed after a double-key undo, from a key tap on the main
/// thread.
struct TextCheckerLexicon: EnglishLexicon {
    func contains(_ word: String) -> Bool {
        Trace.measure("lexicon \"\(word)\"") {
            MainActor.assumeIsolated {
                guard let language = UITextChecker.availableLanguages.first(where: { $0.hasPrefix("en") }) else {
                    return false
                }
                let misspelled = UITextChecker().rangeOfMisspelledWord(
                    in: word, range: NSRange(location: 0, length: word.utf16.count),
                    startingAt: 0, wrap: false, language: language
                )
                return misspelled.location == NSNotFound
            }
        }
    }
}
