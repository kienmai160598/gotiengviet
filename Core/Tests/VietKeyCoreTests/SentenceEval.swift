import Foundation
import Testing
import VietKeyCore

/// Word error rates on running text from Tatoeba (CC BY 2.0 FR, not in the repo).
/// Run: VIETKEY_TATOEBA_DIR=/path/with/vie.tsv+eng.tsv swift test --filter SentenceEval
struct SentenceEval {
    private static let directory = ProcessInfo.processInfo.environment["VIETKEY_TATOEBA_DIR"]

    private static func newSession() -> InputSession {
        InputSession(lexicon: TestLexicon(), frequencies: testFrequencies, corrections: InMemoryCorrectionStore())
    }

    private func sentences(_ file: String, every step: Int) throws -> [String] {
        let text = try String(contentsOfFile: "\(Self.directory!)/\(file)", encoding: .utf8)
        let lines = text.split(separator: "\n")
        return stride(from: 0, to: lines.count, by: step).compactMap { lines[$0].split(separator: "\t").last.map(String.init) }
    }

    enum Mode: CaseIterable {
        /// Every sentence starts without context.
        case fresh
        /// One session for the whole file, as when writing a document.
        case carried
        /// Every sentence follows a short Vietnamese one in the same field.
        case afterVietnamese
    }

    @Test(.enabled(if: directory != nil), arguments: [("vie.tsv", 1), ("eng.tsv", 60)], Mode.allCases)
    func report(file: (name: String, step: Int), mode: Mode) throws {
        var words = 0, skipped = 0
        var errors: [SentenceTyper.WordError: Int] = [:]
        var session = Self.newSession()
        for sentence in try sentences(file.name, every: file.step) {
            if mode != .carried { session = Self.newSession() }
            if mode == .afterVietnamese { _ = SentenceTyper.type("Hôm nay mình làm việc này. ", into: &session) }
            guard let produced = SentenceTyper.type(sentence, into: &session) else { skipped += 1; continue }
            words += SentenceTyper.wordCount(sentence)
            SentenceTyper.errors(expected: sentence, produced: produced).forEach { errors[$0, default: 0] += 1 }
        }
        let wrong = errors.values.reduce(0, +)
        let top = errors.sorted { $0.value > $1.value }.prefix(25).map { "\($0.key.expected)→\($0.key.produced) \($0.value)" }
        print("EVAL \(file.name) \(mode): \(wrong)/\(words) words wrong (\(String(format: "%.3f", Double(wrong) / Double(words) * 100))%), skipped \(skipped) sentences\n  \(top.joined(separator: ", "))")
    }
}
