import UIKit
import VietKeyCore

/// The VietKey keyboard: Telex on a QWERTY layout, deciding Vietnamese or English per word
/// through the same Core session as the Mac input method.
final class KeyboardViewController: UIInputViewController {
    private static let shiftDoubleTap: TimeInterval = 0.3
    /// The app reports the keyboard's own edits back about 30 ms later (simulator); changes
    /// after this long came from somewhere else.
    private static let ownEditEcho: TimeInterval = 0.25
    /// Nil until the models load; keys typed before then wait in `pending`.
    private var models: KeyboardModels?
    private var pending: [TouchKey] = []
    private let keys = KeyboardView()
    private lazy var height = keys.heightAnchor.constraint(equalToConstant: KeyMetrics.compact.height)
    private var lastShiftTap = Date.distantPast
    private var lastKeyTime = Date.distantPast
    private var document: ProxyDocument { ProxyDocument(proxy: textDocumentProxy) }

    override func viewDidLoad() {
        super.viewDidLoad()
        keys.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keys)
        height.priority = .required - 1
        NSLayoutConstraint.activate([
            keys.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keys.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keys.topAnchor.constraint(equalTo: view.topAnchor),
            keys.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            height,
        ])
        keys.onKey = { [weak self] in self?.press($0) }
        keys.bar.onSelect = { [weak self] in self?.choose($0) }
        for globe in keys.globeKeys {
            globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        }
        Task.detached(priority: .userInitiated) { [weak self] in
            let models = KeyboardModels.load()
            await self?.loaded(models)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        height.constant = KeyMetrics.for(width: view.bounds.width, traits: traitCollection).height
        keys.showsGlobe = needsInputModeSwitchKey
        keys.returnTitle = ReturnKeyTitle.title(for: textDocumentProxy.returnKeyType)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keys.haptics.prepare()
        refresh()
    }

    override func viewWillDisappear(_ animated: Bool) {
        keys.releaseKeys()
        models?.keyboard.endWord(in: document)
        super.viewWillDisappear(animated)
    }

    override func textDidChange(_ textInput: UITextInput?) {
        if models?.keyboard.isComposing == true, Date().timeIntervalSince(lastKeyTime) > Self.ownEditEcho {
            Trace.log("keyboard dropped the word: the app changed the text")
            models?.keyboard.dropWord()
        }
        refresh()
    }

    private func loaded(_ models: KeyboardModels) {
        self.models = models
        pending.forEach { self.models?.keyboard.press($0, in: document) }
        pending = []
        refresh()
    }

    private func press(_ key: KeyboardKey) {
        lastKeyTime = Date()
        switch key {
        case .letter(let char): type(.character(keys.shift == .off ? char : Character(char.uppercased())))
        case .symbol(let char): type(.character(char))
        case .space:
            type(.character(" "))
            keys.page = .letters
        case .newline: type(.newline)
        case .backspace:
            // Delete ticks only while it deletes: held on an empty field it stays quiet.
            if models?.keyboard.isComposing == true || !pending.isEmpty || document.hasTextToDelete { keys.haptics.tick() }
            type(.backspace)
        case .shift: return tapShift() // No refresh: it would put Shift back where the text wants it.
        case .globe, .layer: return
        }
        refresh()
    }

    private func type(_ key: TouchKey) {
        guard models != nil else { return pending.append(key) }
        models?.keyboard.press(key, in: document)
    }

    /// A chosen suggestion is followed by a space, as on iOS.
    private func choose(_ suggestion: Suggestion) {
        keys.haptics.tick()
        lastKeyTime = Date()
        switch suggestion {
        case .keepTyped:
            models?.keyboard.press(.keepAsTyped, in: document)
            models?.keyboard.press(.character(" "), in: document)
        case .word(let word):
            models?.keyboard.replaceWord(with: word, in: document)
        }
        refresh()
    }

    /// One tap capitalises the next letter; a quick second tap locks capitals.
    private func tapShift() {
        let now = Date()
        defer { lastShiftTap = now }
        if keys.shift == .once, now.timeIntervalSince(lastShiftTap) < Self.shiftDoubleTap {
            keys.shift = .locked
        } else {
            keys.shift = keys.shift == .off ? .once : .off
        }
    }

    private func refresh() {
        updateShift()
        keys.bar.show(suggestions())
    }

    /// Nothing between words, which leaves the bar to its emoji.
    private func suggestions() -> [Suggestion] {
        guard let models, let word = models.keyboard.word else { return [] }
        let keep = models.keyboard.typedKeys.map { [Suggestion.keepTyped($0)] } ?? []
        return keep + models.markedWords.words(for: word.shown).map(Suggestion.word)
    }

    /// Capitalises the first letter of a sentence when the field asks for it.
    private func updateShift() {
        guard keys.shift != .locked else { return }
        let capitalizes = textDocumentProxy.autocapitalizationType != UITextAutocapitalizationType.none
        let startsSentence = models?.keyboard.isComposing != true && pending.isEmpty
            && SentenceFinder.startsSentence(after: textDocumentProxy.documentContextBeforeInput)
        keys.shift = capitalizes && startsSentence ? .once : .off
    }
}
