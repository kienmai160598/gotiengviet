#!/usr/bin/env python3
"""Builds the emoji list bundled with the iOS keyboard's emoji panel.

Source: Unicode emoji-test.txt, pinned to Emoji 16.0, which iOS 18.4 and later can draw (the
keyboard needs iOS 26). Output: one line per group in Unicode's order, the emoji separated by
spaces. Kept: fully-qualified emoji. Dropped: the Component group and skin tone variants.
Usage: Tools/make-emoji-table.py
"""
import urllib.request
from pathlib import Path

URL = "https://unicode.org/Public/emoji/16.0/emoji-test.txt"
OUTPUT = Path(__file__).resolve().parent.parent / "Apps/iOSKeyboard/Emoji/emoji.txt"
SKIN_TONES = {f"{code:X}" for code in range(0x1F3FB, 0x1F400)}


def groups(lines):
    name, found = None, {}
    for line in lines:
        if line.startswith("# group: "):
            name = line.removeprefix("# group: ")
            found[name] = []
        elif "; fully-qualified" in line:
            codes = line.split(";")[0].split()
            if not SKIN_TONES.intersection(codes):
                found[name].append("".join(chr(int(code, 16)) for code in codes))
    del found["Component"]
    return found


def main():
    with urllib.request.urlopen(URL) as response:
        found = groups(response.read().decode("utf-8").splitlines())
    OUTPUT.write_text("".join(" ".join(emoji) + "\n" for emoji in found.values()), encoding="utf-8")
    for name, emoji in found.items():
        print(f"{name}: {len(emoji)}")


if __name__ == "__main__":
    main()
