"""fix_face_features -- lashes, brow and lip, the three Joan called "raras".

Each fix is anchored to a measurement, not to taste.

1. LASHES -- REMOVE THEM
   They are a 250-vertex solid plate painted near-black, and they read as thick
   eyeliner. They are visible because I put them there: when the eyeballs were
   revealed, `helper-*-eyelashes-*` went into the `body` group alongside them
   without asking whether they belonged.

   They do not. Joan: "las pestanas son hilos" -- and MPFB's are a slab. At the
   Dark and Darker fidelity the refs establish, no individual lash is ever
   visible; the lid line is drawn by SHADOW. So the plate goes back under the
   mask and a thin dark line is painted along the lid edge instead. A painted
   line sits in the skin and cannot catch a highlight; a plate can, and did.

2. BROW -- NARROW THE BAND, IT IS INVADING THE EYELID
   paint_char_skin.py builds the brow as a falloff band:

       brow_z = eye_c[2] + head_h * 0.085      -> 21 mm above the eye centre
       bz     = falloff(|z - brow_z|, 0.011)   -> +/- 11 mm, a 22 mm TALL band

   The centre is right: the supraorbital arch measured 20.7 mm above the eye
   centre, so the band is aimed correctly. The WIDTH is the bug. A real brow is
   8-10 mm tall, and at 22 mm the lower edge lands 10 mm above the eye centre --
   below the top of the globe, which sits at 14.9 mm. That is why it covers the
   lid. Joan, correctly: the brow rides the BONE, never the moving lid.

3. LIP -- TOO TALL, AND MISSING ITS LANDMARKS
   Measured: 25.3 mm tall, 57.3 mm wide, against a male canon of 18-22 x ~50.
   Height comes down through MPFB dials, and cupid's bow plus philtrum go in --
   without them the mouth is an oval pad, which is exactly how it reads.

    blender -b <blend> --python-exit-code 1 --python fix_face_features.py -- \
        --out fixed.blend --strip strip.png

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

ATTR = "Col"
LASH_GROUPS = ("helper-l-eyelashes-1", "helper-l-eyelashes-2",
               "helper-r-eyelashes-1", "helper-r-eyelashes-2")

# Brow band, in metres. The original 0.011 half-width gave a 22 mm band whose
# lower edge sat BELOW the top of the globe (14.9 mm), which is why it covered
# the lid. Dropping to 0.005 overcorrected the other way -- 5 vertices, 2.1 mm,
# a pencil line. 0.009 with the centre lifted to 21 mm puts the band at roughly
# 15-27 mm above the eye centre: a real 10-12 mm brow that starts just clear of
# the globe. The control below asserts the clearance rather than trusting it.
BROW_HALF = 0.009
BROW_ABOVE_EYE = 0.021

# Lid line: a thin shadow along the upper lid edge, replacing the plate.
# 0.0 disables it. The painted lid line replaced the lash plate, but after the
# forehead band was subdivided it came out jagged and reads as grime sitting on
# the lid -- which is a good part of what Joan was calling "la ceja en el
# parpado". The lid shadow has to come from the eyefold geometry, not paint.
LID_LINE_HALF = 0.0

MOUTH_SET = {
    "mouth-upperlip-height-decr": 1.00,
    "mouth-lowerlip-height-decr": 0.85,
    "mouth-cupidsbow-incr": 0.70,     # the notch a mouth needs to read human
    "mouth-philtrum-volume-incr": 0.55,
    "mouth-trans-backward": 0.30,     # pull the pout in
}


def groups(obj):
    return {g.name: g.index for g in obj.vertex_groups}


def verts_in(obj, names) -> list:
    gi = groups(obj)
    want = {gi[n] for n in names if n in gi}
    if not want:
        return []
    return sorted({v.index for v in obj.data.vertices
                   for ge in v.groups
                   if ge.group in want and ge.weight > 0.01})


def hide_lashes(obj) -> int:
    """Take the lash plates back out of `body` so the mask hides them again."""
    body = obj.vertex_groups.get("body")
    idx = verts_in(obj, LASH_GROUPS)
    if body is None or not idx:
        print("      lashes: nothing to hide")
        return 0
    body.remove(idx)
    bpy.context.view_layer.update()
    print("      lashes: %d verts removed from `body` -> masked again"
          % len(idx))
    return len(idx)


def falloff(d, radius):
    t = np.clip(1.0 - d / radius, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def repaint_brow_and_lid(obj, brow_hex="#2A1F18", lid_hex="#3A2A20",
                         paint_brow=True) -> None:
    """Narrow brow on the arch, thin shadow line on the lid edge."""
    W, N = morphed_coords(obj)
    me = obj.data
    attr = me.color_attributes.get(ATTR)
    if attr is None:
        raise SystemExit("no %r colour attribute" % ATTR)

    eye_l = verts_in(obj, ("helper-l-eye",))
    eye_r = verts_in(obj, ("helper-r-eye",))
    if not eye_l or not eye_r:
        raise SystemExit("need both eye groups to anchor the brow")
    cl, cr = W[eye_l].mean(axis=0), W[eye_r].mean(axis=0)
    eye_z = 0.5 * (cl[2] + cr[2])
    eye_x = abs(cl[0])

    x, z = W[:, 0], W[:, 2]
    front = N[:, 1] < -0.30

    # BROW: same centre as before, a third of the width.
    brow_z = eye_z + BROW_ABOVE_EYE
    bz = falloff(np.abs(z - brow_z), BROW_HALF)
    bx = falloff(np.abs(np.abs(x) - eye_x) - 0.004, 0.026)
    brow = (bz * bx) * front > 0.18

    # LID LINE: a narrow band just above the globe top, where the lash plate
    # used to be. Painted into the skin, so it cannot catch a specular.
    lid_z = eye_z + 0.0125
    lz = falloff(np.abs(z - lid_z), LID_LINE_HALF)
    lid = ((lz * bx) * front > 0.30) if LID_LINE_HALF > 0 else np.zeros(len(me.vertices), dtype=bool)

    body = set(verts_in(obj, ("body",)))
    keep = np.zeros(len(me.vertices), dtype=bool)
    keep[list(body)] = True
    brow &= keep
    lid &= keep & ~brow

    def to_lin(h):
        h = h.lstrip("#")
        s = np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])
        return np.where(s <= 0.04045, s / 12.92, ((s + 0.055) / 1.055) ** 2.4)

    lv = np.empty(len(me.loops), dtype=np.int32)
    me.loops.foreach_get("vertex_index", lv)
    cols = np.empty(len(attr.data) * 4, dtype=np.float32)
    attr.data.foreach_get("color", cols)
    cols = cols.reshape(-1, 4)

    if paint_brow:
        sel = brow if attr.domain == "POINT" else brow[lv]
        cols[sel, :3] = to_lin(brow_hex).astype(np.float32)
    else:
        # Skip it on purpose. Painting a brow into the vertex colours only to
        # bake it and then erase it in texture space leaves a flat rectangular
        # patch where the erase ran -- visible as a lighter block around the
        # brow. Cleaner to never put it there: the brow is painted PER TEXEL
        # later, where it has the resolution to be an arch.
        brow = np.zeros(len(me.vertices), dtype=bool)
    sel = lid if attr.domain == "POINT" else lid[lv]
    cols[sel, :3] = to_lin(lid_hex).astype(np.float32)

    attr.data.foreach_set("color", cols.ravel())
    me.update()

    # CONTROL: the brow must sit entirely ABOVE the top of the globe, or it is
    # on the lid again -- which is the whole defect being fixed.
    if not brow.any():
        print('      brow: skipped (painted per texel later)')
        print('      lid line: %d verts' % int(lid.sum()))
        return
    bz_hit = z[brow]
    globe_top = eye_z + 0.0149
    print("      brow: %d verts, z %.4f..%.4f (%.1f mm tall)"
          % (int(brow.sum()), bz_hit.min(), bz_hit.max(),
             (bz_hit.max() - bz_hit.min()) * 1000))
    below = int((bz_hit < globe_top).sum())
    print("      [%s] %d brow verts below the globe top (want 0)"
          % ("OK" if below == 0 else "STILL ON THE LID", below))
    print("      lid line: %d verts" % int(lid.sum()))


def fix_mouth(obj, strength: float) -> None:
    for name, rel in MOUTH_SET.items():
        if not apply_target(obj, name, rel * strength):
            print("      MISSING %s" % name)
    bpy.context.view_layer.update()


# A male lip is slightly DARKER and redder than the surrounding skin. Measured
# on the warrior it was the opposite -- luminance 0.141 against skin 0.113 --
# which is why the mouth read as a pale pad stuck on the face rather than part
# of it. This value sits just under the skin it borders.
LIP_HEX = "#6E3A2E"


def repaint_lip(obj) -> None:
    """Recolour only the VISIBLE vermilion, darker than the skin around it.

    The `lips` vertex group holds 418 verts but only 244 face forward; the rest
    is interior mucosa reaching 25 mm back into the mouth. Painting the whole
    group puts lip colour on surfaces that are not lip, and on a mesh this
    coarse that bleeds outward into the visible silhouette.
    """
    W, N = morphed_coords(obj)
    me = obj.data
    attr = me.color_attributes.get(ATTR)
    lips = verts_in(obj, ("lips",))
    if not lips:
        raise SystemExit("no lips group")

    sel = np.zeros(len(me.vertices), dtype=bool)
    front = np.array([i for i in lips if N[i, 1] < -0.30])
    if len(front) < 20:
        raise SystemExit("only %d forward-facing lip verts" % len(front))
    sel[front] = True

    h = LIP_HEX.lstrip("#")
    s = np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])
    lin = np.where(s <= 0.04045, s / 12.92, ((s + 0.055) / 1.055) ** 2.4)

    lv = np.empty(len(me.loops), dtype=np.int32)
    me.loops.foreach_get("vertex_index", lv)
    cols = np.empty(len(attr.data) * 4, dtype=np.float32)
    attr.data.foreach_get("color", cols)
    cols = cols.reshape(-1, 4)
    mask = sel if attr.domain == "POINT" else sel[lv]
    cols[mask, :3] = lin.astype(np.float32)
    attr.data.foreach_set("color", cols.ravel())
    me.update()

    # CONTROL: the lip must end up DARKER than the skin, or the defect is
    # unchanged no matter how good the hex looked on paper.
    skin = np.array([c for i, c in enumerate(cols[:, :3])
                     if not mask[i]])
    lip_lum = float(lin.mean())
    skin_lum = float(skin.mean())
    print("      lip: %d visible verts (of %d in group) | lum %.3f vs skin"
          " %.3f  [%s]"
          % (len(front), len(lips), lip_lum, skin_lum,
             "OK darker" if lip_lum < skin_lum else "STILL LIGHTER"))


def lip_height(obj) -> float:
    W, _ = morphed_coords(obj)
    lips = verts_in(obj, ("lips",))
    P = W[lips]
    return float(P[:, 2].max() - P[:, 2].min()) * 1000.0


def skin_material():
    m = bpy.data.materials.new("skin")
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    vc = nt.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = ATTR
    nt.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
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
    ap.add_argument("--steps", type=int, default=4)
    ap.add_argument("--max-mouth", type=float, default=1.0)
    ap.add_argument("--no-brow", action="store_true",
                    help="leave the brow out; it will be painted per texel")
    ap.add_argument("--gap", type=float, default=0.28)
    args = ap.parse_args(argv)

    src = bpy.data.objects.get(args.obj)
    if src is None:
        raise SystemExit("no object %r" % args.obj)
    for o in list(bpy.data.objects):
        if o is not src:
            bpy.data.objects.remove(o, do_unlink=True)

    print("")
    print("  lip height before: %.1f mm  (male canon 18-22)" % lip_height(src))

    strengths = ([0.0] if args.steps < 2 else
                 [args.max_mouth * i / (args.steps - 1)
                  for i in range(args.steps)])
    mat = skin_material()
    made = []
    for i, s in enumerate(strengths):
        dup = src.copy()
        dup.data = src.data.copy()
        dup.name = "face_m%03d" % round(s * 100)
        dup.data.name = dup.name
        bpy.context.scene.collection.objects.link(dup)
        dup.location.x = (i - (len(strengths) - 1) / 2.0) * args.gap
        dup.data.materials.clear()
        dup.data.materials.append(mat)
        bpy.context.view_layer.update()
        print("    %s  (mouth %.2f)" % (dup.name, s))
        hide_lashes(dup)
        repaint_brow_and_lid(dup, paint_brow=not args.no_brow)
        repaint_lip(dup)
        fix_mouth(dup, s)
        print("      lip height now: %.1f mm" % lip_height(dup))
        made.append(dup)

    bpy.data.objects.remove(src, do_unlink=True)

    sc = bpy.context.scene
    dg = bpy.context.evaluated_depsgraph_get()
    ev = made[0].evaluated_get(dg)
    me = ev.to_mesh()
    top = max((made[0].matrix_world @ v.co).z for v in me.vertices)
    ev.to_mesh_clear()
    hz = top - 0.118
    light_scene(sc, hz)

    xs = [o.location.x for o in made]
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = 330 * len(made)
    sc.render.resolution_y = 380
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
        raise SystemExit("strip not written to %s" % strip)
    print("  strip -> %s" % strip)

    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(args.out))
    print("  saved %s" % args.out)


if __name__ == "__main__":
    main()
