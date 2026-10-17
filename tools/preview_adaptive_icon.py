"""Render how Android will draw the adaptive icon (circle mask) + report the generated sizes.

Run from the project root:  python tools/preview_adaptive_icon.py
"""
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
OUT = os.path.join(ROOT, "docs", "screens", "41_adaptive_icon_preview.png")


def find(*names):
    for name in names:
        p = os.path.join(ROOT, name)
        if os.path.exists(p):
            return p
    raise SystemExit(f"missing: {names}")


def main():
    fg = Image.open(find("img/adaptive_foreground.png")).convert("RGBA")
    bg = Image.new("RGBA", fg.size, (245, 242, 235, 255))

    # Android draws the foreground at 108dp inside a 72dp-safe inner circle: the
    # launcher scales the 108dp layer, so the visible circle is the middle ~66%.
    composed = Image.alpha_composite(bg, fg)

    mask = Image.new("L", fg.size, 0)
    draw = ImageDraw.Draw(mask)
    inset = int(fg.width * 0.17)
    draw.ellipse((inset, inset, fg.width - inset, fg.height - inset), fill=255)
    circled = Image.new("RGBA", fg.size, (255, 255, 255, 0))
    circled.paste(composed, (0, 0), mask)

    shelf = Image.new("RGBA", (fg.width * 2 + 30, fg.height), (250, 250, 250, 255))
    shelf.paste(composed, (0, 0))
    shelf.paste(circled, (fg.width + 30, 0))
    shelf.save(OUT)

    print("preview ->", os.path.relpath(OUT, ROOT))
    for folder in ("mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi",
                   "mipmap-xxxhdpi", "drawable", "drawable-nodpi", "values"):
        d = os.path.join(RES, folder)
        if os.path.isdir(d):
            files = sorted(os.listdir(d))
            print(f"  {folder:18s} {', '.join(files[:6])}")


if __name__ == "__main__":
    main()
