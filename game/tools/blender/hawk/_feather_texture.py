"""_feather_texture -- a baked barb-pattern atlas, one tinted row per plumage tone.

Why an ATLAS instead of one sheet multiplied by vertex colour: this session
already measured what the glTF exporter does to a Base Color graph it does not
recognise -- it drops EVERYTHING and ships white (turtle skin, 2026-08-25).
A plain image texture is the one pattern proven to survive. So the tint is
baked INTO the texture, eight tinted copies of the same barb pattern stacked
as rows, and each feather's UVs simply select its row. No node graph, no risk.

The pattern is what makes a feather read as a feather instead of a petal:
  * a dark RACHIS line down the centre,
  * BARBS: fine diagonal striations angling outward-backward from the rachis,
  * a slightly pale outer EDGE, and a darker TIP band.
"""
from __future__ import annotations

import math

import numpy as np


def bake_atlas(tones, size=256, rows=None, tip_band=0.18):
    """tones: list of (name, (r, g, b)) linear albedos. Returns (arr, row_map).

    arr is (H, W, 4) float32 linear; row_map maps name -> (v0, v1) band.
    """
    rows = rows or len(tones)
    H, W = size * 2, size
    img = np.zeros((H, W, 4), dtype=np.float32)
    img[..., 3] = 1.0
    row_h = H // rows
    row_map = {}

    for r, (name, rgb) in enumerate(tones):
        y0, y1 = r * row_h, (r + 1) * row_h
        row_map[name] = (y0 / H, y1 / H)
        for py in range(y0, y1):
            t = (py - y0) / max(1, row_h - 1)          # 0 root, 1 tip
            for px in range(W):
                u = px / (W - 1)                        # 0..1 across the vane
                d = u - 0.5                             # signed dist from rachis

                # Barbs: striations that angle outward and backward. The phase
                # couples u and t so the lines run diagonally, mirrored about
                # the rachis like a real vane.
                barb = 0.5 + 0.5 * math.sin(
                    (abs(d) * 46.0 - t * 30.0) * math.pi)
                val = 0.88 + 0.18 * barb

                # Rachis: a hard dark line, fading toward the tip.
                if abs(d) < 0.030:
                    val *= 0.42 + 0.30 * t
                # Pale outer edge -- keeps neighbouring feathers separable.
                if abs(d) > 0.40:
                    val *= 1.14
                # Dark tip band.
                if t > 1.0 - tip_band:
                    val *= 0.62

                for c in range(3):
                    img[py, px, c] = min(1.0, rgb[c] * val)
    return img, row_map


def to_blender_image(arr, name="hawk_feathers"):
    """sRGB-encoded, write-verified. Same contract as the carapace bake."""
    import bpy

    h, w, _ = arr.shape
    im = bpy.data.images.get(name)
    if im is not None:
        bpy.data.images.remove(im)
    im = bpy.data.images.new(name, width=w, height=h, alpha=True,
                             float_buffer=True)
    lin = np.clip(arr, 0.0, 1.0)
    rgb = np.where(lin[..., :3] <= 0.0031308,
                   lin[..., :3] * 12.92,
                   1.055 * np.power(np.maximum(lin[..., :3], 1e-8), 1 / 2.4)
                   - 0.055)
    out = np.concatenate([rgb, lin[..., 3:4]], axis=2)
    im.colorspace_settings.name = "sRGB"
    src = np.ascontiguousarray(out[::-1], dtype=np.float32).ravel()
    im.pixels.foreach_set(src)
    im.update()
    back = np.empty(len(im.pixels), dtype=np.float32)
    im.pixels.foreach_get(back)
    if abs(float(back.mean()) - float(src.mean())) > 1e-4:
        im.pixels[:] = src.tolist()
        im.update()
        im.pixels.foreach_get(back)
        if abs(float(back.mean()) - float(src.mean())) > 1e-4:
            raise SystemExit("_feather_texture: the image buffer will not "
                             "take the bake")
    im.pack()
    return im
