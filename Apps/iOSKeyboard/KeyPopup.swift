import UIKit

/// The balloon that shows the pressed letter above the finger on iPhone. It is drawn inside
/// the keyboard, as an extension cannot draw outside its view, so the suggestion bar above the
/// top row leaves it room.
final class KeyPopup: UIView {
    private static let spread: CGFloat = 10
    private static let balloonHeight: CGFloat = 54
    private static let fontSize: CGFloat = 36
    /// The outer keys' face margin: over Q and P the balloon grows inward, as on iOS.
    private static let edge: CGFloat = 6.5
    private let shape = CAShapeLayer()
    private let label = UILabel()

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isHidden = true
        shape.shadowColor = UIColor.black.cgColor
        shape.shadowOpacity = 0.25
        shape.shadowRadius = 4
        shape.shadowOffset = CGSize(width: 0, height: 1)
        layer.addSublayer(shape)
        label.textAlignment = .center
        label.textColor = .label
        addSubview(label)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("The popup is built in code") }

    /// `face` is the key's face in this view's coordinates.
    func show(_ text: String, over face: CGRect) {
        let balloon = balloonFrame(over: face)
        shape.path = Self.path(face: face, balloon: balloon)
        shape.shadowPath = shape.path
        shape.fillColor = KeyButton.faceColor.resolvedColor(with: traitCollection).cgColor
        label.text = text
        label.frame = balloon.insetBy(dx: 0, dy: 4)
        // Over the top row the balloon is cut short by the top of the keyboard.
        label.font = .systemFont(ofSize: min(Self.fontSize, label.frame.height * 0.85))
        isHidden = false
    }

    func hide() {
        isHidden = true
    }

    /// Wider than the key, kept inside the keyboard at the edges and at the top.
    private func balloonFrame(over face: CGRect) -> CGRect {
        let width = face.width + Self.spread * 2
        let x = min(max(face.minX - Self.spread, Self.edge), bounds.width - Self.edge - width)
        let top = max(face.minY - Self.balloonHeight, 0)
        return CGRect(x: x, y: top, width: width, height: face.minY - top + 6)
    }

    /// The balloon, the key below it and a neck between them, filled as one shape.
    private static func path(face: CGRect, balloon: CGRect) -> CGPath {
        let radius = KeyButton.cornerRadius
        let path = UIBezierPath(roundedRect: balloon, cornerRadius: radius + 2)
        path.append(UIBezierPath(roundedRect: face, cornerRadius: radius))
        // Clockwise like the rounded rects, so the overlaps fill instead of cancelling.
        let neck = UIBezierPath()
        neck.move(to: CGPoint(x: balloon.maxX, y: balloon.maxY - radius))
        neck.addQuadCurve(to: CGPoint(x: face.maxX, y: face.minY + radius), controlPoint: CGPoint(x: face.maxX, y: balloon.maxY))
        neck.addLine(to: CGPoint(x: face.minX, y: face.minY + radius))
        neck.addQuadCurve(to: CGPoint(x: balloon.minX, y: balloon.maxY - radius), controlPoint: CGPoint(x: face.minX, y: balloon.maxY))
        neck.close()
        path.append(neck)
        return path.cgPath
    }
}
