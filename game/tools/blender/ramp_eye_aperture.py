"""ramp_eye_aperture -- open the eye toward the Skyrim ratio, and let Joan pick.

MEASURED, on a ruled overlay applied identically to both images:

    our warrior   5.9 eyes wide across the face
    Skyrim ref    3.4
    academic      5.0

So our eyes are SMALLER than the reference, not larger -- and the reference is
what the project targets. Skyrim runs eyes nearly 50% above the academic canon
on purpose: they are the focal point and they vanish at gameplay distance.

WHY THEY ENDED UP SMALL: I closed them. ramp_eye_shape.py applies
`eyefold-down` at full weight plus `height*-decr`, which lowers the upper lid
and shrinks the aperture. That ramp was built to stop the iris reading as a
full circle -- and it overshot into a squint.

This reverses the aperture half while KEEPING the parts that were right:
the socket shadow, the globe set into the orbit, the under-eye ridge.

Two things were tangled together and are now separated:
  - the GLOBE measures 31.8 mm against 24 mm real -> it protrudes past the
    lid at the outer canthus, visible only in profile
  - the APERTURE is too small -> the eye READS small from the front
Opposite problems. Only the second one is this file's business.

    blender -b <blend> --python-exit-code 1 --python ramp_eye_aperture.py -- \
        --obj face_m000 --out ramp.blend --strip strip.png --steps 5
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
from probe_eye_targets import apply_target
from fix_face_features import skin_material, light_scene

# Opening set. Measured in isolation by probe_eye_targets.py; the direction of
# each was confirmed there rather than assumed from the name.
OPEN_SET = {
    "eyefold-up": 0.85,        # lift the upper lid off the iris
    "height1-incr": 1.00,      # aperture
    "height2-incr": 0.90,
    "height3-incr": 0.60,
    "corner2-up": 0.35,        # outer canthus up -- the axis tilt a face has
}


def apply_open(obj, strength: float) -> int:
    n = 0
    for side in ("l", "r"):
        for stem, rel in OPEN_SET.items():
            if apply_target(obj, "%s-eye-%s" % (side, stem), rel * strength):
                n += 1
            else:
                print("      MISSING %s-eye-%s" % (side, stem))
    bpy.context.view_layer.update()
    return n


def aperture_mm(obj) -> float:
    """Vertical opening, measured on the SCLERA vertices rather than on a
    guessed lid rim.

    Four earlier attempts measured the palpebral aperture from body geometry
    and all four failed -- the 3D rim ring collapses when split by z. The
    sclera is unambiguous: it is only visible where the lids are open, so its
    own vertical extent IS the aperture.
    """
    W, _ = morphed_coords(obj)
    me = obj.data
    attr = me.color_attributes.get("Col")
    gi = {g.name: g.index for g in obj.vertex_groups}
    k = gi.get("helper-l-eye")
    if k is None or attr is None:
        return 0.0
    eye = [v.index for v in me.vertices
           if any(e.group == k and e.weight > 0.01 for e in v.groups)]

    lv = np.empty(len(me.loops), dtype=np.int32)
    me.loops.foreach_get("vertex_index", lv)
    cols = np.empty(len(attr.data) * 4, dtype=np.float32)
    attr.data.foreach_get("color", cols)
    cols = cols.reshape(-1, 4)[:, :3]
    n = len(me.vertices)
    s = np.zeros((n, 3))
    c = np.zeros(n)
    np.add.at(s, lv, cols)
    np.add.at(c, lv, 1.0)
    c[c == 0] = 1.0
    vc = s / c[:, None]

    # Sclera is the light patch on the globe; the iris and pupil are dark.
    lum = vc.mean(axis=1)
    bright = [i for i in eye if lum[i] > 0.35]
    if len(bright) < 4:
        return 0.0
    P = W[bright]
    return float(P[:, 2].max() - P[:, 2].min()) * 1000.0


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", default="face_m000")
    ap.add_argument("--out", required=True)
    ap.add_argument("--strip", required=True)
    ap.add_argument("--steps", type=int, default=5)
    ap.add_argument("--max", type=float, default=1.0)
    ap.add_argument("--gap", type=float, default=0.28)
    args = ap.parse_args(argv)

    src = bpy.data.objects.get(args.obj)
    if src is None:
        raise SystemExit("no object %r -- have %s"
                         % (args.obj, sorted(o.name for o in bpy.data.objects
                                             if o.type == "MESH")))
    for o in list(bpy.data.objects):
        if o is not src:
            bpy.data.objects.remove(o, do_unlink=True)
    src.location = (0, 0, 0)
    bpy.context.view_layer.update()

    base = aperture_mm(src)
    print("")
    print("  aperture before: %.2f mm" % base)

    ks = ([0.0] if args.steps < 2 else
          [args.max * i / (args.steps - 1) for i in range(args.steps)])
    mat = skin_material()
    made = []
    for i, k in enumerate(ks):
        dup = src.copy()
        dup.data = src.data.copy()
        dup.name = "open_%03d" % round(k * 100)
        dup.data.name = dup.name
        bpy.context.scene.collection.objects.link(dup)
        dup.location.x = (i - (len(ks) - 1) / 2.0) * args.gap
        dup.data.materials.clear()
        dup.data.materials.append(mat)
        bpy.context.view_layer.update()
        apply_open(dup, k)
        print("    %-10s strength %.2f   aperture %.2f mm"
              % (dup.name, k, aperture_mm(dup)))
        made.append(dup)

    bpy.data.objects.remove(src, do_unlink=True)

    # CONTROL: the extremes must actually differ, or the ramp did nothing and
    # a strip of identical faces reads as "the effect is subtle".
    spread = aperture_mm(made[-1]) - aperture_mm(made[0])
    print("")
    print("  aperture spread across the ramp: %+.2f mm" % spread)
    if abs(spread) < 0.15:
        # NOT fatal any more, because this metric is itself unreliable: it
        # measures the vertical extent of SCLERA VERTICES IN 3D, and those
        # exist whether or not the lid covers them. So it reports the globe,
        # not the aperture -- the eighth broken probe of this session. The
        # geometric check that follows is the one that decides.
        print("      WARNING: sclera-extent metric shows no change. It cannot")
        print("      see lid movement, so this is expected, not proof.")

    # Real check: did the shape keys move ANY vertex between the extremes?
    # LOCAL space. Comparing world coords measures the gap between the heads
    # on the shelf -- the same mistake made in ramp_eye_shape.py, where it
    # reported "1202 mm of effect" for an eyelid change.
    def local(o):
        W, _ = morphed_coords(o)
        M = np.array(o.matrix_world)
        return (W - M[:3, 3]) @ np.linalg.inv(M[:3, :3]).T

    moved = float(np.abs(local(made[0]) - local(made[-1])).max()) * 1000.0
    print("      geometry spread first vs last: %.2f mm max" % moved)
    if moved < 0.05:
        raise SystemExit("no vertex moved between the extremes -- the targets"
                         " did not apply at all")

    sc = bpy.context.scene
    dg = bpy.context.evaluated_depsgraph_get()
    ev = made[0].evaluated_get(dg)
    me = ev.to_mesh()
    top = max((made[0].matrix_world @ v.co).z for v in me.vertices)
    ev.to_mesh_clear()
    hz = top - 0.112
    light_scene(sc, hz)

    xs = [o.location.x for o in made]
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = 330 * len(made)
    sc.render.resolution_y = 300
    sc.view_settings.view_transform = "Filmic"
    cd = bpy.data.cameras.new("c")
    cam = bpy.data.objects.new("c", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cd.type = "ORTHO"
    cd.ortho_scale = (max(xs) - min(xs)) + args.gap
    cam.location = ((max(xs) + min(xs)) / 2.0, -2.0, hz)
    cam.rotation_euler = (math.radians(90), 0.0, 0.0)
    strip = os.path.abspath(args.strip)
    sc.render.filepath = strip
    bpy.ops.render.render(write_still=True)
    if not (os.path.isfile(strip) and os.path.getsize(strip) > 0):
        raise SystemExit("strip not written")
    print("  strip -> %s" % strip)

    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(args.out))
    print("  saved %s" % args.out)


if __name__ == "__main__":
    main()
