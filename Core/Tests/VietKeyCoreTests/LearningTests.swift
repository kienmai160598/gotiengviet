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
        var session = InputSession(lexicon: TestLexicon(), corrections: store)
        return type(word + " ", into: &session).last
    }

    private func escape(_ keys: String) {
        var session = InputSession(lexicon: TestLexicon(), corrections: store)
        _ = type(keys, into: &session)
        _ = session.handle(.escape)
    }

    private func revert(_ keys: String, confirmed: Bool) {
        var session = InputSession(lexicon: TestLexicon(), corrections: store)
        _ = type(keys + " ", into: &session)
        _ = session.handle(.backspace)
        if confirmed { session.confirmRevert() }
    }

    @Test func confirmedRevertKeepsVietnameseNextTime() {
        revert("text", confirmed: true)
        #expect(committed("text") == .commit(text: "tẽt", raw: "text"))
        #expect(store.preference(for: "text") == .vietnamese)
    }

    @Test func revertTheAdapterCouldNotApplyIsNotLearned() {
        revert("text", confirmed: false)
        #expect(committed("text") == .commit(text: "text", raw: "text"))
    }

    @Test func escapeKeepsTypedKeysNextTimeLiveAndOnCommit() {
        escape("is")
        var session = InputSession(lexicon: TestLexicon(), corrections: store)
        #expect(type("is", into: &session).last == .composing(display: "is", raw: "is"))
        #expect(session.handle(.character(" ")) == .commit(text: "is", raw: "is"))
    }

    @Test func escapeOnWordAlreadyShownAsTypedLearnsNothing() {
        escape("google")
        #expect(store.preference(for: "google") == nil)
    }

    @Test func learnedKeysMatchAnyCase() {
        escape("is")
        #expect(committed("Is") == .commit(text: "Is", raw: "Is"))
    }

    @Test func onlyTheExactKeysAreAffected() {
        escape("is")
        #expect(committed("isf") == .commit(text: "ì", raw: "isf"))
    }

    @Test func learnedWordThatPrefixesAVietnameseWordOnlyAffectsThoseKeys() {
        escape("now")
        var session = InputSession(lexicon: TestLexicon(), corrections: store)
        let shown = type("nowi", into: &session)
        #expect(shown[2] == .composing(display: "now", raw: "now"))
        #expect(shown[3] == .composing(display: "nơi", raw: "nowi"))
        #expect(session.handle(.character(" ")) == .commit(text: "nơi", raw: "nowi"))
    }

    @Test func forgetAllRestoresTheRules() {
        escape("is")
        store.forgetAll()
        #expect(committed("is") == .commit(text: "í", raw: "is"))
    }

    @Test func userDefaultsStoreSurvivesRelaunch() throws {
        let suite = "VietKeyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        UserDefaultsCorrectionStore(defaults: defaults).record(.typedKeys, for: "Is")
        let relaunched = UserDefaultsCorrectionStore(defaults: defaults)
        #expect(relaunched.preference(for: "is") == .typedKeys)
        relaunched.forgetAll()
        #expect(UserDefaultsCorrectionStore(defaults: defaults).preference(for: "is") == nil)
    }
}
