import Foundation
import Testing
import VietKeyCore

/// A correction the user makes once (Backspace revert, Esc) decides those keys from then on.
struct LearningTests {
    private let store = InMemoryCorrectionStore()

    private func type(_ keys: String, into session: inout InputSession) -> [CompositionUpdate] {
        keys.map { session.handle(.character($0)) }
    }

    private func committed(_ word: String) -> CompositionUpdate? {
        var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: store)
        return type(word + " ", into: &session).last
    }

    private func escape(_ keys: String) {
        var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: store)
        _ = type(keys, into: &session)
        _ = session.handle(.escape)
    }

    private func revert(_ keys: String, confirmed: Bool = true, then next: InputKey) {
        var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: store)
        _ = type(keys + " ", into: &session)
        _ = session.handle(.backspace)
        if confirmed { session.confirmRevert() }
        _ = session.handle(next)
    }

    @Test(arguments: [InputKey.character(" "), .character("x"), .escape])
    func revertKeptByTypingOnKeepsVietnameseNextTime(next: InputKey) {
        revert("text", then: next)
        #expect(committed("text") == .commit(text: "tẽt", raw: "text"))
        #expect(store.preference(for: "text") == .vietnamese)
    }

    /// Deleting "is " with Backspace first reverts to "í"; the next Backspace shows the user
    /// was deleting, not choosing the Vietnamese.
    @Test func revertFollowedByBackspaceIsNotLearned() {
        revert("is", then: .backspace)
        #expect(store.preference(for: "is") == nil)
        #expect(committed("is") == .commit(text: "is", raw: "is"))
    }

    @Test func revertTheAdapterCouldNotApplyIsNotLearned() {
        revert("text", confirmed: false, then: .character(" "))
        #expect(committed("text") == .commit(text: "text", raw: "text"))
    }

    @Test func escapeKeepsTypedKeysNextTimeLiveAndOnCommit() {
        escape("car")
        var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: store)
        #expect(type("car", into: &session).last == .composing(display: "car", raw: "car"))
        #expect(session.handle(.character(" ")) == .commit(text: "car", raw: "car"))
    }

    @Test func escapeOnWordAlreadyShownAsTypedLearnsNothing() {
        escape("google")
        #expect(store.preference(for: "google") == nil)
    }

    @Test func learnedKeysMatchAnyCase() {
        escape("car")
        #expect(committed("Car") == .commit(text: "Car", raw: "Car"))
    }

    @Test func onlyTheExactKeysAreAffected() {
        escape("car")
        #expect(committed("cars") == .commit(text: "cá", raw: "cars"))
    }

    @Test func learnedWordThatPrefixesAVietnameseWordOnlyAffectsThoseKeys() {
        escape("now")
        var session = InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: store)
        let shown = type("nowi", into: &session)
        #expect(shown[2] == .composing(display: "now", raw: "now"))
        #expect(shown[3] == .composing(display: "nơi", raw: "nowi"))
        #expect(session.handle(.character(" ")) == .commit(text: "nơi", raw: "nowi"))
    }

    @Test func forgetAllRestoresTheRules() {
        escape("car")
        store.forgetAll()
        #expect(committed("car") == .commit(text: "cả", raw: "car"))
    }

    @Test func userDefaultsStoreSurvivesRelaunch() throws {
        let suite = "VietKeyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        UserDefaultsCorrectionStore(defaults: defaults).record(.typedKeys, for: "Car")
        let relaunched = UserDefaultsCorrectionStore(defaults: defaults)
        #expect(relaunched.preference(for: "car") == .typedKeys)
        relaunched.forgetAll()
        #expect(UserDefaultsCorrectionStore(defaults: defaults).preference(for: "car") == nil)
    }
}
