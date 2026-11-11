import Testing
import VietKeyCore

/// The words just typed settle keys that read as both languages. Sentences are typed with
/// Telex (tone key last) and must come out exactly as written.
struct ContextTests {
    static let vietnameseWithEnglishTerms = [
        "Ok, cả nhà ơi, mai mình họp lúc chín giờ nhé.",
        "Anh check lại cái list này giúp em với.",
        "Mai mình deploy lên server production nhé.",
        "Bug này là do cache chưa được clear.",
        "Em test xong rồi, pass hết cả.",
        "Push code lên main rồi tạo pull request nhé.",
        "Sorry anh, em quên mất cái meeting sáng nay.",
        "Cảm ơn bạn, mình sẽ review lại cái design.",
        "Thế thì để em fix trong sprint này.",
        "Tất cả các test case đều pass rồi.",
        "Đừng merge vội, còn một số comment chưa resolve.",
        "Cái màn hình bên trái bị lỗi layout.",
        "Ít nhất phải có unit test cho phần này.",
        "Unit test cả ngày chưa pass.",
        "Pull request bên em chưa merge.",
        "Ok ko sao, cả nhà cứ làm đi.",
        "Merge request ít quá.",
        "Hôm nay em đi bus, con virus này lây nhanh quá.",
        "Dc r, mai mình review code cả buổi sáng.",
        "Team bên em làm xong chưa?",
        "Mình gửi file bên anh rồi nhé.",
    ]

    static let english = [
        "I bought a new car last week.",
        "There are six people in the room.",
        "These are my own ideas, not hers.",
        "I have been there before.",
        "The moon is bright tonight.",
        "Can you send me the list of tasks?",
        "Please fix the build before the release.",
    ]

    static let vietnamese = [
        "Tôi có thể đến muộn một chút.",
        "Môn toán của em được mười điểm.",
        "Anh ấy là ca sĩ nổi tiếng.",
        "Bác sĩ bảo anh ấy nghỉ thêm sáu ngày.",
        "Ở bên kia có một cái tô lớn.",
    ]

    private static func newSession() -> InputSession {
        InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: InMemoryCorrectionStore())
    }

    /// `asParagraph`: typed one after another in the same field, so each sentence starts
    /// with the previous one as context.
    private static func wrongWords(in sentences: [String], asParagraph: Bool) -> [String] {
        var session = newSession()
        return sentences.flatMap { sentence in
            if !asParagraph { session = newSession() }
            let produced = SentenceTyper.type(sentence + " ", into: &session) ?? ""
            return SentenceTyper.errors(expected: sentence, produced: produced).map { "\($0.expected)→\($0.produced)" }
        }
    }

    /// Ratchet. Known misses: tô is typed "too", far more common in English even right after
    /// Vietnamese; two English words in a row ("Unit test cả", "Pull request bên") read as an
    /// English sentence.
    @Test(arguments: [(vietnameseWithEnglishTerms, 2), (vietnamese, 1)])
    func vietnameseSentencesComeOutAsWritten(sentences: [String], baseline: Int) {
        let wrong = Self.wrongWords(in: sentences, asParagraph: false)
        #expect(wrong.count <= baseline, "\(wrong)")
    }

    @Test func englishParagraphComesOutAsWritten() {
        let wrong = Self.wrongWords(in: Self.english, asParagraph: true)
        #expect(wrong.isEmpty, "\(wrong)")
    }

    /// Ratchet. With nothing typed before, a sentence opening "There"/"These" reads as the
    /// more common thể/thế, and that wrong Vietnamese then weakens the context for the rest.
    @Test func englishSentencesWithoutContextStillMissSome() {
        let wrong = Self.wrongWords(in: Self.english, asParagraph: false)
        #expect(wrong.count <= 8, "\(wrong)")
    }

    @Test func escapeCountsAsEnglishAndAConfirmedRevertAsVietnamese() {
        var session = Self.newSession()
        for word in ["car", "six"] {
            word.forEach { _ = session.handle(.character($0)) }
            _ = session.handle(.escape)
            _ = session.handle(.character(" "))
        }
        #expect(SentenceTyper.type("own ", into: &session) == "own ")
        _ = SentenceTyper.type("text ", into: &session)
        _ = session.handle(.backspace)
        session.confirmRevert()
        #expect(SentenceTyper.type(" own ", into: &session) == " ơn ")
    }

    /// Backspacing over "is " reverts it to "í" first; the second Backspace shows the user was
    /// deleting, so the English run stands.
    @Test func revertThatIsDeletedLeavesTheContextAlone() {
        var session = Self.newSession()
        _ = SentenceTyper.type("you know is ", into: &session)
        _ = session.handle(.backspace)
        session.confirmRevert()
        _ = session.handle(.backspace)
        #expect(SentenceTyper.type("car ", into: &session) == "car ")
    }

    /// Ratchet. Right after a Vietnamese sentence an English one has no run yet, so its first
    /// colliding words ("There", "six" after "are") can still read as Vietnamese.
    @Test func englishAfterVietnameseInTheSameField() {
        let wrong = Self.english.flatMap { sentence in
            var session = Self.newSession()
            _ = SentenceTyper.type("Hôm nay mình làm việc này. ", into: &session)
            let produced = SentenceTyper.type(sentence + " ", into: &session) ?? ""
            return SentenceTyper.errors(expected: sentence, produced: produced).map { "\($0.expected)→\($0.produced)" }
        }
        #expect(wrong.count <= 7, "\(wrong)")
    }
}
