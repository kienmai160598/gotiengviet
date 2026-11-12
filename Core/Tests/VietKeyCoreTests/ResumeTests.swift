import Testing
import VietKeyCore

/// Backspace right after a word's boundary reopens the word when it went in as shown, so a
/// tone or letter can still be added: "hoa ⌫f" gives "hòa".
struct ResumeTests {
    private func session(afterTyping keys: String) -> InputSession {
        var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: InMemoryCorrectionStore())
        keys.forEach { _ = session.handle(.character($0)) }
        return session
    }

    @Test(arguments: [("vieetj", "việt"), ("tesst", "test"), ("google", "google"), ("hoa", "hoa")])
    func backspaceAfterTheBoundaryOffersTheWordBack(keys: String, word: String) {
        var session = session(afterTyping: keys + ",")
        #expect(session.handle(.backspace) == .resume(expected: word + ",", display: word, raw: keys))
    }

    @Test func theConfirmedWordTakesMoreKeys() {
        var session = session(afterTyping: "hoa ")
        _ = session.handle(.backspace)
        session.confirmResume()
        #expect(session.handle(.character("f")) == .composing(display: "hòa", raw: "hoaf"))
        #expect(session.handle(.character(" ")) == .commit(text: "hòa", raw: "hoaf"))
    }

    @Test func anUnconfirmedResumeLeavesNothingBeingTyped() {
        var session = session(afterTyping: "hoa ")
        _ = session.handle(.backspace)
        #expect(session.handle(.character("f")) == .composing(display: "f", raw: "f"))
    }

    @Test(arguments: ["hoa  ", "hoa a"])
    func onlyTheVeryNextKeyCanReopen(typed: String) {
        var session = session(afterTyping: typed)
        if session.isComposing { _ = session.handle(.escape) }
        #expect(session.handle(.backspace) == .passthrough)
    }

    @Test func aWordEndedWithoutABoundaryStaysClosed() {
        var session = session(afterTyping: "hoa")
        _ = session.commit()
        #expect(session.handle(.backspace) == .passthrough)
    }
}
