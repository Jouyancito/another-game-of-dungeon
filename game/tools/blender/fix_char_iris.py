"""fix_char_iris -- give the eyeball enough resolution to hold a round iris.

Joan: "el iris es irregular, se ve parte de abajo blanco, la idea es que sea
circular". Measured, and he is exactly right:

    globe          72 vertices total  (~12 per ring)
    iris painted   5 vertices
    iris radius    5.57 .. 10.99 mm   -> 68% IRREGULAR
    iris diameter  ~16 mm, against a real 11-12 mm

A circle drawn with 5 samples is not a circle. This is the same wall as the
pores and the brow -- Nyquist -- except here it is cheap to move: the globes
are two small spheres and subdividing them costs almost nothing, unlike
subdividing a whole head.

SUBDIVISION GOES THROUGH EDIT MODE ON PURPOSE. bmesh cannot edit a mesh
carrying shape keys without dropping them, and this one has 41 active. The
edit-mode operator propagates them.

Real proportions used:
    globe        24 mm diameter (the model ships 29.8; scale-decr is handling
                 that separately, so this file does not touch size)
    iris         11.7 mm diameter
    pupil        4 mm diameter
    sclera       NOT white. Slightly lighter than skin, warm at the corners.
                 Pure white is the strongest doll signal an eye can give, and
                 measured ratio against skin was 3.6 where 1.5-2.5 is real.

    blender -b <blend> --python-exit-code 1 --python fix_char_iris.py -- \
        --out fixed.blend --cuts 2
"""
from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy
import numpy as np

from _char_common import morphed_coords

ATTR = "Col"
EYE_GROUPS = ("helper-l-eye", "helper-r-eye")

IRIS_D = 0.0117      # metres
PUPIL_D = 0.0040
SCLERA_HEX = "#C9BCAE"   # warm bone, NOT white
IRIS_HEX = "#4A3220"
PUPIL_HEX = "#100C09"
LIMBUS_HEX = "#231708"   # dark ring at the iris edge -- what defines the gaze


def verts_in(obj, names) -> list:
    gi = {g.name: g.index for g in obj.vertex_groups}
    want = {gi[n] for n in names if n in gi}
    if not want:
        return []
    return sorted({v.index for v in obj.data.vertices
                   for ge in v.groups
                   if ge.group in want and ge.weight > 0.01})


def subdivide_eyes(obj, cuts: int) -> int:
    """Subdivide only the eyeball faces, keeping the 41 shape keys alive."""
    before = len(obj.data.vertices)
    idx = set(verts_in(obj, EYE_GROUPS))
    if not idx:
        raise SystemExit("no eye vertices to subdivide")

    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode="OBJECT")
    for v in obj.data.vertices:
        v.select = v.index in idx
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_mode(type="VERT")
    # smoothness=0. At 1.0 the new vertices are pushed outward along the
    # surface normal, and on a 12-segment sphere that is enough to blow the
    # globe into a white spiked star punching through the eyelids. Plain
    # subdivision keeps the silhouette and only adds samples, which is all
    # that is wanted here.
    bpy.ops.mesh.subdivide(number_cuts=cuts, smoothness=0.0)
    bpy.ops.object.mode_set(mode="OBJECT")

    after = len(obj.data.vertices)
    print("      subdivided eyes: %d -> %d verts (%+d)"
          % (before, after, after - before))
    if after <= before:
        raise SystemExit("subdivide added nothing -- the selection was empty")
    return after - before


def to_lin(h: str) -> np.ndarray:
    h = h.lstrip("#")
    s = np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])
    return np.where(s <= 0.04045, s / 12.92, ((s + 0.055) / 1.055) ** 2.4)


def paint_eyes(obj) -> None:
    """Sclera / limbus / iris / pupil as rings around the forward axis.

    Distance is measured to the AXIS through the globe centre pointing -Y (the
    gaze direction), not to a point in front of it. Measuring to a point makes
    the "circle" a spherical cap whose projected radius varies with how far
    round the globe each vertex sits -- which is precisely the 68% wobble.
    """
    W, _ = morphed_coords(obj)
    me = obj.data
    attr = me.color_attributes.get(ATTR)
    if attr is None:
        raise SystemExit("no %r colour attribute" % ATTR)

    lv = np.empty(len(me.loops), dtype=np.int32)
    me.loops.foreach_get("vertex_index", lv)
    cols = np.empty(len(attr.data) * 4, dtype=np.float32)
    attr.data.foreach_get("color", cols)
    cols = cols.reshape(-1, 4)

    report = []
    for gname in EYE_GROUPS:
        eye = verts_in(obj, (gname,))
        if not eye:
            raise SystemExit("group %s is empty" % gname)
        P = W[eye]
        c = P.mean(axis=0)

        # Radial distance from the gaze axis, and only the FRONT hemisphere.
        rad = np.linalg.norm(P[:, [0, 2]] - c[[0, 2]], axis=1)
        front = P[:, 1] < c[1]

        bands = [
            (rad <= PUPIL_D / 2, PUPIL_HEX, "pupil"),
            ((rad > PUPIL_D / 2) & (rad <= IRIS_D / 2 * 0.82), IRIS_HEX, "iris"),
            ((rad > IRIS_D / 2 * 0.82) & (rad <= IRIS_D / 2), LIMBUS_HEX,
             "limbus"),
            (rad > IRIS_D / 2, SCLERA_HEX, "sclera"),
        ]
        for sel, hexcol, label in bands:
            m = np.zeros(len(me.vertices), dtype=bool)
            hit = np.array(eye)[sel & front]
            if len(hit):
                m[hit] = True
                mask = m if attr.domain == "POINT" else m[lv]
                cols[mask, :3] = to_lin(hexcol).astype(np.float32)
            report.append((gname, label, int(len(hit))))

        # CONTROL: circularity of what actually got iris colour. A ring cut by
        # radius is circular BY CONSTRUCTION, so this checks the construction
        # rather than trusting it -- and gives the number to compare against
        # the 68% the point-distance version produced.
        iris_sel = np.array(eye)[(rad <= IRIS_D / 2) & front]
        if len(iris_sel) >= 4:
            Q = W[iris_sel]
            r = np.linalg.norm(Q[:, [0, 2]] - c[[0, 2]], axis=1)
            wob = 100.0 * (r.max() - r.min()) / max(r.mean(), 1e-9)
            print("      %s iris: %d verts, radius %.2f..%.2f mm"
                  " -> %.0f%% wobble (was 68%%)"
                  % (gname, len(iris_sel), r.min() * 1000, r.max() * 1000,
                     wob))

    attr.data.foreach_set("color", cols.ravel())
    me.update()
    for g, label, n in report:
        if n == 0:
            print("      AVISO %s %s got 0 verts" % (g, label))


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
    print("")
    print("  %s" % obj.name)
    subdivide_eyes(obj, args.cuts)
    paint_eyes(obj)
    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(args.out))
    print("  saved %s" % args.out)


if __name__ == "__main__":
    main()
