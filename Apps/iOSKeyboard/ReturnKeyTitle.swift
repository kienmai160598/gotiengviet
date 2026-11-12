import UIKit

/// The word iOS puts on Return for each action the app can ask for.
enum ReturnKeyTitle {
    static func title(for type: UIReturnKeyType?) -> String? {
        switch type ?? .default {
        case .go: "Go"
        case .google, .yahoo, .search: "Search"
        case .join: "Join"
        case .next: "Next"
        case .route: "Route"
        case .send: "Send"
        case .done: "Done"
        case .emergencyCall: "Emergency"
        case .continue: "Continue"
        case .default: nil
        @unknown default: nil
        }
    }
}
