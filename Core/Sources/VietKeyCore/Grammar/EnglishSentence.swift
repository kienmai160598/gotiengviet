extension WordFrequencies {
    /// Whether a sentence is English enough to grammar check. Any Vietnamese letter rules it out,
    /// and so does Vietnamese typed without marks ("Ok anh, de em check lai"): a quarter or more
    /// of its words read as unmarked syllables that are rare in English. Tech terms ("deps",
    /// "useEffect") are not syllables, so they do not count against English.
    public func looksEnglish(_ sentence: String) -> Bool {
        let words = sentence.split { !$0.isLetter && !Self.apostrophes.contains($0) }
            .map(Self.stem)
            .filter { !$0.isEmpty }
        guard words.count >= 2, words.allSatisfy({ $0.allSatisfy(\.isASCII) }) else { return false }
        let vietnamese = words.filter { english($0) < Self.commonEnglish && Syllable.isUnmarked($0) }
        return Double(vietnamese.count) < Double(words.count) * Self.vietnameseShare
    }

    static var vietnameseShare: Double { 0.25 }

    private static var apostrophes: Set<Character> { ["'", "\u{2019}"] }

    /// "You've" is judged by "you": the "ve" left after the apostrophe reads as Vietnamese.
    private static func stem(_ word: Substring) -> String {
        word.prefix { !apostrophes.contains($0) }.lowercased()
    }

    /// Per billion, the same bar LanguageContext uses for English evidence. "em" and "de" pass it;
    /// "anh", "troi" and "lai" do not, though subtitles contain them.
    static var commonEnglish: Int { LanguageContext.evidenceFrequency }
}

extension Syllable {
    private static let unmarkedNuclei = Set(allNuclei.map { String($0.map(Alphabet.base)) })

    /// Whether lowercase ASCII letters spell a Vietnamese syllable with its marks left off.
    static func isUnmarked(_ word: String) -> Bool {
        guard let syllable = parse(Array(word)) else { return false }
        return unmarkedNuclei.contains(syllable.nucleus)
    }
}
