import UIKit

/// Row sizes measured from the system keyboard in portrait: iPhone 17 Pro (402 points wide,
/// iOS 26.5) and iPhone 18 Pro Max (440 wide, iOS 27.0). The Max rows are 2 points taller.
/// Landscape was measured on the Pro Max only.
struct KeyMetrics: Equatable {
    static let compact = KeyMetrics(rowHeight: 54, keyHeight: 43, bottomPadding: -2)
    static let large = KeyMetrics(rowHeight: 56, keyHeight: 43.7, bottomPadding: 0.75)
    static let landscape = KeyMetrics(rowHeight: 40, keyHeight: 32, bottomPadding: -1.75)
    /// Plus and Pro Max phones start at 428 points wide.
    private static let largeWidth: CGFloat = 428

    let rowHeight: CGFloat
    let keyHeight: CGFloat
    /// Below the bottom row; negative on the smaller phones, where the row's slot runs into
    /// the system strip below while its face still fits.
    let bottomPadding: CGFloat

    var faceInset: UIEdgeInsets {
        let vertical = (rowHeight - keyHeight) / 2
        return UIEdgeInsets(top: vertical, left: 3, bottom: vertical, right: 3)
    }

    var height: CGFloat { SuggestionBar.height + rowHeight * 4 + bottomPadding }

    /// A compact vertical size class means an iPhone on its side.
    static func `for`(width: CGFloat, traits: UITraitCollection) -> KeyMetrics {
        if traits.verticalSizeClass == .compact { return landscape }
        return width >= largeWidth ? large : compact
    }
}
