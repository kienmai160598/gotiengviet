public enum ToneStyle: Sendable {
    /// Tone on the first vowel of oa, oe, uy: hòa, thúy.
    case traditional
    /// Tone on the second vowel of oa, oe, uy: hoà, thuý.
    case modern
}

enum Tone: Sendable, Equatable {
    case level, acute, grave, hook, tilde, dot

    init?(telexKey: Character) {
        switch telexKey {
        case "s": self = .acute
        case "f": self = .grave
        case "r": self = .hook
        case "x": self = .tilde
        case "j": self = .dot
        default: return nil
        }
    }

    var combiningMark: Unicode.Scalar? {
        switch self {
        case .level: nil
        case .acute: "\u{301}"
        case .grave: "\u{300}"
        case .hook: "\u{309}"
        case .tilde: "\u{303}"
        case .dot: "\u{323}"
        }
    }

    var fitsStopFinal: Bool { self == .acute || self == .dot }
}

enum Alphabet {
    static let vowels: Set<Character> = ["a", "ă", "â", "e", "ê", "i", "o", "ô", "ơ", "u", "ư", "y"]
    static let markedVowels: Set<Character> = ["ă", "â", "ê", "ô", "ơ", "ư"]
    static let hookedVowels: Set<Character> = ["ă", "ơ", "ư"]
    static let circumflexed: [Character: Character] = ["a": "â", "e": "ê", "o": "ô"]
    static let hooked: [Character: Character] = ["a": "ă", "o": "ơ", "u": "ư"]
    private static let bases: [Character: Character] = [
        "ă": "a", "â": "a", "ê": "e", "ô": "o", "ơ": "o", "ư": "u", "đ": "d",
    ]

    static func isVowel(_ char: Character) -> Bool { vowels.contains(char) }
    static func base(_ char: Character) -> Character { bases[char] ?? char }
}
