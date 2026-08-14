"""char_warrior_male — anatomical base via MPFB2 (MakeHuman for Blender).

Replaces the primitive blockout. Joan's verdict on that one was correct and
worth quoting, because it is the reason this file exists:

    "en general la forma anatomica del cuerpo, como funcionan los musculos,
     grasa, articulaciones, no esta en el modelo. son bloques puestos en
     forma de humano"

Stacking ellipsoids cannot produce anatomy. A muscle originates and inserts on
different bones, crosses a joint, and thickens as it shortens; fat hangs in
masses that lag the skeleton; a joint is two surfaces sliding, with skin
creasing on the compressed side. None of that is reachable by joining cones.

Worse, the audit that passed the blockout was structurally blind to the
complaint: it measured widths at heights, and a cylinder and a real thigh of
equal width measure identically. So the numbers were true and useless.

MPFB2 solves the part that was never mine to sculpt -- muscle and fat are
parameters over an anatomically-correct mesh. What stays mine is making it land
on the canon: 1.80 m, the §5 landmarks, and the shoulder span the brief fixed.

    blender.exe --background --python gen_char_warrior_male_mh.py
"""

import importlib.util
import math
import os
import sys

import addon_utils
import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT_DIR = os.path.join(REPO, "game", "assets", "art", "characters")
RENDER_DIR = os.path.join(HERE, "_review_char_warrior_male_mh")

PLAYER_H = 1.80
SHOULDER_SPAN = 0.598
LANDMARKS = {
    "pie": 0.07, "rodilla": 0.50, "entrepierna": 0.90, "cintura": 1.10,
    "pecho": 1.32, "hombro": 1.47, "menton": 1.56, "tope": 1.80,
}

# Body dials, read straight off the decisions already taken.
#
#   muscle 0.86   "musculatura mas grande que lo normal" -- high, not maxed;
#                 1.0 is a bodybuilder, which is the look Joan rejected.
#   weight 0.62   the fat layer over the muscle. This is what keeps the
#                 abdomen smooth instead of segmented, and it is the single
#                 dial that separates the D2R reference from a gym body.
#   age    0.58   "veterano curtido" per _synthesis.md, not a youth.
#   proportions 0.42  below centre = less idealised, more common-bodied.
#
# race: MakeHuman's model is three coarse morph sliders, not an ethnography.
# The canon's cultural base is Andean/Mapuche, whose morphology sits nearest
# MPFB's "asian" morph in that crude model. The actual cultural identity is
# carried by the trarilonko and the palette, per _art_canon.md §6.1 -- not by
# a slider.
MACRO = {
    "gender": 1.0,
    "age": 0.58,
    "muscle": 0.86,
    "weight": 0.62,
    "proportions": 0.42,
    "height": 0.5,          # solved below
    "cupsize": 0.5,
    "firmness": 0.5,
    "race": {"asian": 0.60, "caucasian": 0.25, "african": 0.15},
}


def boot_mpfb():
    """MPFB installs as an extension, so its module is bl_ext.blender_org.mpfb.
    Its own internals import 'mpfb.*' absolutely, so alias it or they fail."""
    addon_utils.enable("bl_ext.blender_org.mpfb", default_set=True, persistent=True)
    import bl_ext.blender_org.mpfb as mpfb
    sys.modules["mpfb"] = mpfb


def eval_coords(obj):
    """World coordinates of the EVALUATED mesh.

    Reading obj.data.vertices returns the base mesh. In MPFB every macro --
    muscle, weight, height, proportions -- is a shape key, so the base mesh is
    the unmorphed body and none of the dials show up in it. Measuring it made
    the height solver report the same 1.6946 m for every parameter value and
    produced a shoulder span for a body that was never rendered. The render
    then clipped, because the real mesh is bigger than the one being measured.
    """
    dg = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(dg)
    me = ev.to_mesh()
    mw = ev.matrix_world
    out = [mw @ v.co for v in me.vertices]
    ev.to_mesh_clear()
    return out


def measured_height(obj):
    zs = [c.z for c in eval_coords(obj)]
    return max(zs) - min(zs)


def build_human(height_param):
    from mpfb.services.humanservice import HumanService
    for ob in list(bpy.data.objects):
        if ob.type in {"MESH", "ARMATURE", "EMPTY"}:
            bpy.data.objects.remove(ob, do_unlink=True)
    macro = dict(MACRO)
    macro["height"] = height_param
    return HumanService.create_human(macro_detail_dict=macro)


def solve_height():
    """Bisect MPFB's height morph until the mesh measures PLAYER_H.

    Using the morph rather than a uniform scale matters: a tall person is not
    a scaled short person -- limb-to-torso ratio shifts. The morph knows that;
    a scale factor does not. A final sub-centimetre scale lands it exactly.
    """
    lo, hi = 0.0, 1.0
    obj = None
    for i in range(7):
        mid = (lo + hi) / 2.0
        obj = build_human(mid)
        h = measured_height(obj)
        print("  altura: param %.4f -> %.4f m" % (mid, h))
        if abs(h - PLAYER_H) < 0.004:
            break
        if h < PLAYER_H:
            lo = mid
        else:
            hi = mid
    return obj


def normalise(obj):
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.update()

    zs = [c.z for c in eval_coords(obj)]
    obj.location.z -= min(zs)
    bpy.ops.object.transform_apply(location=True)
    bpy.context.view_layer.update()

    zs = [c.z for c in eval_coords(obj)]
    obj.scale = (PLAYER_H / max(zs),) * 3
    bpy.ops.object.transform_apply(scale=True)
    bpy.context.view_layer.update()
    return obj


def torso_width(obj, z, band=0.010, gap_tol=0.022):
    """Same centreline walk as the blockout audit, and it carries the same
    caveat: at chest height the arm crosses the ARMPIT, where arm and ribcage
    are one surface. Values there describe the silhouette, not the ribcage."""
    xs = sorted(abs(c.x) for c in eval_coords(obj) if abs(c.z - z) < band)
    if not xs:
        return 0.0
    edge = xs[0]
    for x in xs[1:]:
        if x - edge > gap_tol:
            break
        edge = x
    return edge


def audit(obj):
    co = eval_coords(obj)
    zs = [c.z for c in co]
    h = max(zs) - min(zs)
    head = LANDMARKS["tope"] - LANDMARKS["menton"]

    print("\n=== char_warrior_male (MPFB) — AUDIT ===")
    print("  vertices       %d" % len(co))
    print("  altura total   %.3f m   (objetivo %.2f, delta %+.3f)"
          % (h, PLAYER_H, h - PLAYER_H))
    print("  pies en z=0    %.3f m" % min(zs))
    print("  cabezas        %.2f     (canon 7.50)" % (h / head))

    # "Shoulder width" is the DELTOID span, and the deltoids sit below the
    # acromion. Sampling a single slice at the 1.47 landmark caught the
    # trapezius and neck instead and reported 0.256 m -- impossible on a
    # 1.80 m body. Take the widest slice in the shoulder region; above the
    # armpit the only geometry there is torso plus deltoid, because the arms
    # angle away downward.
    span = 2.0 * max(abs(c.x) for c in co if 1.36 <= c.z <= 1.50)
    print("\n  ancho hombro   %.3f m   (objetivo %.3f, delta %+.3f)"
          % (span, SHOULDER_SPAN, span - SHOULDER_SPAN))
    print("  (cuello a 1.47  %.3f m — control: debe ser mucho menor)"
          % (torso_width(obj, LANDMARKS["hombro"]) * 2.0))

    xs = sorted(abs(c.x) for c in co if abs(c.z - LANDMARKS["cintura"]) < 0.010)
    gap = max((b - a) for a, b in zip(xs, xs[1:])) if len(xs) > 1 else 0.0
    print("  luz brazo-torso %.3f m  (%s)"
          % (gap, "separado" if gap > 0.030 else "pegado — A-pose necesaria"))

    print("\n  dials: muscle %.2f · weight %.2f · age %.2f · proportions %.2f"
          % (MACRO["muscle"], MACRO["weight"], MACRO["age"], MACRO["proportions"]))
    return {"height": h, "span": span, "verts": len(obj.data.vertices)}


def bounds(obj):
    co = eval_coords(obj)
    return (min(c.x for c in co), max(c.x for c in co),
            min(c.z for c in co), max(c.z for c in co))


def stage_and_render(obj):
    """Reuse the blockout's lighting so the two are comparable, but FIT the
    cameras to the subject instead of inheriting hardcoded values.

    The blockout's camera constants were tuned for a figure with arms nearly
    at its sides. This body's A-pose spans about 1.5 m, and reusing those
    numbers clipped the head off every orthographic view. A frame that only
    works for one subject is not a review rig.
    """
    spec = importlib.util.spec_from_file_location(
        "blockout", os.path.join(HERE, "gen_char_warrior_male.py"))
    blockout = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(blockout)

    blockout.ref_post()
    blockout.setup_scene(obj)

    x0, x1, z0, z1 = bounds(obj)
    x1 = max(x1, 0.70)                      # keep the reference post in frame
    mid = (z0 + z1) / 2.0
    res_x, res_y = 760, 1000
    aspect = res_x / float(res_y)
    # ortho_scale maps to the LARGER render dimension, so the width budget is
    # scale*aspect. Solve for whichever axis needs more room.
    need = max((z1 - z0), (x1 - x0) / aspect) * 1.18

    os.makedirs(RENDER_DIR, exist_ok=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = res_x, res_y

    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam

    shots = [
        ("silhouette",    True,  need, (0.0, -4.0, mid), (90, 0, 0)),
        ("ortho_front",   True,  need, (0.0, -4.0, mid), (90, 0, 0)),
        ("ortho_profile", True,  need, (4.0, 0.0, mid), (90, 0, 90)),
        ("threequarter",  False, 50.0, (2.35, -3.05, mid + 0.62), (80, 0, 38)),
        ("player_eye",    False, 24.0, (0.9, -5.9, 1.65), (88.5, 0, 9)),
    ]

    for label, ortho, val, loc, rot in shots:
        cam_data.type = "ORTHO" if ortho else "PERSP"
        if ortho:
            cam_data.ortho_scale = val
        else:
            cam_data.lens = val
        cam.location = loc
        cam.rotation_euler = tuple(math.radians(a) for a in rot)

        # A silhouette shot is the SUBJECT alone. The earlier version left the
        # 30 m floor plane and the reference post in frame, so the alpha mask
        # touched every border and the clipping check could never come back
        # clean -- it was measuring the floor, not the body.
        hidden = []
        if label == "silhouette":
            for ob in bpy.data.objects:
                if ob.type == "MESH" and ob is not obj:
                    hidden.append((ob, ob.hide_render))
                    ob.hide_render = True
            sc.render.film_transparent = True
            sc.view_settings.view_transform = "Standard"
        else:
            sc.render.film_transparent = False
            sc.view_settings.view_transform = "AgX"

        sc.render.filepath = os.path.join(
            RENDER_DIR, "char_warrior_male_%s.png" % label)
        bpy.ops.render.render(write_still=True)

        for ob, was in hidden:
            ob.hide_render = was
    print("  encuadre: ortho_scale %.3f  centro z %.3f" % (need, mid))


def main():
    boot_mpfb()
    print("\n  resolviendo altura...")
    obj = normalise(solve_height())
    obj.name = "char_warrior_male_mh"

    stats = audit(obj)
    stage_and_render(obj)

    os.makedirs(OUT_DIR, exist_ok=True)
    blend = os.path.join(OUT_DIR, "char_warrior_male_mh.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend)
    print("\n  blend -> %s" % blend)
    return stats


if __name__ == "__main__":
    main()
