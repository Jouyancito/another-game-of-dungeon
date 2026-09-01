"""gen_hair_atlas -- the strand atlas that hair cards sample.

Runs under the SYSTEM python, not Blender's: Blender ships numpy but not PIL,
and this only needs to write a PNG.

Why an atlas at all. The fidelity ceiling for this project is Skyrim
(_asset_creation_contract.md 3b), and on that row hair is "cards con alpha,
mechones translucidos". Opaque shells are the RDR1 row -- the standard Joan
explicitly raised. A card is a flat quad; what makes it read as a lock of hair
is the alpha cutout it carries, which is why the strand shapes live here in 2D
rather than in geometry.

Each cell is one lock: many fine strands of slightly different width, length,
tone and curvature, dense at the middle and thinning to a ragged tip. The
silhouette of the lock comes from where the strands END, so the tips are
staggered rather than cut level -- a card whose alpha ends on a straight line
reads as a ribbon.

Output is a straight RGBA PNG. Colour is near-white so the material tint can
drive the actual hair colour; only the VALUE variation between strands is
baked, because that variation is what survives a flat toon ramp.
"""
from __future__ import annotations

import argparse
import math
import os
import random

import numpy as np
from PIL import Image


def draw_strand(alpha, value, x0, x1, y_top, y_bot, width, curve, tone, rng):
    """Rasterise one strand as a vertical-ish tapered stroke with soft edges."""
    h, w = alpha.shape
    n = max(int(abs(y_bot - y_top)) + 1, 2)
    for k in range(n):
        t = k / (n - 1)
        y = int(round(y_top + (y_bot - y_top) * t))
        if not (0 <= y < h):
            continue
        # Lateral drift: a lock is not a column, it sweeps.
        x = x0 + (x1 - x0) * t + curve * math.sin(t * math.pi) * w * 0.06
        # Full width through the body of the strand, closing to a point.
        taper = math.sin(math.pi * min(1.0, 0.06 + t * 0.97)) ** 0.55
        half = max(width * taper, 0.6)
        lo, hi = int(math.floor(x - half)), int(math.ceil(x + half))
        for px in range(lo, hi + 1):
            if not (0 <= px < w):
                continue
            d = abs(px - x) / half
            if d > 1.0:
                continue
            a = min(1.0, (1.0 - d) * 2.2)
            if a <= alpha[y, px]:
                continue
            alpha[y, px] = a
            value[y, px] = tone


def make_cell(size, rng, strands, curl):
    """One lock of hair: strands packed into a band, tips staggered."""
    a = np.zeros((size, size), dtype=np.float32)
    v = np.zeros((size, size), dtype=np.float32)
    margin = size * 0.07
    for _ in range(strands):
        # Roots crowd the middle so the lock has a body and frayed sides.
        u = rng.gauss(0.5, 0.24)
        u = min(max(u, 0.03), 0.97)
        x0 = margin + u * (size - 2 * margin)
        x1 = x0 + rng.gauss(0.0, size * 0.055) + curl * size * 0.10
        # Staggered tips: this is the lock's silhouette.
        y_bot = size * rng.uniform(0.55, 1.0)
        # Edge strands are shorter, so the lock narrows toward the point.
        y_bot *= 1.0 - 0.42 * abs(u - 0.5) * 2.0 * rng.uniform(0.55, 1.0)
        width = size * rng.uniform(0.0022, 0.0075)
        tone = rng.uniform(0.45, 1.0)
        draw_strand(a, v, x0, x1, 0.0, y_bot, width,
                    rng.uniform(-1.0, 1.0) * curl, tone, rng)
    return a, v


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--size", type=int, default=256, help="cell size in px")
    ap.add_argument("--cols", type=int, default=4)
    ap.add_argument("--rows", type=int, default=2)
    ap.add_argument("--seed", type=int, default=11)
    args = ap.parse_args()

    rng = random.Random(args.seed)
    S = args.size
    W, H = S * args.cols, S * args.rows
    rgba = np.zeros((H, W, 4), dtype=np.float32)

    # Cells vary from a dense wide lock to a thin wispy one, so a hairstyle can
    # use heavy cards for the mass and light ones for the loose strands.
    plans = []
    for r in range(args.rows):
        for c in range(args.cols):
            k = r * args.cols + c
            heavy = 1.0 - (k / max(args.cols * args.rows - 1, 1))
            plans.append((r, c, int(26 + 150 * heavy), 0.25 + 0.7 * (1.0 - heavy)))

    for r, c, strands, curl in plans:
        a, v = make_cell(S, rng, strands, curl)
        y0, x0 = r * S, c * S
        rgba[y0:y0 + S, x0:x0 + S, 0] = 0.86 * (0.55 + 0.45 * v)
        rgba[y0:y0 + S, x0:x0 + S, 1] = 0.86 * (0.55 + 0.45 * v)
        rgba[y0:y0 + S, x0:x0 + S, 2] = 0.86 * (0.55 + 0.45 * v)
        rgba[y0:y0 + S, x0:x0 + S, 3] = a
        cov = float((a > 0.5).mean())
        print("  celda r%dc%d  hebras=%3d  curl=%.2f  cobertura alpha=%.1f%%"
              % (r, c, strands, curl, cov * 100.0))

    img = Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA")
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    img.save(args.out)
    print("  atlas %dx%d (%d celdas) -> %s" % (W, H, len(plans), args.out))


if __name__ == "__main__":
    main()
