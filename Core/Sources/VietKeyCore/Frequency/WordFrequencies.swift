import Foundation

/// How common a word is in each language, in occurrences per billion words; 0 when unknown.
public protocol WordFrequencies: Sendable {
    /// `word` is lowercase keys as typed: "this".
    func english(_ word: String) -> Int
    /// `telexKeys` spells the syllable with the tone key last: "thisf" for "thì".
    func vietnamese(telexKeys: String) -> Int
}

/// The tables bundled with VietKeyCore (FrequencyWords, CC BY-SA 4.0; see Data/LICENSE.md).
public final class BundledWordFrequencies: WordFrequencies {
    let englishCounts: [String: Int]
    let vietnameseCounts: [String: Int]

    public struct UnreadableTable: Error {
        public let name: String
    }

    public init() throws {
        englishCounts = try Self.table(named: "english")
        vietnameseCounts = try Self.table(named: "vietnamese")
    }

    public func english(_ word: String) -> Int { englishCounts[word] ?? 0 }
    public func vietnamese(telexKeys: String) -> Int { vietnameseCounts[telexKeys] ?? 0 }

    private static func table(named name: String) throws -> [String: Int] {
        guard let url = Bundle.module.url(forResource: name, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { throw UnreadableTable(name: name) }
        var counts: [String: Int] = [:]
        for line in text.split(separator: "\n") {
            guard let space = line.firstIndex(of: " "), let count = Int(line[line.index(after: space)...])
            else { throw UnreadableTable(name: name) }
            counts[String(line[..<space])] = count
        }
        return counts
    }
}

extension WordFrequencies {
    /// With no English just before, Vietnamese wins unless the keys, as an English word, are
    /// more than this many times as common. Chosen from the token-weighted sweep
    /// (FrequencyRatchetTests): x1 mangles 0.8% of English and loses 0.16% of Vietnamese to
    /// scoring; x3 gives 1.1% and 0.04%.
    static var vietnameseWeight: Double { 3 }

    func prefersVietnamese(_ composition: Composition, after context: LanguageContext) -> Bool {
        let english = english(composition.raw.lowercased())
        guard english > 0 else { return true }
        let vietnamese = Double(vietnamese(telexKeys: composition.telexKeys))
        return vietnamese * Self.vietnameseWeight * context.vietnameseFactor >= Double(english)
    }
}
