#!/usr/bin/env python3
"""Fetch a Shamela book's pages into an OpenITI-shaped file.

The library CDN builder (`build_library_cdn.py`) already knows how to turn
OpenITI's mARkdown into the app's archive, so a book that only exists on
shamela.ws is scraped into the *same* dialect — `#META#` header, `# PageV…`
page markers, `# ` paragraphs — and then goes through that one builder. Two
builders would mean two sets of quirks to keep in step.

Usage:
    python fetch_shamela_book.py --id 9970 --out books/2000TammamHassan.LughaCarabiyya-ara1
"""

from __future__ import annotations

import argparse
import html
import re
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor

UA = "Mozilla/5.0 (compatible; AwanLibraryBot/1.0)"
OPENITI_BANNER = "######OpenITI#"
PAGE_URL = "https://shamela.ws/book/{book}/{index}"
NASS_RE = re.compile(
    r'<div class="nass[^"]*"[^>]*data-page-num="(\d+)"[^>]*>(.*?)'
    r'(?=<div id="appended_pages"|<div id="load_next_wrap"|</div>\s*</div>\s*<div)',
    re.S,
)
PARA_RE = re.compile(r"<p[^>]*>(.*?)</p>", re.S)
TAG_RE = re.compile(r"<[^>]+>")
# The site appends a "share this page" widget and pager links inside the block.
NOISE = re.compile(r"^(شارك|إغلاق|<<|>>|التالي|السابق|صفحة)\b")


def fetch(url: str, attempts: int = 3) -> str | None:
    for attempt in range(attempts):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(request, timeout=30) as response:
                return response.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as error:
            if error.code == 404:
                return None
            time.sleep(1 + attempt)
        except Exception:
            time.sleep(1 + attempt)
    return None


def page_text(book: int, index: int) -> tuple[int, list[str]] | None:
    raw = fetch(PAGE_URL.format(book=book, index=index))
    if not raw:
        return None
    match = NASS_RE.search(raw)
    if not match:
        return None
    page_no = int(match.group(1))
    fragment = re.sub(r"<span[^>]*class=\"anchor\"[^>]*>\s*</span>", "", match.group(2))
    fragment = re.sub(r'<a [^>]*class="btn_tag[^>]*>.*?</a>', "", fragment, flags=re.S)
    paragraphs: list[str] = []
    blocks = PARA_RE.findall(fragment) or [fragment]
    for block in blocks:
        text = html.unescape(TAG_RE.sub("", block))
        text = re.sub(r"\s+", " ", text).strip()
        if text and not NOISE.match(text):
            paragraphs.append(text)
    return page_no, paragraphs


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", type=int, required=True, help="shamela book id")
    parser.add_argument("--out", required=True, help="output *-ara1 path")
    parser.add_argument("--title", required=True)
    parser.add_argument("--author", required=True)
    parser.add_argument("--died", default="", help="hijri death year, when known")
    parser.add_argument("--uri", required=True, help="OpenITI-style BookURI, no leading #")
    parser.add_argument("--first", type=int, default=1)
    parser.add_argument("--last", type=int, default=2000)
    parser.add_argument("--workers", type=int, default=4)
    args = parser.parse_args()

    results: dict[int, list[str]] = {}
    misses = 0
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {
            index: pool.submit(page_text, args.id, index)
            for index in range(args.first, args.last + 1)
        }
        for index in range(args.first, args.last + 1):
            try:
                page = futures[index].result()
            except Exception as error:  # a single bad page must not stop the book
                print(f"  page {index}: {error}", file=sys.stderr)
                continue
            if page is None:
                misses += 1
                # Ten consecutive misses means the book ended, not that the site
                # hiccupped: stop rather than hammer it for 2000 pages.
                if misses >= 10:
                    break
                continue
            misses = 0
            page_no, paragraphs = page
            results[index] = paragraphs
            if index % 25 == 0:
                print(f"  … {index} pages fetched", flush=True)

    if not results:
        print("nothing fetched", file=sys.stderr)
        return 2

    lines: list[str] = [
        # The corpus dialect opens with this banner; without it the builder never
        # enters header mode and titles the book after its file name.
        OPENITI_BANNER,
        "",
        f"#META# 000.BookURI\t:: #{args.uri}",
        f"#META# 010.AuthorNAME\t:: {args.author}",
    ]
    if args.died:
        lines.append(f"#META# 011.AuthorDIED\t:: {args.died}")
    lines += [
        f"#META# 020.BookTITLE\t:: {args.title}",
        "#META# 300.Notes\t:: scraped from shamela.ws",
        "#META#Header#End#",
        "",
    ]
    written = 0
    for index in sorted(results):
        lines.append(f"# PageV01P{index:04d}")
        for paragraph in results[index]:
            lines.append(f"# {paragraph}")
            written += 1
    with open(args.out, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")
    print(f"wrote {args.out}: {len(results)} pages, {written} paragraphs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
