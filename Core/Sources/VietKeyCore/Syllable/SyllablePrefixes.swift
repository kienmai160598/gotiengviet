/// Letter skeletons (vowel marks and tone stripped) of every prefix of every valid syllable.
/// A word being typed can still become Vietnamese only if its skeleton is in this set:
/// Telex may add marks and change the tone at any point, but letters only ever get appended.
enum SyllablePrefixes {
    private static let skeletons: Set<String> = build()

    static func contains(_ letters: [Character]) -> Bool {
        skeletons.contains(String(letters.map(Alphabet.base)))
    }

    /// Builds the set ahead of the first keystroke.
    static func warmUp() {
        _ = skeletons.count
    }

    private static func build() -> Set<String> {
        var result: Set<String> = []
        for initial in Syllable.initials {
            for nucleus in Syllable.allNuclei {
                for final in Syllable.finals {
                    let chars = Array(initial + nucleus + final)
                    guard let syllable = Syllable.parse(chars),
                          syllable.isValid(with: .acute) || syllable.isValid(with: .level)
                    else { continue }
                    let skeleton = String(chars.map(Alphabet.base))
                    for end in skeleton.indices { result.insert(String(skeleton[...end])) }
                }
            }
        }
        return result
    }
}
