#!/usr/bin/env python3
"""Ground the mutashabihat graph in الكسائي's «مشتبهات القرآن».

The graph shipped so far links two verses whenever they share a wording, and
"share" was measured by the length of the common phrase. That rule is blind in
both directions: it links verses that merely both start with «ذلك», and it misses
passages that only a reader steeped in the text would pair.

الكسائي (ت 189هـ) — the earliest author on the subject — states, surah by surah,
which passages look alike and, just as usefully, which have **no** counterpart
(«ليس مثله»). Those two statements are the precision and the recall this script
applies:

* a link that touches a verse the book calls unique is dropped — the book is an
  authority saying there is nothing to link it to;
* a link resting on one or two shared words, with no book backing, is dropped;
* a link the book itself documents is kept and tagged `kisai`, so the app can
  cite the source instead of implying the app worked it out.

Usage:
    python tools/apply_kisai_filter.py --graph assets/data/mutashabihat_data_normalized.json \
        --book tools/kisai/book.jsonl --quran assets/data/quran_uthmani.json \
        --out-graph assets/data/mutashabihat_data_normalized.json \
        --out-book assets/data/kisai_mutashabihat.json
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter

ARABIC_DIGITS = str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789")
SURAH_RE = re.compile(r"(?:ومن|من)\s+سورة\s+(.+?)(?:\s+عليه\s+السلام)?\s*$")
UNIQUE_MARKS = ("ليس مثله", "ليس في القرآن مثله")
COUNTERPART = "وسائر القرآن"
# Appended to `<rule_text>` so the phone can cite the source of a link.
KISAI_MARK = " | من مشتبهات القرآن للكسائي"


def load_quran(path: str):
    raw = json.load(open(path, encoding="utf-8"))
    counts = {str(s["id"]): s.get("ayah_count") for s in raw.get("surahs", [])}
    names = {s["name_ar"]: s["id"] for s in raw.get("surahs", [])}
    ids, absolute = {}, 1
    for surah in raw.get("surahs", []):
        for number in range(1, (counts[str(surah["id"])] or 0) + 1):
            ids[(surah["id"], number)] = absolute
            absolute += 1
    return ids, names, counts


def load_book(path: str, ids, names):
    """(verses with a counterpart, verses the book calls unique, raw entries)."""
    similar: dict[int, dict] = {}
    unique: dict[int, dict] = {}
    surah: int | None = None
    entries = [json.loads(line) for line in open(path, encoding="utf-8") if line.strip()]
    for record in entries:
        title = (record.get("t") or "").strip()
        matched = SURAH_RE.search(title)
        if matched:
            wanted = matched.group(1).replace("عليه السلام", "").strip()
            wanted = wanted[2:] if wanted.startswith("ال") else wanted
            surah = next(
                (
                    number
                    for name, number in names.items()
                    if (name[2:] if name.startswith("ال") else name).startswith(wanted[:6])
                ),
                surah,
            )
        body = record.get("x") or ""
        if not surah or "فيها" not in body:
            continue
        for chunk in re.split(r"(?=وفيها)", body):
            if "فيها" not in chunk:
                continue
            head = chunk.split(COUNTERPART)[0]
            numbers = {
                int(value.translate(ARABIC_DIGITS))
                for value in re.findall(r"\(([\u0660-\u0669\d]+)\)", head)
            }
            places = [
                (surah, number) for number in sorted(numbers) if (surah, number) in ids
            ]
            if any(mark in chunk for mark in UNIQUE_MARKS):
                # Keep the sentence: it is the author saying *why* there is
                # nothing to link, and the app shows it instead of an empty graph.
                for place in places:
                    unique[ids[place]] = {
                        "absolute_id": ids[place],
                        "surah": place[0],
                        "ayah": place[1],
                        "book_text": chunk.strip()[:240],
                    }
            elif COUNTERPART in chunk:
                for place in places:
                    similar[ids[place]] = {
                        "absolute_id": ids[place],
                        "surah": place[0],
                        "ayah": place[1],
                        "quoted": chunk.split(COUNTERPART)[1].strip()[:200],
                        "book_text": chunk.strip()[:240],
                    }
    return similar, unique


def common_words(rule_text: str) -> int:
    matched = re.search(r"موضع التشابه:\s*(.*?)\s*\|", rule_text or "")
    return len([word for word in (matched.group(1) if matched else "").split() if word])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--graph", required=True)
    parser.add_argument("--book", required=True)
    parser.add_argument("--quran", required=True)
    parser.add_argument("--out-graph", required=True)
    parser.add_argument("--out-book", required=True)
    parser.add_argument("--min-words", type=int, default=3)
    args = parser.parse_args()

    ids, names, _counts = load_quran(args.quran)
    similar, unique = load_book(args.book, ids, names)
    unique_ids = set(unique)
    graph = json.load(open(args.graph, encoding="utf-8"))

    stats = Counter()
    kept_nodes = []
    for node in graph:
        source_id = node["source_absolute_id"]
        targets = []
        for target in node.get("targets", []):
            stats["links_in"] += 1
            target_id = target["target_absolute_id"]
            touches_unique = source_id in unique_ids or target_id in unique_ids
            book_backed = target_id in similar or source_id in similar
            if touches_unique and not book_backed:
                stats["dropped book calls it unique"] += 1
                continue
            if common_words(target.get("rule_text", "")) < args.min_words and not book_backed:
                stats["dropped 1-2 shared words"] += 1
                continue
            if book_backed:
                # Say where it comes from, in the one field the app prints. The
                # app reads the shared wording as the text before the first «|»,
                # so appending a segment keeps every existing reader working.
                rule = target.get("rule_text") or ""
                if KISAI_MARK.strip() not in rule:
                    target["rule_text"] = f"{rule}{KISAI_MARK}"
                stats["kept and book-backed"] += 1
            else:
                stats["kept"] += 1
            targets.append(target)
        stats["links_out"] += len(targets)
        if targets:
            node["targets"] = targets
            kept_nodes.append(node)

    print(f"links: {stats['links_in']} -> {stats['links_out']}  ({stats['links_out']/max(stats['links_in'],1)*100:.0f}%)")
    for key, value in stats.most_common():
        if key not in {"links_in", "links_out"}:
            print(f"   {key}: {value}")
    print(f"verses with a counterpart per the book: {len(similar)} | verses the book calls unique: {len(unique)}")

    with open(args.out_graph, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(kept_nodes, handle, ensure_ascii=False, separators=(",", ":"))
    with open(args.out_book, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(
            {
                "schema": 1,
                "source": "مشتبهات القرآن - أبو الحسن علي بن حمزة الكسائي (ت 189هـ)",
                "similar": sorted(similar.values(), key=lambda item: item["absolute_id"]),
                "unique": sorted(unique.values(), key=lambda item: item["absolute_id"]),
            },
            handle,
            ensure_ascii=False,
            indent=1,
        )
    print("wrote", args.out_graph, "and", args.out_book)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
