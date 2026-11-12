import UIKit

/// What each key shows. Letters follow Shift; Return names the app's action when it has one.
enum KeyLabels {
    private static let shiftSymbol: [ShiftState: String] = [.off: "shift", .once: "shift.fill", .locked: "capslock.fill"]
    private static let layerTitle: [KeyLayer: String] = [.letters: "ABC", .numbers: "123", .symbols: "#+="]
    private static let wordSize: CGFloat = 18

    @MainActor
    static func apply(to button: KeyButton, key: KeyboardKey, shift: ShiftState, returnTitle: String?) {
        button.isAccent = false
        button.show(hint: key == .space ? "VI" : nil)
        switch key {
        case .letter(let char): button.show(title: shift == .off ? String(char) : char.uppercased())
        case .symbol(let char): button.show(title: String(char))
        case .space: button.show(title: "", accessibility: "space")
        case .backspace: button.show(symbol: "delete.left", label: "Delete")
        case .globe: button.show(symbol: "globe", label: "Next keyboard")
        case .shift: button.show(symbol: shiftSymbol[shift] ?? "shift", label: "Shift")
        case .layer(.emoji): button.show(symbol: "face.smiling", label: "Emoji")
        case .layer(let target): button.show(title: layerTitle[target] ?? "", size: wordSize)
        case .newline:
            guard let returnTitle else { return button.show(symbol: "return.left", label: "Return") }
            button.show(title: returnTitle, size: wordSize)
            button.isAccent = true
        }
    }
}
