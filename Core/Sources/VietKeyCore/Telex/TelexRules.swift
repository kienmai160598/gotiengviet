/// Telex modifier keys. Each rule returns true when the key was consumed as a modifier,
/// false when the key should be appended as a letter.
/// Marks apply to the last vowel run wherever the caret is ("tiengse" gives "tiếng").
extension Composition {
    mutating func applyTelex(_ key: Character, key original: Character) -> Bool {
        if let newTone = Tone(telexKey: key) { return applyTone(newTone) }
        switch key {
        case "z": return removeTone()
        case "a", "e", "o": return applyCircumflex(key)
        case "w": return applyHook(key: original)
        case "d": return applyStroke()
        default: return false
        }
    }

    private mutating func applyTone(_ newTone: Tone) -> Bool {
        guard hasVowel else { return false }
        guard tone != newTone else {
            tone = .level
            isLiteral = true
            return false
        }
        tone = newTone
        return true
    }

    private mutating func removeTone() -> Bool {
        guard tone != .level else { return false }
        tone = .level
        return true
    }

    private mutating func applyCircumflex(_ key: Character) -> Bool {
        guard let run = vowelRun,
              let index = run.last(where: { Alphabet.base(letters[$0].char) == key }),
              let marked = Alphabet.circumflexed[key]
        else { return false }
        guard letters[index].char != marked else {
            letters[index].char = key
            isLiteral = true
            return false
        }
        var nucleus = run.map { letters[$0].char }
        let offset = index - run.lowerBound
        nucleus[offset] = marked
        if key == "o", offset > 0, nucleus[offset - 1] == "ư" { nucleus[offset - 1] = "u" }
        // Only mark when it yields a real nucleus, so "ngoeo" keeps its second o.
        guard Syllable.allNuclei.contains(String(nucleus)) else { return false }
        replace(run, with: nucleus)
        return true
    }

    /// w adds a horn or breve: ươ first, then the first single change giving a real nucleus.
    /// With no vowel yet, w alone types ư.
    private mutating func applyHook(key: Character) -> Bool {
        guard let run = vowelRun else {
            append("ư", key: key)
            return true
        }
        let current = run.map { letters[$0].char }
        let variant = Self.hookVariants(of: current).first { Syllable.allNuclei.contains(String($0)) }
        guard let variant else {
            undoHooks(in: run)
            return false
        }
        replace(run, with: variant)
        return true
    }

    private mutating func replace(_ run: Range<Int>, with nucleus: [Character]) {
        for (offset, char) in nucleus.enumerated() { letters[run.lowerBound + offset].char = char }
    }

    private static func hookVariants(of run: [Character]) -> [[Character]] {
        var variants: [[Character]] = []
        if let pair = run.indices.dropLast().first(where: { "uư".contains(run[$0]) && "oơ".contains(run[$0 + 1]) }) {
            var variant = run
            variant[pair] = "ư"
            variant[pair + 1] = "ơ"
            variants.append(variant)
        }
        for (index, char) in run.enumerated() {
            guard let hooked = Alphabet.hooked[char] else { continue }
            var variant = run
            variant[index] = hooked
            variants.append(variant)
        }
        return variants.filter { $0 != run }
    }

    private mutating func undoHooks(in run: Range<Int>) {
        let hooked = run.filter { Alphabet.hookedVowels.contains(letters[$0].char) }
        guard !hooked.isEmpty else { return }
        if run.count == 1, letters[run.lowerBound].key.lowercased() == "w" {
            letters.remove(at: run.lowerBound)
        } else {
            hooked.forEach { letters[$0].char = Alphabet.base(letters[$0].char) }
        }
        isLiteral = true
    }

    /// dd gives đ only right after the initial d, so English words like "did" stay intact.
    private mutating func applyStroke() -> Bool {
        guard letters.count == 1 else { return false }
        switch letters[0].char {
        case "d":
            letters[0].char = "đ"
            return true
        case "đ":
            letters[0].char = "d"
            isLiteral = true
            return false
        default:
            return false
        }
    }

    /// The last run of vowels, excluding the u of "qu" and the i of "gi" when another vowel follows.
    private var vowelRun: Range<Int>? {
        guard let last = letters.lastIndex(where: { Alphabet.isVowel($0.char) }) else { return nil }
        var start = last
        while start > 0, Alphabet.isVowel(letters[start - 1].char) { start -= 1 }
        let glides: [Character: Character] = ["q": "u", "g": "i"]
        if last > start, start > 0, glides[letters[start - 1].char] == letters[start].char { start += 1 }
        return start..<(last + 1)
    }
}
