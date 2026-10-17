"""Flutter 3.24 does not have `Color.withValues` (added in 3.27).

`withValues(alpha: x)` -> `withOpacity(x)` keeps the parenthesis count identical
for the argument forms used in this codebase, so the swap is mechanical.

Run from the project root: python tools/fix_color_api.py
"""
from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path('lib')
PATTERN = re.compile(r'withValues\(\s*alpha:\s*([^()]*(?:\([^()]*\))?[^()]*)\)')

total = 0
for file in sorted(ROOT.rglob('*.dart')):
    text = file.read_text(encoding='utf-8')
    fixed, count = PATTERN.subn(r'withOpacity(\1)', text)
    if count:
        file.write_text(fixed, encoding='utf-8')
        total += count
        print(f'{file}: {count}')

print(f'total replaced: {total}')
