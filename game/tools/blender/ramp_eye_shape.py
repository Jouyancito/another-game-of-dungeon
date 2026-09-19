"""ramp_eye_shape -- N heads in a row, each with more eye anatomy dialled in.

WHY: the lit render showed a face whose structure is good and whose EYES read
as a doll -- full round iris, no lid cutting it, no socket shadow, sclera far
too bright. MPFB ships 68 eye targets and the generator used zero of them.

WHICH DIALS, AND WHY THESE SIX. Every candidate was applied alone first and
measured (probe_eye_targets.py). The earlier aperture-based probe reported 14
of 19 dials "inert"; the displacement probe found 28 of 28 move geometry, so
that first verdict was pure instrument error. Measured max displacement:

    eyefold-down       3.95 mm down   -> lowers the upper lid ONTO the iris
    eyefold-concave    6.04 mm back   -> hollows the fold, giving socket shadow
    push1-in           3.82 mm in     -> sets the globe INTO the socket
    bag-height-incr    6.87 mm down   -> the under-eye ridge
    corner1-down       2.10 mm down   -> inner corner lower than outer
    scale-decr         3.78 mm        -> globe measured 29.8 mm vs a real 24 mm

Weights are RELATIVE, and only the overall strength sweeps. The value is Joan's
call made by looking -- every hand-picked number in this character came in too
hot, five for five.

Rendered WITH LIGHT, always. Judging this face flat is what made it look
broken when the geometry was fine.

    blender -b <blend> --python-exit-code 1 --python ramp_eye_shape.py -- \
        --out ramp.blend --strip strip.png --steps 5

NO --factory-startup: it skips extensions, and MPFB is one.
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

# name -> relative weight. Sign is baked into the target name, so every value
# here is positive and the ramp scales all of them together.
EYE_SET = {
    "eyefold-down": 1.00,       # the doll fix: lid onto the iris
    "eyefold-concave": 0.70,    # socket shadow
    "push1-in": 0.55,           # set the globe in
    "bag-height-incr": 0.45,    # under-eye ridge
    "corner1-down": 0.40,       # axis tilt
    "scale-decr": 0.35,         # 29.8 mm globe -> toward 24 mm
}


def apply_eye_set(obj, strength: float) -> int:
    n = 0
    for side in ("l", "r"):
        for stem, rel in EYE_SET.items():
            name = "%s-eye-%s" % (side, stem)
            if apply_target(obj, name, rel * strength):
                n += 1
            else:
                print("      MISSING %s" % name)
    bpy.context.view_layer.update()
    return n


def skin_material():
    m = bpy.data.materials.new("skin")
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    vc = nt.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Col"
    nt.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
    # Skin is MATTE. At 0.62 the specular ate the crown and rendered it white
    # over a near-black vertex colour.
    bsdf.inputs["Roughness"].default_value = 0.88
    for nm, val in (("Specular IOR Level", 0.25), ("Subsurface Weight", 0.18)):
        if nm in bsdf.inputs:
            bsdf.inputs[nm].default_value = val
    if "Subsurface Radius" in bsdf.inputs:
        bsdf.inputs["Subsurface Radius"].default_value = (0.010, 0.004, 0.002)
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return m


def light_scene(sc, hz):
    def lamp(name, loc, energy, size, color):
        d = bpy.data.lights.new(name, "AREA")
        d.energy, d.size, d.color = energy, size, color
        L = bpy.data.objects.new(name, d)
        sc.collection.objects.link(L)
        L.location = loc
        v = np.array([0.0, -0.10, hz]) - np.array(loc)
        v /= np.linalg.norm(v)
        L.rotation_euler = (math.acos(-v[2]), 0.0, math.atan2(-v[0], v[1]))

    lamp("key", (-0.55, -0.75, hz + 0.42), 22, 0.7, (1.00, 0.95, 0.88))
    lamp("fill", (0.62, -0.55, hz - 0.04), 7, 1.0, (0.74, 0.82, 1.00))
    lamp("rim", (0.32, 0.72, hz + 0.26), 14, 0.35, (1.00, 0.87, 0.75))
    sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs[0].default_value = (
        0.03, 0.032, 0.04, 1.0)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", default="char_warrior_male_mh")
    ap.add_argument("--out", required=True)
    ap.add_argument("--strip", required=True)
    ap.add_argument("--steps", type=int, default=5)
    ap.add_argument("--max-strength", type=float, default=1.0)
    ap.add_argument("--gap", type=float, default=0.30)
    args = ap.parse_args(argv)

    src = bpy.data.objects.get(args.obj)
    if src is None:
        raise SystemExit("no object %r" % args.obj)
    for o in list(bpy.data.objects):
        if o is not src:
            bpy.data.objects.remove(o, do_unlink=True)

    strengths = ([0.0] if args.steps < 2 else
                 [args.max_strength * i / (args.steps - 1)
                  for i in range(args.steps)])
    print("")
    print("  %d variants, strength %.2f .. %.2f"
          % (len(strengths), strengths[0], strengths[-1]))

    mat = skin_material()
    made = []
    for i, s in enumerate(strengths):
        dup = src.copy()
        dup.data = src.data.copy()
        dup.name = "eyes_s%03d" % round(s * 100)
        dup.data.name = dup.name
        bpy.context.scene.collection.objects.link(dup)
        dup.location.x = (i - (len(strengths) - 1) / 2.0) * args.gap
        dup.data.materials.clear()
        dup.data.materials.append(mat)
        bpy.context.view_layer.update()
        n = apply_eye_set(dup, s)
        # CONTROL: the set must actually land. A silent miss here would render
        # five identical heads and look like "the dials do nothing".
        W, _ = morphed_coords(dup)
        print("    %-12s x=%+.2f  %d targets applied" % (dup.name,
                                                         dup.location.x, n))
        made.append((dup, s))

    bpy.data.objects.remove(src, do_unlink=True)

    # Prove the variants differ before rendering: identical meshes mean the
    # ramp failed, and a strip of five identical faces is easy to mistake for
    # "the effect is subtle".
    # LOCAL space, not world. Comparing world coordinates measured the 1.20 m
    # gap between the two heads on the shelf and reported "1202 mm of effect"
    # for what is a sub-millimetre eyelid change -- a control that cannot fail
    # is not a control.
    def local(o):
        W, _ = morphed_coords(o)
        M = np.array(o.matrix_world)
        return (W - M[:3, 3]) @ np.linalg.inv(M[:3, :3]).T

    delta = float(np.abs(local(made[0][0]) - local(made[-1][0])).max()) * 1000.0
    print("")
    print("  spread first vs last: %.2f mm max (local space)" % delta)
    if delta < 0.20:
        raise SystemExit("the extremes differ by %.2f mm -- the ramp did not"
                         " apply, do not read the strip as 'no effect'"
                         % delta)

    sc = bpy.context.scene
    dg = bpy.context.evaluated_depsgraph_get()
    ev = made[0][0].evaluated_get(dg)
    me = ev.to_mesh()
    top = max((made[0][0].matrix_world @ v.co).z for v in me.vertices)
    ev.to_mesh_clear()
    hz = top - 0.118
    light_scene(sc, hz)

    xs = [o.location.x for o, _ in made]
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = 300 * len(made)
    sc.render.resolution_y = 340
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
        raise SystemExit("the strip was not written to %s" % strip)
    print("  strip -> %s" % strip)

    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(args.out))
    print("  saved %s" % args.out)


if __name__ == "__main__":
    main()
