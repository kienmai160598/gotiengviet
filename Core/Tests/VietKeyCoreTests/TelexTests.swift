import Testing
@testable import VietKeyCore

private func compose(_ keys: String, style: ToneStyle = .traditional) -> String {
    var composition = Composition(style: style)
    keys.forEach { composition.type($0) }
    return composition.spelledText
}

struct TelexTests {
    @Test(arguments: vietnameseGolden)
    func composesVietnamese(keys: String, word: String) {
        #expect(compose(keys) == word)
    }

    @Test(arguments: [
        ("w", "ư"), ("nhw", "như"), ("ww", "w"), ("uww", "uw"),
        ("aa", "â"), ("aaa", "aa"), ("dd", "đ"), ("ddd", "dd"), ("ass", "as"), ("asz", "a"),
    ])
    func handlesStandaloneAndUndoKeys(keys: String, expected: String) {
        #expect(compose(keys) == expected)
    }

    @Test(arguments: [("hoaf", "hòa", "hoà"), ("thuyr", "thủy", "thuỷ"), ("toans", "toán", "toán")])
    func placesToneByStyle(keys: String, traditional: String, modern: String) {
        #expect(compose(keys, style: .traditional) == traditional)
        #expect(compose(keys, style: .modern) == modern)
    }

    @Test func doubleKeyUndoMakesRestLiteral() {
        #expect(compose("coffee") == "cofee")
    }

    @Test func deleteBackwardKeepsToneOnRemainingVowel() {
        var composition = Composition(style: .traditional)
        "tieengs".forEach { composition.type($0) }
        composition.deleteBackward()
        #expect(composition.text == "tiến")
        #expect(composition.raw == "tien")
    }
}
