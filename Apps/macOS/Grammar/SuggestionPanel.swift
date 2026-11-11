import Cocoa
import VietKeyCore

/// The floating Liquid Glass card under a checked sentence, one problem at a time.
@MainActor
final class SuggestionPanel {
    static let shared = SuggestionPanel()
    private static let gap: CGFloat = 6
    private let panel = NonKeyPanel()
    private var suggestions: [GrammarSuggestion] = []
    private var index = 0
    private var line = NSRect.zero
    private var actions: SuggestionActions?

    private init() {}

    /// Whether the pointer is over the card, e.g. while clicking a fix.
    var containsMouse: Bool {
        panel.isVisible && panel.frame.contains(NSEvent.mouseLocation)
    }

    /// Shows `suggestions` under `line`. Showing a shorter list after a fix keeps the position
    /// in the list, so the next problem comes up.
    func show(_ suggestions: [GrammarSuggestion], below line: NSRect,
              choose: @escaping (GrammarSuggestion, String) -> Void,
              ignore: @escaping (GrammarSuggestion) -> Void,
              close: @escaping () -> Void) {
        guard !suggestions.isEmpty else { return hide() }
        index = panel.isVisible ? min(index, suggestions.count - 1) : 0
        self.suggestions = suggestions
        self.line = line
        actions = SuggestionActions(choose: choose, ignore: ignore, close: close) { [weak self] in self?.page($0) }
        render()
    }

    func hide() {
        panel.orderOut(nil)
        suggestions = []
        actions = nil
    }

    private func page(_ step: Int) {
        index = min(max(index + step, 0), suggestions.count - 1)
        render()
    }

    private func render() {
        guard let actions else { return }
        let card = SuggestionCard.make(for: suggestions[index], number: index + 1, of: suggestions.count, actions: actions)
        let glass = NSGlassEffectView()
        glass.cornerRadius = SuggestionCard.cornerRadius
        glass.contentView = card
        panel.contentView = glass
        let size = card.fittingSize
        panel.setContentSize(size)
        panel.setFrameOrigin(Self.origin(for: size, below: line))
        guard !panel.isVisible else { return }
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1
        }
    }

    /// Under the line, or above it when there is no room below; kept on the line's screen.
    private static func origin(for size: NSSize, below line: NSRect) -> NSPoint {
        let screen = NSScreen.screens.first { $0.frame.intersects(line) } ?? NSScreen.main
        let visible = screen?.visibleFrame ?? line
        var y = line.minY - size.height - gap
        if y < visible.minY { y = line.maxY + gap }
        let x = min(max(line.minX - SuggestionCard.padding, visible.minX), visible.maxX - size.width)
        return NSPoint(x: x, y: y)
    }
}
