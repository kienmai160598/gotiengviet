import Testing
@testable import VietKeyCore

struct MarkedWordsTests {
    private static let marked = MarkedWords(frequencies: try! BundledWordFrequencies())

    @Test func offersTheCommonWaysToMarkTheLetters() {
        #expect(Self.marked.words(for: "toi").first == "tôi")
        #expect(Self.marked.words(for: "duoc").first == "được")
        #expect(Self.marked.words(for: "di").contains("đi"))
    }

    @Test func offersLongerWordsWhenTheLettersAreNotAWordYet() {
        #expect(Self.marked.words(for: "ng").first == "người")
        #expect(Self.marked.words(for: "nguo").contains("người"))
    }

    @Test func wordsWithExactlyTheLettersComeBeforeLongerOnes() {
        #expect(Self.marked.words(for: "ban").allSatisfy { $0.count == 3 })
    }

    @Test func keepsTheMarksAlreadyTyped() {
        let words = Self.marked.words(for: "tô")
        #expect(words.allSatisfy { $0.contains("ô") || $0.contains("ố") || $0.contains("ồ") || $0.contains("ổ") || $0.contains("ỗ") || $0.contains("ộ") })
        #expect(Self.marked.words(for: "đ").allSatisfy { $0.hasPrefix("đ") })
    }

    /// The table spells "thuở" with the keys "thuowr", which read "thưở" until a boundary.
    @Test func spellsWordsAsABoundaryWouldCommitThem() {
        let words = Self.marked.words(for: "thuo", limit: .max)
        #expect(words.contains("thuở") && !words.contains("thưở"))
    }

    @Test func neverRepeatsTheWordShown() {
        #expect(!Self.marked.words(for: "tôi", limit: 50).contains("tôi"))
    }

    @Test func followsTheCaseOfTheWordShown() {
        #expect(Self.marked.words(for: "Toi").first == "Tôi")
        #expect(Self.marked.words(for: "TOI").first == "TÔI")
        #expect(Self.marked.words(for: "T").allSatisfy { $0.first == "T" && $0 != $0.uppercased() })
    }

    @Test func offersNothingForLettersNoVietnameseWordStartsWith() {
        #expect(Self.marked.words(for: "hel").isEmpty)
        #expect(Self.marked.words(for: "").isEmpty)
    }

    @Test func everyWordInTheTableIsListedOnce() {
        let all = Self.marked.words(for: "t", limit: .max)
        let repeated = Dictionary(grouping: all) { $0 }.filter { $0.value.count > 1 }.keys.sorted()
        #expect(repeated.isEmpty, "\(repeated.prefix(10))")
    }
}
