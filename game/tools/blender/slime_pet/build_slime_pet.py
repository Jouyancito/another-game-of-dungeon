# build_slime_pet.py -- desktop companion slime, expression set.
#
# A THIRD slime, deliberately distinct from the two in the game:
#   field slime   -- NO face (Joan's decision, 2026-07-30)
#   King Slime    -- face + crown INSIDE the body (canon: it swallowed the monarch)
#   THIS one      -- a desktop pet that reacts to what the session is doing
#
# Built FROM the references committed 2026-08-09 in
# game/docs/art/_references/slime_tensura/, not from memory of them. Two rules come
# straight out of those frames and decide the whole design:
#
#   1. THE BODY PERSISTS, THE SYMBOL IS ADDED. In the anime the question mark is a
#      thin gel TENDRIL rising off an intact dome, not the body deformed into a
#      glyph. Cheap, faithful, and composable -- one body, many appendages.
#
#   2. EXCEPT AT HYPERBOLE. Joan, same day: "no es solo generarlo pequeno arriba
#      por duda, es una hiperbole". For !!! (fright) and ??? (disbelief) the WHOLE
#      BODY becomes the glyph. The escalation between the two registers is the
#      expressiveness -- one register alone goes stale on a desktop in three days.
#
# Face vocabulary, also from the frames: two simple CURVED strokes for closed
# content eyes, a broken stroke for strain. Never pupils, teeth or a nose -- the
# toothed slime was already rejected (slime_teeth/, commit 5ebc7f1). Features are
# RELIEF in the gel read by their own shadow, never separate pieces.
#
# Run: blender --background --factory-startup --python-exit-code 1 --python build_slime_pet.py
import math
import os
import sys

import bmesh
import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(HERE, "renders")
os.makedirs(REN_DIR, exist_ok=True)

SEED = 20260809

# ---------------------------------------------------------------- palette ----
# FLOAT_COLOR is LINEAR (motor lesson, 2026-08-08: an sRGB-looking value renders
# near-white). These are linear values for the pale blue-white gel of the frames.
GEL_DEEP = (0.115, 0.185, 0.255)      # bottom of the mass, where light stops
GEL_MID = (0.300, 0.420, 0.520)
GEL_LIGHT = (0.560, 0.680, 0.760)     # top dome, catching the key
EYE_DARK = (0.030, 0.050, 0.080)      # carved stroke, reads as its own shadow

BODY_R = 0.50                          # metres -- a desk pet, not a mob


def lerp3(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def gel_tone(z, z_lo, z_hi):
    """Vertical gradient through the mass: dark base, lit crown."""
    t = (z - z_lo) / max(z_hi - z_lo, 1e-6)
    if t < 0.5:
        return lerp3(GEL_DEEP, GEL_MID, t * 2.0)
    return lerp3(GEL_MID, GEL_LIGHT, (t - 0.5) * 2.0)


# ------------------------------------------------------------------ mesh -----
def new_bm_sphere(radius, segments=56, rings=32):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=radius)
    return bm


def settle_dome(bm, radius, squash=0.62, base_flat=-0.34):
    """A gel mass at rest: squashed, wider than tall, flat where it meets the desk.

    Volume conservation is the hard rule from motion/_motion.md -- squashing Z
    must widen XY, or the thing reads as having lost mass rather than settled.
    """
    widen = 1.0 / math.sqrt(squash)
    for v in bm.verts:
        v.co.x *= widen
        v.co.y *= widen
        v.co.z *= squash
        floor = base_flat * radius
        if v.co.z < floor:
            # Flatten the contact patch instead of letting the sphere pass through
            # the surface it is sitting on.
            v.co.z = floor + (v.co.z - floor) * 0.12
    return bm


def eye_falloff(co, side, radius, arc=0.42, height=0.30, thickness=0.085):
    """Shared stroke field. carve_eye AND darken_eyes must use the SAME function,
    or the paint lands on vertices the carve never touched -- which is exactly how
    the first pass produced jagged dark blotches instead of two clean arcs."""
    if co.y > -0.15 * radius:
        return 0.0
    cx = side * 0.46 * radius
    cz = height * radius
    dx = (co.x - cx) / (arc * radius)
    dz = (co.z - cz) / radius
    curve = 0.16 * dx * dx
    d = math.hypot(dx * 0.55, (dz + curve) / thickness)
    return 0.0 if d > 1.0 else (1.0 - d) ** 2


def carve_eye(bm, side, radius, depth=0.055, arc=0.42, height=0.30, thickness=0.085):
    """Press a CURVED STROKE into the front of the dome -- a closed, content eye.

    The frames show two simple arcs and nothing else. Position follows the rule
    learned on the game slime (2026-07-30): sockets placed close together and low
    read as a snout, so these go WIDE and HIGH. `side` is -1 (left) or +1 (right).
    """
    for v in bm.verts:
        fall = eye_falloff(v.co, side, radius, arc, height, thickness)
        if fall <= 0.0:
            continue
        n = v.co.normalized()
        v.co -= n * (depth * radius * fall)


def squint(bm, side, radius, **kw):
    """A broken, tighter stroke -- strain or annoyance."""
    carve_eye(bm, side, radius, depth=kw.get("depth", 0.075),
              arc=0.30, height=0.34, thickness=0.070)


def sweep_tube(bm, points, radii, ring=8):
    """Sweep a circular profile along a polyline -- the gel tendril primitive.

    Built here rather than pulled from the motor because there is no second
    consumer yet; promote it to ~/motor-blender/recetas when one appears.
    """
    rings = []
    n = len(points)
    for i, (p, r) in enumerate(zip(points, radii)):
        if i == 0:
            tangent = (points[1] - points[0])
        elif i == n - 1:
            tangent = (points[-1] - points[-2])
        else:
            tangent = (points[i + 1] - points[i - 1])
        tangent.normalize()
        helper = Vector((0.0, 1.0, 0.0))
        if abs(tangent.dot(helper)) > 0.9:
            helper = Vector((1.0, 0.0, 0.0))
        u = tangent.cross(helper).normalized()
        w = tangent.cross(u).normalized()
        rings.append([bm.verts.new(p + (u * math.cos(a) + w * math.sin(a)) * r)
                      for a in [k * math.tau / ring for k in range(ring)]])
    for i in range(len(rings) - 1):
        a, b = rings[i], rings[i + 1]
        for k in range(ring):
            k2 = (k + 1) % ring
            try:
                bm.faces.new((a[k], a[k2], b[k2], b[k]))
            except ValueError:
                pass
    # Round the free end so the tendril does not read as a cut pipe.
    tip = points[-1] + (points[-1] - points[-2]).normalized() * radii[-1] * 0.9
    cap = bm.verts.new(tip)
    last = rings[-1]
    for k in range(ring):
        try:
            bm.faces.new((last[k], last[(k + 1) % ring], cap))
        except ValueError:
            pass
    first = rings[0]
    try:
        bm.faces.new(tuple(reversed(first)))
    except ValueError:
        pass


def question_path(scale, n=22):
    """Centre line of a question mark, in the XZ plane, drawn top-down."""
    pts, rad = [], []
    for i in range(n):
        t = i / (n - 1)
        ang = math.pi * (1.15 - 1.55 * t)          # hook over the top
        r = 0.42 * scale
        x = math.cos(ang) * r
        z = 0.72 * scale + math.sin(ang) * r * 0.86
        if t > 0.72:                                # tail drops toward the dot
            k = (t - 0.72) / 0.28
            x = math.cos(math.pi * (1.15 - 1.55 * 0.72)) * r * (1.0 - k) * 0.35
            z = 0.72 * scale + math.sin(math.pi * (1.15 - 1.55 * 0.72)) * r * 0.86 \
                - k * 0.46 * scale
        pts.append(Vector((x, 0.0, z)))
        rad.append(scale * (0.115 - 0.045 * t))     # tapers toward the tip
    return pts, rad


def bang_path(scale, n=12):
    """Centre line of an exclamation mark: a tapered vertical bar."""
    pts, rad = [], []
    for i in range(n):
        t = i / (n - 1)
        pts.append(Vector((0.0, 0.0, 1.10 * scale - t * 0.70 * scale)))
        # Nearly parallel sides with a slight swell: a cone reads as a spinning
        # top, which is what the first pass produced.
        rad.append(scale * (0.105 + 0.030 * t))
    return pts, rad


def add_ball(bm, centre, radius, segments=10):
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=segments // 2,
                              radius=radius,
                              matrix=__import__("mathutils").Matrix.Translation(centre))


def finalize(bm, name, scene):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.normal_update()
    me = bpy.data.meshes.new(name + "_mesh")
    bm.to_mesh(me)
    bm.free()
    me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
    col = me.color_attributes.new(name="Col", type="FLOAT_COLOR", domain="POINT")
    zs = [v.co.z for v in me.vertices]
    z_lo, z_hi = min(zs), max(zs)
    for i, v in enumerate(me.vertices):
        c = gel_tone(v.co.z, z_lo, z_hi)
        col.data[i].color = (c[0], c[1], c[2], 1.0)
    obj = bpy.data.objects.new(name, me)
    scene.collection.objects.link(obj)
    return obj


def darken_eyes(obj, radius, arc=0.42, height=0.30, thickness=0.085):
    """Deepen the carved strokes in vertex colour.

    The relief's own lit shadow is not enough on its own -- the key-lit eye stays
    visible and the fill-side one vanishes (learned on the game slime, 2026-07-30).
    """
    me = obj.data
    col = me.color_attributes["Col"]
    for i, v in enumerate(me.vertices):
        fall = max(eye_falloff(v.co, -1, radius, arc, height, thickness),
                   eye_falloff(v.co, 1, radius, arc, height, thickness))
        if fall <= 0.0:
            continue
        k = 1.0 - 0.72 * fall            # smooth, follows the same arc as the carve
        c = col.data[i].color
        col.data[i].color = (c[0] * k, c[1] * k, c[2] * k, 1.0)


# ------------------------------------------------------------ expressions ----
def make_idle(scene, squint_eyes=False, squash=0.62):
    bm = new_bm_sphere(BODY_R)
    settle_dome(bm, BODY_R, squash=squash)
    if squint_eyes:
        squint(bm, -1, BODY_R)
        squint(bm, 1, BODY_R)
    else:
        carve_eye(bm, -1, BODY_R)
        carve_eye(bm, 1, BODY_R)
    return bm


def with_tendril(bm, kind, scale):
    """Register LEVE: the dome stays whole and the glyph GROWS OUT OF it.

    The anchor is computed from the mesh's real top, not assumed. The first pass
    placed the glyph at a fixed height and left 23 cm of air under it -- the same
    floating-geometry failure the rock work hit three times, for the same reason:
    a size that was modelled instead of measured.
    """
    top = max(v.co.z for v in bm.verts)
    if kind == "question":
        pts, rad = question_path(scale)
        base_z = top - 0.18 * scale                 # sinks INTO the gel
        off = Vector((0.10, 0.0, base_z - pts[-1].z))
        sweep_tube(bm, [p + off for p in pts], rad)
        add_ball(bm, pts[-1] + off + Vector((0.0, 0.0, -0.16 * scale)), scale * 0.075)
    else:
        pts, rad = bang_path(scale)
        base_z = top - 0.14 * scale
        off = Vector((0.06, 0.0, base_z - pts[-1].z))
        sweep_tube(bm, [p + off for p in pts], rad)
        add_ball(bm, pts[-1] + off + Vector((0.0, 0.0, -0.17 * scale)), scale * 0.085)
    return bm


def make_hyperbole(kind, scale):
    """Register HIPERBOLE: there is no dome -- the body IS the glyph.

    Joan, 2026-08-09: for !!! and ??? the escalation has to be visible from the
    corner of the eye, and a small appendage cannot carry that. The face rides on
    the thickest part of the glyph so it still reads as the same creature.
    """
    bm = bmesh.new()
    if kind == "question":
        pts, rad = question_path(scale, n=26)
        rad = [r * 2.1 for r in rad]
        sweep_tube(bm, pts, rad, ring=12)
        add_ball(bm, Vector((0.02, 0.0, -0.10 * scale)), scale * 0.185, segments=14)
    else:
        pts, rad = bang_path(scale, n=14)
        rad = [r * 2.3 for r in rad]
        sweep_tube(bm, pts, rad, ring=12)
        add_ball(bm, Vector((0.0, 0.0, 0.22 * scale)), scale * 0.20, segments=14)
    return bm


def make_deflate(scene):
    """Melted: the mass gives up and spreads. Volume still conserved."""
    bm = new_bm_sphere(BODY_R)
    settle_dome(bm, BODY_R, squash=0.30, base_flat=-0.55)
    for v in bm.verts:                      # eyes become flat resigned lines
        pass
    carve_eye(bm, -1, BODY_R, depth=0.045, height=0.10, thickness=0.055)
    carve_eye(bm, 1, BODY_R, depth=0.045, height=0.10, thickness=0.055)
    return bm


def make_sweat(scene):
    bm = make_idle(scene, squint_eyes=True, squash=0.66)
    for (x, z, r) in ((-0.42, 0.46, 0.052), (0.40, 0.52, 0.044), (0.52, 0.30, 0.036)):
        add_ball(bm, Vector((x * BODY_R * 1.6, -0.30 * BODY_R, z * BODY_R * 1.6)),
                 r, segments=8)
    return bm


EXPRESSIONS = [
    ("idle",           lambda s: make_idle(s)),
    ("pleased",        lambda s: make_idle(s, squash=0.55)),
    ("question_soft",  lambda s: with_tendril(make_idle(s), "question", 0.34)),
    ("alert_soft",     lambda s: with_tendril(make_idle(s, squint_eyes=True), "bang", 0.34)),
    ("sweat",          make_sweat),
    ("deflate",        make_deflate),
    ("question_hyper", lambda s: make_hyperbole("question", 0.62)),
    ("alert_hyper",    lambda s: make_hyperbole("bang", 0.62)),
]


# ------------------------------------------------------------------ scene ----
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

mat = bpy.data.materials.new("mat_slime_pet")
mat.use_nodes = True
nt = mat.node_tree
bsdf = nt.nodes["Principled BSDF"]
attr = nt.nodes.new("ShaderNodeAttribute")
attr.attribute_name = "Col"
nt.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Roughness"].default_value = 0.18
if "IOR" in bsdf.inputs:
    bsdf.inputs["IOR"].default_value = 1.33


def sun(name, energy, color, rot):
    d = bpy.data.lights.new(name, type="SUN")
    d.energy = energy
    d.color = color
    o = bpy.data.objects.new(name, d)
    o.rotation_euler = rot
    scene.collection.objects.link(o)


sun("key", 2.6, (1.0, 0.97, 0.92), (math.radians(52), 0, math.radians(28)))
sun("fill", 1.1, (0.72, 0.82, 1.0), (math.radians(66), 0, math.radians(-124)))
sun("rim", 1.6, (0.88, 0.94, 1.0), (math.radians(112), 0, math.radians(190)))

world = bpy.data.worlds.new("w")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.06, 0.08, 1.0)

engines = scene.render.bl_rna.properties["engine"].enum_items.keys()
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
if hasattr(scene, "eevee") and hasattr(scene.eevee, "taa_render_samples"):
    scene.eevee.taa_render_samples = 96
scene.view_settings.view_transform = "Standard"
# Transparent film: a desktop pet has to sit on the user's wallpaper, not a card.
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.resolution_x = 512
scene.render.resolution_y = 512

cam_data = bpy.data.cameras.new("cam")
cam_data.lens = 62
cam = bpy.data.objects.new("cam", cam_data)
cam.location = (0.15, -2.35, 0.62)
cam.rotation_euler = (math.radians(83), 0.0, math.radians(4))
scene.collection.objects.link(cam)
scene.camera = cam

print("[pet] rendering %d expressions" % len(EXPRESSIONS))
for key, fn in EXPRESSIONS:
    for o in [o for o in scene.objects if o.type == "MESH"]:
        bpy.data.objects.remove(o, do_unlink=True)
    bm = fn(scene)
    obj = finalize(bm, "pet_" + key, scene)
    if key.endswith("_hyper"):
        # The glyph must still be the SAME creature, so the face rides on its
        # thickest part -- Joan's whole point about the hyperbole register.
        darken_eyes(obj, BODY_R * 0.62, arc=0.30, height=0.60, thickness=0.070)
    else:
        darken_eyes(obj, BODY_R)
    obj.data.materials.append(mat)
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    scene.render.filepath = os.path.join(REN_DIR, "pet_%s.png" % key)
    bpy.ops.render.render(write_still=True)
    print("[pet] %-16s verts=%4d tris=%4d  -> renders/pet_%s.png"
          % (key, len(obj.data.vertices), tris, key))

print("[pet] DONE")
