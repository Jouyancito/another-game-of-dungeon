"""fit_eyeball -- shrink the globe to anatomical size without shrinking the EYE.

Two things kept getting confused, and separating them is the whole point:

    GLOBE    31.8 mm across, against 24 mm in a real head. Too big for the
             orbit, so it breaks through the lid -- visible as a triangle of
             sclera in profile, and as a row of saw teeth above the lid from
             the front.
    APERTURE too small, so the eye READS small. Measured 5.9 eyes across the
             face where Skyrim runs 3.4.

Opposite problems. Joan pushed back when I proposed "shrink the eye", and he
was right: shrinking what you SEE was the wrong move. Shrinking the BALL while
the lids open wider is not.

The scale is applied about the globe's own centre, so the pupil stays on the
interpupillary line (measured 61.5 mm, already correct) and the gaze direction
does not move.

    blender -b <blend> --python-exit-code 1 --python fit_eyeball.py -- \
        --obj open_050 --out fitted.blend --target-mm 24
"""
from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy
import numpy as np

from _char_common import morphed_coords

EYE_GROUPS = ("helper-l-eye", "helper-r-eye")


def verts_in(obj, name) -> list:
    gi = {g.name: g.index for g in obj.vertex_groups}
    k = gi.get(name)
    if k is None:
        return []
    return sorted({v.index for v in obj.data.vertices
                   for ge in v.groups
                   if ge.group == k and ge.weight > 0.01})


def globe_diameter(obj, name) -> float:
    W, _ = morphed_coords(obj)
    idx = verts_in(obj, name)
    if not idx:
        return 0.0
    P = W[idx]
    c = P.mean(axis=0)
    return float(np.linalg.norm(P - c, axis=1).mean()) * 2000.0


def scale_globe(obj, name, factor: float) -> int:
    """Scale one globe about its own centre, in the BASE mesh.

    Writing base coordinates is the right move HERE and only here: the globe
    carries no shape-key deformation of its own worth preserving, and the
    scale has to survive into the file. Everywhere else in this project,
    reading or writing me.vertices is the shape-key trap.
    """
    idx = verts_in(obj, name)
    if not idx:
        raise SystemExit("group %s is empty" % name)
    me = obj.data
    co = np.empty(len(me.vertices) * 3, dtype=np.float32)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    sel = np.array(idx)
    c = co[sel].mean(axis=0)
    co[sel] = c + (co[sel] - c) * factor
    me.vertices.foreach_set("co", co.ravel())

    # Shape keys hold their own copy of every coordinate. Skipping them leaves
    # the rendered globe untouched while the base cage shrinks -- the exact
    # silent no-op this project keeps hitting.
    sk = me.shape_keys
    if sk:
        for kb in sk.key_blocks:
            d = np.empty(len(me.vertices) * 3, dtype=np.float32)
            kb.data.foreach_get("co", d)
            d = d.reshape(-1, 3)
            kc = d[sel].mean(axis=0)
            d[sel] = kc + (d[sel] - kc) * factor
            kb.data.foreach_set("co", d.ravel())
    me.update()
    return len(idx)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--target-mm", type=float, default=24.0)
    args = ap.parse_args(argv)

    obj = bpy.data.objects.get(args.obj)
    if obj is None:
        raise SystemExit("no object %r -- have %s"
                         % (args.obj, sorted(o.name for o in bpy.data.objects
                                             if o.type == "MESH")))
    obj.location = (0, 0, 0)
    bpy.context.view_layer.update()

    print("")
    for g in EYE_GROUPS:
        before = globe_diameter(obj, g)
        if before <= 0:
            print("      %s: not found" % g)
            continue
        factor = args.target_mm / before
        n = scale_globe(obj, g, factor)
        bpy.context.view_layer.update()
        after = globe_diameter(obj, g)
        print("      %-16s %.2f -> %.2f mm  (x%.3f, %d verts)"
              % (g, before, after, factor, n))
        # CONTROL: the measured result must land on the target. A shape-key
        # copy left unscaled would show up right here as an unchanged number.
        if abs(after - args.target_mm) > 0.5:
            raise SystemExit(
                "%s ended at %.2f mm, not %.2f -- the scale did not take"
                " everywhere (shape keys?)" % (g, after, args.target_mm))

    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(args.out))
    print("  saved %s" % args.out)


if __name__ == "__main__":
    main()
