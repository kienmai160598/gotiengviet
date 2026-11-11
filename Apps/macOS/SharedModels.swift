import Foundation
import VietKeyCore

/// Loaded once per process and shared by every input controller, so a correction made in one
/// app applies in all of them.
enum SharedModels {
    static let corrections = UserDefaultsCorrectionStore(defaults: .standard)

    /// main.swift touches this at launch, so a missing table stops the input method at once
    /// instead of silently falling back to the syllable rules.
    static let frequencies: BundledWordFrequencies = {
        do { return try BundledWordFrequencies() } catch {
            fatalError("Frequency tables missing from the app bundle: \(error)")
        }
    }()
}
