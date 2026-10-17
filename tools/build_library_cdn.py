#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build a static "CDN" library for Awan from an OpenITI text corpus.

Why this exists
---------------
The official Shamela has no REST API, so the library ships as *static files*:
one master index plus one small archive per book. A plain static host (GitHub
Releases, S3, R2, any nginx) is then the whole backend — no server code, no
database to run, nothing to keep alive.

What one book becomes
---------------------
    <book_id>.sqlite        canonical, openable by any SQLite client
    <book_id>.jsonl         one JSON object per chunk — what the app streams
    (both inside)  books/<book_id>.sqlite.zip

The JSONL twin is deliberate: the app's installer runs inside a Dart isolate and
must not depend on a native SQLite build to read a book. It still ships the
`.sqlite` file so the archive is useful outside the app (and so a future client
that *does* link SQLite can read the same artefact).

Index
-----
    library_index.json  — metadata only (id, title, author, category, size,
                          chapters, url). The app caches this in Isar and searches
                          it locally: zero network calls while typing.

Usage
-----
    python tools/build_library_cdn.py --source tools/openiti_sample \
        --out tools/cdn --base-url https://cdn.example.com/awan/library

Reads every `*-ara1` file under --source (or a single file), writes the CDN tree
and prints a progress line per book.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
import zipfile
from typing import Dict, Iterable, List, Optional, Tuple

# Chunk size for the reading view: big enough to keep Isar rows few, small enough
# that a single ListView item is cheap to lay out.
TARGET_CHARS = 3500
# Below this, a page/section break keeps accumulating instead of emitting a row.
MIN_CHARS = 700

BOM = "\ufeff"
HEADER_END = "#META#Header#End#"
SURAH_START = "######OpenITI#"

# Stripped from the body: mARkdown quotes, hemistich separators, manuscript/page
# micro-markers. Left in place they would print as litter inside a paragraph.
TOKEN_RE = re.compile(
    r"@QB@|@QE@|%~%|ms\d{2,}|Page[VP]\d*(?:P\d+)?|#MILESTONE\d+|@@[A-Z]+@@"
)
PAGE_RE = re.compile(r"^#\s*PageV(\d+)P(\d+)\s*$")
SECTION_RE = re.compile(r"^#+\s*\|\s*(.+?)\s*$")

# Author death year, from either the numbered field or the Arabic prose headers.
DIED_RE = re.compile(r"(?:المتوفى[:\s]*|ت\s*:?\s*)(\d{3,4})")
DIED_RANGE_RE = re.compile(r"\(?\s*(\d{3,4})\s*[-–]\s*(\d{3,4})\s*ه")

# Only used when the corpus record carries no subject field at all.
CATEGORY_HINTS: List[Tuple[str, str]] = [
    ("تفسير", "التفسير وعلوم القرآن"),
    ("إعجاز", "التفسير وعلوم القرآن"),
    ("علوم القرآن", "التفسير وعلوم القرآن"),
    ("بخاري", "شروح الحديث"),
    ("صحيح", "شروح الحديث"),
    ("سنن", "متون الحديث"),
    ("حديث", "علوم الحديث"),
    ("ديوان", "الشعر والأدب"),
    ("شعر", "الشعر والأدب"),
    ("أدب", "الشعر والأدب"),
    ("فقه", "الفقه"),
    ("هداية", "الفقه"),
    ("مدونة", "الفقه"),
    ("عقيدة", "العقيدة"),
    ("توحيد", "العقيدة"),
    ("طب", "الطب"),
    ("تاريخ", "التاريخ والتراجم"),
    ("تراجم", "التاريخ والتراجم"),
    ("لغة", "اللغة والنحو"),
    ("نحو", "اللغة والنحو"),
    ("فصيح", "اللغة والنحو"),
]
DEFAULT_CATEGORY = "متون ورسائل"


# --------------------------------------------------------------------------- IO
def log(message: str) -> None:
    print(message, flush=True)


def iter_corpus_files(source: str) -> List[str]:
    """Every OpenITI version file (…-ara1) under a folder, or the file itself."""
    if os.path.isfile(source):
        return [source]
    found: List[str] = []
    for root, _dirs, files in os.walk(source):
        for name in files:
            if name.endswith("-ara1"):
                found.append(os.path.join(root, name))
    return sorted(found)


def read_text(path: str) -> str:
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        return handle.read().lstrip(BOM)


# ----------------------------------------------------------------- metadata
def split_header(text: str) -> Tuple[Dict[str, str], str]:
    """Return (raw header fields, body). Handles both header dialects."""
    fields: Dict[str, str] = {}
    body_start = 0
    lines = text.split("\n")
    in_header = False
    for index, line in enumerate(lines):
        if SURAH_START in line and not in_header:
            in_header = True
            continue
        if in_header:
            if line.startswith(HEADER_END):
                body_start = index + 1
                in_header = False
                break
            if not line.startswith("#META#"):
                # A record whose header is interrupted but never closed: treat it
                # as ended rather than swallowing the first paragraphs as metadata.
                if line.strip() and not line.startswith("#"):
                    body_start = index
                    break
                continue
            payload = line[len("#META#"):].strip()
            if not payload:
                continue
            if "::" in payload:
                key, value = payload.split("::", 1)
            elif "\t" in payload:
                key, value = payload.split("\t", 1)
            elif ":" in payload:
                key, value = payload.split(":", 1)
            else:
                key, value = payload, ""
            key = key.replace("\t", " ").strip().rstrip(":")
            fields.setdefault(key, value.strip())
    return fields, "\n".join(lines[body_start:])


def field(fields: Dict[str, str], *names: str) -> Optional[str]:
    """First non-empty value among candidate keys (case/space tolerant)."""
    lowered = {k.lower().replace("\u00a0", " ").strip(): v for k, v in fields.items()}
    for name in names:
        value = lowered.get(name.lower())
        if value and value.strip() and value.strip().upper() != "NODATA":
            return value.strip()
    return None


TITLE_LABELS = ("المؤلف", "ملاحظة", "المحقق", "الناشر", "الطبعة", "عدد الأجزاء", "bkid", "auth")


def title_from(fields: Dict[str, str], fallback: str) -> str:
    raw = field(fields, "020.BookTITLE", "bk", "BookTITLE", "الكتاب") or ""
    if not raw:
        # `الكتاب` in Shamela records is a whole blob: العنوان ¶ المؤلف ¶ ملاحظة
        blob = field(fields, "الكتاب") or ""
        raw = blob.split("¶")[0]
    raw = raw.replace("¶", " ").strip()
    # Cut as soon as the next labelled field starts inside the same string.
    for label in TITLE_LABELS:
        for separator in (" :", ":", "  "):
            marker = f"{label}{separator}"
            if marker in raw:
                raw = raw.split(marker)[0]
    raw = re.sub(r"[\s\u00a0]{2,}", " ", raw).strip(" .:-")
    return (raw or fallback)[:180]


def author_from(fields: Dict[str, str], fallback: str) -> str:
    raw = field(fields, "010.AuthorNAME", "المؤلف", "auth", "AuthorNAME") or fallback
    raw = raw.replace("¶", " ").strip()
    raw = re.sub(r"[\s\u00a0]{2,}", " ", raw)
    # «(المتوفى: 238هـ)» and «(319 - 388 ه = 931 - 998 م)» add nothing to a name /
    # a list row: the hijri death year is its own field.
    raw = re.sub(r"\([^()]*(?:المتوفى|\d{3,4}\s*[-–]\s*\d{3,4})[^()]*\)", " ", raw)
    raw = re.sub(r"[\s\u00a0]{2,}", " ", raw).strip(" .،-")
    return (raw or fallback)[:160]


def died_from(fields: Dict[str, str]) -> Optional[int]:
    direct = field(fields, "011.AuthorDIED", "AuthorDIED")
    if direct and direct.isdigit():
        return int(direct)
    haystack = " ".join(
        v for k, v in fields.items() if k.lower() in
        {"010.authorname", "مؤلف", "المؤلف", "auth", "authinf"}
    )
    match = DIED_RE.search(haystack)
    if match:
        return int(match.group(1))
    match = DIED_RANGE_RE.search(haystack)
    if match:
        return int(match.group(2))
    return None


def category_from(fields: Dict[str, str], title: str) -> str:
    subject = field(fields, "021.BookSUBJ", "BookSUBJ", "التصنيف", "موضوع")
    if subject:
        # Some records glue a hierarchy together («تواريخ البلدان :: كتب التاريخ»);
        # the leaf is the useful shelf.
        return subject.split("::")[-1].strip() or DEFAULT_CATEGORY
    for needle, category in CATEGORY_HINTS:
        if needle in title:
            return category
    return DEFAULT_CATEGORY


SAFE_ID_RE = re.compile(r"[^0-9A-Za-z._-]+")


def ids_from(path: str, fields: Dict[str, str]) -> Tuple[str, str, str]:
    """(book_id, version, author_slug) from the URI field or the file name.

    Several corpus records carry a placeholder instead of a URI (`#NOCODE`).
    Trusting it produced six books with the *same* id — and therefore six
    archives overwriting one another — so a placeholder falls back to the file
    name, which is unique per corpus file.
    """
    name = os.path.basename(path)
    stem = name[: -len("-ara1")] if name.endswith("-ara1") else name
    parts = stem.split(".")
    version = parts[-1] if len(parts) > 1 else "ara1"
    fallback_id = ".".join(parts[:-1]) if len(parts) > 1 else stem

    uri = field(fields, "000.BookURI", "BookURI") or ""
    clean = uri.lstrip("#").strip()
    looks_real = (
        bool(clean)
        and "." in clean
        and not re.search(r"NOCODE|NODATA|^#*$", clean, re.IGNORECASE)
    )
    book_id = clean if looks_real else fallback_id
    book_id = SAFE_ID_RE.sub("-", book_id).strip("-._") or "book"
    return book_id, version, book_id.split(".")[0]


# ------------------------------------------------------------------- cleaning
def to_paragraphs(body: str) -> List[Tuple[str, str]]:
    """mARkdown body -> [(kind, text)] with kind in {text, section, page}.

    `# ` opens a paragraph and every following `~~` line continues it: OpenITI
    wraps long paragraphs, so a `~~` line is *not* a new paragraph and joining it
    with a space is what reproduces the printed sentence.
    """
    out: List[Tuple[str, str]] = []
    buffer: List[str] = []

    def flush() -> None:
        if buffer:
            text = " ".join(buffer)
            text = TOKEN_RE.sub(" ", text)
            text = re.sub(r"\s{2,}", " ", text).strip()
            if text:
                out.append(("text", text))
            buffer.clear()

    for raw_line in body.split("\n"):
        line = raw_line.rstrip()
        if not line:
            continue
        if line.startswith("#META#") or SURAH_START in line:
            continue
        section = SECTION_RE.match(line)
        if section:
            flush()
            title = TOKEN_RE.sub(" ", section.group(1)).strip(" ()")
            if title:
                out.append(("section", title))
            continue
        page = PAGE_RE.match(line)
        if page:
            flush()
            out.append(("page", page.group(2).lstrip("0") or "0"))
            continue
        if line.startswith("~~"):
            buffer.append(TOKEN_RE.sub(" ", line[2:]).strip())
            continue
        if line.startswith("#"):
            flush()
            buffer.append(TOKEN_RE.sub(" ", line.lstrip("#").strip()))
            continue
        buffer.append(TOKEN_RE.sub(" ", line).strip())
    flush()
    return out


def to_chunks(paragraphs: Iterable[Tuple[str, str]]) -> List[Dict[str, object]]:
    """Pack paragraphs into reading chunks, breaking on sections/pages/size."""
    chunks: List[Dict[str, object]] = []
    current: List[str] = []
    current_title: Optional[str] = None
    current_page: Optional[str] = None
    size = 0

    def flush() -> None:
        nonlocal current, current_title, current_page, size
        if current:
            chunks.append(
                {
                    "title": current_title,
                    "page": current_page,
                    "text": "\n\n".join(current),
                }
            )
        current, size = [], 0
        current_title = None
        current_page = None

    for kind, text in paragraphs:
        if kind == "page":
            # A page break ends a chunk only once the chunk is worth showing on
            # its own; a book whose pages are two lines each would otherwise
            # become thousands of one-line rows.
            if size >= MIN_CHARS:
                flush()
            elif current_page is None:
                current_page = text
            continue
        if kind == "section":
            flush()
            current_title = text
            continue
        current.append(text)
        size += len(text)
        if size >= TARGET_CHARS:
            flush()

    flush()
    return chunks


# --------------------------------------------------------------------- output
def write_sqlite(path: str, meta: Dict[str, object], chunks: List[Dict[str, object]]) -> None:
    if os.path.exists(path):
        os.remove(path)
    connection = sqlite3.connect(path)
    try:
        connection.execute("CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT)")
        connection.execute(
            "CREATE TABLE chapters (idx INTEGER PRIMARY KEY, title TEXT, page TEXT, text TEXT)"
        )
        connection.executemany(
            "INSERT INTO meta (key, value) VALUES (?, ?)",
            [(k, "" if v is None else str(v)) for k, v in meta.items()],
        )
        connection.executemany(
            "INSERT INTO chapters (idx, title, page, text) VALUES (?, ?, ?, ?)",
            [
                (i, c.get("title"), c.get("page"), c["text"])
                for i, c in enumerate(chunks)
            ],
        )
        connection.execute("CREATE INDEX idx_chapters_title ON chapters(title)")
        connection.commit()
    finally:
        connection.close()


def write_jsonl(path: str, chunks: List[Dict[str, object]]) -> None:
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        for index, chunk in enumerate(chunks):
            handle.write(
                json.dumps(
                    {
                        "i": index,
                        "t": chunk.get("title"),
                        "p": chunk.get("page"),
                        "x": chunk["text"],
                    },
                    ensure_ascii=False,
                )
                + "\n"
            )


def build_book(path: str, out_dir: str, base_url: str) -> Dict[str, object]:
    text = read_text(path)
    fields, body = split_header(text)
    fallback_title = os.path.basename(path).split(".")[1] if "." in os.path.basename(path) else os.path.basename(path)
    book_id, version, author_slug = ids_from(path, fields)
    title = title_from(fields, fallback_title)
    author = author_from(fields, author_slug)
    died = died_from(fields)
    category = category_from(fields, title)

    paragraphs = to_paragraphs(body)
    chunks = to_chunks(paragraphs)
    chars = sum(len(str(c["text"])) for c in chunks)

    meta: Dict[str, object] = {
        "id": book_id,
        "title": title,
        "author": author,
        "author_died": died,
        "category": category,
        "source": "openiti",
        "version": version,
        "chapters": len(chunks),
        "chars": chars,
        "openiti_path": os.path.basename(path),
    }

    books_dir = os.path.join(out_dir, "books")
    os.makedirs(books_dir, exist_ok=True)
    sqlite_path = os.path.join(books_dir, f"{book_id}.sqlite")
    jsonl_path = os.path.join(books_dir, f"{book_id}.jsonl")
    write_sqlite(sqlite_path, meta, chunks)
    write_jsonl(jsonl_path, chunks)

    archive_name = f"books/{book_id}.sqlite.zip"
    archive_path = os.path.join(out_dir, archive_name)
    with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        archive.write(sqlite_path, arcname=f"{book_id}.sqlite")
        archive.write(jsonl_path, arcname=f"{book_id}.jsonl")
    os.remove(sqlite_path)   # keep only the served artefacts
    os.remove(jsonl_path)

    meta["file_size"] = os.path.getsize(archive_path)
    meta["archive"] = archive_name
    meta["url"] = f"{base_url.rstrip('/')}/{archive_name}"
    return meta


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Build the Awan static book CDN from OpenITI texts.")
    parser.add_argument("--source", required=True, help="OpenITI folder (or a single *-ara1 file)")
    parser.add_argument("--out", required=True, help="output folder for library_index.json + books/")
    parser.add_argument("--base-url", default="https://example.invalid/awan/library",
                        help="public base URL the app will prepend to each archive")
    parser.add_argument("--limit", type=int, default=0, help="stop after N books (0 = all)")
    args = parser.parse_args(argv)

    files = iter_corpus_files(args.source)
    if args.limit:
        files = files[: args.limit]
    if not files:
        log(f"no *-ara1 files under {args.source}")
        return 2

    os.makedirs(args.out, exist_ok=True)
    entries: List[Dict[str, object]] = []
    log(f"building {len(files)} book(s) -> {args.out}")
    for index, path in enumerate(files, start=1):
        try:
            entry = build_book(path, args.out, args.base_url)
        except Exception as error:  # keep going: one bad file must not kill the run
            log(f"  [{index}/{len(files)}] FAILED {os.path.basename(path)}: {error}")
            continue
        entries.append(entry)
        log(
            f"  [{index}/{len(files)}] {entry['id'][:52]:<52} "
            f"{entry['chapters']:>5} chunks  {entry['chars']:>9,} chars  "
            f"{entry['file_size']/1024:>8.0f} KB  [{entry['category']}]"
        )

    # A duplicate id silently overwrites another book's archive on the host, and
    # a missing archive is a 404 the reader only discovers mid-download: both are
    # caught here rather than in the app.
    ids = [str(e["id"]) for e in entries]
    duplicates = sorted({i for i in ids if ids.count(i) > 1})
    if duplicates:
        log(f"ERROR duplicate ids: {duplicates}")
        return 3
    missing = [
        e["archive"] for e in entries
        if not os.path.exists(os.path.join(args.out, str(e["archive"])))
    ]
    if missing:
        log(f"ERROR missing archives: {missing}")
        return 4

    entries.sort(key=lambda e: (str(e["category"]), str(e["title"])))
    index_path = os.path.join(args.out, "library_index.json")
    with open(index_path, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(
            {
                "schema": 1,
                "generated_by": "build_library_cdn.py",
                "count": len(entries),
                "books": entries,
            },
            handle,
            ensure_ascii=False,
            indent=1,
        )
    total_kb = sum(int(e["file_size"]) for e in entries) / 1024
    log(f"index: {index_path}  ({len(entries)} books, {total_kb/1024:.1f} MB of archives)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
