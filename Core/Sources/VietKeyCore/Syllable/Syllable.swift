/// A Vietnamese syllable split into initial consonant, vowel nucleus and final consonant.
/// Works on lowercase letters without tone marks.
struct Syllable: Equatable {
    let initial: String
    let nucleus: String
    let final: String
    let nucleusStart: Int

    static let initials = [
        "ngh", "ch", "gh", "gi", "kh", "ng", "nh", "ph", "qu", "th", "tr",
        "b", "c", "d", "đ", "g", "h", "k", "l", "m", "n", "p", "r", "s", "t", "v", "x", "",
    ]
    static let finals: Set<String> = ["", "c", "ch", "m", "n", "ng", "nh", "p", "t"]

    /// Returns the first structural split that fits, or nil when the letters cannot form a syllable.
    /// Longer initials win, except when they leave no vowel ("gìn" parses as g + in).
    static func parse(_ chars: [Character]) -> Syllable? {
        for initial in initials where chars.starts(with: initial) {
            let start = initial.count
            let end = chars[start...].firstIndex { !Alphabet.isVowel($0) } ?? chars.count
            guard end > start else { continue }
            let final = String(chars[end...])
            guard finals.contains(final) else { continue }
            return Syllable(
                initial: initial,
                nucleus: String(chars[start..<end]),
                final: final,
                nucleusStart: start
            )
        }
        return nil
    }
}
