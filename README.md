# VietKey (codename)

Vietnamese Telex typing with no VN/EN toggle: each word comes out as Vietnamese or English on
its own ("Team bên em", "I bought a new car"). On Mac, English sentences also get offline
grammar suggestions ([Harper](https://github.com/Automattic/harper)). Status: PoC.

## Install on Mac

Apple Silicon, macOS 26 or later:

```sh
curl -fsSL https://raw.githubusercontent.com/kienmai160598/gotiengviet/main/install.sh | bash
```

Then, once: System Settings > Keyboard > Input Sources > Edit > + > Vietnamese > VietKey.

- Update: run the same line again.
- Uninstall: end the line with `bash -s -- --uninstall` instead of `bash`.

Signed ad hoc, not notarized. No network code, no keystroke logging.

## More

- iPhone keyboard and building from source: [docs/BUILDING.md](docs/BUILDING.md)
- How it works, what was tested, known limits: [docs/NOTES.md](docs/NOTES.md)
