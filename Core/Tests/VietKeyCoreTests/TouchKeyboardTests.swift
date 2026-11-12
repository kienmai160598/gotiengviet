import Testing
import VietKeyCore

/// A text view as a touch keyboard sees it: committed text plus marked text at the caret.
private final class FakeDocument: TextDocument {
    var text = ""
    var marked = ""
    var textBeforeCaret: String? { text }

    func setMarkedText(_ text: String) { marked = text }
    func unmarkText() { text += marked; marked = "" }
    func insertText(_ inserted: String) { text += inserted; marked = "" }
    func deleteBackward() { _ = text.popLast() }
}

struct TouchKeyboardTests {
    private let document = FakeDocument()
    private var keyboard = TouchKeyboard(session: InputSession(
        lexicon: TestLexicon(), frequencies: testFrequencies, corrections: InMemoryCorrectionStore()
    ))

    private mutating func type(_ keys: String) {
        keys.forEach { keyboard.press(.character($0), in: document) }
    }

    @Test mutating func showsTheWordAsMarkedTextUntilABoundary() {
        type("vieetj")
        #expect(document.marked == "việt")
        #expect(document.text.isEmpty)
        type(" ")
        #expect(document.text == "việt ")
        #expect(document.marked.isEmpty)
    }

    @Test mutating func typesBoundaryKeysAndNewlinesItself() {
        type("hello, ")
        keyboard.press(.newline, in: document)
        type("!")
        #expect(document.text == "hello, \n!")
    }

    @Test mutating func backspaceEditsTheWordThenTheDocument() {
        type("ab ")
        type("cd")
        keyboard.press(.backspace, in: document)
        #expect(document.marked == "c")
        keyboard.press(.backspace, in: document)
        keyboard.press(.backspace, in: document)
        #expect(document.text == "ab")
        #expect(document.marked.isEmpty)
    }

    @Test mutating func backspaceAfterABoundaryRestoresTheShownVietnamese() {
        type("text ")
        #expect(document.text == "text ")
        keyboard.press(.backspace, in: document)
        #expect(document.text == "tẽt")
    }

    @Test mutating func revertOnlyDeletesWhenTheTextIsStillThere() {
        type("text ")
        document.text = "changed"
        keyboard.press(.backspace, in: document)
        #expect(document.text == "change")
    }

    @Test mutating func backspaceOverTheBoundaryReopensTheWord() {
        type("hoa ")
        keyboard.press(.backspace, in: document)
        #expect(document.text.isEmpty && document.marked == "hoa")
        type("f ")
        #expect(document.text == "hòa ")
    }

    @Test mutating func aWordIsReopenedOnlyWhenItIsStillThere() {
        type("hoa ")
        document.text = "hoa,"
        keyboard.press(.backspace, in: document)
        #expect(document.text == "hoa" && !keyboard.isComposing)
    }

    @Test mutating func endingTheWordCommitsItWithoutABoundary() {
        type("dduwowngf")
        keyboard.endWord(in: document)
        #expect(document.text == "đường")
        #expect(!keyboard.isComposing)
    }

    @Test mutating func offersAndKeepsTheKeysAsTyped() {
        type("car")
        #expect(document.marked == "cả")
        #expect(keyboard.typedKeys == "car")
        keyboard.press(.keepAsTyped, in: document)
        #expect(document.text == "car")
        #expect(keyboard.typedKeys == nil)
        type(" ")
        #expect(document.text == "car ")
    }

    @Test mutating func offersNothingWhenTheKeysAreShown() {
        type("goog")
        #expect(keyboard.typedKeys == nil)
    }

    @Test mutating func aChosenWordReplacesTheWordAndAddsASpace() {
        type("toi")
        keyboard.replaceWord(with: "tôi", in: document)
        #expect(document.text == "tôi ")
        #expect(keyboard.word == nil)
        type("a ")
        #expect(document.text == "tôi a ")
    }

    /// "unit test car" keeps car; a word chosen with its marks ends the English run.
    @Test mutating func aChosenWordCountsAsVietnameseForTheNextWords() {
        type("unit test ban")
        keyboard.replaceWord(with: "bạn", in: document)
        type("car ")
        #expect(document.text == "unit test bạn cả ")
    }

    @Test mutating func anEmojiEndsTheWordLikeAnyBoundary() {
        type("vieetj😂")
        #expect(document.text == "việt😂")
        #expect(!keyboard.isComposing)
    }

    @Test mutating func aDroppedWordDoesNotComeBack() {
        type("ok")
        document.marked = ""
        keyboard.dropWord()
        type("a ")
        #expect(document.text == "a ")
    }
}

struct SentenceStartTests {
    @Test(arguments: [nil, "", "Hi. ", "Hi?  ", "line\n", "   "])
    func capitalises(before: String?) {
        #expect(SentenceFinder.startsSentence(after: before))
    }

    @Test(arguments: ["Hi.", "hello ", "3.14", "e.g. this "])
    func keepsLowercase(before: String) {
        #expect(!SentenceFinder.startsSentence(after: before))
    }
}
