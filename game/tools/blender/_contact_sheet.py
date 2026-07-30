#!/usr/bin/env python
"""Compose a labelled contact sheet from a set of renders.

One image holding every angle is what makes a multi-angle judgement actually
happen — flipping between separate files invites looking at the flattering one
and calling it done. The motor gate also looks for a file whose name contains
"contact_sheet"/"showcase"/"board"/"ficha" before it will let an asset be
reported as finished.

Pure stdlib + Pillow, no Blender needed: this composes renders that already
exist (from a build script's showcase pass, or from Godot's mob_capture).

Usage:
  python _contact_sheet.py --out <sheet.png> --cols 3 \
      --shot label=path/to/render.png [--shot label=...] ...
"""
import argparse
import os
import sys

try:
    from PIL import Image, ImageDraw
except ImportError:
    sys.exit("_contact_sheet: Pillow required (pip install pillow)")

CELL = 420
PAD = 10
LABEL_H = 26
BG = (26, 24, 34)
FG = (232, 230, 238)


def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--cols", type=int, default=3)
    ap.add_argument("--title", default="")
    ap.add_argument("--shot", action="append", default=[],
                    help="label=path, repeatable; order is preserved")
    return ap.parse_args()


def main():
    args = parse_args()
    shots = []
    for spec in args.shot:
        if "=" not in spec:
            print(f"[sheet] skipping malformed --shot {spec!r}")
            continue
        label, path = spec.split("=", 1)
        if not os.path.exists(path):
            print(f"[sheet] MISSING {path} — cell will be blank")
            shots.append((label, None))
            continue
        shots.append((label, path))
    if not shots:
        sys.exit("_contact_sheet: no shots given")

    cols = max(1, args.cols)
    rows = (len(shots) + cols - 1) // cols
    title_h = 34 if args.title else 0
    W = cols * CELL + (cols + 1) * PAD
    H = rows * (CELL + LABEL_H) + (rows + 1) * PAD + title_h

    sheet = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(sheet)
    if args.title:
        draw.text((PAD, PAD), args.title, fill=FG)

    for i, (label, path) in enumerate(shots):
        r, c = divmod(i, cols)
        x = PAD + c * (CELL + PAD)
        y = title_h + PAD + r * (CELL + LABEL_H + PAD)
        if path is not None:
            img = Image.open(path).convert("RGB")
            # Fit inside the cell without distorting: a stretched render would
            # misrepresent the very proportions the sheet exists to judge.
            img.thumbnail((CELL, CELL), Image.LANCZOS)
            ox = x + (CELL - img.width) // 2
            oy = y + (CELL - img.height) // 2
            sheet.paste(img, (ox, oy))
        else:
            draw.rectangle([x, y, x + CELL, y + CELL], outline=(90, 80, 70))
            draw.text((x + 12, y + CELL // 2), "(missing)", fill=(150, 140, 130))
        draw.text((x + 4, y + CELL + 6), label, fill=FG)

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    sheet.save(args.out)
    print(f"[sheet] {args.out} — {len(shots)} shots, {cols}x{rows}, {W}x{H}px")


if __name__ == "__main__":
    main()
