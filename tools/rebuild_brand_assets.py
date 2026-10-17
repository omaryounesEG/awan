"""Rebuild every logo-derived asset from the high_quality sources.

Run from the project root:  python tools/rebuild_brand_assets.py
"""
import os
import shutil

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = os.path.join(ROOT, "img")
HQ = os.path.join(IMG, "high_quality")
ASSETS = os.path.join(ROOT, "assets", "images")
BACKUP = os.path.join(IMG, "_old_lowres")

BRAND_BG = (245, 242, 235, 255)  # #F5F2EB, the app's sand


def backup_old():
    os.makedirs(BACKUP, exist_ok=True)
    for name in ("awan_logo.png", "awan_logo_transparent.png"):
        src = os.path.join(IMG, name)
        if os.path.exists(src):
            shutil.copy2(src, os.path.join(BACKUP, name))


def adopt_high_quality():
    for name in ("awan_logo.png", "awan_logo_transparent.png"):
        shutil.copy2(os.path.join(HQ, name), os.path.join(IMG, name))


def content_box(image, threshold=10):
    alpha = image.getchannel("A")
    mask = alpha.point(lambda v: 255 if v > threshold else 0)
    return mask.getbbox()


def widest_gap(alpha_rows, top, bottom):
    """The transparent band that separates the mark from the wordmark."""
    gaps, start = [], None
    for y in range(top, bottom):
        if not alpha_rows[y]:
            start = y if start is None else start
        elif start is not None:
            gaps.append((start, y, y - start))
            start = None
    if start is not None:
        gaps.append((start, bottom, bottom - start))
    return max(gaps, key=lambda g: g[2]) if gaps else None


def main():
    backup_old()
    adopt_high_quality()

    lockup_src = Image.open(os.path.join(IMG, "awan_logo_transparent.png")).convert("RGBA")
    box = content_box(lockup_src)
    lockup = lockup_src.crop(box)
    lockup.save(os.path.join(IMG, "logo_lockup.png"))

    alpha = lockup_src.getchannel("A")
    rows = [alpha.getpixel((x, y)) > 10 for y in range(box[1], box[3]) for x in range(0, lockup_src.width, 3)]
    import numpy as np

    a = np.asarray(alpha)
    row_has_ink = (a > 10).any(axis=1)
    gap = widest_gap(row_has_ink, box[1], box[3])
    mark_bottom = gap[0] if gap else box[3]
    mark_region = lockup_src.crop((box[0], box[1], box[2], mark_bottom))
    mark = mark_region.crop(content_box(mark_region))
    mark.save(os.path.join(IMG, "logo_mark.png"))

    # Adaptive icon: the mark alone, centred in the guaranteed-visible safe zone.
    size = 1024
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    scale = (size * 0.62) / mark.width
    resized = mark.resize((int(mark.width * scale), int(mark.height * scale)), Image.LANCZOS)
    canvas.paste(resized, ((size - resized.width) // 2, (size - resized.height) // 2), resized)
    canvas.save(os.path.join(IMG, "adaptive_foreground.png"))

    # Legacy icon: the full lockup, on the brand background, square.
    full = Image.open(os.path.join(IMG, "awan_logo.png")).convert("RGBA")
    legacy = Image.new("RGBA", (size, size), BRAND_BG)
    inner = full.resize((size, size), Image.LANCZOS)
    legacy.paste(inner, (0, 0), inner)
    legacy.convert("RGB").save(os.path.join(IMG, "icon_legacy.png"))

    # Anything the app renders at runtime lives under assets/images/.
    os.makedirs(ASSETS, exist_ok=True)
    for name in ("awan_logo.png", "awan_logo_transparent.png", "logo_lockup.png", "logo_mark.png"):
        shutil.copy2(os.path.join(IMG, name), os.path.join(ASSETS, name))

    print("mark     ", mark.size)
    print("lockup   ", lockup.size)
    print("gap rows ", gap)
    print("written  img/{logo_mark,logo_lockup,adaptive_foreground,icon_legacy}.png + assets/images/*")


if __name__ == "__main__":
    main()
