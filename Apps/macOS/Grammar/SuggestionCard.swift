import Cocoa
import VietKeyCore

/// What the card's buttons do. `page` moves to the previous (-1) or next (+1) problem.
struct SuggestionActions {
    let choose: (GrammarSuggestion, String) -> Void
    let ignore: (GrammarSuggestion) -> Void
    let close: () -> Void
    let page: (Int) -> Void
}

/// One problem: its category, the sentence with the fix marked in place, Harper's explanation
/// and the fixes.
@MainActor
enum SuggestionCard {
    static let width: CGFloat = 300
    /// The same on every side, so the card's corners stay concentric with the buttons'.
    static let padding: CGFloat = 12
    static var cornerRadius: CGFloat { PillButton.cornerRadius + padding }
    private static let maxReplacements = 3
    private static let contextLength = 48

    static func make(for suggestion: GrammarSuggestion, number: Int, of count: Int, actions: SuggestionActions) -> NSView {
        let message = label(suggestion.message, size: NSFont.smallSystemFontSize, color: .secondaryLabelColor)
        let preview = NSTextField(labelWithAttributedString: preview(of: suggestion))
        preview.maximumNumberOfLines = 0
        preview.lineBreakMode = .byWordWrapping
        let card = NSStackView(views: [
            header(suggestion.category, number: number, of: count, actions: actions),
            fixed(preview), fixed(message), buttons(for: suggestion, actions: actions),
        ])
        card.orientation = .vertical
        card.alignment = .leading
        card.spacing = 10
        card.setCustomSpacing(8, after: card.arrangedSubviews[0])
        card.setCustomSpacing(4, after: card.arrangedSubviews[1])
        card.edgeInsets = NSEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        return card
    }

    private static func header(_ category: String, number: Int, of count: Int, actions: SuggestionActions) -> NSView {
        let icon = NSImageView(image: NSImage(systemSymbolName: "text.badge.checkmark", accessibilityDescription: nil) ?? NSImage())
        icon.symbolConfiguration = .init(pointSize: 12, weight: .semibold)
        icon.contentTintColor = .controlAccentColor
        let title = label(category, size: NSFont.smallSystemFontSize, color: .secondaryLabelColor, weight: .semibold)
        let row = NSStackView(views: [icon, title])
        row.spacing = 6
        if count > 1 {
            let previous = pager("chevron.left", label: "Previous", isAvailable: number > 1) { actions.page(-1) }
            let position = label("\(number) of \(count)", size: NSFont.smallSystemFontSize, color: .tertiaryLabelColor)
            let next = pager("chevron.right", label: "Next", isAvailable: number < count) { actions.page(1) }
            [previous, position, next].forEach { row.addView($0, in: .trailing) }
        }
        row.addView(PillButton(symbol: "xmark", label: "Close", handler: actions.close), in: .trailing)
        return fixed(row)
    }

    private static func buttons(for suggestion: GrammarSuggestion, actions: SuggestionActions) -> NSView {
        let fixes = suggestion.replacements.prefix(maxReplacements).enumerated().map { index, replacement in
            PillButton(replacement.isEmpty ? "Remove" : replacement, isPrimary: index == 0) {
                actions.choose(suggestion, replacement)
            }
        }
        let row = NSStackView(views: fixes)
        row.spacing = 6
        row.addView(PillButton("Ignore", isPrimary: false) { actions.ignore(suggestion) }, in: .trailing)
        return fixed(row)
    }

    /// "…He ~~go~~ goes to school." around the problem, the old text struck out in red and the
    /// best fix in green.
    private static func preview(of suggestion: GrammarSuggestion) -> NSAttributedString {
        let sentence = suggestion.sentence as NSString
        let end = suggestion.offset + suggestion.length
        let before = sentence.substring(to: suggestion.offset)
        let after = sentence.substring(from: end)
        let base: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 14), .foregroundColor: NSColor.labelColor]
        let text = NSMutableAttributedString(string: clipped(before, keepingEnd: true), attributes: base)
        var removed = base
        removed[.foregroundColor] = NSColor.systemRed
        removed[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        text.append(NSAttributedString(string: suggestion.original, attributes: removed))
        if let fix = suggestion.replacements.first, !fix.isEmpty {
            var added = base
            added[.foregroundColor] = NSColor.systemGreen
            added[.font] = NSFont.systemFont(ofSize: 14, weight: .semibold)
            text.append(NSAttributedString(string: " " + fix, attributes: added))
        }
        text.append(NSAttributedString(string: clipped(after, keepingEnd: false), attributes: base))
        return text
    }

    /// Long sentences show only the words next to the problem.
    private static func clipped(_ text: String, keepingEnd: Bool) -> String {
        guard text.count > contextLength else { return text }
        if keepingEnd {
            let tail = text.suffix(contextLength)
            return "…" + tail.drop { $0 != " " }.dropFirst()
        }
        let head = text.prefix(contextLength)
        return head[..<(head.lastIndex(of: " ") ?? head.endIndex)] + "…"
    }

    private static func pager(_ symbol: String, label: String, isAvailable: Bool, page: @escaping () -> Void) -> NSView {
        let button = PillButton(symbol: symbol, label: label, handler: page)
        button.isEnabled = isAvailable
        return button
    }

    private static func label(_ text: String, size: CGFloat, color: NSColor, weight: NSFont.Weight = .regular) -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: text)
        field.font = .systemFont(ofSize: size, weight: weight)
        field.textColor = color
        return field
    }

    /// Every section spans the card, so trailing items line up on the right edge.
    private static func fixed(_ view: NSView) -> NSView {
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
        if let field = view as? NSTextField { field.preferredMaxLayoutWidth = width }
        return view
    }
}
