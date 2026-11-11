import AppKit
import VietKeyCore

/// English word check backed by the system spell checker. Core calls it only when a word is
/// committed after a double-key undo, which happens on the main thread inside IMKit callbacks.
struct SpellCheckerLexicon: EnglishLexicon {
    func contains(_ word: String) -> Bool {
        Trace.measure("lexicon \"\(word)\"") {
            MainActor.assumeIsolated {
                let misspelled = NSSpellChecker.shared.checkSpelling(
                    of: word, startingAt: 0, language: "en", wrap: false,
                    inSpellDocumentWithTag: 0, wordCount: nil
                )
                return misspelled.location == NSNotFound
            }
        }
    }
}
