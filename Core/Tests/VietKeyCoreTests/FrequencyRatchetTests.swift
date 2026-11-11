import Testing
@testable import VietKeyCore

/// Token-weighted error rates over the bundled tables. Scored and measured on the same lists,
/// so this guards against regressions; it is not a corpus round-trip.
@Suite(.serialized) struct FrequencyRatchetTests {
    private static let perBillion = 1_000_000_000.0
    private var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: InMemoryCorrectionStore())

    private mutating func commit(_ keys: String) -> String {
        keys.forEach { _ = session.handle(.character($0)) }
        guard case .commit(let text, _) = session.handle(.character(" ")) else { return keys }
        return text
    }

    /// Share of English word occurrences that Telex turns into Vietnamese.
    @Test mutating func englishTokensMangled() {
        let mangled = testFrequencies.englishCounts.filter { commit($0.key) != $0.key }
        let share = Double(mangled.values.reduce(0, +)) / Self.perBillion
        #expect(share <= 0.0109, "mangled \(share * 100)%, top: \(Self.top(mangled))")
    }

    /// Share of Vietnamese syllable occurrences (with a diacritic) that do not come out as typed,
    /// for typists who put the tone key last ("lats") and for those who type it before the final
    /// consonant ("last"), which collides with more English words.
    @Test(arguments: [(false, 0.0012), (true, 0.0014)])
    mutating func vietnameseTokensLost(toneBeforeFinal: Bool, baseline: Double) {
        let lost = testFrequencies.vietnameseCounts.filter { keys, _ in
            let typed = toneBeforeFinal ? Self.movingToneBeforeFinal(keys) : keys
            let text = commit(typed)
            return text == typed || TelexKeys.keys(for: text) != keys
        }
        let share = Double(lost.values.reduce(0, +)) / Self.perBillion
        #expect(share <= baseline, "lost \(share * 100)%, top: \(Self.top(lost))")
    }

    /// "lats" becomes "last": the tone key moves right after the last vowel key.
    private static func movingToneBeforeFinal(_ keys: String) -> String {
        guard let tone = keys.last, "sfrxj".contains(tone),
              let vowel = keys.dropLast().lastIndex(where: { "aeiouyw".contains($0) })
        else { return keys }
        var typed = keys.dropLast()
        typed.insert(tone, at: typed.index(after: vowel))
        return String(typed)
    }

    private static func top(_ counts: [String: Int]) -> String {
        counts.sorted { $0.value > $1.value }.prefix(10).map { "\($0.key) \($0.value)" }.joined(separator: ", ")
    }
}
