import UIKit
import VietKeyCore

/// The app's text as Core sees it, through the keyboard's document proxy. UIKit calls a keyboard
/// only on the main thread, so the proxy is used there.
@MainActor
struct ProxyDocument: @MainActor TextDocument {
    let proxy: UITextDocumentProxy

    var textBeforeCaret: String? { proxy.documentContextBeforeInput }

    /// Text before the caret or a selection, which is what Delete removes.
    var hasTextToDelete: Bool {
        textBeforeCaret?.isEmpty == false || proxy.selectedText?.isEmpty == false
    }

    func setMarkedText(_ text: String) {
        proxy.setMarkedText(text, selectedRange: NSRange(location: text.utf16.count, length: 0))
    }

    func unmarkText() { proxy.unmarkText() }
    func insertText(_ text: String) { proxy.insertText(text) }
    func deleteBackward() { proxy.deleteBackward() }
}
