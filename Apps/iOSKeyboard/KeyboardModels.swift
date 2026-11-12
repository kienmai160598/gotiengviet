import VietKeyCore

/// What typing needs that is slow to build: parsing the frequency tables. Built off the main
/// thread, so the keys show at once instead of leaving a blank keyboard on a cold start.
struct KeyboardModels: Sendable {
    var keyboard: TouchKeyboard
    let markedWords: MarkedWords

    static func load() -> KeyboardModels {
        Trace.measure("keyboard models") {
            KeyboardModels(
                keyboard: TouchKeyboard(session: InputSession(
                    lexicon: TextCheckerLexicon(),
                    frequencies: SharedModels.frequencies,
                    corrections: SharedModels.corrections
                )),
                markedWords: MarkedWords(frequencies: SharedModels.frequencies)
            )
        }
    }
}
