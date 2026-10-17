"""Fetch a complete tafsir (التفسير الميسّر) as a bundled offline add-on.

The quran.com v4 API exposes tafsir only per-ayah (`/tafsirs/{id}/by_ayah/{key}`),
so the 6,236 ayat are fetched with a small thread pool and retried on failure.

  python tools/fetch_tafsir.py
"""
import json
import os
import re
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "addons", "tafsir_muyassar.json")
QURAN = os.path.join(ROOT, "assets", "data", "quran_uthmani.json")
API = "https://api.quran.com/api/v4/tafsirs/16/by_ayah/"
UA = {"User-Agent": "AwanApp/1.0 (offline tafsir fetch)"}
TAG = re.compile(r"<[^>]+>")


def fetch(key, tries=4):
    for i in range(tries):
        try:
            req = urllib.request.Request(API + key, headers=UA)
            with urllib.request.urlopen(req, timeout=45) as r:
                text = json.loads(r.read().decode("utf-8"))["tafsir"]["text"]
            return key, TAG.sub("", text).strip()
        except Exception as e:  # noqa: BLE001
            if i == tries - 1:
                print(f"  !! {key}: {e}", flush=True)
                return key, ""
            time.sleep(1.2 * (i + 1))


def main():
    if os.path.exists(OUT) and os.path.getsize(OUT) > 2_000_000:
        print("cached", os.path.getsize(OUT) // 1024, "KB")
        return
    with open(QURAN, encoding="utf-8") as f:
        data = json.load(f)
    keys = []
    for s, ayahs in data["ayahs"].items():
        for i in range(len(ayahs)):
            keys.append(f"{s}:{i + 1}")
    print(f"ayahs to fetch: {len(keys)}")

    done = {}
    t0 = time.time()
    with ThreadPoolExecutor(max_workers=12) as pool:
        for n, (k, txt) in enumerate(pool.map(fetch, keys), 1):
            if txt:
                done[k] = txt
            if n % 500 == 0:
                print(f"  {n}/{len(keys)}  ok={len(done)}  {int(time.time()-t0)}s", flush=True)

    payload = {
        "id": 16,
        "slug": "muyassar",
        "name": "التفسير الميسّر",
        "author": "مجمع الملك فهد لطباعة المصحف الشريف",
        "source": "api.quran.com v4 (ar-tafsir-muyassar)",
        "ayahs": done,
    }
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, separators=(",", ":"))
    print(f"written {OUT}  {os.path.getsize(OUT)//1024} KB  ayat={len(done)}")


if __name__ == "__main__":
    sys.exit(main())
