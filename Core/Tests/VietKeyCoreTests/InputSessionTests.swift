import Testing
import VietKeyCore

private func type(_ keys: String, into session: inout InputSession) -> CompositionUpdate? {
    keys.reduce(nil) { _, char in session.handle(.character(char)) }
}

private func commitWord(_ keys: String) -> String? {
    var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: InMemoryCorrectionStore())
    _ = type(keys, into: &session)
    guard case .commit(let text, _) = session.handle(.character(" ")) else { return nil }
    return text
}

struct InputSessionTests {
    @Test(arguments: vietnameseGolden)
    func commitsVietnamese(keys: String, word: String) {
        #expect(commitWord(keys) == word)
    }

    @Test(.disabled("Known gap: final k only occurs in place names like Đắk Lắk"))
    func commitsPlaceNameWithFinalK() {
        #expect(commitWord("DDawks") == "Đắk")
    }

    @Test(arguments: [
        "class", "user", "text", "data", "Facebook", "windows", "good", "google", "error",
        "coffee", "saw", "show", "the", "string", "first", "dear",
    ])
    func restoresEnglishWhenNotAVietnameseSyllable(keys: String) {
        #expect(commitWord(keys) == keys)
    }

    @Test(arguments: [
        ("tesst", "test"), ("casse", "case"), ("Tesst", "Test"), ("CASSE", "CASE"), ("cassse", "casse"),
    ])
    func doubleKeyUndoCommitsWhatWasShown(keys: String, word: String) {
        #expect(commitWord(keys) == word)
    }

    @Test(arguments: ["class", "press", "error", "coffee", "boss", "miss", "CLASS"])
    func doubleLettersInEnglishKeepRawWhenRawIsAWord(keys: String) {
        #expect(commitWord(keys) == keys)
    }

    /// Ratchet: English words whose Telex reading is a real, common syllable still come out
    /// Vietnamese (car→cả, six→sĩ, these→thế). Context from the previous word should fix these.
    @Test func englishManglingDoesNotRegress() {
        let mangled = commonEnglishWords.filter { commitWord($0) != $0 }
        #expect(mangled.count <= Self.englishManglingBaseline, "mangled: \(mangled)")
    }

    private static let englishManglingBaseline = 7

    @Test func composingReportsDisplayAndRaw() {
        var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: InMemoryCorrectionStore())
        #expect(type("vieetj", into: &session) == .composing(display: "việt", raw: "vieetj"))
    }

    @Test func backspaceRemovesLastLetterThenEndsComposition() {
        var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: InMemoryCorrectionStore())
        _ = type("as", into: &session)
        #expect(session.handle(.backspace) == .composing(display: "", raw: ""))
        #expect(!session.isComposing)
        #expect(session.handle(.backspace) == .passthrough)
    }

    @Test func escapeCommitsRawKeys() {
        var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: InMemoryCorrectionStore())
        _ = type("mix", into: &session)
        #expect(session.handle(.escape) == .commit(text: "mix", raw: "mix"))
        #expect(session.handle(.escape) == .passthrough)
    }

    @Test func boundaryWithoutCompositionPassesThrough() {
        var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: InMemoryCorrectionStore())
        #expect(session.handle(.character(" ")) == .passthrough)
    }
}
