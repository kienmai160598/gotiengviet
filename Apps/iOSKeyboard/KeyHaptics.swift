import UIKit

/// The tick under the finger as a key goes down. Nothing is felt on an iPad or in the
/// simulator, which have no haptic engine.
@MainActor
final class KeyHaptics {
    private let generator: UIImpactFeedbackGenerator

    init(view: UIView) {
        generator = UIImpactFeedbackGenerator(style: .light, view: view)
    }

    /// Wakes the engine, so the first tick is not late.
    func prepare() {
        generator.prepare()
    }

    func tick() {
        generator.impactOccurred()
        generator.prepare()
    }
}
