import Carbon.HIToolbox
import Cocoa
import VietKeyCore

enum KeyAction: Equatable {
    /// Feed the key to the typing session.
    case session(InputKey)
    /// Finish the current word, then let the app handle the key (shortcuts, Return, arrows...).
    case commitThenPassthrough
}

enum KeyEventMapper {
    private static let shortcutModifiers: NSEvent.ModifierFlags = [.command, .control, .option]
    private static let caretKeys: Set<Int> = [
        kVK_Return, kVK_ANSI_KeypadEnter, kVK_Tab, kVK_ForwardDelete, kVK_Home, kVK_End,
        kVK_PageUp, kVK_PageDown, kVK_LeftArrow, kVK_RightArrow, kVK_UpArrow, kVK_DownArrow,
    ]

    static func action(for event: NSEvent) -> KeyAction {
        let keyCode = Int(event.keyCode)
        if !event.modifierFlags.intersection(shortcutModifiers).isEmpty || caretKeys.contains(keyCode) {
            return .commitThenPassthrough
        }
        switch keyCode {
        case kVK_Delete: return .session(.backspace)
        case kVK_Escape: return .session(.escape)
        default:
            guard let char = event.characters?.first else { return .commitThenPassthrough }
            return .session(.character(char))
        }
    }
}
