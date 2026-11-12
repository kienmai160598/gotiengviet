# VietKey (codename)

Vietnamese Telex typing with no VN/EN toggle: each word comes out as Vietnamese or English on
its own, so "Team bên em" and "I bought a new car" both type right without switching. On Mac,
English sentences also get grammar suggestions (offline, [Harper](https://github.com/Automattic/harper)).
There is an iPhone keyboard too.

Status: PoC. What has been checked, and known limits, are in [docs/NOTES.md](docs/NOTES.md).

## Install on Mac

Needs an Apple Silicon Mac on macOS 26 or later. In Terminal:

```sh
curl -fsSL https://raw.githubusercontent.com/kienmai160598/gotiengviet/main/install.sh | bash
```

Then, the first time only: System Settings > Keyboard > Input Sources > Edit > + > Vietnamese >
VietKey. If it is not in the list yet, log out and back in.

- Update: run the same line again.
- Uninstall: the same line with `bash -s -- --uninstall` at the end, then remove VietKey from
  Input Sources.

[`install.sh`](install.sh) downloads the latest [release](https://github.com/kienmai160598/gotiengviet/releases/latest),
checks its signature and copies it into `~/Library/Input Methods` (no `sudo`). The app is
signed ad hoc and not notarized. It has no network code and does not log keystrokes.
Tried on one Mac so far (2026-11-12).

In the menu bar input menu, VietKey has two options: Check English Grammar, and Forget Learned
Corrections (Backspace or Esc right after a word teaches it to keep those keys as typed).

## Install on iPhone

There is no download: Apple requires each install to be signed with your own Apple account,
so it is built on a Mac. Do "Build from source" below first, then:

1. Xcode > Settings > Accounts: sign in with your Apple ID. A free account works, but the app
   stops opening after 7 days and needs installing again.
2. Save your team ID (Xcode > Settings > Accounts) for this clone:
   `echo 'DEVELOPMENT_TEAM = <team ID>' > Config/Signing.local.xcconfig`
3. On the iPhone: Settings > Privacy & Security > Developer Mode on. Connect the cable and
   trust the Mac.
4. Build and install (`xcrun devicectl list devices` shows the `<device>` identifier):

   ```sh
   xcodegen generate
   xcodebuild -scheme VietKeyiOS -configuration Release -destination 'id=<device>' \
     -derivedDataPath .build/ios-device -allowProvisioningUpdates build
   xcrun devicectl device install app --device <device> \
     .build/ios-device/Build/Products/Release-iphoneos/VietKey.app
   ```

5. On the iPhone: Settings > General > Keyboard > Keyboards > Add New Keyboard > VietKey. Turn
   on Allow Full Access only if you want key ticks (haptics). In a text field, hold the globe
   key and pick VietKey.

If Xcode rejects the bundle IDs under your team, change `bundleIdPrefix` and the IDs in
`project.yml`.

## Build from source

Needs Xcode 26 or later, XcodeGen and Rust, on an Apple Silicon Mac with macOS 26 or later.

```sh
brew install xcodegen
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh   # Rust, for the grammar checker
git clone https://github.com/kienmai160598/gotiengviet.git && cd gotiengviet
Tools/build-grammar.sh    # about 2 minutes the first time; every build needs it
Tools/install-mac.sh      # builds and installs the Mac input method
```

`Tools/install-mac.sh --debug` installs a Debug build that logs keystrokes; do not use it for
daily typing.

| Command | Does |
|---|---|
| `cd Core && swift test` | Core tests |
| `cd Grammar && swift test` | grammar tests (after `Tools/build-grammar.sh`) |
| `xcodegen generate && xcodebuild test -scheme VietKeyiOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` | iOS keyboard UI tests (simulator setup in [NOTES](docs/NOTES.md#ios-and-ipados-keyboard)) |
| `Tools/package-mac.sh` | Release build packed as `.build/VietKey.zip` ([publishing](docs/NOTES.md#publishing-a-mac-release)) |

`VietKey.xcodeproj` is generated from `project.yml`; do not edit it by hand.

## Layout

- `Core/`: Swift package `VietKeyCore`, no AppKit or UIKit: Telex engine, syllable model, `InputSession`.
- `Apps/macOS/`: the Mac input method (InputMethodKit).
- `Apps/iOS/`, `Apps/iOSKeyboard/`, `Apps/iOSUITests/`: iPhone app, keyboard extension, UI tests.
- `Apps/Shared/`: code shared by the Mac app and the keyboard.
- `Grammar/`: Rust crate and Swift package `VietKeyGrammar` (Harper).
- `Tools/`: build, install and packing scripts, table generators.

Word frequency tables come from FrequencyWords (OpenSubtitles 2018), CC BY-SA 4.0; see
`Core/Sources/VietKeyCore/Frequency/Data/LICENSE.md`. Emoji list: `Apps/iOSKeyboard/Emoji/LICENSE.md`.
