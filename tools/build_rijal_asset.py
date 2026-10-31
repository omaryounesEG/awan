"""Build the rijal (narrator) index the hadith section ships.

Source: the narrator table of the Hadith_RAG project
(`data/narrators_cleaned.parquet`), which carries an Arabic name gloss beside the
transliterated one, a reliability category, a death year and the places a
narrator lived in.

What we keep is exactly what the dataset says. The five categories are the
dataset's own `grade_category` values — «صحابي», «ثقة», «صدوق», «ضعيف»,
«غير محدد» — not our verdict on anyone. Where the source does not classify a
narrator, the app says «غير محدد» rather than guessing.

Usage:
    python tools/build_rijal_asset.py --source "H:/Hadith_RAG/data/narrators_cleaned.parquet" --out assets/hadith
"""
from __future__ import annotations

import argparse
import gzip
import json
import os
import re

import pandas as pd

CATEGORIES = [
    ("sahabi", "صحابي"),
    ("thiqah", "ثقة"),
    ("sadook", "صدوق"),
    ("daeef", "ضعيف"),
    ("unknown", "غير محدد"),
]
CATEGORY_INDEX = {key: i for i, (key, _) in enumerate(CATEGORIES)}

ARABIC = re.compile(r"[\u0600-\u06FF]")
PAREN = re.compile(r"[()]")


ARABIC_RUN = re.compile(r"[\u0600-\u06FF][\u0600-\u06FF\s\u0670\u0640]*")


def arabic_name(raw: str) -> str:
    """The longest Arabic run in the record, without the blessing formulas.

    The source mixes layouts — sometimes the Arabic is in parentheses, sometimes
    it simply trails the transliteration — so the longest Arabic run is taken
    rather than trusting one shape.
    """
    text = str(raw or "")
    runs = [match.group(0).strip() for match in ARABIC_RUN.finditer(text)]
    runs = [run for run in runs if len(run) >= 3]
    if not runs:
        return ""
    name = max(runs, key=len)
    for stop in (" رضي ", " رحمه ", " عليه ", " صلى ", " صلّى "):
        index = name.find(stop)
        if index != -1:
            name = name[:index]
    for blessing in (
        "رضي الله عنه",
        "رضي الله عنها",
        "رضي الله عنهم",
        "رحمه الله",
        "صلى الله عليه وسلم",
        "صلّى الله عليه وسلّم",
    ):
        name = name.replace(blessing, " ")
    name = name.replace(")", " ").strip(" .،-()")
    name = re.sub(r"\s+", " ", name)
    # A name of only particles is not a name.
    if len(name) < 3 or name in ("رضي الله عنه", "صلى الله عليه وسلم"):
        return ""
    return name


def clean_place(raw: object) -> str:
    text = str(raw or "").strip()
    if not text or text.lower() == "nan" or not ARABIC.search(text):
        return ""
    return text.split(",")[0].strip()


def death_year(raw: object) -> int:
    try:
        value = float(raw)
    except (TypeError, ValueError):
        return 0
    if value != value or value <= 0:  # NaN or nonsense
        return 0
    return int(round(value))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True)
    parser.add_argument("--out", default="assets/hadith")
    args = parser.parse_args()

    table = pd.read_parquet(
        args.source,
        columns=["scholar_indx", "name", "grade_category", "death_year", "places"],
    )

    rows = []
    for record in table.itertuples(index=False):
        name = arabic_name(record.name)
        if len(name) < 3:
            continue
        category = CATEGORY_INDEX.get(str(record.grade_category).strip(), 4)
        rows.append(
            [
                name,
                category,
                death_year(record.death_year),
                clean_place(record.places),
            ]
        )

    seen = set()
    unique = []
    for row in rows:
        key = (row[0], row[1])
        if key in seen:
            continue
        seen.add(key)
        unique.append(row)
    rows = unique
    rows.sort(key=lambda row: row[0])
    doc = {
        "v": 1,
        "categories": [label for _, label in CATEGORIES],
        "note": "التصنيف من مصدر البيانات، و«غير محدد» تعني أن المصدر لم يصنّف الراوي.",
        "narrators": rows,
    }

    os.makedirs(args.out, exist_ok=True)
    path = os.path.join(args.out, "rijal_v1.json.gz")
    raw = json.dumps(doc, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    with gzip.open(path, "wb", compresslevel=9) as handle:
        handle.write(raw)

    counts = {}
    for row in rows:
        counts[CATEGORIES[row[1]][1]] = counts.get(CATEGORIES[row[1]][1], 0) + 1
    print(f"narrators {len(rows)}")
    print(f"raw {len(raw) / 1e6:.2f} MB -> {os.path.getsize(path) / 1e6:.2f} MB gz")
    print(counts)
    print(rows[:3])


if __name__ == "__main__":
    main()
