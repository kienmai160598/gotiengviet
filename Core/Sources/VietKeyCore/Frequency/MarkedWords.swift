import Foundation

/// Vietnamese words the letters typed so far could be once they carry their marks, for a
/// touch keyboard's bar: "toi" offers "tôi", "tới", "tối", so one tap replaces the mark keys.
public struct MarkedWords: Sendable {
    private typealias Entry = (base: String, word: String, count: Int)
    /// The real syllables in the frequency table, sorted by `base`: the word without its
    /// marks. The table also lists foreign words that carry a mark, and misspellings whose
    /// keys type a real word ("thuowng" types "thương"), which are counted with that word.
    private let entries: [Entry]

    public init(frequencies: BundledWordFrequencies, style: ToneStyle = .traditional) {
        var counts: [String: Int] = [:]
        for (keys, count) in frequencies.vietnameseCounts {
            let composition = Composition(style: style, keys: keys)
            guard composition.isValidVietnamese else { continue }
            counts[composition.spelledText, default: 0] += count
        }
        entries = counts.map { (Self.unmarked($0.key), $0.key, $0.value) }.sorted { $0.base < $1.base }
    }

    /// `shown` is the word on screen ("Toi", "tô"). Words that keep the marks already on it
    /// come first ("tôi" gives "tối" before "tới"), then words with exactly its letters before
    /// longer ones, then the most common. They are cased like `shown` and never repeat it.
    public func words(for shown: String, limit: Int = 3) -> [String] {
        let typed = shown.lowercased()
        let base = Self.unmarked(typed)
        guard !base.isEmpty else { return [] }
        let hasMarks = typed != base
        return matches(base).filter { $0.word != typed }.map { entry in
            let keepsMarks = !hasMarks || Self.keeps(typed, in: entry.word)
            return (word: entry.word, rank: (keepsMarks ? 1 : 0, entry.base == base ? 1 : 0, entry.count))
        }.sorted { $0.rank > $1.rank }.prefix(limit).map { Self.cased($0.word, like: shown) }
    }

    /// "đường" gives "duong". Folding strips tones and vowel marks; đ is a letter of its own.
    private static func unmarked(_ word: String) -> String {
        word.folding(options: .diacriticInsensitive, locale: nil).replacingOccurrences(of: "đ", with: "d")
    }

    /// Whether `word` still has every mark typed so far: after "tô", "tối" does, "tới" does not.
    private static func keeps(_ typed: String, in word: String) -> Bool {
        zip(typed, word).allSatisfy { typed, written in
            marks(on: typed).isSubset(of: marks(on: written)) && (typed != "đ" || written == "đ")
        }
    }

    private static func marks(on letter: Character) -> Set<Unicode.Scalar> {
        Set(String(letter).decomposedStringWithCanonicalMapping.unicodeScalars.dropFirst())
    }

    /// Caps lock ("TOI") gives "TÔI"; a capital first letter gives "Tôi".
    private static func cased(_ word: String, like shown: String) -> String {
        if shown.count > 1, shown == shown.uppercased() { return word.uppercased() }
        return shown.first?.isUppercase == true ? word.prefix(1).uppercased() + word.dropFirst() : word
    }

    /// Entries whose base starts with `prefix`, found by binary search in the sorted table.
    private func matches(_ prefix: String) -> ArraySlice<Entry> {
        var low = 0, high = entries.count
        while low < high {
            let mid = (low + high) / 2
            if entries[mid].base < prefix { low = mid + 1 } else { high = mid }
        }
        var end = low
        while end < entries.count, entries[end].base.hasPrefix(prefix) { end += 1 }
        return entries[low..<end]
    }
}
