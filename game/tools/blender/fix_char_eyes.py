"""fix_char_eyes -- make the eyes visible, then measure whether they read.

THE FINDING THAT SHAPED THIS FILE: the warrior was not missing eyes. Measured
on char_warrior_male_mh_painted.blend:

    helper-l-eye   72 verts, bbox 27.6 x 29.3 x 27.6 mm, radius 14.9 mm
    painted        6 distinct colours, luminance 0.0225 (pupil) .. 0.7662 (sclera)
    centre spacing 61.5 mm  -- human adult IPD is 60-65 mm. Correct.
    body reaches   12.1 mm from the eye centre -- so the lids exist too.

The globes are modelled, painted with an iris, and correctly placed. They are
INVISIBLE because `MASK 'Hide helpers'` keeps only the `body` vertex group, and
the eyeballs are not in it. Nothing needed modelling; something needed showing.

WHAT THIS SCRIPT DOES
  1. Adds the eyeball and eyelash groups into `body` so the existing MASK lets
     them through. The mask itself is left alone -- it is doing its job for
     every other helper (sleeves, skirt, head cover), and turning it off is
     what produced the hooded contaminated render earlier today.
  2. Optionally protects the brows, which the thirds pass tinted yellow on top
     of brown and turned OLIVE GREEN. Any stamped zone must be named or the
     next pass paints over it.
  3. Measures IRIS COVERAGE, the metric fixed before building: what fraction
     of the iris disc survives once the lids occlude it.

WHY IRIS COVERAGE IS THE METRIC: in the Arthur close-up the upper lid cuts the
top of the iris. A fully round, fully visible iris is the single strongest
"doll" signal a face can give. Target is 0.75-0.85; 1.00 means nothing occludes
it and the globe is sitting on the face rather than in it.

It is measured, not eyeballed: the iris renders as pure magenta with everything
else flat grey, once with the head present and once with the head hidden. The
ratio of magenta pixels is the coverage.

    blender -b <painted.blend> --factory-startup --python-exit-code 1 \
        --python fix_char_eyes.py -- --out out.blend
"""
from __future__ import annotations

import argparse
import math
import os
import sys

import bpy
import numpy as np

EYE_GROUPS = ("helper-l-eye", "helper-r-eye")
LASH_GROUPS = ("helper-l-eyelashes-1", "helper-l-eyelashes-2",
               "helper-r-eyelashes-1", "helper-r-eyelashes-2")
BROW_CANDIDATES = ("brows", "eyebrows", "helper-l-eyebrow", "helper-r-eyebrow")

# The iris was stamped from #3A2415 -> linear. Anything on the globe darker
# than this counts as iris or pupil rather than sclera.
IRIS_LUM_MAX = 0.10


def verts_in(obj, names) -> set:
    gi = {g.name: g.index for g in obj.vertex_groups}
    want = {gi[n] for n in names if n in gi}
    if not want:
        return set()
    return {v.index for v in obj.data.vertices
            for ge in v.groups if ge.group in want and ge.weight > 0.01}


def reveal(obj, names, label: str) -> int:
    """Add `names` into the `body` group so the existing MASK passes them."""
    body = obj.vertex_groups.get("body")
    if body is None:
        raise SystemExit("no `body` vertex group -- the mask cannot be fed")
    idx = sorted(verts_in(obj, names))
    if not idx:
        print("      %-10s no vertices found for %s" % ("skip", label))
        return 0
    body.add(idx, 1.0, "REPLACE")
    print("      revealed %-9s %d verts -> group `body`" % (label, len(idx)))
    return len(idx)


def vertex_colours(me, attr_name="Col") -> np.ndarray:
    attr = me.color_attributes.get(attr_name)
    raw = np.empty(len(attr.data) * 4, dtype=np.float32)
    attr.data.foreach_get("color", raw)
    raw = raw.reshape(-1, 4)[:, :3].astype(np.float64)
    if attr.domain == "POINT":
        return raw
    n = len(me.vertices)
    lv = np.empty(len(me.loops), dtype=np.int32)
    me.loops.foreach_get("vertex_index", lv)
    s = np.zeros((n, 3))
    c = np.zeros(n)
    np.add.at(s, lv, raw)
    np.add.at(c, lv, 1.0)
    c[c == 0] = 1.0
    return s / c[:, None]


def flat_mat(name, rgb):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = (*rgb, 1.0)
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    return m


def measure_iris_coverage(obj, out_dir: str) -> float:
    """Fraction of the iris disc that survives lid occlusion.

    Two renders of the same camera: one as-is, one with every non-iris face
    pushed out of frame. Their magenta pixel counts divide.
    """
    me = obj.data
    vc = vertex_colours(me)
    eye_v = verts_in(obj, EYE_GROUPS)
    lum = vc.mean(axis=1)
    iris_v = {i for i in eye_v if lum[i] < IRIS_LUM_MAX}
    if not iris_v:
        raise SystemExit("no iris vertices found (nothing on the globe is"
                         " darker than %.2f) -- the metric cannot run"
                         % IRIS_LUM_MAX)

    me.materials.clear()
    me.materials.append(flat_mat("m_other", (0.30, 0.30, 0.30)))
    me.materials.append(flat_mat("m_iris", (1.0, 0.0, 1.0)))
    n_iris_faces = 0
    for poly in me.polygons:
        vs = list(poly.vertices)
        if sum(1 for v in vs if v in iris_v) * 2 > len(vs):
            poly.material_index = 1
            n_iris_faces += 1
        else:
            poly.material_index = 0
    if n_iris_faces == 0:
        raise SystemExit("iris vertices exist but no face has a majority of"
                         " them -- cannot measure")

    # Everything else leaves the scene. This blend ships 16 Cylinders, 2
    # Planes and 2 ref_posts; the first run rendered 0 iris pixels in BOTH
    # passes because something was parked in front of the camera.
    for o in list(bpy.data.objects):
        if o.type == "MESH" and o is not obj:
            bpy.data.objects.remove(o, do_unlink=True)

    # A second MASK isolates the iris for the unoccluded pass. The obvious
    # approach -- push the other vertices out of frame -- CANNOT WORK here:
    # this mesh carries 41 shape keys, and with shape keys present, writing
    # me.vertices.co never reaches the render (gotcha #2 in the motor recipe
    # paint_por_geometria.py). It fails silently, which is how the first run
    # produced two identical empty images.
    iso = obj.vertex_groups.new(name="_iris_only")
    iso.add(sorted(iris_v), 1.0, "REPLACE")
    iso_mod = obj.modifiers.new("iris only", "MASK")
    iso_mod.vertex_group = iso.name
    iso_mod.show_viewport = False
    iso_mod.show_render = False

    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = sc.render.resolution_y = 900
    sc.view_settings.view_transform = "Standard"
    sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0, 0, 0, 1)

    dg = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(dg)
    tmp = ev.to_mesh()
    mw = obj.matrix_world
    top = max((mw @ v.co).z for v in tmp.vertices)
    ev.to_mesh_clear()

    world = np.array([mw @ v.co for v in me.vertices])
    eye_c = world[sorted(eye_v)].mean(axis=0)

    cd = bpy.data.cameras.new("c")
    cam = bpy.data.objects.new("c", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cd.type = "ORTHO"
    cd.ortho_scale = 0.075
    cam.location = (eye_c[0], eye_c[1] - 1.0, eye_c[2])
    cam.rotation_euler = (math.radians(90), 0, 0)

    def count(path):
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        if not (os.path.isfile(path) and os.path.getsize(path) > 0):
            raise SystemExit("render did not write %s" % path)
        img = bpy.data.images.load(path)
        px = np.array(img.pixels[:]).reshape(-1, 4)
        bpy.data.images.remove(img)
        return int(((px[:, 0] > 0.6) & (px[:, 1] < 0.4)
                    & (px[:, 2] > 0.6)).sum())

    visible = count(os.path.join(out_dir, "iris_visible.png"))

    iso_mod.show_viewport = iso_mod.show_render = True
    bpy.context.view_layer.update()
    total = count(os.path.join(out_dir, "iris_total.png"))
    iso_mod.show_viewport = iso_mod.show_render = False
    bpy.context.view_layer.update()

    if total == 0:
        raise SystemExit("the unoccluded iris rendered 0 px -- the framing is"
                         " broken and the ratio would be meaningless")
    if visible > total:
        raise SystemExit("visible (%d) exceeds unoccluded (%d) -- the two"
                         " passes are not measuring the same thing"
                         % (visible, total))
    cov = visible / total
    print("\n      IRIS COVERAGE  %d / %d px = %.3f" % (visible, total, cov))
    print("      target 0.75-0.85 (upper lid must cut the top of the iris)")
    if cov > 0.95:
        print("      -> DOLL: nothing is occluding the iris.")
    elif cov < 0.55:
        print("      -> the lids are swallowing the eye.")
    else:
        print("      -> in range.")
    return cov


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", default="char_warrior_male_mh")
    ap.add_argument("--out", required=True)
    ap.add_argument("--no-lashes", action="store_true")
    ap.add_argument("--measure-dir", default=None,
                    help="write the iris-coverage renders here and report")
    args = ap.parse_args(argv)

    obj = bpy.data.objects.get(args.obj)
    if obj is None:
        raise SystemExit("no object %r" % args.obj)

    before = len(obj.evaluated_get(
        bpy.context.evaluated_depsgraph_get()).to_mesh().vertices)
    print("\n  evaluated verts before: %d (base %d)"
          % (before, len(obj.data.vertices)))

    reveal(obj, EYE_GROUPS, "eyeballs")
    if not args.no_lashes:
        reveal(obj, LASH_GROUPS, "lashes")

    found = [g for g in BROW_CANDIDATES if g in
             {vg.name for vg in obj.vertex_groups}]
    print("      brow groups present: %s" % (found or "NONE -- brows live in"
                                             " the body mesh, so protecting"
                                             " them needs a colour test, not"
                                             " a group"))

    bpy.context.view_layer.update()
    after = len(obj.evaluated_get(
        bpy.context.evaluated_depsgraph_get()).to_mesh().vertices)
    print("  evaluated verts after:  %d  (%+d)" % (after, after - before))
    if after <= before:
        raise SystemExit("the mask still hides them -- revealing did nothing")

    if args.measure_dir:
        os.makedirs(args.measure_dir, exist_ok=True)
        measure_iris_coverage(obj, args.measure_dir)

    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(args.out))
    print("  saved %s" % args.out)


if __name__ == "__main__":
    main()
