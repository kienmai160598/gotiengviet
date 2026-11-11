/// What the words just typed say about the language, to settle keys that read as both
/// ("car": "cả" or "car"). Vietnamese chat borrows single English words ("team bên em"), so
/// English only counts once two common English words run together.
struct LanguageContext: Sendable {
    /// English words in a row since the last Vietnamese one. Words that read the same in both
    /// languages ("the", "anh") and rare ones ("ko", "dc") neither extend nor break the run.
    private var englishRun = 0

    static let afterEnglishRun = 1.0 / 100
    /// English words a run needs before it means an English sentence. Kien chose 2 over 3:
    /// "I bought a new car" right after Vietnamese keeps car, at the cost of "Unit test cả"
    /// giving car.
    static let runLength = 2
    /// Occurrences per billion an English word needs to count as evidence (20 per million).
    static let evidenceFrequency = 20_000

    /// Multiplies how much Vietnamese counts against English for the next word.
    var vietnameseFactor: Double {
        englishRun >= Self.runLength ? Self.afterEnglishRun : 1
    }

    mutating func record(committed text: String, from composition: Composition, englishFrequency: Int) {
        if text.contains(where: { !$0.isASCII }) {
            userChoseVietnamese()
        } else if text == composition.raw, englishFrequency >= Self.evidenceFrequency,
                  composition.text != composition.raw || !composition.isValidVietnamese {
            englishRun += 1
        }
    }

    mutating func userChoseVietnamese() {
        englishRun = 0
    }

    mutating func userChoseTypedKeys() {
        englishRun += 1
    }
}
