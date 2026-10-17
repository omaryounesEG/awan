#!/usr/bin/env python3
"""Turn الكسائي's «مشتبهات القرآن» into verse-to-verse pairs.

The book — the earliest work devoted to mutashabihat — lists, surah by surah,
the passages that look alike, in the form

    [فيها]: يا أيها الناس اعبدوا ربكم (21) وسائر القرآن: اتقوا ربكم (1).

so the *source* verse is known (the section's surah + the number in brackets)
but the *other* verse is quoted only by its wording. The Quran text resolves it:
the quoted phrase is normalised (no diacritics, no editorial asides) and matched
against every verse, with the bracketed number as the tie-breaker.

Output: one JSON record per pair, plus a report of what could not be resolved —
an unresolved phrase is reported, never guessed.
"""

from __future__ import annotations

import argparse
import json
import re
import unicodedata
from collections import Counter

# ----------------------------------------------------------------- normalising
DIACRITICS = re.compile(r"[\u0617-\u061A\u064B-\u0652\u0670\u06D6-\u06ED\u0640]")
TATWEEL = "\u0640"


def normalise(text: str) -> str:
    """Strip what the two texts disagree about: diacritics and letter shapes."""
    text = unicodedata.normalize("NFKC", text)
    text = text.replace(TATWEEL, "")
    text = DIACRITICS.sub("", text)
    text = re.sub(r"[أإآٱ]", "ا", text)
    text = text.replace("ى", "ي").replace("ؤ", "و").replace("ئ", "ي").replace("ء", "")
    text = re.sub(r"[^\u0621-\u064A\s]", " ", text)
    return re.sub(r"\s+", " ", text).strip()


SURAH_TITLE = re.compile(r"(?:ومن|من)\s+سورة\s+(.+?)(?:\s+عليه\s+السلام)?\s*$")
WORD_TITLE = re.compile(r"^(حرف|حرفان|ثلاثة|أربعة|خمسة|ستة|سبعة|ثمانية|تسعة|عشرة)\b")
# The editorial asides the book scatters inside its quotations.
ASIDE = re.compile(
    r"\(بألف ولام\)|\(بغير\s*من\)|\(بمن\)|\(بألف\)|\(مثلها\)|\(بالتاء\)|\(بالنون\)|\(فيه تقديم وتأخير\)"
)
ITEM = re.compile(r"\[?\s*فيها\s*\]?\s*:?\s*(.+?)\s*$")
# «لا افتدوا به (1)» and friends: the book drops the conjunction the Quran keeps.
QUOTE_TAIL = re.compile(r"^و?لا\s|\bولافتدت\b|\bو?لاافتدوا\b")
BUCKET_WORDS = {
    "حرف": 1, "حرفان": 2, "ثلاثة أحرف": 3, "أربعة أحرف": 4, "خمسة أحرف": 5,
    "ستة أحرف": 6, "سبعة أحرف": 7, "ثمانية أحرف": 8, "تسعة أحرف": 9,
    "عشرة أحرف": 10, "أحد عشر حرفا": 11,
}
CONNECTORS = ("و", "ف", "ل", "ب", "ك")


def trim(word: str) -> str:
    """The book quotes a passage without the conjunction the verse may keep."""
    for letter in CONNECTORS:
        if len(word) > 3 and word.startswith(letter):
            return word[1:]
    return word


def common_run(verse_words: list[str], phrase_words: list[str]) -> list[str]:
    """The longest consecutive run of the phrase found in the verse."""
    best: list[str] = []
    for start in range(len(verse_words)):
        run: list[str] = []
        for offset, phrase_word in enumerate(phrase_words):
            index = start + offset
            if index >= len(verse_words):
                break
            verse_word = verse_words[index]
            if verse_word == phrase_word or trim(verse_word) == trim(phrase_word):
                run.append(phrase_word)
            else:
                break
        if len(run) > len(best):
            best = run
    return best


def contains(verse_words: list[str], phrase_words: list[str]) -> bool:
    return len(common_run(verse_words, phrase_words)) == len(phrase_words)


def parse_book(records: list[dict]) -> tuple[list[dict], Counter]:
    """(pairs, unresolved reasons) from the book's chunks."""
    pairs: list[dict] = []
    notes: Counter = Counter()
    surah: str | None = None
    bucket: str | None = None

    for record in records:
        title = (record.get("t") or "").strip()
        body = (record.get("x") or "").strip()
        if title:
            matched = SURAH_TITLE.search(title)
            if matched:
                surah = matched.group(1).strip()
                bucket = None
            elif WORD_TITLE.match(title):
                # «حرفان:» … the book regroups the same material by how many
                # letters the passages share; keep it as the pair's strength.
                bucket = title.rstrip(":").strip()
            elif normalise(title) in {normalise("بسم الله الرحمن الرحيم")}:
                pass
        if not body or "فيها" not in body:
            continue
        if not surah:
            notes["before any surah heading"] += 1
            continue
        for raw in re.split(r"(?=وفيها)", body):
            chunk = raw.strip()
            if "فيها" not in chunk:
                continue
            rest = re.sub(r"^.*?فيها\s*\]?\s*:?\s*", "", chunk, count=1)
            if "ليس في القرآن مثله" in rest:
                notes["unique - nothing to link"] += 1
            sides = re.split(r"وسائر القرآن\s*:?", rest, maxsplit=1)
            if len(sides) < 2:
                notes["no counterpart quoted"] += 1
                continue
            source, target = sides[0], sides[1]
            sn = re.search(r"\(([\u0660-\u0669\d]+)\)", source)
            tn = re.search(r"\(([\u0660-\u0669\d]+)\)", target)
            pairs.append(
                {
                    "surah": surah,
                    "bucket": bucket,
                    "source_text": ASIDE.sub(" ", source).strip(),
                    "source_number": int(sn.group(1)) if sn else None,
                    "target_text": ASIDE.sub(" ", target).strip(),
                    "target_number": int(tn.group(1)) if tn else None,
                    "raw": chunk[:200],
                }
            )
    return pairs, notes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--book", required=True, help="mutashabbihat jsonl")
    parser.add_argument("--quran", required=True, help="quran uthmani json")
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    records = [
        json.loads(line)
        for line in open(args.book, encoding="utf-8")
        if line.strip()
    ]
    quran = json.load(open(args.quran, encoding="utf-8"))
    # The asset is {surahs: [...], ayahs: {"<surah>": [text, ...]}}; a surah whose
    # list carries the basmala up front is offset by one, so the surah metadata's
    # ayah_count decides where numbering starts.
    counts = {str(s["id"]): s.get("ayah_count") for s in quran.get("surahs", [])}
    verses: list[tuple[str, int, int]] = []
    for key, texts in quran["ayahs"].items():
        number = int(key)
        offset = len(texts) - (counts.get(key) or len(texts))
        for index, text in enumerate(texts):
            ayah_number = index + 1 - offset
            if ayah_number < 1:
                continue
            verses.append((normalise(text), number, ayah_number))
    print(f"verses loaded: {len(verses)} (expected 6236)")

    pairs, notes = parse_book(records)
    print(f"items parsed: {len(pairs)}")
    for key, value in notes.most_common():
        print(f"   skipped - {key}: {value}")

    resolved, ambiguous, missing = [], 0, 0
    for pair in pairs:
        # The bracketed number is the citation, not part of the wording: leaving
        # it in makes the last token of every phrase a digit, so nothing matches.
        quote = re.sub(r"\(\s*[\u0660-\u0669\d]+\s*\)", " ", pair["target_text"])
        phrase = QUOTE_TAIL.sub("", normalise(quote)).strip()
        words = phrase.split()
        if len(words) < 2:
            missing += 1
            continue
        hits = [v for v in verses if contains(v[0].split(), words)]
        if pair["target_number"]:
            narrowed = [v for v in hits if v[2] == pair["target_number"]]
            if narrowed:
                hits = narrowed
        if len(hits) > 1 and pair.get("bucket"):
            # The book groups its material by how many words the passages share,
            # so the group itself breaks the tie between two candidate verses.
            wanted = BUCKET_WORDS.get(pair["bucket"])
            if wanted:
                same = [v for v in hits if len(common_run(v[0].split(), words)) == wanted]
                if same:
                    hits = same
        if len(hits) == 1:
            resolved.append({**pair, "target_surah": hits[0][1], "target_ayah": hits[0][2]})
        elif hits:
            ambiguous += 1
        else:
            missing += 1

    print(f"resolved: {len(resolved)} | ambiguous: {ambiguous} | unresolved: {missing}")
    with open(args.out, "w", encoding="utf-8", newline="\n") as handle:
        json.dump({"schema": 1, "count": len(resolved), "pairs": resolved}, handle, ensure_ascii=False, indent=1)
    print("wrote", args.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
