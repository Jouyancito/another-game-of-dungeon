"""TEMPORARY DEV TOOL — quantify foliage shimmer from a shimmer_probe.gd sweep.

A static screenshot cannot show shimmer, so scenes/dev/shimmer_probe.gd renders a
camera yaw sweep (fixed small increments, camera position frozen) and this script
scores the temporal behaviour of the sequence.

Two numbers per region:

  MAD      mean absolute luminance difference between consecutive frames, 0-255.
           Smooth, correctly-filtered surfaces sliding across the screen produce a
           small MAD concentrated on real silhouette edges.

  SPECKLE  percentage of region pixels whose frame-to-frame luminance jump exceeds
           SPECKLE_T (default 24/255). Alpha-tested foliage without antialiasing
           flips a pixel between "leaf" and "sky/branch behind" in a single frame,
           which is a large jump; a mip-filtered, coverage-blended edge moves
           through intermediate values instead. SPECKLE is therefore the metric
           that actually separates shimmer from motion.

Regions come from mask.png, which shimmer_probe.gd renders with unshaded
white on leaf-card surfaces and unshaded black on everything else:

  FOLIAGE  mask luminance > 128 — the leaf cards.
  WORLD    the rest of the frame (terrain, grass, bark, rock, sky). This is the
           control: a "fix" that lowers FOLIAGE by blurring the whole game would
           drag WORLD down with it, and that shows up here.

Usage:
    python analyze.py <dir_a> [<dir_b> ...]
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

SPECKLE_T = 24.0  # luminance units out of 255
# Rec. 709 luma — matches how the eye weights the flicker being complained about.
LUMA = np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)


def load_luma(path: Path) -> np.ndarray:
    arr = np.asarray(Image.open(path).convert("RGB"), dtype=np.float32)
    return arr @ LUMA


def score(run_dir: Path) -> dict:
    frames = sorted(run_dir.glob("f[0-9][0-9][0-9].png"))
    if len(frames) < 2:
        raise SystemExit(f"{run_dir}: need >=2 frames, found {len(frames)}")

    mask_path = run_dir / "mask.png"
    if mask_path.exists():
        m = load_luma(mask_path)
        foliage = m > 128.0
        # The mask must be a flat white/black stencil. If it is not, it is being
        # tinted by the leaf texture and the region split is meaningless — fail
        # loudly rather than quietly reporting a number for the wrong pixels.
        mid = np.count_nonzero((m > 16.0) & (m < 200.0))
        if foliage.sum() == 0:
            raise SystemExit(f"{run_dir}: mask.png has no foliage pixels")
        if mid > 0.25 * foliage.sum():
            raise SystemExit(
                f"{run_dir}: mask.png is not a clean stencil "
                f"({mid} mid-tone px vs {int(foliage.sum())} white px)")
    else:
        foliage = np.zeros(load_luma(frames[0]).shape, dtype=bool)
    world = ~foliage

    acc = {
        "foliage_abs": 0.0, "foliage_spk": 0.0,
        "world_abs": 0.0, "world_spk": 0.0,
        "all_abs": 0.0, "all_spk": 0.0,
    }
    n_f = int(foliage.sum())
    n_w = int(world.sum())
    n_a = foliage.size
    pairs = 0

    prev = load_luma(frames[0])
    for f in frames[1:]:
        cur = load_luma(f)
        d = np.abs(cur - prev)
        spk = d > SPECKLE_T
        acc["foliage_abs"] += float(d[foliage].sum()) if n_f else 0.0
        acc["foliage_spk"] += float(spk[foliage].sum()) if n_f else 0.0
        acc["world_abs"] += float(d[world].sum()) if n_w else 0.0
        acc["world_spk"] += float(spk[world].sum()) if n_w else 0.0
        acc["all_abs"] += float(d.sum())
        acc["all_spk"] += float(spk.sum())
        prev = cur
        pairs += 1

    def per(key_abs, key_spk, n):
        if n == 0 or pairs == 0:
            return (float("nan"), float("nan"))
        return (acc[key_abs] / (n * pairs), 100.0 * acc[key_spk] / (n * pairs))

    f_mad, f_spk = per("foliage_abs", "foliage_spk", n_f)
    w_mad, w_spk = per("world_abs", "world_spk", n_w)
    a_mad, a_spk = per("all_abs", "all_spk", n_a)

    meta = {}
    mp = run_dir / "meta.json"
    if mp.exists():
        meta = json.loads(mp.read_text())

    return {
        "tag": run_dir.name,
        "pairs": pairs,
        "foliage_px": n_f,
        "foliage_pct": 100.0 * n_f / n_a,
        "FOLIAGE_MAD": f_mad, "FOLIAGE_SPECKLE": f_spk,
        "WORLD_MAD": w_mad, "WORLD_SPECKLE": w_spk,
        "ALL_MAD": a_mad, "ALL_SPECKLE": a_spk,
        "meta": meta,
    }


def main() -> None:
    dirs = [Path(a) for a in sys.argv[1:]]
    if not dirs:
        raise SystemExit(__doc__)
    rows = [score(d) for d in dirs]

    hdr = (f"{'tag':<16}{'foliage%':>9}{'FOL_MAD':>9}{'FOL_SPK%':>10}"
           f"{'WORLD_MAD':>11}{'WLD_SPK%':>10}{'ALL_MAD':>9}{'ALL_SPK%':>10}")
    print(hdr)
    print("-" * len(hdr))
    for r in rows:
        print(f"{r['tag']:<16}{r['foliage_pct']:>9.2f}{r['FOLIAGE_MAD']:>9.3f}"
              f"{r['FOLIAGE_SPECKLE']:>10.3f}{r['WORLD_MAD']:>11.3f}"
              f"{r['WORLD_SPECKLE']:>10.3f}{r['ALL_MAD']:>9.3f}{r['ALL_SPECKLE']:>10.3f}")

    if len(rows) >= 2:
        a, b = rows[0], rows[-1]
        print()
        print(f"delta {a['tag']} -> {b['tag']}")
        for k in ("FOLIAGE_MAD", "FOLIAGE_SPECKLE", "WORLD_MAD", "WORLD_SPECKLE",
                  "ALL_MAD", "ALL_SPECKLE"):
            va, vb = a[k], b[k]
            pct = (vb - va) / va * 100.0 if va else float("nan")
            print(f"  {k:<16} {va:>9.3f} -> {vb:>9.3f}   {pct:+7.1f}%")


if __name__ == "__main__":
    main()
