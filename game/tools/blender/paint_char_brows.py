"""paint_char_brows -- brows PAINTED into the head, after subdividing for them.

Joan, looking at the geometry version: "leo dos cejas... la que le agregaste es
un poligono encima de ella, esta separada de la cabeza, se ve como un cuerpo 3D
pegado encima de algo que esta una malla completa, fusionada. La idea seria
pintar en vez de agregar, o si se agrega que tome la misma figura que la malla."

He is right on both counts, and the audit agrees: the strip floats 2.2 mm proud
with its own cast shadow and hard silhouette, so it reads as an object resting
on a face rather than hair growing out of it. Cohesion was never the problem --
belonging was.

THE THIRD WAY. Painting was ruled out because a correct brow is ~5.5 mm tall on
a mesh with 4.07 mm edges: one and a half vertices. But that limit is not a law
of the mesh, it is a law of THIS mesh AT THIS DENSITY -- and the iris proved the
way out. Subdividing the eyeball took the iris from 5 samples and 68% wobble to
a clean circle. Same move here: subdivide the forehead band over the eyes, THEN
paint. The brow ends up inside the single fused mesh, with no floating object,
no second silhouette and no cast shadow of its own.

Shape comes from the same verified numbers as the geometry version, which were
measured off Skyrim's Farkas at matched interpupillary distance:

    body centre   0.140 of IPD above the pupil line
    arch rise     0.045, peaking ~2/3 of the way out
    head half     0.048 IPD  (inner end, thick)
    tail half     0.016 IPD  (outer end, thin)

    blender -b <blend> --python-exit-code 1 --python paint_char_brows.py -- \
        --out painted.blend --cuts 2
"""
from __future__ import annotations

import argparse
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy
import numpy as np

from _char_common import morphed_coords

ATTR = "Col"
BROW_HEX = "#231A14"

BODY_ABOVE_PUPIL = 0.185
ARCH_RISE = 0.045
# Measured, not chosen. measure_brow_gap.py on the previous pass:
#   aperture 45 px | gap lid->brow 1 px (ratio 0.02) | brow height 97 px (2.16)
# against a Skyrim target of 0.73 for BOTH. The centre was already correct --
# it computed to exactly the right row -- so the whole defect was THICKNESS:
# the brow was 3x too tall and its lower edge swallowed the lid. Verifying the
# centre and never the edge is how that passed as [OK] for two passes.
HEAD_HALF = 0.030
TAIL_HALF = 0.011
INNER_X = 0.20
OUTER_X = 0.78
PEAK_T = 0.62

# Vertical extent of the band that gets subdivided, in IPD fractions above the
# pupil line. Wide enough to hold the arch plus a soft edge on each side.
BAND_LO = 0.055
BAND_HI = 0.260


def verts_in(obj, names) -> list:
    gi = {g.name: g.index for g in obj.vertex_groups}
    want = {gi[n] for n in names if n in gi}
    if not want:
        return []
    return sorted({v.index for v in obj.data.vertices
                   for ge in v.groups
                   if ge.group in want and ge.weight > 0.01})


def anchors(obj):
    W, _ = morphed_coords(obj)
    gi = {g.name: g.index for g in obj.vertex_groups}

    def centre(gname):
        k = gi[gname]
        idx = [v.index for v in obj.data.vertices
               if any(e.group == k and e.weight > 0.01 for e in v.groups)]
        return W[idx].mean(axis=0)

    cl, cr = centre("helper-l-eye"), centre("helper-r-eye")
    return float(abs(cl[0] - cr[0])), 0.5 * (cl[2] + cr[2])


def subdivide_band(obj, cuts: int) -> int:
    """Subdivide only the forehead band, keeping the 41 shape keys alive.

    Edit-mode operator on purpose: bmesh drops shape keys. smoothness=0 --
    at 1.0 the eyeball subdivision blew the globes into spiked stars.
    """
    ipd, pupil_z = anchors(obj)
    W, _ = morphed_coords(obj)
    body = set(verts_in(obj, ("body",)))
    excl = set()
    for g in ("helper-l-eye", "helper-r-eye", "scalp",
              "helper-l-eyelashes-1", "helper-l-eyelashes-2",
              "helper-r-eyelashes-1", "helper-r-eyelashes-2"):
        excl.update(verts_in(obj, (g,)))

    lo = pupil_z + ipd * BAND_LO
    hi = pupil_z + ipd * BAND_HI
    sel = {i for i in body
           if i not in excl and lo <= W[i, 2] <= hi
           and abs(W[i, 0]) < ipd * 0.95}
    if len(sel) < 20:
        raise SystemExit("band holds %d verts -- nothing to subdivide"
                         % len(sel))

    before = len(obj.data.vertices)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="OBJECT")
    for v in obj.data.vertices:
        v.select = v.index in sel
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_mode(type="VERT")
    bpy.ops.mesh.subdivide(number_cuts=cuts, smoothness=0.0)
    bpy.ops.object.mode_set(mode="OBJECT")
    after = len(obj.data.vertices)
    print("      band %d verts -> subdivided %d -> %d (%+d)"
          % (len(sel), before, after, after - before))
    if after <= before:
        raise SystemExit("subdivide added nothing")
    return after - before


def smoothstep(t):
    t = np.clip(t, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def brow_weight(x, z, ipd, pupil_z) -> np.ndarray:
    """Soft 0..1 mask shaped like a brow, evaluated per vertex.

    Not a band: t runs along the brow, and BOTH the arch height and the
    thickness vary with t. The painted version this replaces was a symmetric
    horizontal slab, which is not a brow shape at any position.
    """
    ax = np.abs(x) / ipd
    t = (ax - INNER_X) / (OUTER_X - INNER_X)
    inside = (t >= 0.0) & (t <= 1.0)
    t = np.clip(t, 0.0, 1.0)

    hump = 0.5 * (1.0 - np.cos(2.0 * np.pi * np.minimum(t / (2 * PEAK_T), 1.0)))
    centre = pupil_z + ipd * (BODY_ABOVE_PUPIL + ARCH_RISE * hump)
    taper = 1.0 - smoothstep((t - 0.35) / 0.65)
    half = ipd * (TAIL_HALF + (HEAD_HALF - TAIL_HALF) * taper)

    d = np.abs(z - centre) / np.maximum(half, 1e-9)
    w = 1.0 - smoothstep((d - 0.55) / 0.45)          # soft edge, no hard rim
    # Fade the ends instead of chopping them, so the head and tail dissolve
    # into skin the way real brow hair thins out.
    ends = smoothstep(t / 0.12) * (1.0 - smoothstep((t - 0.80) / 0.20))
    return w * ends * inside


def paint(obj) -> None:
    ipd, pupil_z = anchors(obj)
    W, N = morphed_coords(obj)
    me = obj.data
    attr = me.color_attributes.get(ATTR)
    if attr is None:
        raise SystemExit("no %r colour attribute" % ATTR)

    body = np.zeros(len(me.vertices), dtype=bool)
    body[verts_in(obj, ("body",))] = True
    for g in ("helper-l-eye", "helper-r-eye", "scalp",
              "helper-l-eyelashes-1", "helper-l-eyelashes-2",
              "helper-r-eyelashes-1", "helper-r-eyelashes-2"):
        body[verts_in(obj, (g,))] = False

    w = brow_weight(W[:, 0], W[:, 2], ipd, pupil_z)
    w *= smoothstep((-N[:, 1] - 0.05) / 0.45) * body

    h = BROW_HEX.lstrip("#")
    s = np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])
    lin = np.where(s <= 0.04045, s / 12.92, ((s + 0.055) / 1.055) ** 2.4)

    lv = np.empty(len(me.loops), dtype=np.int32)
    me.loops.foreach_get("vertex_index", lv)
    cols = np.empty(len(attr.data) * 4, dtype=np.float32)
    attr.data.foreach_get("color", cols)
    cols = cols.reshape(-1, 4)

    # BLEND, do not stamp. A hard replace draws a silhouette with an edge --
    # which is what made both the old painted band and the geometry strip read
    # as something laid on the face rather than growing from it.
    a = (w if attr.domain == "POINT" else w[lv])[:, None]
    cols[:, :3] = cols[:, :3] * (1.0 - a) + lin[None, :] * a
    attr.data.foreach_set("color", cols.ravel())
    me.update()

    hit = w > 0.5
    if not hit.any():
        raise SystemExit("brow mask is empty -- nothing was painted")
    zs = W[hit, 2]
    frac = (zs.mean() - pupil_z) / ipd
    print("      painted: %d verts core (%d touched at all)"
          % (int(hit.sum()), int((w > 0.02).sum())))
    print("      [%s] body at %+.3f of IPD (Farkas 0.10..0.18)"
          % ("OK" if 0.10 <= frac <= 0.18 else "OFF-REF", frac))
    print("      height %.1f mm (Farkas ~5.5 mm)"
          % ((zs.max() - zs.min()) * 1000))


def clear_old(obj) -> None:
    """Erase whatever dark smear the previous brow passes left behind.

    Sample skin from the clean forehead ABOVE the brow, excluding the eye
    helpers -- the globes live in the `body` group since they were revealed,
    and averaging them in once repainted the band near-white.
    """
    ipd, pupil_z = anchors(obj)
    W, _ = morphed_coords(obj)
    me = obj.data
    attr = me.color_attributes.get(ATTR)
    n = len(me.vertices)

    body = np.zeros(n, dtype=bool)
    body[verts_in(obj, ("body",))] = True
    for g in ("helper-l-eye", "helper-r-eye", "scalp",
              "helper-l-eyelashes-1", "helper-l-eyelashes-2",
              "helper-r-eyelashes-1", "helper-r-eyelashes-2"):
        body[verts_in(obj, (g,))] = False

    lv = np.empty(len(me.loops), dtype=np.int32)
    me.loops.foreach_get("vertex_index", lv)
    cols = np.empty(len(attr.data) * 4, dtype=np.float32)
    attr.data.foreach_get("color", cols)
    cols = cols.reshape(-1, 4)
    s = np.zeros((n, 3))
    c = np.zeros(n)
    np.add.at(s, lv, cols[:, :3])
    np.add.at(c, lv, 1.0)
    c[c == 0] = 1.0
    vc = s / c[:, None]
    lum = vc.mean(axis=1)

    fore = body & (W[:, 2] > pupil_z + ipd * 0.30) & (W[:, 2] < pupil_z
                                                      + ipd * 0.50)
    if fore.sum() < 8:
        print("      clear_old: no clean forehead sample, skipped")
        return
    ref = vc[fore].mean(axis=0)
    band = body & (W[:, 2] > pupil_z + ipd * 0.04) & (W[:, 2] < pupil_z
                                                      + ipd * 0.30)
    dark = band & (lum < ref.mean() * 0.72)
    if dark.any():
        mask = dark if attr.domain == "POINT" else dark[lv]
        cols[mask, :3] = ref.astype(np.float32)
        attr.data.foreach_set("color", cols.ravel())
        me.update()
    print("      cleared %d old brow verts (skin ref lum %.3f)"
          % (int(dark.sum()), float(ref.mean())))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", default="char_warrior_male_mh")
    ap.add_argument("--out", required=True)
    ap.add_argument("--cuts", type=int, default=2)
    args = ap.parse_args(argv)

    obj = bpy.data.objects.get(args.obj)
    if obj is None:
        raise SystemExit("no object %r -- have %s"
                         % (args.obj, sorted(o.name for o in bpy.data.objects
                                             if o.type == "MESH")))
    obj.location = (0, 0, 0)
    bpy.context.view_layer.update()

    # Any geometry brows in the file go: they are what "dos cejas" meant.
    for o in list(bpy.data.objects):
        if o is not obj and o.type == "MESH" and "brow" in o.name.lower():
            print("      removed geometry brow %s" % o.name)
            bpy.data.objects.remove(o, do_unlink=True)

    print("")
    print("  %s" % obj.name)
    clear_old(obj)
    subdivide_band(obj, args.cuts)
    paint(obj)
    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(args.out))
    print("  saved %s" % args.out)


if __name__ == "__main__":
    main()
