import Cocoa

/// A borderless floating panel that never becomes key or main, so the text view keeps focus.
final class NonKeyPanel: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.nonactivatingPanel, .borderless], backing: .buffered, defer: true)
        isFloatingPanel = true
        level = .popUpMenu
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// A capsule (or, with a symbol, a circle) button that runs a closure. Drawn by hand because
/// the input method is never the active app, so AppKit would draw its controls as inactive.
final class PillButton: NSButton {
    static let height: CGFloat = 28
    static var cornerRadius: CGFloat { height / 2 }
    private static let padding: CGFloat = 14
    private var handler: () -> Void = {}
    private var isPrimary = false
    private var isHovered = false

    convenience init(_ title: String, isPrimary: Bool, handler: @escaping () -> Void) {
        self.init(handler: handler)
        self.isPrimary = isPrimary
        attributedTitle = NSAttributedString(string: title, attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold),
            .foregroundColor: isPrimary ? NSColor.white : NSColor.labelColor,
        ])
        widthAnchor.constraint(equalToConstant: attributedTitle.size().width + Self.padding * 2).isActive = true
    }

    convenience init(symbol: String, label: String, handler: @escaping () -> Void) {
        self.init(handler: handler)
        image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        symbolConfiguration = .init(pointSize: 11, weight: .bold)
        contentTintColor = .labelColor
        toolTip = label
        widthAnchor.constraint(equalToConstant: Self.height).isActive = true
    }

    private convenience init(handler: @escaping () -> Void) {
        self.init(title: "", target: nil, action: nil)
        self.handler = handler
        target = self
        action = #selector(run)
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = Self.cornerRadius
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: Self.height).isActive = true
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self))
    }

    /// The panel is never key, so without this the first click would only try to focus it.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    /// Symbol images pad the alignment rect, which made circles 28 wide but 32 tall.
    override var alignmentRectInsets: NSEdgeInsets { NSEdgeInsetsZero }

    override var isEnabled: Bool {
        didSet { alphaValue = isEnabled ? 1 : 0.35 }
    }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        let fill = isPrimary ? NSColor.controlAccentColor : NSColor.labelColor.withAlphaComponent(isHovered ? 0.14 : 0.08)
        let pressed = isHighlighted ? 0.7 : 1
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = fill.withAlphaComponent(fill.alphaComponent * pressed).cgColor
        }
    }

    override func highlight(_ flag: Bool) {
        super.highlight(flag)
        needsDisplay = true
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    @objc private func run() {
        handler()
    }
}
