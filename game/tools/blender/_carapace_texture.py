"""_carapace_texture -- bake the carapace's albedo from the SAME functions
that shaped it.

Why a texture at all, on a project whose style contract used to say "detail in
notches, not albedo complexity": because `_art_canon.md` 17.3 replaced that for
the world -- "mundo (terreno, arquitectura, props, criaturas): sombreado suave
PBR... la textura y la atmosfera mandan" -- and because of a measurement.

The measurement: growth rings need more resolution than the mesh has. Face
colour resolution IS mesh resolution, so at 40x40 grid divisions a plate is
about 8 cells across and five rings land two cells apart. Rendered, that is not
rings, it is a checkerboard -- which is exactly what the shell looked like
after the geometry was already correct. Raising the grid until colour reads
would cost triangles for something a 1024px image carries for free.

The trick that makes this cheap and exact: the mesh's UV IS its construction
grid, so this file can call `plate_of_cell` and `scute_relief`'s own
distance-to-border on the pixel's grid coordinate. The texture cannot drift out
of register with the geometry, because it is generated from it.

Palette: `_references/turtle/_synthesis.md` puts our animal on the terrapin
axis (water-edge galapago), so it keeps a muted olive rather than the tortoise
browns -- but far duller than the mint green the vertex-colour build drifted
into. Ring bands are alternating value, not alternating hue: keratin laid down
in a good season is paler and thicker, and that reads as VALUE.
"""
from __future__ import annotations

import math

import numpy as np

import _carapace


# Base albedo per plate kind, linear (NOT sRGB): Blender and glTF both want
# linear, and this project has already been bitten twice by handing sRGB floats
# to something that expects linear.
# Warm, not neutral. Measured off Joan's Godot screenshot the shell sampled
# (97, 97, 92) -- a flat grey. R > G > B is what makes keratin read as horn
# rather than as slate, and it is what every reference photo shows.
# First bake came out near-black: 0.07 linear is a very dark albedo, and the
# ring modulation then multiplies DOWN from it. The lesson about picking linear
# values for the rig that multiplies them cuts both ways -- it was applied here
# hard enough to bury the pattern that the whole bake exists to show.
KIND_RGB = {
    "nuchal": (0.130, 0.107, 0.052),
    "vertebral": (0.168, 0.138, 0.064),
    "pleural": (0.136, 0.112, 0.053),
    "marginal": (0.100, 0.082, 0.038),
}
SEAM_RGB = (0.030, 0.024, 0.014)


def _hash01(a, b, c=0):
    """Deterministic per-plate jitter. No RNG: the build must be repeatable."""
    x = math.sin(a * 12.9898 + b * 78.233 + c * 37.719) * 43758.5453
    return x - math.floor(x)


def bake(spec, size=1024):
    """Return an (size, size, 4) float32 RGBA array in linear space."""
    n, band = spec.n, spec.band
    img = np.zeros((size, size, 4), dtype=np.float32)
    img[..., 3] = 1.0

    # Fine grain, so the surface is not plastic under a PBR light. Two octaves
    # of value noise at texel scale -- keratin is not smooth.
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    grain = (np.sin(xx * 0.7) * np.sin(yy * 0.9) * 0.5 +
             np.sin(xx * 2.3 + yy * 1.7) * 0.5)
    grain = 1.0 + 0.10 * grain

    for py in range(size):
        v = py / (size - 1)
        for px in range(size):
            u = px / (size - 1)

            if v <= 0.85 and u <= 0.85:
                # Interior: back out the grid coordinate this texel came from.
                gi = (u / 0.85) * n
                gj = (v / 0.85) * n
                ci = min(int(gi), n - 1)
                cj = min(int(gj), n - 1)
                kind, pid, i0, i1, j0, j1 = _carapace.plate_of_cell(spec, ci, cj)
                edge_d = _carapace._plate_local(gi, gj, i0, i1, j0, j1)
                bu = (gi - i0) / max(1, (i1 - i0))
                bv = (gj - j0) / max(1, (j1 - j0))
            else:
                # Marginal band strip along the top of the map.
                m = 4 * n
                per = max(1, m // 24)
                k = (u * m) % m
                pid = int(k // per)
                kind = "marginal"
                along = (k % per) / per
                t = min(1.0, max(0.0, (v - 0.87) / 0.13))
                edge_d = min(t * 0.5, 0.5 * along, 0.5 * (1.0 - along))
                bu, bv = along, t

            base = KIND_RGB[kind]
            e = max(0.0, min(0.5, edge_d)) * 2.0        # 0 border, 1 middle

            # Growth rings: a value ramp inside each annulus, brighter toward
            # the plate's middle, with a dark line in the groove. Same phase as
            # the geometry's grooves, so light and shadow agree.
            #
            # The ring COUNT varies per plate and the spacing crowds toward the
            # border. Both are real -- a scute adds a ring per growth season, so
            # neighbouring plates that started at different times carry
            # different counts, and the early rings are packed at the outside
            # where the plate was smallest. Uniform concentric squares
            # everywhere read as wallpaper, which is what the first bake did.
            kseed = _hash01(pid, hash(kind) % 97)
            n_rings = spec.rings + int(_hash01(pid, 11, 3) * 3.0) - 1
            phase = (((1.0 - e) ** 1.35) * n_rings + kseed * 0.7) % 1.0
            groove = math.exp(-((phase - 0.5) ** 2) / 0.020)
            band_val = 0.66 + 0.52 * e - 0.60 * groove

            # Per-plate variation, or the shell reads as one printed pattern.
            jitter = 0.80 + 0.34 * kseed

            # Dark blotch over part of the plate. Every reference photo of a
            # Testudo shows this: pale keratin with a dark patch, not a flat
            # tone -- and it is the cheapest thing that stops a shell looking
            # printed.
            blot = math.exp(-(((bu - 0.30 - 0.4 * kseed) ** 2) / 0.10 +
                              ((bv - 0.34) ** 2) / 0.12))
            jitter *= (1.0 - 0.42 * blot)

            # The seam itself: nearly black, narrow, and it is what makes the
            # plates read as separate pieces at a distance.
            seam = math.exp(-e / 0.05)

            val = band_val * jitter
            rgb = [base[c] * val * (1.0 - seam) + SEAM_RGB[c] * seam
                   for c in range(3)]
            img[py, px, 0:3] = rgb

    img[..., 0:3] *= grain[..., None]
    np.clip(img, 0.0, 1.0, out=img)
    return img


def to_blender_image(arr, name="turtle_carapace"):
    """Wrap a float array as a Blender image, non-colour data handled by caller."""
    import bpy

    h, w, _ = arr.shape
    im = bpy.data.images.get(name)
    if im is not None:
        bpy.data.images.remove(im)
    im = bpy.data.images.new(name, width=w, height=h, alpha=True,
                             float_buffer=True)

    # ENCODE TO sRGB, and tag the image sRGB. `bake()` works in linear because
    # that is the right space to do the maths in, but a glTF `baseColorTexture`
    # is sRGB BY SPECIFICATION -- the viewer will decode it. Handing over linear
    # values tagged Non-Color means they get decoded a second time: measured
    # 2026-08-24, the carapace arrived in the GLB almost black while the
    # in-Blender preview looked right. Tagging it sRGB and encoding once keeps
    # Blender's own render correct too, because Blender then decodes back to
    # the linear values `bake()` chose.
    lin = np.clip(arr, 0.0, 1.0)
    rgb = np.where(lin[..., :3] <= 0.0031308,
                   lin[..., :3] * 12.92,
                   1.055 * np.power(np.maximum(lin[..., :3], 1e-8), 1 / 2.4)
                   - 0.055)
    out = np.concatenate([rgb, lin[..., 3:4]], axis=2)
    im.colorspace_settings.name = "sRGB"

    # Blender's pixel buffer is bottom-up; the array is top-down.
    src = np.ascontiguousarray(out[::-1], dtype=np.float32).ravel()

    # MEASURED 2026-08-24: `pixels.foreach_set` on a freshly created image can
    # write NOTHING and raise nothing. Read back afterwards, the buffer was
    # still the default (0,0,0,1) -- mean 0.2500 against the 0.3067 written,
    # which is precisely "alpha survived, colour did not". From the render that
    # failure is indistinguishable from a lighting problem, and it cost a pass.
    # So: write, force the update, VERIFY, and fall back to the slow path
    # rather than shipping a black texture.
    im.pixels.foreach_set(src)
    im.update()
    back = np.empty(len(im.pixels), dtype=np.float32)
    im.pixels.foreach_get(back)
    if abs(float(back.mean()) - float(src.mean())) > 1e-4:
        im.pixels[:] = src.tolist()
        im.update()
        im.pixels.foreach_get(back)
        if abs(float(back.mean()) - float(src.mean())) > 1e-4:
            raise SystemExit(
                "_carapace_texture: the image buffer will not take the bake "
                "(wrote %.4f, read %.4f)" % (src.mean(), back.mean()))
    im.pack()
    return im
