#!/usr/bin/env python3
"""Builds the word frequency tables bundled with VietKeyCore.

Source: FrequencyWords by Hermit Dave (OpenSubtitles 2018), CC BY-SA 4.0, pinned to one
commit so the tables can be rebuilt byte for byte. Output lines are "<keys> <per billion>":
- english.txt: every lowercase a-z word. Marks apply anywhere in a word ("element" has e...e),
  so any word can collide with Telex and the table doubles as the English word list.
- vietnamese.txt: syllables with a diacritic, keyed by their Telex keys with the tone key
  last, so "hòa" and "hoà" count as one entry.
Usage: Tools/make-frequency-tables.py
"""
import re
import unicodedata
import urllib.request
from collections import defaultdict
from pathlib import Path

COMMIT = "525f9b560de45753a5ea01069454e72e9aa541c6"
URL = "https://raw.githubusercontent.com/hermitdave/FrequencyWords/{}/content/2018/{}/{}_50k.txt"
OUTPUT = Path(__file__).resolve().parent.parent / "Core/Sources/VietKeyCore/Frequency/Data"
TONES = {"́": "s", "̀": "f", "̉": "r", "̃": "x", "̣": "j"}


def download(language):
    with urllib.request.urlopen(URL.format(COMMIT, language, language)) as response:
        rows = [line.split(" ") for line in response.read().decode("utf-8").splitlines()]
    counts = [(unicodedata.normalize("NFC", word), int(count)) for word, count in rows]
    total = sum(count for _, count in counts)
    return [(word, count * 1_000_000_000 // total) for word, count in counts]


def telex_keys(syllable):
    keys, tone = "", None
    for char in unicodedata.normalize("NFD", syllable):
        if "a" <= char <= "z":
            keys += char
        elif char == "đ":
            keys += "dd"
        elif char == "̂" and keys:
            keys += keys[-1]
        elif char in ("̆", "̛"):
            keys += "w"
        elif char in TONES and tone is None:
            tone = TONES[char]
        else:
            return None
    return keys + (tone or "") if keys else None


def write(name, table):
    lines = (f"{keys} {count}\n" for keys, count in table.items() if count > 0)
    (OUTPUT / name).write_text("".join(lines), encoding="utf-8")
    print(f"{name}: {len(table)} entries")


def main():
    english = {word: count for word, count in download("en")
               if re.fullmatch(r"[a-z]+", word)}
    vietnamese = defaultdict(int)
    for word, count in download("vi"):
        keys = telex_keys(word)
        if keys and not word.isascii():
            vietnamese[keys] += count
    write("english.txt", english)
    write("vietnamese.txt", dict(sorted(vietnamese.items(), key=lambda item: -item[1])))


if __name__ == "__main__":
    main()
