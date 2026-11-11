import Testing
@testable import VietKeyCore

private func isValid(_ word: String, tone: Tone = .level) -> Bool {
    Syllable.parse(Array(word))?.isValid(with: tone) ?? false
}

struct SyllableTests {
    @Test(arguments: ["tiêng", "ngươi", "khuyên", "quyêt", "gin", "nghiêng", "oanh", "huynh", "boong", "yêu"])
    func acceptsRealSyllables(word: String) {
        #expect(isValid(word, tone: .acute))
    }

    @Test(arguments: ["class", "ue", "ce", "ngi", "tâ", "ing", "ăch", "iên", "tyên"])
    func rejectsImpossibleSyllables(word: String) {
        #expect(!isValid(word, tone: .acute))
    }

    @Test func stopFinalsTakeOnlyAcuteOrDot() {
        #expect(isValid("tôt", tone: .acute))
        #expect(isValid("tôt", tone: .dot))
        #expect(!isValid("tôt", tone: .level))
        #expect(!isValid("tôt", tone: .tilde))
    }

    @Test func giMergesWhenNoOtherVowelFollows() {
        #expect(Syllable.parse(Array("gin"))?.initial == "g")
        #expect(Syllable.parse(Array("gia"))?.initial == "gi")
    }
}
