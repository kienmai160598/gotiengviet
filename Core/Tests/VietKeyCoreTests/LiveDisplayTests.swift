import Testing
@testable import VietKeyCore

/// The marked text must show, on every key, what a word boundary would insert.
struct LiveDisplayTests {
    private func updates(for keys: String) -> (session: InputSession, updates: [CompositionUpdate]) {
        var session = InputSession(lexicon: TestLexicon(), corrections: InMemoryCorrectionStore())
        let updates = keys.map { session.handle(.character($0)) }
        return (session, updates)
    }

    private func typedText(_ keys: some Sequence<Character>) -> String {
        Composition(style: .traditional, keys: keys).text
    }

    @Test(arguments: vietnameseGolden)
    func vietnameseNeverFlipsToRawKeysWhileTyping(keys: String, word: String) {
        let shown = updates(for: keys).updates
        for (index, update) in shown.enumerated() {
            let prefix = keys.prefix(index + 1)
            #expect(update == .composing(display: typedText(prefix), raw: String(prefix)), "after \(prefix)")
        }
    }

    @Test(arguments: [("goog", "goog"), ("google", "google"), ("wind", "wind"), ("windows", "windows"), ("clas", "clas")])
    func englishShowsTypedKeysOnceVietnameseIsImpossible(keys: String, shown: String) {
        #expect(updates(for: keys).updates.last == .composing(display: shown, raw: keys))
    }

    @Test func keepsVietnameseWhileAToneChangeCouldStillFixIt() {
        #expect(updates(for: "tex").updates.last == .composing(display: "tẽ", raw: "tex"))
        #expect(updates(for: "text").updates.last == .composing(display: "tẽt", raw: "text"))
    }

    @Test(arguments: [("tesst", "test"), ("casse", "case"), ("cassse", "casse"), ("class", "class"), ("google", "google")])
    func commitInsertsExactlyWhatWasShown(keys: String, shown: String) {
        var (session, shownUpdates) = updates(for: keys)
        #expect(shownUpdates.last == .composing(display: shown, raw: keys))
        #expect(session.handle(.character(" ")) == .commit(text: shown, raw: keys))
    }

    @Test func showsHornedVowelsUntilTheWordIsFinished() {
        var (session, shownUpdates) = updates(for: "thuowr")
        #expect(shownUpdates.last == .composing(display: "thưở", raw: "thuowr"))
        #expect(session.handle(.character(" ")) == .commit(text: "thuở", raw: "thuowr"))
    }

    @Test func backspaceOnTypedKeysRemovesOneKey() {
        var session = updates(for: "googl").session
        #expect(session.handle(.backspace) == .composing(display: "goog", raw: "goog"))
    }

    @Test func backspaceBackToAPossibleSyllableShowsVietnameseAgain() {
        var session = updates(for: "dduwowb").session
        #expect(session.handle(.backspace) == .composing(display: "đươ", raw: "dduwow"))
    }
}
