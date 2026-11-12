# VietKey (codename)

Vietnamese Telex input method without a VN/EN toggle: each word is typed as Vietnamese or
English on its own, so "Team bên em" and "I bought a new car" both come out right with no
switching. On Mac, English sentences also get grammar suggestions (Harper, offline). There is
an iPhone keyboard too. The shared `Core` package is built for macOS, iOS and iPadOS.

Status: PoC. See each section below for what has been checked and how.

## Install on Mac

Needs an Apple Silicon Mac on macOS 26 or later. In Terminal:

```sh
curl -fsSL https://raw.githubusercontent.com/kienmai160598/gotiengviet/main/install.sh | bash
```

Then, the first time only: System Settings > Keyboard > Input Sources > Edit > + > Vietnamese >
VietKey. Switch to it from the input menu in the menu bar. If VietKey is not in the list yet,
log out and back in.

- Update: run the same line again. It replaces the app and restarts the input method.
- Uninstall: `curl -fsSL https://raw.githubusercontent.com/kienmai160598/gotiengviet/main/install.sh | bash -s -- --uninstall`,
  then remove VietKey from Input Sources.

What [`install.sh`](install.sh) does: downloads `VietKey.zip` from the latest
[GitHub Release](https://github.com/kienmai160598/gotiengviet/releases/latest), checks the
app's code signature, and copies `VietKey.app` into `~/Library/Input Methods` (no `sudo`). If
the download or the check fails, the installed app is left as it was. The app is signed ad hoc,
not with an Apple Developer ID, and not notarized. Release builds do not log keystrokes, and
VietKey has no network code.

Checked 2026-11-12 on the author's Mac only, from a local zip: install, update, uninstall, a
404 download and a tampered app (refused). Not yet tried on a second Mac.

The iPhone keyboard has no ready-made download: Apple requires each install to be signed with
your own Apple account, so it is built from source (below).

## How words are decided

Each word is decided at the word boundary. A word stays Vietnamese when it is a valid
syllable, unless the keys are an English word more than 3x as common (word frequency tables).
After a run of English words the bar drops to 1/33x, so "I bought a new car" keeps car. A run
needs 2 common English words in a row (rare ones like ko, dc and words valid in both languages
like the, anh do not count), so "Team bên em" and "Ok, cả nhà" stay Vietnamese but "Unit test
cả" gives car (chosen over a longer run so English right after Vietnamese works). Esc counts as English; a kept
Backspace revert counts as Vietnamese. Context is never reset (not on Return either).
While typing, the Vietnamese reading is shown as long as it is still possible.
Compared with OpenKey's engine (EVKey's source is not public), 2026-11-12: "uw" then a plain o
completes ươ (`tuwong` gives tương; a lone w stays, so "two" stays English); one letter
repeated ("ww", "aaa") is never an English word, so the double-key undo stands even where the
Mac spell checker accepts it; Backspace inside a word leaves the keys of what is still shown
("tôi" less i is "too", judged like typing "too", where it used to be "to").
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

## Build from source

Needs an Apple Silicon Mac on macOS 26 or later, Xcode 26 or later (built here with Xcode 27.2),
XcodeGen and Rust. The grammar checker is built from source (about 2 minutes) and the project
needs it even for the iPhone build: a fresh clone fails with "Could not resolve package
dependencies" until `Tools/build-grammar.sh` has run (checked 2026-11-12).

```sh
brew install xcodegen
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh   # Rust, for the grammar checker
git clone https://github.com/kienmai160598/gotiengviet.git && cd gotiengviet
```

### Mac input method from source

```sh
Tools/install-mac.sh          # builds the grammar checker, then VietKey (Release), into ~/Library/Input Methods
```

Then System Settings > Keyboard > Input Sources > Edit > + > Vietnamese > VietKey. After an
update, run the script again; it restarts the input method. `--debug` builds the Debug version,
which logs keystrokes (see Trace in `Apps/Shared`); do not use it for daily typing.

### iPhone keyboard

1. Xcode > Settings > Accounts: sign in with your Apple ID. A free account works; its apps stop
   opening after 7 days and need installing again.
2. Put your team ID in `Config/Signing.local.xcconfig` (gitignored, so each Mac needs its own).
   The ID is in Xcode > Settings > Accounts, or at developer.apple.com > Account > Membership.

   ```sh
   echo 'DEVELOPMENT_TEAM = <team ID>' > Config/Signing.local.xcconfig
   ```

   With a team other than the one that first registered `dev.vietkey.ios`, Xcode may refuse
   the bundle IDs; change `bundleIdPrefix` and the IDs in `project.yml` if it does.
3. On the iPhone: Settings > Privacy & Security > Developer Mode on, and trust the Mac when
   you connect the cable.
4. Build and install:

   ```sh
   xcrun devicectl list devices    # the Identifier column is <device>
   Tools/build-grammar.sh          # once per clone: the project does not resolve without it
   xcodegen generate
   xcodebuild -scheme VietKeyiOS -configuration Release -destination 'id=<device>' \
     -derivedDataPath .build/ios-device -allowProvisioningUpdates build
   xcrun devicectl device install app --device <device> \
     .build/ios-device/Build/Products/Release-iphoneos/VietKey.app
   ```

   `-allowProvisioningUpdates` lets Xcode create the signing profiles on the first build.
5. On the iPhone: Settings > General > Keyboard > Keyboards > Add New Keyboard > VietKey. Turn
   on Allow Full Access only for the key ticks (see Touches below). In a text field, hold the
   globe key and pick VietKey.

### Publishing a Mac release

```sh
Tools/package-mac.sh     # Release build only, packed as .build/VietKey.zip, signature checked
git push origin main     # first, so the tag lands on the commit that was built
gh release create v0.1.0 .build/VietKey.zip --title "VietKey 0.1.0 (Mac)" \
  --notes "Apple Silicon, macOS 26+. Signed ad hoc, not notarized."
```

Keep the asset name `VietKey.zip` and do not mark the release as a pre-release: `install.sh`
downloads `releases/latest/download/VietKey.zip`, and GitHub's latest release skips
pre-releases and drafts. The script never packs the installed app, which may be a Debug build
that logs keystrokes. `Tools/build-grammar.sh` maps the home folder out of the Rust source
paths, so the binary does not carry the builder's user name (checked with `strings`, 2026-11-12).

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
by hand in Notes 2026-11-11; checking on a pause seen working in a chat app the same day.

`Grammar/` wraps [Harper](https://github.com/Automattic/harper) (harper-core 3.0.0, Apache-2.0,
offline) for Swift through UniFFI. How it works on Mac:

- The sentence at the caret is checked once typing pauses for 1 second (untuned), finished or
  not, so a chat message is checked before Return sends it. Any key hides the card, so it never
  flashes mid-typing. The word still being typed is left out. The sentence is read back from
  the document, up to 600 characters before the caret, and must start after a newline, after
  `.`, `?` or `!` plus whitespace (so "example.com" and "3.14" do not end one), or at the
  document start.
- Only English sentences are sent: no Vietnamese letters, and under a quarter of the words
  read as Vietnamese typed without marks ("Ok anh, de em check lai" is skipped).
- Off in Harper: the `SpellCheck` and `WrongNegative` rules (they flag every Vietnamese word
  and tech term, "deps" -> "imps"), and lints of kind Capitalization, Style, Enhancement,
  Readability, Regionalism and Formatting. Harper loads only while checking is on.
- Problems show one at a time in a Liquid Glass card under the sentence: the category, the
  sentence with the fix marked in place, Harper's message, up to 3 fixes, Ignore, and arrows when
  there are more. Clicking a fix replaces the text only if it is still exactly where it was
  checked, then the next problem shows. Ignored and closed problems stay hidden until the
  text field loses focus. Toggle from the input menu: VietKey > Check English Grammar.
- Notes reports the line's rect one line too high, so the card is moved down for Notes only
  (`TextGeometry.swift`); NSTextView apps (TextEdit) report it exactly.

Limits: Apple Silicon Macs only. The app grows by about 17 MB (Release, unstripped) and Harper
peaks around 195 MB of RAM, so iOS is roadmap (likely too much for a keyboard extension;
untested). "Mr. Smith" or "e.g. this" end a sentence early. A chat message sent within 1 second of
the last key is not checked. Apps that do not expose their text
to input methods (likely Chrome and Electron) get no suggestions.

## iOS and iPadOS keyboard

Status: PoC. UI tests pass in the simulator on iPhone 17 Pro (iOS 26.5) and iPhone 18 Pro Max
(iOS 27.0), 2026-11-11. Used by hand on an iPhone 14 Pro Max (iOS 27.2.1) in Messages and the
Claude app, 2026-11-12, for layout and look; the Telex results there are not checked against a
list. Memory is measured in the simulator only (see the emoji page below); the limit iOS puts
on a keyboard extension on a device is not. Not tried in Notes or Safari. Install: see "Build from source".

A custom keyboard (QWERTY, Telex) that types through the same Core `InputSession` as the Mac,
so words are decided Vietnamese or English the same way, and Backspace right after a boundary
restores the shown Vietnamese or reopens the word (`hoa ` Delete `f` gives "hòa"). The word being typed is marked text; committing it with
`insertText` replaces the marked text. (Marking the final text and then unmarking it made the
text field put the next character before the word.) Capitals at a sentence start when the
field asks for them; double tap Shift for caps lock.

Mid-word: hiding the keyboard commits the word. When the app changes the text while a word is
being typed (a chat app sends and clears it), the word is dropped so the next key does not
bring it back; edits reported within 250 ms of a key are taken as the keyboard's own echo.
That path is covered by a Core test only. A tap in the field while a word is marked does not
move the caret in the simulator, so typing goes on.

The look follows the system keyboard, measured from simulator screenshots: key colours, sizes
and gaps, 54-point rows on the smaller phones and 56 on Plus and Pro Max (40 in landscape,
measured on the Pro Max only), the letter balloon
on press (iPhone), Delete repeat while held, number and symbol pages, and Return named after
the field's action ("Send", "Search").

Lowercase letters are centred on their x-height, capitals on their cap height. Liquid Glass
key faces were tried (2026-11-12) and dropped at the user's request; the faces stay solid.

Touches:

- A tap in the gap between two key faces, or in the strip between an outer key and the screen
  edge, types the nearest key. Before, those taps were lost: in the iOS 26.5 simulator a
  keyboard extension is given no touch that lands on a clear pixel, and the gaps are about a
  third of the keys' area. The keyboard now has a background too faint to see. Covered by a
  UI test; not confirmed on a device.
- Two thumbs overlapping type in the order they touched (`KeyRollover`): a finger landing on
  any key first types the key still held. Keys type on lift, so before, "n" down, "j" down,
  "j" up, "n" up typed "jn". Unit tested only: a UI test cannot overlap two touches.
- Each key ticks as it goes down (`UIImpactFeedbackGenerator`, light). Delete ticks on every
  repeat while there is text before the caret, a selection or a word being typed; held on an
  empty field it stays quiet (checked in the simulator by logging the decision).
  Felt on an iPhone 14 Pro Max (iOS 27.2.1), 2026-11-12: nothing at first, then it worked
  after turning on Full Access, reopening the keyboard and checking System Haptics; which of
  the three it needed was not isolated. Custom keyboards are widely reported to need Full
  Access for haptics; Apple's pages on open access do not say so. `RequestsOpenAccess` is on so that the switch exists in Settings
  (Keyboards, VietKey, Allow Full Access). Turning it on gives up the system's guarantee that
  keystrokes cannot leave the keyboard, and iOS warns about that; VietKey has no network
  code. There is no setting to turn the tick off, and it does not follow the system's
  Keyboard Feedback setting, which an app cannot read.
- Work per key, Debug simulator, typing "vieetj nam ": 1.7 ms inside the key handler, before
  and after. The keys were also relabelled, all of them, 26 times for those 11 keys (about
  0.65 ms each); now 3 times, changing only the keys that differ. The bar no longer fades
  its words in on every key.
- A system gesture recognizer on the keyboard's window has `delaysTouchesBegan` set. In the
  simulator a touch reaches its key about 1 ms after it happened, at the edges as in the
  middle, with the flag on or off, so it is left alone; whether the outer keys feel late on
  a device is not checked.
- Shift between sentences: one tap capitalises the next letter, a double tap locks capitals.
  Before, a tap anywhere but at a sentence start was undone at once.

The bar is 30 points tall, not the 46 the simulator's system keyboard suggests. On an iPhone
(iOS 27.2.1, in Messages and the Claude app) iOS puts about 16 points of its own glass above
a custom keyboard, which the keyboard cannot draw into. Measured from screenshots:
with a 46-point bar the keys sat 69 points below the top of the glass, with 30 they sit
53, against 52 for the system keyboard. Developers
report the same strip since iOS 26 in apps that use Liquid Glass, with no reply from Apple
and no API to control it ([forum](https://developer.apple.com/forums/thread/800838)). The strip
comes and goes on its own: in VietKey's own app (iPhone 17 Pro Max simulator, iOS 26.5,
2026-11-12) it is missing when the keyboard first opens and there, about 17 points, after
going to the home screen and back. The keyboard's view keeps the height it asked for in both
cases (254.67 points). The keyboard cannot see the strip: its window is exactly its own height,
with no offset or safe area, so the strip is drawn by the app's process. So the space above the
bar looks thicker or thinner from app to app and moment to moment, and the keys stay put; this
is left as it is. So the emoji and words stay mid-bar: under the strip they sit 31 points below
the top of the glass against 26 for the system's predictions. Lifting them to 27 put them
against the top edge in VietKey's own app (tried 2026-11-12). Over the top row the letter balloon is cut short by the top of the
keyboard, so its letter is drawn smaller. The bar and keys are laid out from the bottom: while
the keyboard opens, iOS can make the view taller for a moment (444 and 874 points for 244 asked,
simulator log 2026-11-12), and laid out from the top they jumped up.

The bar above the keys:

- Between words it is a row of eight emoji. A placeholder until there is a better use for
  the room: the list is fixed, nothing counts which emoji are used.
- While a word is typed it has three slots like the iOS predictions, offering the word with
  its marks: typing "toi" offers "tôi", "tới", "tối", and a tap puts the word and a space,
  which saves the mark keys. Words come from the bundled frequency table (real syllables
  only). Order, untuned: words that keep the marks already typed ("tôi" gives "tối" before
  "tới"), then words with exactly the letters typed before longer ones ("ng" offers
  "người"), then the most common. A chosen word counts as Vietnamese for the VN/EN decision
  on the words after it.
- The left slot shows the keys as typed, in quotes, when the word shows something else
  (typing "car" shows "cả"; choosing "car" keeps it and teaches the keyboard).
- No Vietnamese word starts with the letters ("hel"): the emoji show. There are no English
  completions and no next-word prediction. Words without any mark ("con", "anh") are not in
  the table, so they are never offered.

The emoji key, left of the space bar, opens VietKey's own emoji page: a keyboard extension
cannot open the system's (`UIInputViewController` only offers switching to the next keyboard).
1,906 emoji from Unicode's Emoji 16.0 list (`Tools/make-emoji-table.py`,
`Apps/iOSKeyboard/Emoji/LICENSE.md`) in nine groups, in one grid that scrolls down, with a
strip of group tabs between "ABC" and Delete. No recents, skin tones or search.

Memory, iPhone 17 Pro simulator, Debug build: the keyboard process uses 42 MB before the page
is opened and 132 MB after scrolling through every group, about 50 KB for each emoji drawn.
Smaller glyphs and a lower scale did not change that. Closing the page, which drops its
views, gave back about 14 MB. (Each number is from its own trial build; the combination that
ships was not measured again.) So `EmojiBudget` stops drawing new emoji once fewer than 16 MB
are left before the process's limit (`os_proc_available_memory`); their cells stay blank and
do nothing, while emoji drawn earlier keep working. The 16 MB is a guess, and the guard has
only run in unit tests: the simulator reports 0, which means no limit, and nothing has been
measured on a device. The header says 0 is also what a process that "is not an app" gets; if
that covers a keyboard extension on a device, the guard never trips there.

The frequency tables load off the main thread (about 160 ms in a Debug simulator build), so
the keys show before they are ready; keys typed meanwhile wait. On the simulator the extension
process itself still takes about 2 seconds to launch the first time, before any VietKey code
runs.

Not yet: the iPad layout (iPadOS has its own: Tab, caps lock, two Shift keys, flick down for
numbers, a hide key; VietKey shows the iPhone layout stretched, under the system's own
shortcut bar), long press for accents, grammar, expanding abbreviations in the bar
("ko" to "không", planned next). The system spell
checker (`UITextChecker`, used only after a double-key undo) is not exercised by any test yet.
Corrections stay in the keyboard process (no App Group). Apple does not let custom keyboards
type in secure or phone number fields.

The UI tests type on the real keyboard in the simulator. Make VietKey the simulator's first
keyboard once, then reboot that simulator:

```sh
xcrun simctl spawn <device> defaults write .GlobalPreferences AppleKeyboards -array dev.vietkey.ios.keyboard "en_US@sw=QWERTY;hw=Automatic"
xcrun simctl spawn <device> defaults write .GlobalPreferences AppleKeyboardsExpanded -int 1
xcrun simctl shutdown <device> && xcrun simctl boot <device>
```

## Layout

- `Core/`: Swift Package `VietKeyCore`, no AppKit/UIKit. Telex engine, syllable model, `InputSession`.
- `Apps/macOS/`: InputMethodKit adapter (`VietKeyInputController`).
- `Apps/iOS/`, `Apps/iOSKeyboard/`, `Apps/iOSUITests/`: container app, keyboard extension, UI tests.
- `Apps/Shared/`: shared by the Mac app and the keyboard (models, debug trace).
- `Grammar/`: Rust crate + Swift Package `VietKeyGrammar`, English grammar checking (Harper).
- `install.sh`: the one-line Mac installer (downloads the latest release).
- `Tools/`: build-and-install and release packing scripts, icon generator, frequency table generator, grammar build script.

## Commands

```sh
cd Core && swift test                                                     # Core tests
xcodebuild -scheme VietKeyCore -destination 'generic/platform=iOS' build  # Core builds for iOS (run in Core/)
Tools/install-mac.sh                                                      # build + install the Mac input method
Tools/package-mac.sh                                                      # Release build packed as .build/VietKey.zip
Tools/build-grammar.sh && (cd Grammar && swift test)                      # grammar xcframework + tests (needs cargo)
xcodegen generate && xcodebuild test -project VietKey.xcodeproj -scheme VietKeyiOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'               # iOS keyboard UI tests
# iPhone install: see "Build from source"
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

Otherwise Backspace right after a boundary reopens the word that went in as shown, so a tone
can still be added (`hoa ` then Backspace then `f` gives "hòa", as in OpenKey): the word and
its boundary become marked text again. Same checks as the revert, Terminal excluded. Covered by
Core tests, an iOS simulator UI test and an NSTextView probe; not yet checked by hand in apps.
