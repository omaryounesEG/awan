"""Download the offline data assets for the Awan app.

Sources (all keyless / public):
  * Quran Uthmani text + surah metadata : api.quran.com v4
  * Tafseer (add-on packages)           : api.quran.com v4 tafsirs
  * Fonts (OFL)                         : github raw (IBM Plex Sans Arabic, Amiri Quran)

Usage:  python tools/fetch_data.py            (from the project root)
"""
import json
import os
import sys
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "assets", "data")
FONTS = os.path.join(ROOT, "assets", "fonts")
ADDONS = os.path.join(ROOT, "assets", "addons")
for d in (DATA, FONTS, ADDONS):
    os.makedirs(d, exist_ok=True)

API = "https://api.quran.com/api/v4"
UA = {"User-Agent": "AwanApp/1.0 (offline data fetch)"}

FONT_URLS = {
    # UI font (IBM Plex Sans Arabic - OFL)
    "IBMPlexSansArabic-Light.ttf": "https://raw.githubusercontent.com/IBM/plex/master/packages/plex-sans-arabic/fonts/complete/ttf/IBMPlexSansArabic-Light.ttf",
    "IBMPlexSansArabic-Regular.ttf": "https://raw.githubusercontent.com/IBM/plex/master/packages/plex-sans-arabic/fonts/complete/ttf/IBMPlexSansArabic-Regular.ttf",
    "IBMPlexSansArabic-Medium.ttf": "https://raw.githubusercontent.com/IBM/plex/master/packages/plex-sans-arabic/fonts/complete/ttf/IBMPlexSansArabic-Medium.ttf",
    "IBMPlexSansArabic-SemiBold.ttf": "https://raw.githubusercontent.com/IBM/plex/master/packages/plex-sans-arabic/fonts/complete/ttf/IBMPlexSansArabic-SemiBold.ttf",
    "IBMPlexSansArabic-Bold.ttf": "https://raw.githubusercontent.com/IBM/plex/master/packages/plex-sans-arabic/fonts/complete/ttf/IBMPlexSansArabic-Bold.ttf",
    # Quranic script (Amiri Quran - OFL, full Uthmani vowel support)
    "AmiriQuran-Regular.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/amiriquran/AmiriQuran-Regular.ttf",
    "ScheherazadeNew-Regular.ttf": "https://raw.githubusercontent.com/google/fonts/main/ofl/scheherazadenew/ScheherazadeNew-Regular.ttf",
}


def get_json(url, tries=5):
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.loads(r.read().decode("utf-8"))
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(1.5 * (i + 1))
    raise SystemExit(f"FAILED {url}: {last}")


def download(url, path, tries=4):
    if os.path.exists(path) and os.path.getsize(path) > 1024:
        print(f"  = {os.path.basename(path)} ({os.path.getsize(path)//1024} KB, cached)")
        return
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=120) as r:
                blob = r.read()
            with open(path, "wb") as f:
                f.write(blob)
            print(f"  + {os.path.basename(path)} ({len(blob)//1024} KB)")
            return
        except Exception as e:  # noqa: BLE001
            print("    retry", i + 1, e)
            time.sleep(2 * (i + 1))
    raise SystemExit(f"FAILED download {url}")


def fetch_fonts():
    print("[fonts]")
    for name, url in FONT_URLS.items():
        download(url, os.path.join(FONTS, name))


def fetch_quran():
    print("[quran metadata]")
    ar = get_json(f"{API}/chapters?language=ar")["chapters"]
    en = {c["id"]: c for c in get_json(f"{API}/chapters?language=en")["chapters"]}
    surahs = []
    for c in ar:
        e = en[c["id"]]
        surahs.append({
            "id": c["id"],
            "name_ar": c["name_arabic"],
            "name_en": e["name_simple"],
            "translated_en": e["translated_name"]["name"].replace("Surah ", ""),
            "place": c["revelation_place"],
            "ayah_count": c["verses_count"],
            "bismillah_pre": c["bismillah_pre"],
            "page_start": c["pages"][0],
        })
    print(f"  surahs={len(surahs)}")

    ayahs_path = os.path.join(DATA, "quran_uthmani.json")
    if os.path.exists(ayahs_path) and os.path.getsize(ayahs_path) > 500000:
        print("  = quran_uthmani.json cached")
        return surahs
    print("[quran text] 114 requests ...")
    ayahs = {}
    for s in range(1, 115):
        chunk = get_json(f"{API}/quran/verses/uthmani?chapter_number={s}")["verses"]
        ayahs[str(s)] = [v["text_uthmani"] for v in chunk]
        print(f"  - {s:3d}/{114}  {len(chunk)} ayat", flush=True)
    payload = {"source": "api.quran.com v4 (uthmani)", "surahs": surahs, "ayahs": ayahs}
    with open(ayahs_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, separators=(",", ":"))
    print(f"  + quran_uthmani.json ({os.path.getsize(ayahs_path)//1024} KB)")
    return surahs


TAFSIR_TARGETS = {
    # id -> slug used for the add-on file name
    16: "muyassar",       # التفسير الميسر (bundled)
}


def fetch_tafsirs():
    print("[tafsir list]")
    all_t = get_json(f"{API}/resources/tafsirs?language=ar")["tafsirs"]
    arabic = [t for t in all_t if t["language_name"] == "arabic"]
    print("  arabic tafsirs:", [(t["id"], t["name"], t["slug"]) for t in arabic][:14])
    manifest = {"source": "api.quran.com v4", "tafsirs": []}

    # probe structure once
    probe = get_json(f"{API}/quran/tafsirs/16?chapter_number=1")
    keys = list(probe.keys())
    print("  probe keys:", keys)
    sample = probe.get("tafsirs") or probe.get("verses") or []
    print("  probe sample:", json.dumps(sample[:1], ensure_ascii=False)[:300])

    for tid, slug in TAFSIR_TARGETS.items():
        out = os.path.join(ADDONS, f"tafsir_{slug}.json")
        meta = next((t for t in all_t if t["id"] == tid), None)
        name = meta["name"] if meta else slug
        author = meta["author_name"] if meta else ""
        if os.path.exists(out) and os.path.getsize(out) > 100000:
            print(f"  = tafsir_{slug}.json cached")
        else:
            print(f"[tafsir {tid} {name}] 114 requests ...")
            verses = {}
            for s in range(1, 115):
                chunk = get_json(f"{API}/quran/tafsirs/{tid}?chapter_number={s}")
                rows = chunk.get("tafsirs") or chunk.get("verses") or []
                for row in rows:
                    key = row.get("verse_key") or f"{s}:{row.get('verse_number')}"
                    text = row.get("text") or row.get("tafsir") or ""
                    if text:
                        verses[key] = text
                print(f"  - {s:3d}/114  total={len(verses)}", flush=True)
            with open(out, "w", encoding="utf-8") as f:
                json.dump({"id": tid, "name": name, "author": author, "slug": slug,
                           "source": "api.quran.com v4", "ayahs": verses},
                          f, ensure_ascii=False, separators=(",", ":"))
            print(f"  + tafsir_{slug}.json ({os.path.getsize(out)//1024} KB)")
        manifest["tafsirs"].append({
            "id": tid, "slug": slug, "name": name, "author": author,
            "language": "ar", "bundled": True,
            "size_kb": os.path.getsize(out) // 1024,
        })

    # additional offline-installable tafsirs advertised in the add-on store
    for t in arabic:
        if t["id"] in TAFSIR_TARGETS:
            continue
        manifest["tafsirs"].append({
            "id": t["id"], "slug": t["slug"], "name": t["name"],
            "author": t["author_name"], "language": "ar", "bundled": False,
            "size_kb": None,
            "download_url": f"{API}/quran/tafsirs/{t['id']}?chapter_number={{chapter}}",
        })
    with open(os.path.join(ADDONS, "addons_manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)
    print("  + addons_manifest.json")


if __name__ == "__main__":
    fetch_fonts()
    fetch_quran()
    if "--quran-only" not in sys.argv:
        fetch_tafsirs()
    print("done")
