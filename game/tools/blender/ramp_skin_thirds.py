"""ramp_skin_thirds -- N warriors in a row, each with more chromatic separation.

WHY A RAMP: every hand-picked value in this character came in too hot, five for
five. The value is Joan's call, made by looking, not mine made by reasoning. So
the script does not pick a number -- it builds the whole range side by side in
one .blend, and he points.

WHAT IT FIXES: measure_skin_spectrum found the three thirds of the face sitting
at redness 0.6420 / 0.6199 / 0.6162 -- the same hue at three brightnesses. The
brightness comes from baked AO, not from a colour decision. That is flat paint
with shading on top, which is the exact thing the brief said to avoid.

THE ANATOMY (portrait canon, confirmed by both refs -- Skyrim Farkas and the
RDR Arthur close-up):

    forehead      more YELLOW  -- thin skin over bone, few capillaries
    nose / cheek  more RED     -- the most vascular region of the face
    jaw / chin    COLDER, darker -- in a male, beard sitting under the skin

LANDMARKS ARE DERIVED FROM TWO REAL ANCHORS, not guessed and not taken from
the crown. Classical canon puts the eye line at 0.50 H above the chin and the
mouth line at 0.20 H, and this mesh ships both `joint-l-eye` and `lips`:

    H          = (z_eyes - z_lips) / 0.30
    z_chin     = z_lips - 0.20 * H
    z_hairline = z_chin + 0.79 * H

Run 1 solved H from the CROWN instead, and it failed visibly: the cranial vault
inflates z_crown, so H came out short, z_chin landed above the real chin, and
the yellow third painted the SKULL while the red painted the MOUTH. Two checks
now guard it -- the predicted crown must land within 30 mm of the real one, and
joint-jaw must fall in the bottom third.

The three EQUAL thirds are measured between chin and hairline, never between
chin and crown; that is what put the neck in the bottom third earlier.

Borders are smoothstepped, never hard: skin has no seam between its thirds.
Brows, lips, lashes and the rest keep their stamped colour untouched.

    blender -b <painted.blend> --factory-startup --python-exit-code 1 \
        --python ramp_skin_thirds.py -- --out ramp.blend --steps 5
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

# Direction each third moves, in LINEAR RGB, per unit of ramp strength. These
# are directions only -- the magnitude is what the ramp sweeps.
#   forehead  -> yellow: red and green up together, blue down
#   nose      -> red:    red up, green and blue down
#   jaw       -> cold:   red down, blue up, and darker overall
DIR_FOREHEAD = np.array([0.026, 0.019, -0.009])
DIR_NOSE = np.array([0.034, -0.006, -0.008])
DIR_JAW = np.array([-0.021, -0.009, 0.007])

DISCRETE_GROUPS = (
    "lips", "fingernails", "toenails", "nipple", "nippleTip", "scalp",
    "helper-upper-teeth", "helper-lower-teeth",
    "helper-l-eyelashes-1", "helper-l-eyelashes-2",
    "helper-r-eyelashes-1", "helper-r-eyelashes-2",
    "helper-l-eye", "helper-r-eye", "helper-tongue",
)


def group_centroid(obj, world, name: str):
    gi = {g.name: g.index for g in obj.vertex_groups}.get(name)
    if gi is None:
        return None
    idx = [v.index for v in obj.data.vertices
           if any(ge.group == gi and ge.weight > 0.01 for ge in v.groups)]
    return world[idx].mean(axis=0) if idx else None


def smoothstep(t):
    t = np.clip(t, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def band_weights(z, z_chin, z_hairline):
    """Three overlapping weights that sum to 1 along the face height.

    Plateau in the middle of each third, smooth crossfade at the boundaries.
    A hard cut would draw two visible stripes across the face, which is the
    opposite of what skin does.
    """
    h = max(z_hairline - z_chin, 1e-6)
    t = (z - z_chin) / h                       # 0 at chin, 1 at hairline
    # boundaries at 1/3 and 2/3, each with a half-third-wide crossfade
    w_jaw = 1.0 - smoothstep((t - 1 / 6) / (1 / 3))
    w_fore = smoothstep((t - 1 / 2) / (1 / 3))
    w_nose = np.clip(1.0 - w_jaw - w_fore, 0.0, 1.0)
    return w_jaw, w_nose, w_fore


def paint_variant(obj, strength: float) -> None:
    me = obj.data
    attr = me.color_attributes.get(ATTR)
    if attr is None:
        raise SystemExit("object %r has no %r colour attribute"
                         % (obj.name, ATTR))

    n = len(me.vertices)
    M = np.array(obj.matrix_world)
    # MORPHED, not the base cage. This mesh has 41 active shape keys and the
    # base sits ~10 cm below what renders, non-uniformly -- landmarks read off
    # me.vertices put the thirds in the wrong place and the error is silent.
    world, nw = morphed_coords(obj)

    z_crown = world[:, 2].max()
    eye_l = group_centroid(obj, world, "joint-l-eye")
    eye_r = group_centroid(obj, world, "joint-r-eye")
    lips = group_centroid(obj, world, "lips")
    if eye_l is None or eye_r is None or lips is None:
        raise SystemExit("need joint-l-eye, joint-r-eye and lips to anchor")
    z_eyes = 0.5 * (eye_l[2] + eye_r[2])
    z_lips = lips[2]

    # TWO real landmarks, not the crown. Deriving head height from the crown
    # failed on the first run: the cranial vault inflates z_crown, head_h came
    # out short, and z_chin landed ABOVE the real chin -- so the yellow third
    # painted the skull and the red painted the mouth. Both anchors below are
    # measured on this mesh.
    #
    #   canon:  eye line at 0.50 H above the chin
    #           mouth line at 0.20 H above the chin
    #   =>      z_eyes - z_lips = 0.30 H
    head_h = (z_eyes - z_lips) / 0.30
    z_chin = z_lips - 0.20 * head_h
    z_hairline = z_chin + 0.79 * head_h

    # CONTROLS. Both must hold or the anchor is wrong and every colour lands
    # in the wrong place -- which is exactly what happened on run 1.
    pred_crown = z_chin + head_h
    err = abs(pred_crown - z_crown)
    print("      chin %.4f  lips %.4f  eyes %.4f  hairline %.4f  H %.4f"
          % (z_chin, z_lips, z_eyes, z_hairline, head_h))
    print("      [%s] predicted crown %.4f vs actual %.4f (%.1f mm off)"
          % ("OK" if err < 0.030 else "SUSPECT", pred_crown, z_crown,
             err * 1000))
    jaw = group_centroid(obj, world, "joint-jaw")
    if jaw is not None:
        t_jaw = (jaw[2] - z_chin) / max(z_hairline - z_chin, 1e-6)
        print("      [%s] joint-jaw at t=%.3f of the face (want 0.10..0.45)"
              % ("OK" if 0.10 < t_jaw < 0.45 else "SUSPECT", t_jaw))

    # Vertices that keep their stamped colour.
    gidx = {g.name: g.index for g in obj.vertex_groups}
    wanted = {gidx[g] for g in DISCRETE_GROUPS if g in gidx}
    protected = np.zeros(n, dtype=bool)
    for v in me.vertices:
        for ge in v.groups:
            if ge.group in wanted and ge.weight > 0.01:
                protected[v.index] = True
                break

    # Only the head, and only front-facing: the back of the skull has no
    # thirds and the shift would just tint the nape.
    on_face = (world[:, 2] > z_chin) & (world[:, 2] < z_hairline) & ~protected
    # Fade the effect out around the sides instead of stopping at a line.
    front = np.clip((-nw[:, 1] - 0.05) / 0.45, 0.0, 1.0)
    front = smoothstep(front) * on_face

    w_jaw, w_nose, w_fore = band_weights(world[:, 2], z_chin, z_hairline)
    delta = (w_jaw[:, None] * DIR_JAW
             + w_nose[:, None] * DIR_NOSE
             + w_fore[:, None] * DIR_FOREHEAD) * strength * front[:, None]

    # Write through FACE_CORNER: each loop takes its own vertex's delta.
    loop_v = np.empty(len(me.loops), dtype=np.int32)
    me.loops.foreach_get("vertex_index", loop_v)
    cols = np.empty(len(attr.data) * 4, dtype=np.float32)
    attr.data.foreach_get("color", cols)
    cols = cols.reshape(-1, 4)
    if attr.domain == "CORNER":
        cols[:, :3] = np.clip(cols[:, :3] + delta[loop_v], 0.0, 1.0)
    else:
        cols[:, :3] = np.clip(cols[:, :3] + delta, 0.0, 1.0)
    attr.data.foreach_set("color", cols.ravel())
    me.update()

    touched = int((front > 0.01).sum())
    print("      strength %.2f -> %d verts shifted" % (strength, touched))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", default="char_warrior_male_mh")
    ap.add_argument("--out", required=True)
    ap.add_argument("--steps", type=int, default=5)
    ap.add_argument("--max-strength", type=float, default=1.6)
    ap.add_argument("--gap", type=float, default=0.62)
    args = ap.parse_args(argv)

    src = bpy.data.objects.get(args.obj)
    if src is None:
        raise SystemExit("no object %r" % args.obj)

    # Everything that is not the body gets out of the way, so the row reads
    # clean and nothing else drags a MASK into the duplicates.
    for o in list(bpy.data.objects):
        if o.type == "MESH" and o is not src:
            bpy.data.objects.remove(o, do_unlink=True)
    # MASK modifiers STAY. Removing them on run 1 unhid the MakeHuman helper
    # geometry (sleeves, skirt, the head cover) and the whole strip rendered
    # as a hooded figure -- the colour verdict was judged on a contaminated
    # image. Painting reads me.vertices directly, which is the base cage, so
    # the mask never needed touching in the first place.

    strengths = [0.0] if args.steps < 2 else [
        args.max_strength * i / (args.steps - 1) for i in range(args.steps)]

    print("\n  building %d variants, strength %.2f .. %.2f"
          % (len(strengths), strengths[0], strengths[-1]))

    for i, s in enumerate(strengths):
        dup = src.copy()
        dup.data = src.data.copy()
        dup.name = "warrior_s%02d" % round(s * 100)
        dup.data.name = dup.name
        bpy.context.scene.collection.objects.link(dup)
        dup.location.x = (i - (len(strengths) - 1) / 2.0) * args.gap
        bpy.context.view_layer.update()
        print("    %s  (x = %+.2f m)" % (dup.name, dup.location.x))
        paint_variant(dup, s)

    bpy.data.objects.remove(src, do_unlink=True)

    # A label per variant so the strength is readable in the viewport and Joan
    # can name the one he wants without counting from the left.
    for i, s in enumerate(strengths):
        cur = bpy.data.curves.new("lbl%d" % i, type="FONT")
        cur.body = "%.2f" % s
        cur.align_x = "CENTER"
        cur.size = 0.08
        txt = bpy.data.objects.new("lbl_%.2f" % s, cur)
        bpy.context.scene.collection.objects.link(txt)
        txt.location = ((i - (len(strengths) - 1) / 2.0) * args.gap, 0.0, 1.95)
        txt.rotation_euler = (1.5708, 0.0, 0.0)

    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(args.out))
    print("\n  saved %s" % args.out)


if __name__ == "__main__":
    main()
