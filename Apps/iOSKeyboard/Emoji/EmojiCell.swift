import UIKit

final class EmojiCell: UICollectionViewCell {
    private let label = UILabel()
    /// Nil leaves the cell blank and dead: the emoji is over the memory budget.
    var emoji: Character? {
        didSet {
            label.text = emoji.map(String.init)
            accessibilityLabel = label.text
            isAccessibilityElement = emoji != nil
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .systemFont(ofSize: 30)
        label.textAlignment = .center
        contentView.addSubview(label)
        contentView.layer.cornerRadius = KeyButton.cornerRadius
        accessibilityTraits = .keyboardKey
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Cells are built in code") }

    override var isHighlighted: Bool {
        didSet { contentView.backgroundColor = isHighlighted && emoji != nil ? .systemFill : .clear }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = contentView.bounds
    }
}
