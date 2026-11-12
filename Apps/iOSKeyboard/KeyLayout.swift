import CoreGraphics

enum KeyboardKey: Equatable {
    case letter(Character)
    case symbol(Character)
    case space, newline, backspace, shift, globe
    case layer(KeyLayer)
}

enum KeyLayer: CaseIterable {
    case letters, numbers, symbols, emoji
}

enum ShiftState {
    case off, once, locked
}

/// The iOS layouts. Widths are in units of a letter key, ten to a row; a width of 0 takes what
/// the row has left, so the space bar grows when the globe key is hidden. The emoji page has
/// no rows of keys: `EmojiPanel` draws it.
enum KeyLayout {
    typealias Row = [(key: KeyboardKey, units: CGFloat)]
    static let unitsPerRow: CGFloat = 10

    static func rows(for layer: KeyLayer) -> [Row] {
        switch layer {
        case .letters:
            return [
                letters("qwertyuiop"),
                letters("asdfghjkl"),
                [(.shift, 1.5)] + letters("zxcvbnm") + [(.backspace, 1.5)],
                bottomRow(switchingTo: .numbers),
            ]
        case .numbers:
            return [
                symbols("1234567890"),
                symbols("-/:;()$&@\""),
                [(.layer(.symbols), 1.5)] + punctuation + [(.backspace, 1.5)],
                bottomRow(switchingTo: .letters),
            ]
        case .symbols:
            return [
                symbols("[]{}#%^*+="),
                symbols("_\\|~<>€£¥•"),
                [(.layer(.numbers), 1.5)] + punctuation + [(.backspace, 1.5)],
                bottomRow(switchingTo: .letters),
            ]
        case .emoji:
            return []
        }
    }

    /// Five keys across the seven units between the two wide keys.
    private static let punctuation: Row = ".,?!'".map { (.symbol($0), 7.0 / 5) }

    private static func bottomRow(switchingTo layer: KeyLayer) -> Row {
        [(.layer(layer), 1.25), (.layer(.emoji), 1.25), (.globe, 1.25), (.space, 0), (.newline, 2.5)]
    }

    private static func letters(_ keys: String) -> Row { keys.map { (.letter($0), 1) } }
    private static func symbols(_ keys: String) -> Row { keys.map { (.symbol($0), 1) } }
}
