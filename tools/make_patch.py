"""Build an `AWANPCH1` delta: `<from>__<to>.patch`, which the app applies to
the APK it is already running.

Why a format of our own instead of `bsdiff`: an APK is a zip of large compressed
entries, and bsdiff's byte-level matching is both memory-hungry on a phone (it
decodes a diff stream the size of the whole file) and tied to one C library's
quirks. Content-defined chunking is boring and predictable — identical regions
are copied from the installed APK, changed regions travel — and the applier can
stream it in fixed-size pieces.

Container:

    offset 0    "AWANPCH1"            8 bytes
    offset 8    old size              u64 LE
    offset 16   new size              u64 LE
    offset 24   op count              u32 LE
    offset 28   reserved              u32 LE
    offset 32   ops stream length     u64 LE (zlib)
    offset 40   literals length       u64 LE (zlib)
    offset 48   ops stream            op count × (u8 kind, u64 offset, u64 len)
    ...         literals stream       concatenated literal bytes

kind 0 copies `len` bytes from the old file at `offset`; kind 1 takes `len`
bytes from the literal stream. Every byte of the new file is accounted for,
and the applier refuses anything that does not add up to `new size`.

    python tools/make_patch.py --from old.apk --to new.apk \
        --from-version 1.20.0 --to-version 1.21.0 --out dist
"""
from __future__ import annotations

import argparse
import hashlib
import os
import random
import struct
import sys
import zlib

MAGIC = b"AWANPCH1"
HEADER = 48

# Chunk boundaries are chosen by content, not by position, so insertion or
# deletion early in the file does not invalidate every later chunk.
MASK = (1 << 13) - 1        # average chunk ≈ 8 KB
MIN_CHUNK = 1024
MAX_CHUNK = 65536

_rng = random.Random(0xA1A1)
GEAR = [_rng.getrandbits(64) for _ in range(256)]


def chunk_bounds(data: bytes):
    start = 0
    h = 0
    n = len(data)
    for i in range(n):
        h = ((h << 1) + GEAR[data[i]]) & 0xFFFFFFFFFFFFFFFF
        size = i - start + 1
        if size >= MIN_CHUNK and ((h & MASK) == 0 or size >= MAX_CHUNK):
            yield start, size
            start = i + 1
            h = 0
    if start < n:
        yield start, n - start


def build_ops(old: bytes, new: bytes):
    index = {}
    for off, size in chunk_bounds(old):
        key = hashlib.blake2b(old[off:off + size], digest_size=12).digest()
        index.setdefault(key, []).append((off, size))

    ops = bytearray()
    literals = bytearray()
    copied = literal = 0
    count = 0

    for off, size in chunk_bounds(new):
        block = new[off:off + size]
        key = hashlib.blake2b(block, digest_size=12).digest()
        match = None
        for cand_off, cand_size in index.get(key, ()):
            # A hash match is a candidate, not a fact: compare the bytes.
            if cand_size == size and old[cand_off:cand_off + size] == block:
                match = cand_off
                break
        if match is None:
            ops += struct.pack("<BQQ", 1, 0, size)
            literals += block
            literal += size
        else:
            ops += struct.pack("<BQQ", 0, match, size)
            copied += size
        count += 1
    return bytes(ops), bytes(literals), copied, literal, count


def sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--from", dest="old", required=True)
    ap.add_argument("--to", dest="new", required=True)
    ap.add_argument("--from-version", required=True)
    ap.add_argument("--to-version", required=True)
    ap.add_argument("--out", default=None)
    args = ap.parse_args()

    for path in (args.old, args.new):
        if not os.path.isfile(path):
            print(f"missing: {path}", file=sys.stderr)
            return 2

    old = open(args.old, "rb").read()
    new = open(args.new, "rb").read()

    ops, literals, copied, literal, count = build_ops(old, new)
    zops = zlib.compress(ops, 9)
    zlits = zlib.compress(literals, 9)

    out_dir = args.out or os.path.dirname(os.path.abspath(args.new))
    os.makedirs(out_dir, exist_ok=True)
    name = f"{args.from_version}__{args.to_version}.patch"
    target = os.path.join(out_dir, name)

    with open(target, "wb") as f:
        f.write(MAGIC)
        f.write(struct.pack("<QQ", len(old), len(new)))
        f.write(struct.pack("<II", count, 0))
        f.write(struct.pack("<QQ", len(zops), len(zlits)))
        f.write(zops)
        f.write(zlits)

    size = os.path.getsize(target)
    print(f"patch  : {target}")
    print(f"old    : {len(old) / 1048576:.1f} MB  ({os.path.basename(args.old)})")
    print(f"new    : {len(new) / 1048576:.1f} MB  ({os.path.basename(args.new)})")
    print(f"copied : {copied / 1048576:.1f} MB   literal: {literal / 1048576:.1f} MB   ops: {count}")
    print(f"delta  : {size / 1048576:.2f} MB  ({100.0 * size / max(len(new), 1):.1f}% of the new APK)")
    print(f"sha256 : {sha256(target)}")
    print(f"apk sha: {sha256(args.new)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
