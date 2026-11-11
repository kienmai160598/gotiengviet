import VietKeyCore

/// Types a sentence the way a Telex user would (Vietnamese words as Telex keys, English words
/// as written) and rebuilds the text the app ends up with.
enum SentenceTyper {
    struct WordError: Hashable {
        let expected: String
        let produced: String
    }

    /// nil when a word cannot be typed with Telex (digits inside words, foreign letters).
    static func type(_ sentence: String, into session: inout InputSession) -> String? {
        var output = ""
        for run in runs(of: sentence) {
            if run.first!.isLetter {
                guard let keys = keys(for: run) else { return nil }
                keys.forEach { output += applied(session.handle(.character($0)), key: $0) }
            } else {
                run.forEach { output += applied(session.handle(.character($0)), key: $0) }
            }
        }
        if session.isComposing { output += applied(session.commit(), key: nil) }
        return output
    }

    /// Word-by-word differences, ignoring tone placement style (hòa and hoà match).
    static func errors(expected: String, produced: String) -> [WordError] {
        let pairs = zip(runs(of: expected).filter { $0.first!.isLetter }, runs(of: produced).filter { $0.first!.isLetter })
        return pairs.filter { !matches($0, $1) }.map { WordError(expected: String($0), produced: String($1)) }
    }

    static func wordCount(_ sentence: String) -> Int {
        runs(of: sentence).filter { $0.first!.isLetter }.count
    }

    /// Raw keys ("too") never match the Vietnamese they spell ("tô"); only the two tone
    /// placement styles of the same Vietnamese word do.
    private static func matches(_ expected: Substring, _ produced: Substring) -> Bool {
        guard expected != produced else { return true }
        let bothVietnamese = [expected, produced].allSatisfy { $0.contains { !$0.isASCII } }
        return bothVietnamese
            && expected.first?.isUppercase == produced.first?.isUppercase
            && TelexKeys.keys(for: String(expected)) == TelexKeys.keys(for: String(produced))
    }

    private static func keys(for word: Substring) -> String? {
        if word.allSatisfy(\.isASCII) { return String(word) }
        guard let keys = TelexKeys.keys(for: String(word)) else { return nil }
        return word.first!.isUppercase ? keys.prefix(1).uppercased() + keys.dropFirst() : keys
    }

    private static func applied(_ update: CompositionUpdate, key: Character?) -> String {
        let passed = key.map(String.init) ?? ""
        switch update {
        case .commit(let text, _): return text + (key?.isLetter == false ? passed : "")
        case .passthrough: return passed
        case .composing, .revert: return ""
        }
    }

    private static func runs(of text: String) -> [Substring] {
        var runs: [Substring] = []
        var start = text.startIndex
        for index in text.indices.dropFirst() where text[index].isLetter != text[text.index(before: index)].isLetter {
            runs.append(text[start..<index])
            start = index
        }
        if start < text.endIndex { runs.append(text[start...]) }
        return runs
    }
}
