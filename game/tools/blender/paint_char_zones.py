"""paint_char_zones — colour a MPFB body by its OWN anatomy, not by guesswork.

Two corrections drove this file, both of them Joan's.

First: I claimed the mesh had no groups for nails or eyebrows. That came from a
regex over group NAMES, not from reading the 152 groups. `fingernails`,
`toenails` and `scalp` were there the whole time. A filtered view is not an
inventory.

Second, and bigger: he proposed overlaying a mesh that recreates the eyes with
the same shape. It turns out MPFB already ships it -- `helper-l-eye` and
`helper-r-eye` are real eyeball geometry, along with teeth, tongue and
eyelashes. A MASK modifier named "Hide helpers" was switching them off, and I
had accepted that default without looking. So no overlay is needed; the
features only had to stop being hidden.

Everything here is assigned by vertex-group membership -- the mesh's own
anatomical labelling -- so no feature is placed by typing a coordinate. That
distinction is the whole point: coordinate-placed face features are the
documented failure mode in this project.

    blender.exe -b <char.blend> --python paint_char_zones.py -- \
        --obj char_warrior_male_mh --skin "#A8724E" --out <dir>
"""

import argparse
import importlib.util
import math
import os
import sys

import bpy

# Everything that should render. The default mask shows only `body`, which is
# why the character had no eyes, no teeth and no lashes.
VISIBLE = [
    "body",
    "helper-l-eye", "helper-r-eye",
    "helper-upper-teeth", "helper-lower-teeth",
    "helper-l-eyelashes-1", "helper-l-eyelashes-2",
    "helper-r-eyelashes-1", "helper-r-eyelashes-2",
]

# Zone -> (colour, priority). Priority breaks ties when a face touches two
# groups: the more specific feature must win over the skin it sits in, or the
# lips get repainted as cheek.
ZONES = [
    ("eye_iris",  "#3A2415", 100),
    ("eye_white", "#E8E4DC",  90),
    ("lashes",    "#1A1512",  85),
    ("teeth",     "#DCD6C8",  80),
    ("lips",      "#8E5A48",  60),   # near the skin, not lipstick
    ("nails",     "#B98A6C",  55),
    ("nipple",    "#7A4436",  50),
    ("scalp",     "#241A14",  45),
    ("skin",      None,        0),
]

GROUP_TO_ZONE = {
    "lips": "lips",
    "fingernails": "nails",
    "toenails": "nails",
    "nipple": "nipple",
    "nippleTip": "nipple",
    "scalp": "scalp",
    "helper-upper-teeth": "teeth",
    "helper-lower-teeth": "teeth",
    "helper-l-eyelashes-1": "lashes",
    "helper-l-eyelashes-2": "lashes",
    "helper-r-eyelashes-1": "lashes",
    "helper-r-eyelashes-2": "lashes",
}
EYE_GROUPS = ("helper-l-eye", "helper-r-eye")


def load_toon():
    here = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location(
        "toonmod", os.path.join(here, "preview_char_toon.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def unmask(obj):
    """Point the mask at every group that should be visible.

    Rebuilding the mask's group rather than deleting the modifier keeps the
    rest of the helper geometry (skirt, tights, hair cap, joint cubes) hidden.
    Those are modelling aids and would render as sheets floating on the body.
    """
    vgs = {g.name: g for g in obj.vertex_groups}
    missing = [n for n in VISIBLE if n not in vgs]
    if missing:
        print("  aviso: grupos ausentes -> %s" % missing)

    vis = obj.vertex_groups.new(name="visible_render")
    wanted = {vgs[n].index for n in VISIBLE if n in vgs}
    idx = [v.index for v in obj.data.vertices
           if any(ge.group in wanted for ge in v.groups if ge.weight > 0.01)]
    vis.add(idx, 1.0, "REPLACE")
    print("  visibles: %d de %d verts" % (len(idx), len(obj.data.vertices)))

    for m in obj.modifiers:
        if m.type == "MASK":
            m.vertex_group = vis.name
            m.invert_vertex_group = False
    return vis


def face_zone(obj, poly, vgs, eye_axis):
    """Highest-priority zone touched by this face.

    Weight is read per-vertex against the named groups; a face is assigned the
    most specific zone any of its corners belongs to.
    """
    best, best_pri = "skin", -1
    for vi in poly.vertices:
        for ge in obj.data.vertices[vi].groups:
            if ge.weight <= 0.01:
                continue
            gname = vgs.get(ge.group)
            if gname in EYE_GROUPS:
                # The eyeball is a known sphere pointing along the character's
                # facing axis, so splitting sclera from iris uses the eye's OWN
                # geometry -- not a coordinate typed by hand.
                centre, fwd = eye_axis[gname]
                n = (obj.data.vertices[vi].co - centre)
                # 0.93 is a ~21 deg half-angle. The first pass used 0.80
                # (~37 deg), which wrapped the iris around most of the eyeball
                # and, with the dark lashes beside it, read as heavy eyeliner
                # rather than an eye.
                if n.length > 1e-6 and (n.normalized().dot(fwd)) > 0.93:
                    z, pri = "eye_iris", 100
                else:
                    z, pri = "eye_white", 90
            else:
                z = GROUP_TO_ZONE.get(gname)
                if z is None:
                    continue
                pri = dict((n_, p) for n_, _c, p in ZONES)[z]
            if pri > best_pri:
                best, best_pri = z, pri
    return best


def paint(obj, skin_hex, toonmod):
    vgs = {g.index: g.name for g in obj.vertex_groups}
    name_to_idx = {g.name: g.index for g in obj.vertex_groups}

    eye_axis = {}
    for gname in EYE_GROUPS:
        gi = name_to_idx.get(gname)
        if gi is None:
            continue
        pts = [v.co for v in obj.data.vertices
               if any(ge.group == gi and ge.weight > 0.01 for ge in v.groups)]
        centre = sum(pts, pts[0] * 0.0) / len(pts)
        # The character faces -Y, so the pupil is the -Y pole of the eyeball.
        fwd = (centre * 0.0)
        fwd.y = -1.0
        eye_axis[gname] = (centre, fwd)

    obj.data.materials.clear()
    slot = {}
    for zname, col, _pri in ZONES:
        mat = toonmod.toon_material("z_" + zname, col if col else skin_hex)
        obj.data.materials.append(mat)
        slot[zname] = len(obj.data.materials) - 1

    tally = {}
    for poly in obj.data.polygons:
        z = face_zone(obj, poly, vgs, eye_axis)
        poly.material_index = slot[z]
        tally[z] = tally.get(z, 0) + 1

    print("\n  caras por zona:")
    for zname, _c, _p in ZONES:
        print("    %-10s %6d" % (zname, tally.get(zname, 0)))
    return tally


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", required=True)
    ap.add_argument("--skin", default="#A8724E")
    ap.add_argument("--out", required=True)
    ap.add_argument("--look", default="dramatic", choices=("flat", "dramatic"))
    args = ap.parse_args(argv)

    toonmod = load_toon()
    obj = bpy.data.objects.get(args.obj)
    if obj is None:
        raise SystemExit("no existe %r" % args.obj)

    unmask(obj)
    paint(obj, args.skin, toonmod)

    # Conservar el pelo: es un objeto aparte y borrarlo dejaria al personaje
    # pelado justo en el render que viene a juzgar el pelo.
    for ob in list(bpy.data.objects):
        if ob is obj or "hair" in ob.name.lower():
            continue
        if ob.type in {"MESH", "LIGHT", "CAMERA"}:
            bpy.data.objects.remove(ob, do_unlink=True)

    # Lighting from _references/pixelart_painterly_mmo: "base muy oscura +
    # fuentes de luz de color saturado que hacen todo el trabajo... la silueta
    # se lee por CONTRALUZ, no por su textura." The flat look Joan rejected was
    # not a texture problem -- an even area light on a neutral grey-blue world
    # flattens anything, and a 3-band ramp needs a real terminator to band.
    def lamp(kind, loc, rot, energy, size, colour):
        bpy.ops.object.light_add(type=kind, location=loc)
        L = bpy.context.object
        L.data.energy = energy
        L.data.color = colour
        if hasattr(L.data, "size"):
            L.data.size = size
        L.rotation_euler = tuple(math.radians(a) for a in rot)
        return L

    world = bpy.data.worlds.new("w")
    bpy.context.scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]

    if args.look == "flat":
        lamp("AREA", (2.0, -2.8, 2.9), (48, 0, 34), 620, 3.0, (1, 1, 1))
        lamp("AREA", (-2.2, -2.2, 1.8), (66, 0, -46), 150, 4.0, (1, 1, 1))
        bg.inputs[0].default_value = (0.07, 0.08, 0.10, 1)
        bg.inputs[1].default_value = 0.35
    else:
        # TWO lights, not four. toon_basic.gdshader line 52 accumulates
        # DIFFUSE_LIGHT per light, so every extra lamp adds another set of
        # bands and washes the banding flat. The first "dramatic" rig had key
        # + two rims + bounce and came out FLATTER than the even light it was
        # meant to replace -- more lamps is the opposite of more drama here.
        #
        # KEY: warm, steep and well off-axis, so a real terminator crosses the
        # body and the ramp has something to band.
        lamp("AREA", (2.9, -1.6, 2.9), (58, 0, 62), 1100, 1.6, (1.00, 0.70, 0.38))
        # CONTRALUZ: cool, behind and high. With the rim now gated by the lit
        # side, this is what draws the silhouette as a bright edge.
        lamp("AREA", (-1.6, 2.9, 2.5), (122, 0, -152), 2200, 1.2, (0.40, 0.68, 1.00))
        # Near-black ground: the reference's saturated lights only read as
        # saturated against darkness.
        bg.inputs[0].default_value = (0.020, 0.024, 0.035, 1)
        bg.inputs[1].default_value = 0.55

    x0, x1, z0, z1 = toonmod.eval_bounds(obj)
    mid = (z0 + z1) / 2.0

    # Frame from the anatomy, not from typed numbers. The first pass guessed
    # a hand position and rendered an empty frame, and guessed a face height
    # that cropped the skull. Both landmarks exist as vertex groups, so ask
    # the mesh where they are.
    def morphed_coords():
        """Per-vertex world coords WITH the macro shape keys applied, indexed
        like the base mesh so vertex groups still address them.

        This is the shape-key trap a second time. The measurement path was
        already fixed to read the evaluated mesh; the camera path was written
        fresh against obj.data.vertices and inherited the same blindness, so
        the eye landmark came back at its UNMORPHED height and the close-up
        framed the chest. The MASK has to come off first -- it deletes
        vertices, and then evaluated indices no longer match the groups.
        """
        states = [(m, m.show_viewport) for m in obj.modifiers if m.type == "MASK"]
        for m, _ in states:
            m.show_viewport = False
        bpy.context.view_layer.update()
        dg = bpy.context.evaluated_depsgraph_get()
        ev = obj.evaluated_get(dg)
        me = ev.to_mesh()
        mw = ev.matrix_world
        co = [mw @ v.co for v in me.vertices]
        ev.to_mesh_clear()
        for m, was in states:
            m.show_viewport = was
        bpy.context.view_layer.update()
        return co

    MCO = morphed_coords()
    if len(MCO) != len(obj.data.vertices):
        print("  aviso: indices no alinean (%d vs %d) — cae a malla base"
              % (len(MCO), len(obj.data.vertices)))
        MCO = [obj.matrix_world @ v.co for v in obj.data.vertices]

    def group_centre(gname):
        gi = {g.name: g.index for g in obj.vertex_groups}.get(gname)
        if gi is None:
            return None
        pts = [MCO[v.index] for v in obj.data.vertices
               if any(ge.group == gi and ge.weight > 0.01 for ge in v.groups)]
        return sum(pts, pts[0] * 0.0) / len(pts) if pts else None

    eyec = group_centre("helper-l-eye") or group_centre("helper-r-eye")
    face_z = eyec.z if eyec else z0 + (z1 - z0) * 0.92

    ngi = {g.name: g.index for g in obj.vertex_groups}.get("fingernails", -1)
    nails = [MCO[v.index] for v in obj.data.vertices
             if any(ge.group == ngi and ge.weight > 0.01 for ge in v.groups)]
    right = [c for c in nails if c.x > 0]
    hand = (sum(right, right[0] * 0.0) / len(right)) if right else None
    print("  encuadre: ojo z=%.3f  mano=%s"
          % (face_z, tuple(round(c, 3) for c in hand) if hand else "no hallada"))

    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "Standard"

    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam

    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)

    head_top = z1
    shots = [
        # Pull back far enough to hold the whole skull: the eye sits well
        # below the crown, so centring on it and staying close cropped the head.
        ("cara",  "PERSP", 62.0, (0.0, -1.30, face_z - 0.02), (90, 0, 0), 560, 660),
        ("cara34", "PERSP", 62.0, (0.62, -1.15, face_z - 0.02), (90, 0, 28), 560, 660),
        ("cuerpo", "ORTHO", None, (0.0, -4.0, mid), (90, 0, 0), 560, 900),
    ]
    if hand:
        shots.append(("mano", "PERSP", 90.0,
                      (hand.x + 0.10, hand.y - 0.34, hand.z + 0.06),
                      (84, 0, 16), 560, 480))
    for label, kind, val, loc, rot, rx, ry in shots:
        sc.render.resolution_x, sc.render.resolution_y = rx, ry
        cam_data.type = kind
        if kind == "ORTHO":
            cam_data.ortho_scale = max((z1 - z0), (x1 - x0) / (rx / float(ry))) * 1.10
        else:
            cam_data.lens = val
        cam.location = loc
        cam.rotation_euler = tuple(math.radians(a) for a in rot)
        sc.render.filepath = os.path.join(out, "zones_%s.png" % label)
        bpy.ops.render.render(write_still=True)

    print("\n  piel %s -> %s" % (args.skin, out))
    for f in sorted(os.listdir(out)):
        print("    %s" % f)


if __name__ == "__main__":
    main()
