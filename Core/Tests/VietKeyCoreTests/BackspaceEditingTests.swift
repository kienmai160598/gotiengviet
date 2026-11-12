import Testing
import VietKeyCore

/// Backspace inside a word leaves the session as if only the remaining letters had been typed,
/// so the word is not judged by whatever its bare letters spell in English ("tôi" less i is "to").
struct BackspaceEditingTests {
    private func commit(_ keys: [InputKey]) -> String? {
        var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: InMemoryCorrectionStore())
        keys.forEach { _ = session.handle($0) }
        guard case .commit(let text, _) = session.handle(.character(" ")) else { return nil }
        return text
    }

    private func keys(_ typed: String) -> [InputKey] {
        typed.map { $0 == "<" ? .backspace : .character($0) }
    }

    @Test(arguments: [("tooi<", "too"), ("toois<", "toos"), ("hoafn<", "hoaf"), ("Tooi<", "Too"), ("TOOI<", "TOO"), ("TOOIS<", "TOOS"), ("nguwowif<", "nguwowf"), ("maays<y", "maasy")])
    func deletingALetterEqualsTypingTheRest(typed: String, rest: String) {
        #expect(commit(keys(typed)) == commit(keys(rest)))
    }

    @Test(arguments: [("toois<", "tố"), ("maays<y", "mấy")])
    func aWordWithMarksKeepsThemAfterDeletingALetter(typed: String, word: String) {
        #expect(commit(keys(typed)) == word)
    }
}
