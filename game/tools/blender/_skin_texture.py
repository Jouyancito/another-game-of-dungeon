"""_skin_texture -- a TILEABLE scale sheet for chelonian skin.

Why this exists. The neck and limbs carried a procedural noise that
`_bake_vcol` resolved into vertex colour, and vertex colour resolution IS mesh
resolution: a leg here is a twelve-segment cone, so anything finer than "one
tone per facet" was never going to survive. Rendered, the skin came out as a
flat pale capsule -- which is exactly what Joan called "de menor calidad", and
he was right about the read even though the geometry was fine.

The references are explicit that this is THE defining surface of the animal
(`_references/turtle_terrestrial/_synthesis.md`): "escamas grandes y salientes,
no piel lisa", "la piel del cuello rugosa y plegada". Large, legible plates --
not a noise grain.

Two decisions worth stating:

* It is TILEABLE, so the mesh needs no unique unwrap and no atlas packing. A
  limb is a cylinder; a cylindrical projection plus a repeating sheet gets the
  whole job done, and nothing has to be re-packed when a part changes size.
* The cells are a jittered Worley grid, not a noise texture. A scale has a
  BORDER, and it is the border that reads at distance -- the same reason the
  carapace needed real seams rather than a mottle.
"""
from __future__ import annotations

import math

import numpy as np


# Linear albedo. Deliberately close in value to the carapace: measured on
# 2026-08-25 the skin rendered 2.5x brighter than the shell, which is why it
# looked like it belonged to a different animal.
SKIN_RGB = (0.086, 0.092, 0.050)
GAP_RGB = (0.030, 0.032, 0.019)


def _hash2(i, j, salt=0.0):
    """Deterministic 0-1 pair for a cell. No RNG -- the build must repeat."""
    a = math.sin(i * 127.1 + j * 311.7 + salt) * 43758.5453
    b = math.sin(i * 269.5 + j * 183.3 + salt) * 24634.6345
    return a - math.floor(a), b - math.floor(b)


def bake(size=512, cells=9, jitter=0.36):
    """Return a tileable (size, size, 4) float32 RGBA scale sheet, linear."""
    img = np.zeros((size, size, 4), dtype=np.float32)
    img[..., 3] = 1.0

    # Cell centres, one per grid square, jittered. Wrapping the indices is what
    # keeps the sheet tileable -- a seam here would run down every limb.
    centres = {}
    for j in range(cells):
        for i in range(cells):
            hx, hy = _hash2(i, j)
            centres[(i, j)] = ((i + 0.5 + (hx - 0.5) * 2 * jitter) / cells,
                               (j + 0.5 + (hy - 0.5) * 2 * jitter) / cells)

    for py in range(size):
        v = py / size
        for px in range(size):
            u = px / size
            ci, cj = int(u * cells), int(v * cells)

            best, second, bi = 9.9, 9.9, (0, 0)
            for dj in (-1, 0, 1):
                for di in (-1, 0, 1):
                    key = ((ci + di) % cells, (cj + dj) % cells)
                    cx, cy = centres[key]
                    # Nearest image of the centre across the wrap, so the
                    # pattern is continuous over the seam.
                    dx = u - (cx + (ci + di - key[0]) / cells)
                    dy = v - (cy + (cj + dj - key[1]) / cells)
                    d = math.hypot(dx, dy)
                    if d < best:
                        second, best, bi = best, d, key
                    elif d < second:
                        second = d

            # Distance to the CELL BORDER, not to its centre: that is the line
            # the eye reads, and it is what a scale actually has.
            border = second - best
            gap = math.exp(-border / (0.35 / cells))

            hx, _hy = _hash2(bi[0], bi[1], 7.0)
            tone = 0.80 + 0.40 * hx
            # Each scale is domed: brighter in the middle, falling to its rim.
            tone *= 0.82 + 0.30 * min(1.0, border * cells * 2.2)

            for c in range(3):
                img[py, px, c] = (SKIN_RGB[c] * tone * (1.0 - gap)
                                  + GAP_RGB[c] * gap)

    np.clip(img, 0.0, 1.0, out=img)
    return img


def to_blender_image(arr, name="turtle_skin"):
    """Same sRGB contract as the carapace bake -- see _carapace_texture."""
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

    # Verified write: `foreach_set` on a fresh image can land nothing and raise
    # nothing (measured 2026-08-24 on the carapace bake).
    im.pixels.foreach_set(src)
    im.update()
    back = np.empty(len(im.pixels), dtype=np.float32)
    im.pixels.foreach_get(back)
    if abs(float(back.mean()) - float(src.mean())) > 1e-4:
        im.pixels[:] = src.tolist()
        im.update()
        im.pixels.foreach_get(back)
        if abs(float(back.mean()) - float(src.mean())) > 1e-4:
            raise SystemExit("_skin_texture: the image buffer will not take "
                             "the bake (wrote %.4f, read %.4f)"
                             % (src.mean(), back.mean()))
    im.pack()
    return im
