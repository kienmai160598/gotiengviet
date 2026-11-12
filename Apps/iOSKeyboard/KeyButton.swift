import UIKit

/// One key, styled like the iOS 26 keyboard: every key the same colour, no shadow. The whole
/// slot takes touches, so a tap between two keys still lands on one; the face sits inside it.
final class KeyButton: UIControl {
    static let cornerRadius: CGFloat = 8.5
    static let faceColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.30, alpha: 1) : .white }
    private static let pressedColor = UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(white: 0.20, alpha: 1) : UIColor(red: 0.67, green: 0.70, blue: 0.74, alpha: 1)
    }

    private let face = UIView()
    private let label = UILabel()
    private let icon = UIImageView()
    private let hintLabel = UILabel()
    var faceInset = KeyMetrics.compact.faceInset {
        didSet { if faceInset != oldValue { setNeedsLayout() } }
    }
    /// Extra room beside the face, so Shift and Delete stand apart from the letters.
    var extraInset = UIEdgeInsets.zero
    /// Return turns blue when the app names its action ("Send", "Search").
    var isAccent = false {
        didSet { updateFace() }
    }

    var faceFrame: CGRect { face.frame }

    init() {
        super.init(frame: .zero)
        face.isUserInteractionEnabled = false
        face.layer.cornerRadius = Self.cornerRadius
        face.layer.cornerCurve = .continuous
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        icon.contentMode = .center
        hintLabel.font = .systemFont(ofSize: 11)
        hintLabel.textColor = .secondaryLabel
        [face, label, icon, hintLabel].forEach(addSubview)
        isAccessibilityElement = true
        accessibilityTraits = .keyboardKey
        updateFace()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Keys are built in code") }

    /// `size` 22 for a letter, as measured against the system keys; smaller for "123", "Send".
    func show(title: String, size: CGFloat = 22, accessibility: String? = nil) {
        label.text = title
        label.font = .systemFont(ofSize: size)
        icon.image = nil
        accessibilityLabel = accessibility ?? title
        setNeedsLayout()
    }

    /// Small text in the face's bottom-right corner, like "VI" on the iOS space bar.
    func show(hint: String?) {
        hintLabel.text = hint
    }

    func show(symbol: String, label accessibility: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        icon.image = UIImage(systemName: symbol, withConfiguration: config)
        label.text = nil
        accessibilityLabel = accessibility
    }

    override var isHighlighted: Bool {
        didSet { updateFace() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = faceInset
        face.frame = bounds.inset(by: UIEdgeInsets(
            top: inset.top, left: inset.left + extraInset.left,
            bottom: inset.bottom, right: inset.right + extraInset.right
        ))
        let inside = face.frame
        label.frame = inside.insetBy(dx: 4, dy: 0).offsetBy(dx: 0, dy: glyphOffset)
        icon.frame = inside
        hintLabel.sizeToFit()
        hintLabel.frame.origin = CGPoint(x: inside.maxX - hintLabel.frame.width - 6, y: inside.maxY - hintLabel.frame.height - 3)
    }

    /// A label centres its line, which keeps room for descenders, so lowercase letters sit low.
    /// This centres the letters themselves: their x-height, or cap height for capitals.
    private var glyphOffset: CGFloat {
        guard let font = label.font, let text = label.text else { return 0 }
        let isLowercase = text == text.lowercased() && text != text.uppercased()
        return font.lineHeight / 2 - font.ascender + (isLowercase ? font.xHeight : font.capHeight) / 2
    }

    private func updateFace() {
        // A blue Return stays blue while pressed.
        face.backgroundColor = isAccent ? .systemBlue : isHighlighted ? Self.pressedColor : Self.faceColor
        let ink: UIColor = isAccent ? .white : .label
        label.textColor = ink
        icon.tintColor = ink
    }
}
