import UIKit

/// A few emoji across the bar, shown while there is no word to suggest marks for.
final class EmojiRow: UIView {
    private let buttons: [UIButton]
    var onEmoji: (Character) -> Void = { _ in }

    init(emoji: [Character]) {
        buttons = emoji.map { _ in UIButton(type: .system) }
        super.init(frame: .zero)
        for (emoji, button) in zip(emoji, buttons) {
            button.setTitle(String(emoji), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 22)
            button.addAction(UIAction { [weak self] _ in self?.onEmoji(emoji) }, for: .touchUpInside)
            addSubview(button)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("The row is built in code") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = (bounds.width - KeyboardView.sidePadding * 2) / CGFloat(buttons.count)
        for (index, button) in buttons.enumerated() {
            button.frame = CGRect(x: KeyboardView.sidePadding + CGFloat(index) * width, y: 0, width: width, height: bounds.height)
        }
    }
}
