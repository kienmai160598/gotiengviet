import Testing
@testable import VietKeyCore

/// At a word boundary a valid syllable stays Vietnamese unless the keys are an English word
/// more than three times as common.
struct FrequencyTests {
    private func committed(_ keys: String, frequencies: any WordFrequencies = testFrequencies) -> String {
        var session = InputSession(lexicon: TestLexicon(), frequencies: frequencies, corrections: InMemoryCorrectionStore())
        keys.forEach { _ = session.handle(.character($0)) }
        guard case .commit(let text, _) = session.handle(.character(" ")) else { return keys }
        return text
    }

    @Test(arguments: [("is", "is"), ("this", "this"), ("now", "now"), ("last", "last"), ("Is", "Is")])
    func commonEnglishBeatsRareVietnamese(keys: String, text: String) {
        #expect(committed(keys) == text)
    }

    @Test(arguments: [("tooi", "tôi"), ("cars", "cá"), ("thisch", "thích"), ("ddi", "đi"), ("sex", "sẽ")])
    func commonVietnameseStays(keys: String, text: String) {
        #expect(committed(keys) == text)
    }

    @Test func englishNeedsMoreThanThreeTimesTheVietnameseCount() {
        let tie = FixedFrequencies(english: ["bas": 300], vietnamese: ["bas": 100])
        let englishWins = FixedFrequencies(english: ["bas": 301], vietnamese: ["bas": 100])
        #expect(committed("bas", frequencies: tie) == "bá")
        #expect(committed("bas", frequencies: englishWins) == "bas")
    }

    @Test func styleDoesNotChangeTheLookup() {
        #expect(Composition(style: .modern, keys: "hoaf").telexKeys == "hoaf")
        #expect(Composition(style: .traditional, keys: "thuowr").telexKeys == "thuowr")
    }

    @Test func liveDisplayKeepsVietnameseUntilTheBoundary() {
        var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: InMemoryCorrectionStore())
        #expect(session.handle(.character("i")) == .composing(display: "i", raw: "i"))
        #expect(session.handle(.character("s")) == .composing(display: "í", raw: "is"))
        #expect(session.handle(.character(" ")) == .commit(text: "is", raw: "is"))
        #expect(session.handle(.backspace) == .revert(expected: "is ", replacement: "í"))
    }
}

private struct FixedFrequencies: WordFrequencies {
    let english: [String: Int]
    let vietnamese: [String: Int]

    func english(_ word: String) -> Int { english[word] ?? 0 }
    func vietnamese(telexKeys: String) -> Int { vietnamese[telexKeys] ?? 0 }
}
