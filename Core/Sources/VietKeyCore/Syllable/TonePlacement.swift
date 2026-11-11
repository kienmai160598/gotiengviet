enum TonePlacement {
    /// Index of the letter that carries the tone mark, or nil when there is no vowel.
    static func index(in chars: [Character], style: ToneStyle) -> Int? {
        guard let syllable = Syllable.parse(chars) else { return fallbackIndex(in: chars) }
        return syllable.nucleusStart + syllable.toneOffset(style: style)
    }

    /// For letters that are not a Vietnamese syllable (usually English being typed):
    /// mark the last vowel run, preferring a marked vowel.
    private static func fallbackIndex(in chars: [Character]) -> Int? {
        guard let last = chars.lastIndex(where: Alphabet.isVowel) else { return nil }
        var first = last
        while first > 0, Alphabet.isVowel(chars[first - 1]) { first -= 1 }
        return chars[first...last].lastIndex(where: Alphabet.markedVowels.contains) ?? first
    }
}

private extension Syllable {
    func toneOffset(style: ToneStyle) -> Int {
        let vowels = Array(nucleus)
        if let marked = vowels.lastIndex(where: Alphabet.markedVowels.contains) { return marked }
        if !final.isEmpty { return vowels.count - 1 }
        switch vowels.count {
        case 1: return 0
        case 2: return style == .modern && ["oa", "oe", "uy"].contains(nucleus) ? 1 : 0
        default: return 1
        }
    }
}
