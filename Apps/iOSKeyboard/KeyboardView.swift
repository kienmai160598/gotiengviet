import os
import UIKit
import VietKeyCore

/// The suggestion bar over four rows of keys, sized like the system keyboard (`KeyMetrics`).
/// Keys for every layer are built once; switching layers only shows another set. The emoji
/// page exists only while it is open, to keep launch and memory small.
final class KeyboardView: UIView {
    /// With each key's own inset, the outer keys sit 6.5 points from the edge.
    static let sidePadding: CGFloat = 3.5
    typealias Slot = (key: KeyboardKey, units: CGFloat, button: KeyButton)
    private let layers: [KeyLayer: [[Slot]]]
    let popup = KeyPopup()
    let repeater = KeyRepeater()
    let bar = SuggestionBar()
    private var emojiPanel: EmojiPanel?
    /// Outlives the panel, as the drawn emoji do.
    private let emojiBudget = EmojiBudget { Int(os_proc_available_memory()) }
    var rollover = KeyRollover<KeyboardKey>()
    private(set) lazy var haptics = KeyHaptics(view: self)
    var onKey: (KeyboardKey) -> Void = { _ in }

    // These are set again on every key typed, so each acts only on a change, and only on the
    // keys it changes.
    var page = KeyLayer.letters {
        didSet { if page != oldValue { showLayer() } }
    }

    var shift = ShiftState.off {
        didSet { if shift != oldValue { relabel { if case .letter = $0 { true } else { $0 == .shift } } } }
    }

    var showsGlobe = true {
        didSet {
            guard showsGlobe != oldValue else { return }
            globeKeys.forEach { $0.isHidden = !showsGlobe }
            setNeedsLayout()
        }
    }

    /// The name of the app's action, "Send" or "Search"; nil shows the return arrow.
    var returnTitle: String? {
        didSet { if returnTitle != oldValue { relabel { $0 == .newline } } }
    }

    var globeKeys: [KeyButton] { slots(in: KeyLayer.allCases).filter { $0.key == .globe }.map(\.button) }

    init() {
        layers = Dictionary(uniqueKeysWithValues: KeyLayer.allCases.map { layer in
            (layer, KeyLayout.rows(for: layer).map { $0.map { ($0.key, $0.units, KeyButton()) } })
        })
        super.init(frame: .zero)
        // A keyboard gets no touches on clear pixels (seen in the iOS 26.5 simulator), and the
        // gaps between key faces are clear: about a third of the keys' area. This is too faint
        // to see and enough to get the touches.
        backgroundColor = UIColor(white: 0.5, alpha: 0.001)
        addSubview(bar)
        bar.onEmoji = { [weak self] in self?.typeEmoji($0) }
        for slot in slots(in: KeyLayer.allCases) {
            addSubview(slot.button)
            slot.button.extraInset = Self.extraInset(for: slot)
            wire(slot)
        }
        addSubview(popup)
        relabel { _ in true }
        showLayer()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("The keyboard is built in code") }

    /// A touch beside the outer keys, at the screen edge or left of A, goes to the nearest key.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        guard hit === self, point.y >= bar.frame.maxY else { return hit }
        return nearestKey(to: point) ?? hit
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let metrics = KeyMetrics.for(width: bounds.width, traits: traitCollection)
        // From the bottom, like the system keys: while the keyboard opens iOS can make the view
        // taller for a moment (444 or even 874 points for 244 asked), which lifted everything.
        let content = CGRect(x: 0, y: bounds.height - metrics.height, width: bounds.width, height: metrics.height)
        bar.frame = CGRect(x: 0, y: content.minY, width: bounds.width, height: SuggestionBar.height)
        popup.frame = bounds
        emojiPanel?.frame = content
        emojiPanel?.metrics = metrics
        let unit = (bounds.width - Self.sidePadding * 2) / KeyLayout.unitsPerRow
        for (index, row) in (layers[page] ?? []).enumerated() {
            let widths = Self.widths(of: row)
            var x = Self.sidePadding + (KeyLayout.unitsPerRow - widths.reduce(0, +)) / 2 * unit
            let y = bar.frame.maxY + CGFloat(index) * metrics.rowHeight
            for (slot, units) in zip(row, widths) where !slot.button.isHidden {
                slot.button.faceInset = metrics.faceInset
                slot.button.frame = CGRect(x: x, y: y, width: units * unit, height: metrics.rowHeight)
                x += units * unit
            }
        }
    }

    private func showLayer() {
        let shown = Set(slots(in: [page]).map { ObjectIdentifier($0.button) })
        for slot in slots(in: KeyLayer.allCases) {
            slot.button.alpha = shown.contains(ObjectIdentifier(slot.button)) ? 1 : 0
            slot.button.isUserInteractionEnabled = shown.contains(ObjectIdentifier(slot.button))
            slot.button.accessibilityElementsHidden = !shown.contains(ObjectIdentifier(slot.button))
        }
        bar.isHidden = page == .emoji
        if page == .emoji, emojiPanel == nil { emojiPanel = makeEmojiPanel() }
        if page != .emoji, let panel = emojiPanel {
            repeater.stop() // A held Delete goes away with the panel and never lifts.
            panel.removeFromSuperview()
            emojiPanel = nil
        }
        setNeedsLayout()
    }

    private func makeEmojiPanel() -> EmojiPanel {
        let panel = EmojiPanel(budget: emojiBudget)
        panel.onEmoji = { [weak self] in self?.typeEmoji($0) }
        wire((.layer(.letters), 0, panel.lettersKey))
        wire((.backspace, 0, panel.deleteKey))
        addSubview(panel)
        return panel
    }

    func slots(in layers: [KeyLayer]) -> [Slot] {
        layers.flatMap { (self.layers[$0] ?? []).joined() }
    }

    private func typeEmoji(_ emoji: Character) {
        haptics.tick()
        onKey(.symbol(emoji))
    }

    private func relabel(where changes: (KeyboardKey) -> Bool) {
        for slot in slots(in: KeyLayer.allCases) where changes(slot.key) {
            KeyLabels.apply(to: slot.button, key: slot.key, shift: shift, returnTitle: returnTitle)
        }
    }
}
