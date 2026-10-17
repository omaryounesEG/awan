"""`CalculatePrayerTimes.forDate` takes named arguments.

Rewrites `engine.forDate(date, spec)` -> `engine.forDate(date: date, spec: spec)`
inside test files, splitting on the top-level comma only (a naive regex breaks on
`DateTime(2026, 10, 10)`).

Run from the project root: python tools/fix_for_date_calls.py
"""
from __future__ import annotations

import pathlib

MARKER = '.forDate('


def split_top_level(text: str) -> list[str]:
    parts: list[str] = []
    depth = 0
    current: list[str] = []
    for char in text:
        if char in '([{':
            depth += 1
        elif char in ')]}':
            depth -= 1
        if char == ',' and depth == 0:
            parts.append(''.join(current))
            current = []
            continue
        current.append(char)
    parts.append(''.join(current))
    return parts


def fix(source: str) -> tuple[str, int]:
    out: list[str] = []
    index = 0
    count = 0
    while True:
        hit = source.find(MARKER, index)
        if hit == -1:
            out.append(source[index:])
            break
        start = hit + len(MARKER)
        out.append(source[index:start])
        depth = 1
        cursor = start
        while cursor < len(source) and depth:
            if source[cursor] in '([{':
                depth += 1
            elif source[cursor] in ')]}':
                depth -= 1
                if depth == 0:
                    break
            cursor += 1
        inner = source[start:cursor]
        args = [a.strip() for a in split_top_level(inner) if a.strip()]
        if len(args) == 2 and ':' not in args[0] and ':' not in args[1]:
            out.append(f'date: {args[0]}, spec: {args[1]}')
            count += 1
        else:
            out.append(inner)
        index = cursor
    return ''.join(out), count


def main() -> None:
    for file in sorted(pathlib.Path('test').rglob('*.dart')):
        text = file.read_text(encoding='utf-8')
        fixed, count = fix(text)
        if count:
            file.write_text(fixed, encoding='utf-8')
            print(f'{file}: {count}')


if __name__ == '__main__':
    main()
