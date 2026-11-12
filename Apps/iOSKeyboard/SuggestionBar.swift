import UIKit

enum Suggestion: Equatable {
    /// The keys as typed while the word shows something else: "car" while "cả" shows.
    case keepTyped(String)
    /// The word with its marks: "tôi" for "toi".
    case word(String)
}

/// The strip above the keys. While a word is typed it has three slots split by thin lines,
/// like the iOS predictions: the best suggestion in the middle and the keys as typed, when
/// offered, on the left. With nothing to suggest it is a row of emoji.
final class SuggestionBar: UIView {
    /// On an iPhone (iOS 27.2) iOS draws about 16 points of its own glass above a custom
    /// keyboard in Messages and other Liquid Glass apps, which the keyboard cannot draw into.
    /// With it, 30 puts the keys where the system keyboard has them, 52 points below the top.
    /// Without it (VietKey's own app) there is no strip, so the content stays mid-bar.
    nonisolated static let height: CGFloat = 30
    private static let separatorHeight: CGFloat = 18
    private let slots = (0..<3).map { _ in UIButton(type: .system) }
    private let separators = (0..<2).map { _ in UIView() }
    private let emoji = EmojiRow(emoji: EmojiCatalog.favourites)
    private var shown: [Suggestion?] = [nil, nil, nil]
    var onSelect: (Suggestion) -> Void = { _ in }
    var onEmoji: (Character) -> Void {
        get { emoji.onEmoji }
        set { emoji.onEmoji = newValue }
    }

    init() {
        super.init(frame: .zero)
        for (index, slot) in slots.enumerated() {
            slot.titleLabel?.font = .systemFont(ofSize: 15)
            slot.titleLabel?.lineBreakMode = .byTruncatingMiddle
            slot.tintColor = .label
            slot.addAction(UIAction { [weak self] _ in self?.select(index) }, for: .touchUpInside)
            addSubview(slot)
        }
        separators.forEach {
            $0.backgroundColor = .separator
            addSubview($0)
        }
        addSubview(emoji)
        slots.forEach { $0.isHidden = true }
        separators.forEach { $0.isHidden = true }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("The bar is built in code") }

    /// Called on every key typed. Without animation: a system button fades its title in.
    func show(_ suggestions: [Suggestion]) {
        let arranged = Self.arrange(suggestions)
        guard arranged != shown else { return }
        shown = arranged
        UIView.performWithoutAnimation {
            for (slot, suggestion) in zip(slots, shown) {
                slot.setTitle(suggestion.map(Self.title), for: .normal)
                slot.isHidden = suggestion == nil
                slot.layoutIfNeeded()
            }
        }
        let isEmpty = shown.allSatisfy { $0 == nil }
        emoji.isHidden = !isEmpty
        separators.forEach { $0.isHidden = isEmpty }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        emoji.frame = bounds
        let width = bounds.width / 3
        for (index, slot) in slots.enumerated() {
            slot.frame = CGRect(x: CGFloat(index) * width, y: 0, width: width, height: bounds.height).insetBy(dx: 6, dy: 0)
        }
        for (index, line) in separators.enumerated() {
            let x = CGFloat(index + 1) * width
            line.frame = CGRect(x: x, y: (bounds.height - Self.separatorHeight) / 2, width: 1 / traitCollection.displayScale, height: Self.separatorHeight)
        }
    }

    /// Keep-as-typed on the left, then the best word in the middle and the next on the right.
    private static func arrange(_ suggestions: [Suggestion]) -> [Suggestion?] {
        var slots: [Suggestion?] = [nil, nil, nil]
        var words = suggestions.filter { if case .word = $0 { true } else { false } }[...]
        if let keep = suggestions.first(where: { if case .keepTyped = $0 { true } else { false } }) {
            slots[0] = keep
        } else if words.count > 1 {
            slots[0] = words.remove(at: words.index(after: words.startIndex))
        }
        slots[1] = words.popFirst()
        slots[2] = words.popFirst()
        return slots
    }

    /// Quoted, as iOS quotes the word you typed when it would otherwise correct it.
    private static func title(for suggestion: Suggestion) -> String {
        switch suggestion {
        case .keepTyped(let keys): "“\(keys)”"
        case .word(let word): word
        }
    }

    private func select(_ index: Int) {
        guard let suggestion = shown[index] else { return }
        onSelect(suggestion)
    }
}
