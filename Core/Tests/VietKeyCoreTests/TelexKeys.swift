import Foundation

/// Turns a Vietnamese syllable into the Telex keys that type it, tone key last, so
/// "hòa" and "hoà" both give "hoaf". Returns nil for text Telex cannot produce.
enum TelexKeys {
    private static let tones: [Unicode.Scalar: Character] = [
        "\u{301}": "s", "\u{300}": "f", "\u{309}": "r", "\u{303}": "x", "\u{323}": "j",
    ]

    static func keys(for syllable: String) -> String? {
        var keys = ""
        var tone: Character?
        for scalar in syllable.lowercased().decomposedStringWithCanonicalMapping.unicodeScalars {
            switch scalar {
            case "a"..."z": keys.unicodeScalars.append(scalar)
            case "đ": keys += "dd"
            case "\u{302}":
                guard let vowel = keys.last else { return nil }
                keys.append(vowel)
            case "\u{306}", "\u{31B}": keys += "w"
            default:
                guard let key = tones[scalar], tone == nil else { return nil }
                tone = key
            }
        }
        return keys.isEmpty ? nil : keys + (tone.map(String.init) ?? "")
    }
}
