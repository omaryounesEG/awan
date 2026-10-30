"""Build the hadith asset the app ships.

Source: https://github.com/AhmedBaset/hadith-json (db/by_book/the_9_books).
We take the four books the reader asked for — Bukhari, Muslim, Abu Dawud,
Tirmidhi — and keep what the screen actually uses: the Arabic text, the book and
chapter it belongs to, the grade we can defend, and the cross-book links.

Grades are not a field in that dataset, so they are derived and the derivation is
deliberately conservative:

* Bukhari and Muslim are «صحيح» by the consensus on their books, not by us.
* Tirmidhi and Abu Dawud carry the scholar's own verdict inside the text
  («قَالَ أَبُو عِيسَى: هَذَا حَدِيثٌ حَسَنٌ صَحِيحٌ»), so it is read from there.
* Anything else is «غير مبيّن» — an honest empty, never a guess.

Relations are exact-matn matches across the four books: the isnad is dropped, the
matn is normalised, and hadiths whose first hundred letters agree are linked.
That is what makes «التخريج» possible without inventing anything.

Usage:
    python tools/build_hadith_asset.py --source .tmp_hadith --out assets/hadith
"""
from __future__ import annotations

import argparse
import gzip
import json
import os
import re
import unicodedata
from collections import defaultdict

BOOKS = [
    ("bukhari", "صحيح البخاري", "Sahih al-Bukhari"),
    ("muslim", "صحيح مسلم", "Sahih Muslim"),
    ("abudawud", "سنن أبي داود", "Sunan Abu Dawud"),
    ("tirmidhi", "جامع الترمذي", "Jami' at-Tirmidhi"),
]

GRADES = ["sahih", "hasan", "hasan_sahih", "daif", "unspecified"]
GRADE_AR = {
    "sahih": "صحيح",
    "hasan": "حسن",
    "hasan_sahih": "حسن صحيح",
    "daif": "ضعيف",
    "unspecified": "غير مبيّن",
}

DIACRITICS = re.compile(r"[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]")
MATN_MARKERS = [
    "قَالَ رَسُولُ اللَّهِ",
    "قَالَ رَسُولُ الله",
    "أَنَّ رَسُولَ اللَّهِ",
    "أَنَّ رَسُولَ الله",
    "عَنِ النَّبِيِّ",
    "عَنِ النَّبِيّ",
    "أَنَّ النَّبِيَّ",
    "أَنَّ النَّبِيّ",
]


def normalize(text: str) -> str:
    text = unicodedata.normalize("NFKC", text)
    text = DIACRITICS.sub("", text)
    text = (
        text.replace("أ", "ا")
        .replace("إ", "ا")
        .replace("آ", "ا")
        .replace("ى", "ي")
        .replace("ة", "ه")
        .replace("ؤ", "و")
        .replace("ئ", "ي")
    )
    text = re.sub(r"[^\w\s]", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def matn_of(arabic: str) -> str:
    """The part after the isnad: where the Prophet is quoted."""
    normalized = normalize(arabic)
    cut = -1
    for marker in MATN_MARKERS:
        index = normalized.rfind(normalize(marker))
        if index > cut:
            cut = index
    body = normalized[cut:] if cut >= 0 else normalized
    return body[:180]


def grade_of(book: str, arabic: str) -> str:
    if book in ("bukhari", "muslim"):
        return "sahih"
    text = normalize(arabic)
    if "حسن صحيح" in text:
        return "hasan_sahih"
    if "ضعيف" in text or "منكر" in text or "موضوع" in text:
        # A weak verdict is only trusted when it is the scholar speaking about
        # *this* hadith; Tirmidhi sentences usually read «حديث ضعيف».
        return "daif" if re.search(r"حديث (ضعيف|منكر|موضوع)", text) else "unspecified"
    if re.search(r"حديث حسن", text):
        return "hasan"
    if re.search(r"حديث صحيح", text):
        return "sahih"
    return "unspecified"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", default=".tmp_hadith")
    parser.add_argument("--out", default="assets/hadith")
    args = parser.parse_args()

    books = []
    hadiths = []
    chapter_titles = {}

    for index, (key, ar, en) in enumerate(BOOKS):
        path = os.path.join(args.source, f"{key}.json")
        with open(path, encoding="utf-8") as handle:
            doc = json.load(handle)
        chapters = []
        for chapter in doc.get("chapters", []):
            title = (chapter.get("arabic") or "").strip()
            chapters.append({"id": chapter.get("id"), "ar": title})
            chapter_titles[(key, chapter.get("id"))] = title
        books.append(
            {
                "key": key,
                "ar": ar,
                "en": en,
                "count": len(doc.get("hadiths", [])),
                "chapters": chapters,
            }
        )
        for item in doc.get("hadiths", []):
            arabic = (item.get("arabic") or "").strip()
            if not arabic:
                continue
            hadiths.append(
                {
                    "b": index,
                    "n": item.get("idInBook"),
                    "c": item.get("chapterId"),
                    "t": arabic,
                    "g": GRADES.index(grade_of(key, arabic)),
                }
            )
        print(f"{key}: {len(doc.get('hadiths', []))} hadiths, {len(chapters)} chapters")

    # Cross-book links: same matn, different book.
    buckets: dict[str, list[int]] = defaultdict(list)
    for position, hadith in enumerate(hadiths):
        key_of_matn = matn_of(hadith["t"])[:100]
        if len(key_of_matn) >= 40:
            buckets[key_of_matn].append(position)

    linked = 0
    for positions in buckets.values():
        if len(positions) < 2:
            continue
        for position in positions:
            others = [p for p in positions if p != position]
            others.sort(key=lambda p: hadiths[p]["b"] == hadiths[position]["b"])
            hadiths[position]["r"] = others[:6]
            linked += 1

    doc = {
        "v": 1,
        "gradeLabels": [GRADE_AR[g] for g in GRADES],
        "books": books,
        "hadiths": hadiths,
    }
    os.makedirs(args.out, exist_ok=True)
    raw = json.dumps(doc, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    path = os.path.join(args.out, "hadith_v1.json.gz")
    with gzip.open(path, "wb", compresslevel=9) as handle:
        handle.write(raw)

    graded = defaultdict(int)
    for hadith in hadiths:
        graded[GRADES[hadith["g"]]] += 1
    print(f"total {len(hadiths)} hadiths, {linked} linked")
    print(f"raw {len(raw) / 1e6:.1f} MB -> {os.path.getsize(path) / 1e6:.1f} MB gz")
    print(dict(graded))


if __name__ == "__main__":
    main()
