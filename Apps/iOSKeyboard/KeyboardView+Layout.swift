import UIKit

/// How wide each key in a row is, and where its face sits in its slot.
extension KeyboardView {
    /// Shift and Delete are narrower than their slot, leaving a gap before Z and after M.
    private static var wideKeyGap: CGFloat { 8 }

    /// A hidden key takes no room; a width of 0 takes what the row has left, so the space bar
    /// grows when the globe hides.
    static func widths(of row: [Slot]) -> [CGFloat] {
        var widths = row.map { $0.button.isHidden ? 0 : $0.units }
        guard let flexible = row.firstIndex(where: { $0.units == 0 }) else { return widths }
        widths[flexible] = KeyLayout.unitsPerRow - widths.reduce(0, +)
        return widths
    }

    /// The 1.5-unit keys beside Z and M: their gap faces the letters.
    static func extraInset(for slot: Slot) -> UIEdgeInsets {
        guard slot.units == 1.5 else { return .zero }
        return slot.key == .backspace
            ? UIEdgeInsets(top: 0, left: wideKeyGap, bottom: 0, right: 0)
            : UIEdgeInsets(top: 0, left: 0, bottom: 0, right: wideKeyGap)
    }
}
