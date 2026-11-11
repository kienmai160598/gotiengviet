# VietKey (codename)

Vietnamese Telex input method without a VN/EN toggle. macOS first; the shared `Core` package
is built for iOS/iPadOS from day one.

Status: each word is decided at the word boundary. A word stays Vietnamese when it is a valid
syllable, unless the keys are an English word more than 3x as common (word frequency tables).
After a run of English words the bar drops to 1/33x, so "I bought a new car" keeps car. A run
needs 2 common English words in a row (rare ones like ko, dc and words valid in both languages
like the, anh do not count), so "Team bên em" and "Ok, cả nhà" stay Vietnamese but "Unit test
cả" gives car (chosen over a longer run so English right after Vietnamese works). Esc counts as English; a kept
Backspace revert counts as Vietnamese. Context is never reset (not on Return either).
While typing, the Vietnamese reading is shown as long as it is still possible.
Mac: context rule and the double-key undo fix (Canada, element) checked by hand 2026-11-11.

Word error rate on Tatoeba running text (tone key typed last, test word list instead of the
system spell checker; eval data not in the repo; factors were picked on this same data):

| Text | No context | With context |
|---|---|---|
| Vietnamese, 33k sentences | 0.139% | 0.134% |
| English, 34k sentences, each typed fresh | 1.10% | 0.43% |
| English, each right after a Vietnamese sentence | 1.10% | 0.43% |
| English, typed as one document | 1.10% | 0.08% |

The "No context" column was measured before the double-key undo fix (Canada→Canda).

Untuned: the 20-per-million evidence threshold and the 1/100 factor were set by hand.
Known misses: an English sentence opening "There"/"These" with no English run before gets
thể/thế; two English words in a row turn the next colliding word English ("Unit test cả" gives
car); tô (typed `too`) becomes "too"; names whose Telex reading is a valid syllable become
Vietnamese (Baya→Bây, Boris→Bói).

## Learning from corrections

Status: Core tested; not yet checked by hand in the Mac app.

Each correction is remembered for that exact key sequence (case-insensitive), on this device only:

- Backspace revert after a boundary (`text ` back to "tẽt"), then any key but Backspace: those
  keys stay Vietnamese. A second Backspace means the word is being deleted, so nothing is learned.
- Esc while the word shows Vietnamese (`car` shown as "cả"): those keys stay as typed.

Stored in the input method's UserDefaults (`VietKey.corrections`). Clear it from the input
menu in the menu bar: VietKey > Forget Learned Corrections.

## Grammar (English)

Status: PoC. Builds and unit tests pass. Mac: the card and applying two fixes in a row checked
by hand in Notes 2026-11-11; other apps not tested yet.

`Grammar/` wraps [Harper](https://github.com/Automattic/harper) (harper-core 3.0.0, Apache-2.0,
offline) for Swift through UniFFI. How it works on Mac:

- A sentence is checked when whitespace follows `.`, `?` or `!` (so "example.com" and "3.14"
  do not end one). It is read back from the document, up to 600 characters before the caret,
  and must start after a newline, after an earlier sentence, or at the document start.
- Only English sentences are sent: no Vietnamese letters, and under a quarter of the words
  read as Vietnamese typed without marks ("Ok anh, de em check lai" is skipped).
- Off in Harper: the `SpellCheck` and `WrongNegative` rules (they flag every Vietnamese word
  and tech term, "deps" -> "imps"), and lints of kind Capitalization, Style, Enhancement,
  Readability, Regionalism and Formatting. Harper loads only while checking is on.
- Problems show one at a time in a Liquid Glass card under the sentence: the category, the
  sentence with the fix marked in place, Harper's message, up to 3 fixes, Ignore, and arrows when
  there are more. Clicking a fix replaces the text only if it is still exactly where it was
  checked, then the next problem shows. Toggle from the input menu: VietKey > Check English Grammar.
- Notes reports the line's rect one line too high, so the card is moved down for Notes only
  (`TextGeometry.swift`); NSTextView apps (TextEdit) report it exactly.

Limits: Apple Silicon Macs only. The app grows by about 17 MB (Release, unstripped) and Harper
peaks around 195 MB of RAM, so iOS is roadmap (likely too much for a keyboard extension;
untested). "Mr. Smith" or "e.g. this" end a sentence early. The last sentence of a chat message is
never checked: Return sends it, and without a final period nothing triggers. Apps that do not expose their text
to input methods (likely Chrome and Electron) get no suggestions.

## Layout

- `Core/`: Swift Package `VietKeyCore`, no AppKit/UIKit. Telex engine, syllable model, `InputSession`.
- `Apps/macOS/`: InputMethodKit adapter (`VietKeyInputController`).
- `Grammar/`: Rust crate + Swift Package `VietKeyGrammar`, English grammar checking (Harper).
- `Tools/`: install script, icon generator, frequency table generator, grammar build script.

## Commands

```sh
cd Core && swift test                                                     # Core tests
xcodebuild -scheme VietKeyCore -destination 'generic/platform=iOS' build  # Core builds for iOS (run in Core/)
Tools/install-mac.sh                                                      # build + install the Mac input method
Tools/build-grammar.sh && (cd Grammar && swift test)                      # grammar xcframework + tests (needs cargo)
# Tatoeba eval: put vie.tsv and eng.tsv from downloads.tatoeba.org/exports/per_language in a folder
cd Core && VIETKEY_TATOEBA_DIR=/path swift test -c release -Xswiftc -enable-testing --filter SentenceEval
```

Word frequency tables (`Core/Sources/VietKeyCore/Frequency/Data`) come from FrequencyWords
(OpenSubtitles 2018) and are licensed CC BY-SA 4.0; see `LICENSE.md` there. Rebuild them with
`python3 -I Tools/make-frequency-tables.py`.

`VietKey.xcodeproj` is generated by XcodeGen from `project.yml`; do not edit it by hand.

## App compatibility (macOS)

Backspace right after a boundary that replaced the shown Vietnamese with the raw keys
(`text` shown as "tẽt", committed as "text ") restores the shown text. It needs the app to
expose and replace text before the caret.

| App | Revert on Backspace | Checked |
|---|---|---|
| Notes | works | 2026-11-11, manual |
| TextEdit | works | 2026-11-11, manual |
| Terminal | disabled on purpose: Backspace deletes the space | 2026-11-11, manual |
| Safari, Chrome, Cursor/VS Code | not tested yet | |
