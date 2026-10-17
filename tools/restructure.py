"""One-off restructure: relative imports -> package imports, then relocate the
feature code into the strict Feature-First Clean Architecture tree.

Run from the project root: python tools/restructure.py
"""
import os
import pathlib
import re
import shutil

LIB = pathlib.Path("lib")

MOVES = {
    "core/database/isar_service.dart": "core/services/isar_service.dart",
    "core/location/app_location.dart": "core/services/location/app_location.dart",
    "core/location/cities.dart": "core/services/location/cities.dart",
    "core/location/location_service.dart": "core/services/location/location_service.dart",
    "core/notifications/notification_service.dart": "core/services/notifications/notification_service.dart",
    "core/notifications/ringer_service.dart": "core/services/notifications/silent_mode_service.dart",
    "features/prayer/domain/prayer_models.dart": "features/prayer_engine/domain/entities/prayer_entities.dart",
    "features/prayer/domain/prayer_repository.dart": "features/prayer_engine/domain/repositories/prayer_repository.dart",
    "features/prayer/domain/prayer_calculator.dart": "features/prayer_engine/domain/usecases/calculate_prayer_times.dart",
    "features/prayer/data/prayer_local_data_source.dart": "features/prayer_engine/data/datasources/prayer_local_datasource.dart",
    "features/prayer/data/prayer_remote_data_source.dart": "features/prayer_engine/data/datasources/aladhan_remote_datasource.dart",
    "features/prayer/data/prayer_repository_impl.dart": "features/prayer_engine/data/repositories/prayer_repository_impl.dart",
    "features/prayer/data/prayer_sync_task.dart": "features/prayer_engine/data/datasources/prayer_sync_worker.dart",
    "features/prayer/presentation/prayer_providers.dart": "features/prayer_engine/presentation/providers/prayer_providers.dart",
    "features/prayer/presentation/widgets/next_prayer_card.dart": "features/prayer_engine/presentation/widgets/next_prayer_card.dart",
    "features/prayer/presentation/widgets/prayer_tile.dart": "features/prayer_engine/presentation/widgets/prayer_tile.dart",
    "features/home/presentation/home_screen.dart": "features/home/presentation/screens/home_screen.dart",
    "features/quran/data/quran_local_data_source.dart": "features/quran_tafseer/data/datasources/quran_asset_datasource.dart",
    "features/quran/data/quran_repository_impl.dart": "features/quran_tafseer/data/repositories/quran_repository_impl.dart",
    "features/quran/domain/quran_models.dart": "features/quran_tafseer/domain/entities/quran_entities.dart",
    "features/quran/presentation/quran_providers.dart": "features/quran_tafseer/presentation/providers/quran_providers.dart",
    "features/prayer/domain/prayer_calculator2.dart": "features/prayer_engine/domain/usecases/calculate_prayer_times.dart",
}

DELETE = [
    "features/prayer/domain/usecases.dart",
    "core/database/models.dart",
    "core/database/models.g.dart",
]

REL_IMPORT = re.compile(r"""import\s+'(\.[^']+)'""")
PKG = ""


def phase1() -> int:
    changed = 0
    for path in list(LIB.rglob("*.dart")):
        text = path.read_text(encoding="utf-8")

        def repl(match: re.Match) -> str:
            target = (path.parent / match.group(1)).resolve()
            rel = target.relative_to(LIB.resolve()).as_posix()
            return "import '{}wan/{}'".format(PKG, rel)

        new = REL_IMPORT.sub(repl, text)
        if new != text:
            path.write_text(new, encoding="utf-8")
            changed += 1
    return changed


def phase2() -> int:
    moved = 0
    for old, new in MOVES.items():
        src, dst = LIB / old, LIB / new
        if not src.exists():
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(src), str(dst))
        moved += 1
    return moved


def phase3() -> int:
    repl = {"package:awan/" + old: "package:awan/" + new for old, new in MOVES.items()}
    changed = 0
    for path in list(LIB.rglob("*.dart")):
        text = path.read_text(encoding="utf-8")
        original = text
        for old, new in repl.items():
            text = text.replace(old, new)
        if text != original:
            path.write_text(text, encoding="utf-8")
            changed += 1
    return changed


def phase4() -> None:
    for rel in DELETE:
        path = LIB / rel
        if path.exists():
            path.unlink()
            print("deleted", rel)
    for root, _dirs, _files in os.walk(LIB, topdown=False):
        if root != str(LIB) and not os.listdir(root):
            os.rmdir(root)
            print("rmdir", root)


if __name__ == "__main__":
    print("phase1 (imports -> package):", phase1())
    print("phase2 (moves):", phase2())
    print("phase3 (path rewrites):", phase3())
    phase4()
