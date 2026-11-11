import Cocoa
import InputMethodKit

/// Where text sits on screen, as reported by the app.
enum TextGeometry {
    /// Notes puts the top of the line in `origin.y` instead of the bottom, so its rects sit one
    /// line too high (checked 2026-11-11 against a screenshot; NSTextView, as in TextEdit,
    /// reports the glyph box exactly).
    private static let clientsWithRaisedRects: Set<String> = ["com.apple.Notes"]

    /// Screen rect of `range`, or `.zero` when the app does not say.
    static func rect(of range: NSRange, in client: IMKTextInput) -> NSRect {
        var actual = NSRange(location: NSNotFound, length: 0)
        var rect = client.firstRect(forCharacterRange: range, actualRange: &actual)
        if rect == .zero {
            // Some apps answer only this older call.
            _ = client.attributes(forCharacterIndex: range.location, lineHeightRectangle: &rect)
        } else if clientsWithRaisedRects.contains(client.bundleIdentifier() ?? "") {
            rect.origin.y -= rect.height
        }
        return rect
    }
}
