"""Fetch the Mushaf page / juz / hizb / sajda index for all 6,236 ayat (keyless, api.quran.com v4).

Why: the shipped `quran_uthmani.json` stores only the text, per surah. A reader that
groups by *Mushaf page* (604 pages) and remembers where the reader stopped needs the
page number of every ayah, and that mapping cannot be derived from the text.

Output: assets/data/quran_index.json
    {"source": ..., "verses": 6236, "pages": 604, "juz": 30,
     "index": {"1": [[page, juz, hizb, sajda], ...7 ayat], "2": [...286], ...}}

Run:  python tools/fetch_quran_index.py
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

API = "https://api.quran.com/api/v4"
UA = "Mozilla/5.0 (compatible; AwanApp/1.0; Quran index builder)"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "data", "quran_index.json")

FIELDS = "page_number,juz_number,hizb_number,sajdah_number"


def get_json(url, tries=4):
    last = None
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=60) as response:
                return json.loads(response.read().decode("utf-8", "replace"))
        except Exception as exc:  # noqa: BLE001
            last = exc
            time.sleep(1.5 * (attempt + 1))
    raise SystemExit(f"FAILED {url}: {last}")


def main():
    index = {}
    for surah in range(1, 115):
        url = f"{API}/verses/by_chapter/{surah}?fields={FIELDS}&per_page=300"
        data = get_json(url)
        rows = []
        for verse in data.get("verses", []):
            rows.append([
                int(verse.get("page_number") or 0),
                int(verse.get("juz_number") or 0),
                int(verse.get("hizb_number") or 0),
                int(verse.get("sajdah_number") or 0),
            ])
        index[str(surah)] = rows
        print(f"  surah {surah:>3}: {len(rows):>3} ayat  (page {rows[0][0]}..{rows[-1][0]})"
              if rows else f"  surah {surah:>3}: EMPTY")
        sys.stdout.flush()

    ayat = sum(len(v) for v in index.values())
    pages = max(r[0] for v in index.values() for r in v)
    juz = max(r[1] for v in index.values() for r in v)
    sajda = sum(1 for v in index.values() for r in v if r[3])

    payload = {
        "source": "api.quran.com v4 /verses/by_chapter (page_number, juz_number, hizb_number, sajdah_number)",
        "verses": ayat,
        "pages": pages,
        "juz": juz,
        "sajda_ayat": sajda,
        "index": index,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, ensure_ascii=False, separators=(",", ":"))

    size_kb = os.path.getsize(OUT) / 1024
    print(f"\n>> {os.path.relpath(OUT, ROOT)}  {size_kb:.0f} KB")
    print(f"   ayat={ayat} pages={pages} juz={juz} sajda={sajda}")
    assert ayat == 6236, f"expected 6236 ayat, got {ayat}"
    assert pages == 604, f"expected 604 pages, got {pages}"
    assert juz == 30, f"expected 30 juz, got {juz}"


if __name__ == "__main__":
    main()
