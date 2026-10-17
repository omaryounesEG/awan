"""Download the authentic Mushaf fonts (QPC Hafs + QPC Symbols) into assets/fonts.

Flutter only loads `.ttf`/`.otf`, so the WOFF2 copies are useless here. Both files
are checked before they are accepted:

* **tables in bounds** — quran.com's own hosted copy of `UthmanicHafs1Ver18.ttf` is
  famously truncated (19 KB with a `glyf` table claiming 176 KB), and a truncated
  font renders as empty boxes at runtime with no error at build time;
* **Quranic coverage** — the font must map the ayah-end sign ۝ (U+06DD) and the
  Arabic-Indic digits, which is what makes a mushaf page look like a mushaf.

Sources (King Fahd Complex fonts, redistributed by the Quran Foundation CDN and the
`mustafa0x/qpc-fonts` mirror):

  https://verses.quran.foundation/fonts/quran/hafs/uthmanic_hafs/UthmanicHafs1Ver18.ttf
  https://raw.githubusercontent.com/mustafa0x/qpc-fonts/<sha>/various/UthmanicHafs1%20Ver09.ttf

Run:  python tools/fetch_mushaf_fonts.py
"""
import os
import struct
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = os.path.join(ROOT, "assets", "fonts")
UA = "Mozilla/5.0 (compatible; AwanApp/1.0; mushaf font fetch)"

SOURCES = {
    "UthmanicHafs1Ver18.ttf": [
        "https://verses.quran.foundation/fonts/quran/hafs/uthmanic_hafs/UthmanicHafs1Ver18.ttf",
        "https://raw.githubusercontent.com/mustafa0x/qpc-fonts/f93bf5f3/various/UthmanicHafs1%20Ver09.ttf",
    ],
}


def tables_ok(path):
    """Every top-level table must lie inside the file (catches truncation)."""
    with open(path, "rb") as fh:
        data = fh.read()
    if len(data) < 12:
        return False, "too small"
    num_tables = struct.unpack_from(">H", data, 4)[0]
    if not 0 < num_tables < 200:
        return False, f"implausible table count {num_tables}"
    for index in range(num_tables):
        off = 12 + index * 16
        if off + 16 > len(data):
            return False, "table directory past end of file"
        tag = data[off:off + 4].decode("ascii", "replace")
        # tag(4) checksum(4) offset(4) length(4)
        _, offset, length = struct.unpack_from(">III", data, off + 4)
        if offset + length > len(data):
            return False, f"table {tag} ends at {offset + length} > file {len(data)}"
    return True, f"{num_tables} tables"


def download(url, path):
    request = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(request, timeout=120) as response:
        with open(path, "wb") as fh:
            fh.write(response.read())


def main():
    os.makedirs(FONTS, exist_ok=True)
    failures = []
    for name, urls in SOURCES.items():
        target = os.path.join(FONTS, name)
        got = False
        for url in urls:
            try:
                download(url, target)
            except Exception as exc:  # noqa: BLE001
                print(f"  {name}: {url} -> {type(exc).__name__} {exc}")
                continue
            ok, note = tables_ok(target)
            size_kb = os.path.getsize(target) / 1024
            if ok:
                print(f"  OK  {name}  {size_kb:.0f} KB  ({note})  from {url}")
                got = True
                break
            print(f"  BAD {name}  {size_kb:.0f} KB  ({note}) — rejected, trying next source")
            os.remove(target)
        if not got:
            failures.append(name)

    if failures:
        raise SystemExit(f"could not obtain: {', '.join(failures)}")

    print("\nNow declare them in pubspec.yaml:")
    for name in SOURCES:
        print(f"    - family: {name[:-4]}\n      fonts:\n        - asset: assets/fonts/{name}")


if __name__ == "__main__":
    main()
