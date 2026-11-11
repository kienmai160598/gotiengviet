import Foundation

struct Letter: Equatable, Sendable {
    /// Lowercase letter with vowel marks (â, ư, đ...) but no tone.
    var char: Character
    /// The key that produced this letter, keeping the typed case.
    let key: Character
}

/// The word currently being typed: letters, one tone, and the raw keys behind them.
struct Composition: Equatable, Sendable {
    private(set) var rawKeys: [Character] = []
    var letters: [Letter] = []
    var tone: Tone = .level
    /// Set after a double-key undo (ss, aaa, ww...): later keys are taken literally.
    var isLiteral = false
    let style: ToneStyle

    init(style: ToneStyle) {
        self.style = style
    }

    init(style: ToneStyle, keys: some Sequence<Character>) {
        self.init(style: style)
        keys.forEach { type($0) }
    }

    var isEmpty: Bool { letters.isEmpty }
    var raw: String { String(rawKeys) }
    var hasVowel: Bool { letters.contains { Alphabet.isVowel($0.char) } }

    var isValidVietnamese: Bool {
        Syllable.parse(spelledChars)?.isValid(with: tone) ?? false
    }

    /// Whether more keys could still turn this into a valid syllable.
    var canBecomeVietnamese: Bool {
        SyllablePrefixes.contains(letters.map(\.char))
    }

    /// Letters as written: Telex "uow" is ươ, but without a final consonant it is spelled uơ (thuở).
    private var spelledChars: [Character] {
        var chars = letters.map(\.char)
        if let syllable = Syllable.parse(chars), syllable.nucleus == "ươ", syllable.final.isEmpty {
            chars[syllable.nucleusStart] = "u"
        }
        return chars
    }

    /// The spelled word as canonical Telex keys, tone key last: "hòa" and "hoà" give "hoaf".
    var telexKeys: String {
        spelledChars.map(Alphabet.telexKeys(for:)).joined() + (tone.telexKey.map { String($0) } ?? "")
    }

    mutating func type(_ key: Character) {
        let repeatsPreviousKey = rawKeys.last?.lowercased() == key.lowercased()
        rawKeys.append(key)
        let lower = Character(key.lowercased())
        let wasLiteral = isLiteral
        if !isLiteral, applyTelex(lower, key: key) { return }
        if isLiteral, !wasLiteral, !repeatsPreviousKey {
            spellAsTyped()
        } else {
            append(lower, key: key)
        }
    }

    /// A double-key undo drops the key that made the mark ("aaa" gives "aa", "tesst" gives
    /// "test"). When that key was typed further back and marked across other letters ("Canada":
    /// the second a made "cân"), the user was not typing a mark at all, so every key comes back.
    private mutating func spellAsTyped() {
        letters = rawKeys.map { Letter(char: Character($0.lowercased()), key: $0) }
        tone = .level
    }

    /// Removes the last visible letter. The tone stays while a vowel remains.
    /// Raw keys are rebuilt from the remaining letters, since modifier keys no longer map cleanly.
    mutating func deleteBackward() {
        guard !letters.isEmpty else { return }
        letters.removeLast()
        guard !letters.isEmpty else {
            self = Composition(style: style)
            return
        }
        rawKeys = letters.map(\.key)
        if !hasVowel { tone = .level }
    }

    mutating func append(_ char: Character, key: Character) {
        letters.append(Letter(char: char, key: key))
    }

    /// The word as typed so far. Keeps ươ while the final consonant may still come (đươ → đường).
    var text: String { render(letters.map(\.char)) }

    /// The word as it is written once finished (thuở, not thưở).
    var spelledText: String { render(spelledChars) }

    private func render(_ chars: [Character]) -> String {
        let toneIndex = tone == .level ? nil : TonePlacement.index(in: chars, style: style)
        var scalars = String.UnicodeScalarView()
        for (index, (char, letter)) in zip(chars, letters).enumerated() {
            let cased = letter.key.isUppercase ? char.uppercased() : String(char)
            scalars.append(contentsOf: cased.unicodeScalars)
            if index == toneIndex, let mark = tone.combiningMark { scalars.append(mark) }
        }
        return String(scalars).precomposedStringWithCanonicalMapping
    }
}
