"""Repair the import paths damaged by the bulk restructure (tools/restructure.py).

The restructure rewrote relative imports to package imports *before* moving the
files, so several of them point at paths that no longer exist
(`package:awan/features/core/...`, `package:awan/features/prayer/prayer/...`).

Strategy, cheapest rule first, per import line:

1. collapse a duplicated path segment (`features/x/x/` -> `features/x/`);
2. move a stray `features/core/` back under `core/`;
3. apply the known file-rename table (models/providers/entities);
4. fall back to "find the file by basename anywhere under lib/ and use its real
   package path" (only when the basename is unique);
5. anything still unresolved is printed — never guessed.

Run from the project root: python tools/heal_imports.py
"""
from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path('.')
LIB = ROOT / 'lib'

# 3 -- the moves performed by the restructure, keyed by old package path suffix.
RENAMES: dict[str, str] = {
    'core/theme/app_colors.dart': 'core/constants/app_colors.dart',
    'core/theme/app_typography.dart': 'core/constants/app_typography.dart',
    'core/location/app_location.dart': 'core/services/location/app_location.dart',
    'core/location/cities.dart': 'core/services/location/cities.dart',
    'core/location/location_service.dart': 'core/services/location/location_service.dart',
    'core/notifications/notification_service.dart':
        'core/services/notifications/notification_service.dart',
    'core/notifications/ringer_service.dart':
        'core/services/notifications/silent_mode_service.dart',
    'core/background/background_tasks.dart':
        'core/services/background_sync_service.dart',
    'features/prayer/domain/prayer_models.dart':
        'features/prayer_engine/domain/entities/prayer_entities.dart',
    'features/prayer/domain/prayer_calculator.dart':
        'features/prayer_engine/domain/usecases/calculate_prayer_times.dart',
    'features/prayer/domain/prayer_repository.dart':
        'features/prayer_engine/domain/repositories/prayer_repository.dart',
    'features/prayer/data/prayer_local_data_source.dart':
        'features/prayer_engine/data/datasources/prayer_local_datasource.dart',
    'features/prayer/data/prayer_remote_data_source.dart':
        'features/prayer_engine/data/datasources/aladhan_remote_datasource.dart',
    'features/prayer/data/prayer_repository_impl.dart':
        'features/prayer_engine/data/repositories/prayer_repository_impl.dart',
    'features/prayer/data/prayer_sync_task.dart':
        'features/prayer_engine/data/datasources/prayer_sync_worker.dart',
    'features/prayer/presentation/prayer_providers.dart':
        'features/prayer_engine/presentation/providers/prayer_providers.dart',
    'features/prayer/presentation/widgets/next_prayer_card.dart':
        'features/prayer_engine/presentation/widgets/next_prayer_card.dart',
    'features/prayer/presentation/widgets/prayer_tile.dart':
        'features/prayer_engine/presentation/widgets/prayer_tile.dart',
    'features/quran/domain/quran_models.dart':
        'features/quran_tafseer/domain/entities/quran_entities.dart',
    'features/quran/data/quran_local_data_source.dart':
        'features/quran_tafseer/data/datasources/quran_asset_datasource.dart',
    'features/quran/data/quran_repository_impl.dart':
        'features/quran_tafseer/data/repositories/quran_repository_impl.dart',
    'features/quran/presentation/quran_providers.dart':
        'features/quran_tafseer/presentation/providers/quran_providers.dart',
    'features/home/presentation/home_screen.dart':
        'features/home/presentation/screens/home_screen.dart',
}

DUP = re.compile(r'features/(\w+)/\1/')
IMPORT = re.compile(r"""^(?P<head>\s*(?:import|export)\s+['"])(?P<path>[^'"]+)(?P<tail>['"].*)$""")

# Basenames that appear more than once under lib/ -> never auto-resolved.
_by_name: dict[str, list[str]] = {}
for f in LIB.rglob('*.dart'):
    if f.name.endswith('.g.dart'):
        continue
    _by_name.setdefault(f.name, []).append(
        f.relative_to(LIB).as_posix()
    )


def _exists(rel: str) -> bool:
    return (LIB / rel).is_file()


def _resolve(path: str) -> tuple[str, str]:
    """Return (new_path, how) — ``how`` is empty when nothing changed."""
    if not path.startswith('package:awan/'):
        return path, ''
    rel = path[len('package:awan/'):]

    # 1 -- duplicated segment
    deduped = DUP.sub(r'features/\1/', rel)
    if deduped != rel and (_exists(deduped) or True):
        rel = deduped

    # 2 -- features/core -> core
    if rel.startswith('features/core/'):
        rel = rel[len('features/'):]

    if _exists(rel):
        return f'package:awan/{rel}', 'rewritten'

    # 3 -- known renames (applied to the tail after core/ or features/)
    for old, new in RENAMES.items():
        if rel.endswith(old):
            if _exists(new):
                return f'package:awan/{new}', 'renamed'
            print(f'  ! rename target missing: {new} (from {rel})')

    # 4 -- unique basename
    name = rel.rsplit('/', 1)[-1]
    hits = _by_name.get(name, [])
    if len(hits) == 1:
        return f'package:awan/{hits[0]}', 'relocated'

    # ambiguous or unknown: if a same-named file sits in one of the feature's
    # own directories, and the old path's last two segments match it, use it.
    tail = '/'.join(rel.rsplit('/', 2)[-2:])
    matches = [h for h in hits if h.endswith(tail)]
    if len(matches) == 1:
        return f'package:awan/{matches[0]}', 'relocated'

    return path, ''


def main() -> None:
    changed_files = 0
    unresolved: list[tuple[str, str]] = []

    for file in sorted(LIB.rglob('*.dart')):
        text = file.read_text(encoding='utf-8')
        lines = text.splitlines(keepends=True)
        touched = False

        out: list[str] = []
        for line in lines:
            m = IMPORT.match(line)
            if not m:
                out.append(line)
                continue
            new_path, _how = _resolve(m.group('path'))
            if new_path != m.group('path'):
                if not _exists(new_path[len('package:awan/'):]):
                    unresolved.append((str(file), m.group('path')))
                    out.append(line)
                    continue
                out.append(f"{m.group('head')}{new_path}{m.group('tail')}")
                touched = True
            else:
                if m.group('path').startswith('package:awan/') and not _exists(
                    m.group('path')[len('package:awan/'):]
                ):
                    unresolved.append((str(file), m.group('path')))
                out.append(line)

        if touched:
            file.write_text(''.join(out), encoding='utf-8')
            changed_files += 1

    print(f'files rewritten: {changed_files}')
    if unresolved:
        print(f'unresolved imports: {len(unresolved)}')
        for path, imp in unresolved:
            print(f'  {path}: {imp}')
    else:
        print('all package imports resolve')


if __name__ == '__main__':
    main()
