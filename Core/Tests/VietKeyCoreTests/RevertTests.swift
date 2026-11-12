import Testing
import VietKeyCore

/// Backspace right after a boundary brings back the Vietnamese that was on screen, but only
/// when the boundary replaced it with the raw keys.
struct RevertTests {
    private func session(afterTyping keys: String) -> InputSession {
        var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: InMemoryCorrectionStore())
        keys.forEach { _ = session.handle(.character($0)) }
        return session
    }

    @Test(arguments: [("text", " ", "tẽt"), ("data", " ", "dât"), ("data", ",", "dât")])
    func backspaceAfterBoundaryRestoresShownVietnamese(keys: String, boundary: Character, shown: String) {
        var session = session(afterTyping: keys)
        #expect(session.handle(.character(boundary)) == .commit(text: keys, raw: keys))
        #expect(session.handle(.backspace) == .revert(expected: keys + String(boundary), replacement: shown))
    }

    /// Only the spelling changed (thưở to thuở): nothing to bring back, and the word did not go
    /// in as shown, so it is not reopened either.
    @Test func backspaceDeletesNormallyWhenOnlyTheSpellingChanged() {
        var session = session(afterTyping: "thuowr ")
        #expect(session.handle(.backspace) == .passthrough)
    }

    @Test func revertIsOfferedOnlyForTheVeryNextKey() {
        var session = session(afterTyping: "data ,")
        #expect(session.handle(.backspace) == .passthrough)
    }

    @Test func revertIsOfferedOnce() {
        var session = session(afterTyping: "data ")
        _ = session.handle(.backspace)
        #expect(session.handle(.backspace) == .passthrough)
    }

    @Test func commitWithoutBoundaryCannotBeReverted() {
        var session = session(afterTyping: "data")
        _ = session.commit()
        #expect(session.handle(.backspace) == .passthrough)
    }
}
