import Foundation

/// The emoji the keyboard offers, in Unicode's groups (`Tools/make-emoji-table.py`).
enum EmojiCatalog {
    /// A fixed set for the bar; nothing counts which emoji the user picks yet.
    static let favourites: [Character] = ["😂", "❤️", "🥰", "👍", "😭", "🙏", "😘", "😊"]

    /// An SF Symbol and a spoken name for each group, in the table's order.
    static let tabs: [(symbol: String, name: String)] = [
        ("face.smiling", "Smileys"), ("person", "People"), ("pawprint", "Animals and nature"),
        ("fork.knife", "Food and drink"), ("car", "Travel and places"), ("soccerball", "Activities"),
        ("lightbulb", "Objects"), ("heart", "Symbols"), ("flag", "Flags"),
    ]

    /// One group per line of emoji.txt. Empty when the table is missing, which leaves the
    /// emoji page blank but the rest of the keyboard working.
    static func loadGroups() -> [[Character]] {
        guard let url = Bundle.main.url(forResource: "emoji", withExtension: "txt"),
              let table = try? String(contentsOf: url, encoding: .utf8)
        else {
            Trace.log("emoji table is missing from the keyboard bundle")
            return []
        }
        return table.split(separator: "\n").map { line in
            line.split(separator: " ").compactMap { $0.count == 1 ? $0.first : nil }
        }
    }
}
