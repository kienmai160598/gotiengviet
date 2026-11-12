import UIKit

/// What each key does when touched: most type on lift, Shift, Delete and the layer keys act
/// on touch down as on iOS, and Delete repeats while held.
extension KeyboardView {
    func wire(_ slot: Slot) {
        let button = slot.button
        let key = slot.key
        button.addAction(UIAction { [weak self] _ in self?.touchDown(key) }, for: .touchDown)
        switch key {
        case .globe, .shift, .layer:
            return
        case .backspace:
            button.addAction(UIAction { [weak self] _ in self?.repeater.stop() }, for: [.touchUpInside, .touchUpOutside, .touchCancel])
        case .letter, .symbol:
            button.addAction(UIAction { [weak self] _ in self?.showPopup(over: button) }, for: [.touchDown, .touchDragEnter])
            button.addAction(UIAction { [weak self] _ in self?.popup.hide() }, for: .touchDragExit)
            fallthrough
        case .space, .newline:
            button.addAction(UIAction { [weak self] _ in self?.lift(key, types: true) }, for: .touchUpInside)
            button.addAction(UIAction { [weak self] _ in self?.lift(key, types: false) }, for: [.touchUpOutside, .touchCancel])
        }
    }

    /// Types the key another finger still holds before this one acts (`KeyRollover`).
    private func touchDown(_ key: KeyboardKey) {
        if let held = rollover.interrupt() {
            popup.hide()
            onKey(held)
        }
        switch key {
        case .backspace: // Ticks only when it deletes, which the controller knows.
            return repeater.start { [weak self] in self?.onKey(.backspace) }
        case .shift: onKey(.shift)
        case .layer(let target): page = target
        case .letter, .symbol, .space, .newline: rollover.hold(key)
        case .globe: break
        }
        haptics.tick()
    }

    private func lift(_ key: KeyboardKey, types: Bool) {
        guard rollover.lift(key) else { return }
        popup.hide()
        if types { onKey(key) }
    }

    /// For when the keyboard hides under a finger: that key's lift never arrives.
    func releaseKeys() {
        repeater.stop()
        popup.hide()
        rollover = .init()
    }

    func nearestKey(to point: CGPoint) -> KeyButton? {
        let keys = slots(in: [page]).map(\.button).filter { !$0.isHidden }
        return keys.min { distance(from: point, to: $0.frame) < distance(from: point, to: $1.frame) }
    }

    private func distance(from point: CGPoint, to frame: CGRect) -> CGFloat {
        let x = max(frame.minX - point.x, 0, point.x - frame.maxX)
        let y = max(frame.minY - point.y, 0, point.y - frame.maxY)
        return x * x + y * y
    }

    /// iPhone only: iPad keys are big enough to see under the finger.
    private func showPopup(over button: KeyButton) {
        guard traitCollection.userInterfaceIdiom == .phone, let title = button.accessibilityLabel else { return }
        popup.show(title, over: button.convert(button.faceFrame, to: self))
        bringSubviewToFront(popup)
    }
}
