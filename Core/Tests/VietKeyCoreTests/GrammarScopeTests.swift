import Testing
import VietKeyCore

@Suite struct SentenceFinderTests {
    @Test func findsTheSentenceAfterThePreviousOne() throws {
        let found = try #require(SentenceFinder.lastSentence(in: "Hi there. He go home.", reachesDocumentStart: false))
        #expect(found.text == "He go home.")
        #expect(found.offset == 10)
    }

    @Test func startsAfterANewlineOrAtTheDocumentStart() {
        #expect(SentenceFinder.lastSentence(in: "Notes\n  He go home!", reachesDocumentStart: false)?.text == "He go home!")
        #expect(SentenceFinder.lastSentence(in: " He go home?!", reachesDocumentStart: true)?.text == "He go home?!")
    }

    @Test func offsetsCountUTF16() {
        #expect(SentenceFinder.lastSentence(in: "Đẹp 😀. He go.", reachesDocumentStart: false)?.offset == 8)
    }

    @Test func refusesASentenceWhoseStartWasNotRead() {
        #expect(SentenceFinder.lastSentence(in: "to school every day.", reachesDocumentStart: false) == nil)
    }

    @Test func takesAnUnfinishedSentenceWithoutTrailingWhitespace() {
        #expect(SentenceFinder.lastSentence(in: "Hi. she don't like it \n", reachesDocumentStart: false)?.text == "she don't like it")
        #expect(SentenceFinder.lastSentence(in: "He go home. ", reachesDocumentStart: true)?.text == "He go home.")
        #expect(SentenceFinder.lastSentence(in: "see example.com now", reachesDocumentStart: true)?.text == "see example.com now")
    }

    @Test func needsLetters() {
        #expect(SentenceFinder.lastSentence(in: "Done. ...", reachesDocumentStart: false) == nil)
        #expect(SentenceFinder.lastSentence(in: "Done.\n  ", reachesDocumentStart: true)?.text == "Done.")
        #expect(SentenceFinder.lastSentence(in: "", reachesDocumentStart: true) == nil)
    }
}

@Suite struct EnglishSentenceTests {
    @Test(arguments: [
        "He go to school every day.",
        "She don't like coffee.",
        "The useEffect hook reruns when the deps array changes.",
        "I am working here since 2020.",
        "You've been had.",
    ])
    func checksEnglish(sentence: String) {
        #expect(testFrequencies.looksEnglish(sentence))
    }

    @Test(arguments: [
        "Team bên em deploy xong rồi.",
        "Hom nay troi dep qua.",
        "Anh oi, em gui file nay nhe.",
        "Ok anh, de em check lai.",
        "Done.",
    ])
    func skipsVietnameseAndSingleWords(sentence: String) {
        #expect(!testFrequencies.looksEnglish(sentence))
    }
}

@Suite struct GrammarSuggestionTests {
    @Test func placesTheProblemInTheDocument() throws {
        let suggestion = try #require(Self.make("Đẹp. He go.", start: 100, offset: 8, length: 2))
        #expect(suggestion.location == 108)
        #expect(suggestion.original == "go")
    }

    @Test func rejectsARangeOutsideTheSentence() {
        #expect(Self.make("He go.", start: 0, offset: 4, length: 9) == nil)
    }

    @Test func applyingRewritesTheSentenceAndShiftsLaterProblems() throws {
        let sentence = "He go and she go."
        let first = try #require(Self.make(sentence, start: 10, offset: 3, length: 2))
        let second = try #require(Self.make(sentence, start: 10, offset: 14, length: 2))
        let left = try #require([first, second].applying(first, replacement: "goes").first)
        #expect(left.location == 26)
        #expect(left.sentence == "He goes and she go.")
        #expect(left.original == "go")
        let earlier = try #require([first, second].applying(second, replacement: "goes").first)
        #expect(earlier.location == 13)
        #expect(earlier.sentence == "He go and she goes.")
    }

    private static func make(_ sentence: String, start: Int, offset: Int, length: Int) -> GrammarSuggestion? {
        GrammarSuggestion(in: sentence, sentenceStart: start, offset: offset, length: length,
                          replacements: ["goes"], message: "Agreement", category: "Agreement")
    }
}
