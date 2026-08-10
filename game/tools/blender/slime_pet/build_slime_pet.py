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

sys.path.insert(0, os.path.join(os.path.expanduser("~"), "motor-blender", "recetas"))
import use_size  # noqa: E402

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


# Vertices belonging to eye strokes, refilled per expression. Module level so the
# make_* functions keep their signatures; threading a set through six of them
# would have bought nothing.
DARK = set()


def add_eye_stroke(bm, side, radius, arc=0.30, height=0.32, thick=0.030,
                   dip=0.18, proud=0.012, n=13, squash=0.62):
    """The eye as REAL GEOMETRY laid on the dome, not a crease carved into it.

    Measured reason (2026-08-09): a carved crease is a diffuse valley and its
    contrast DIES on downscale. At 72 px -- the size a desktop pet actually is --
    the carved face vanished completely. A dark strip is a shape with hard edges,
    so it survives being made small, which is the only test that matters here.

    Follows the dome's curvature and sits fractionally proud of it, so it reads as
    a drawn line the way the anime frames do.
    """
    # settle_dome widens XY by 1/sqrt(squash) and compresses Z by squash, so the
    # body is an ELLIPSOID by the time strokes are added. The first version solved
    # for a sphere of the original radius and buried every stroke inside the mass:
    # the face vanished at every size. Third time today that a shape was assumed
    # instead of measured -- the rocks and the tendrils were the other two.
    widen = 1.0 / math.sqrt(squash)
    ax = radius * widen          # semi-axis X
    ay = radius * widen          # semi-axis Y (depth)
    az = radius * squash         # semi-axis Z
    cx = side * 0.46 * ax
    cz = height * az
    pts, rad = [], []
    for i in range(n):
        t = i / (n - 1)
        u = (t - 0.5) * 2.0                       # -1 .. 1 across the stroke
        x = cx + u * arc * ax
        z = cz - dip * az * (u * u)               # arcs down at the outer ends
        # Front surface of the ellipsoid at (x, z); clamp so the root stays real.
        q = (x / ax) ** 2 + (z / az) ** 2
        y = -ay * math.sqrt(max(1.0 - min(q, 0.999), 0.0))
        # Outward normal of an ellipsoid is (x/ax^2, y/ay^2, z/az^2), NOT the
        # position vector -- using the position is what a sphere lets you get away
        # with and an ellipsoid does not.
        nrm = Vector((x / (ax * ax), y / (ay * ay), z / (az * az)))
        if nrm.length > 1e-9:
            nrm.normalize()
        p = Vector((x, y, z)) + nrm * (proud * radius)
        pts.append(p)
        rad.append(thick * radius * (1.0 - 0.45 * abs(u)))    # tapers to the tips
    before = set(bm.verts)
    sweep_tube(bm, pts, rad, ring=6)
    DARK.update(set(bm.verts) - before)


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


def glyph_bm(char, height, depth=0.30, bevel=0.055, res=4):
    """A ? or ! taken from a REAL TYPEFACE, not drawn by hand.

    Joan, 2026-08-09: *"si buscás signo de interrogación en Internet te vas a dar
    cuenta que no son iguales... se entiende, pero se cerró, no se ve bien
    prolijo"*. He is right, and the fix is better than hunting for a picture: a
    question mark is not a shape to be guessed, it is a TYPOGRAPHIC form. The
    hand-rolled parametric hook curled too far and closed into a ring, which is
    exactly why it read as a coat hook.

    Blender's own text object carries the real outline. Extrude gives it body and
    a bevel rounds the edge so it reads as gel rather than as type. Uses the
    built-in font, so there is no external dependency and no font licence to
    worry about.

    Headless-safe: the mesh is pulled through the depsgraph
    (`new_from_object` on the evaluated object), never through `object.convert`,
    which needs an editor area.
    """
    curve = bpy.data.curves.new("glyph_" + char, type="FONT")
    curve.body = char
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    curve.extrude = depth * 0.5
    curve.bevel_depth = bevel
    curve.bevel_resolution = res
    ob = bpy.data.objects.new("glyph_" + char, curve)
    bpy.context.scene.collection.objects.link(ob)

    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg), depsgraph=dg)

    bm = bmesh.new()
    bm.from_mesh(me)
    bpy.data.meshes.remove(me)
    bpy.data.objects.remove(ob, do_unlink=True)
    bpy.data.curves.remove(curve)

    # The text object lies in XY with its normal along Z. Stand it up so it faces
    # the camera, then scale so its real height matches what the caller asked for.
    for v in bm.verts:
        v.co = Vector((v.co.x, -v.co.z, v.co.y))
    zs = [v.co.z for v in bm.verts]
    span = max(zs) - min(zs)
    if span > 1e-6:
        k = height / span
        for v in bm.verts:
            v.co *= k
    mid = (max(v.co.z for v in bm.verts) + min(v.co.z for v in bm.verts)) * 0.5
    for v in bm.verts:
        v.co.z -= mid
    return bm


def merge_bm(dst, src, offset=Vector((0.0, 0.0, 0.0)), mark_dark=False):
    """Copy src's geometry into dst at an offset. src is freed."""
    src.verts.ensure_lookup_table()
    made = [dst.verts.new(v.co + offset) for v in src.verts]
    for f in src.faces:
        try:
            dst.faces.new([made[v.index] for v in f.verts])
        except ValueError:
            pass
    if mark_dark:
        DARK.update(made)
    src.free()
    return made


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
        # A tumbler is what a short fat bar gives you. The glyph is TALL against
        # its dot -- roughly four dot-diameters -- with near-parallel sides.
        pts.append(Vector((0.0, 0.0, 1.42 * scale - t * 1.05 * scale)))
        rad.append(scale * (0.062 + 0.026 * t))
    return pts, rad


def add_ball(bm, centre, radius, segments=10):
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=segments // 2,
                              radius=radius,
                              matrix=__import__("mathutils").Matrix.Translation(centre))


def finalize(bm, name, scene):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.normal_update()
    # Snapshot the stroke coordinates BEFORE freeing the bmesh: a BMVert is dead
    # the moment bm.free() runs, and reading one afterwards raises
    # "BMesh data of type BMVert has been removed" -- which is exactly what the
    # first run of this version did.
    dark_co = {(round(v.co.x, 5), round(v.co.y, 5), round(v.co.z, 5))
               for v in DARK if v.is_valid}
    me = bpy.data.meshes.new(name + "_mesh")
    bm.to_mesh(me)
    bm.free()
    me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
    col = me.color_attributes.new(name="Col", type="FLOAT_COLOR", domain="POINT")
    zs = [v.co.z for v in me.vertices]
    z_lo, z_hi = min(zs), max(zs)
    for i, v in enumerate(me.vertices):
        key = (round(v.co.x, 5), round(v.co.y, 5), round(v.co.z, 5))
        if key in dark_co:
            col.data[i].color = (EYE_DARK[0], EYE_DARK[1], EYE_DARK[2], 1.0)
            continue
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
    """Body first, then strokes placed on the body that actually resulted."""
    bm = new_bm_sphere(BODY_R)
    settle_dome(bm, BODY_R, squash=squash)
    for side in (-1, 1):
        if squint_eyes:
            add_eye_stroke(bm, side, BODY_R, arc=0.24, height=0.34,
                           thick=0.034, dip=-0.26, squash=squash)   # strain
        else:
            add_eye_stroke(bm, side, BODY_R, squash=squash)
    return bm


def with_tendril(bm, kind, scale):
    """Register LEVE: the dome stays whole and the glyph GROWS OUT OF it.

    The anchor is computed from the mesh's real top, not assumed. The first pass
    placed the glyph at a fixed height and left 23 cm of air under it -- the same
    floating-geometry failure the rock work hit three times, for the same reason:
    a size that was modelled instead of measured.
    """
    top = max(v.co.z for v in bm.verts)
    char = "?" if kind == "question" else "!"
    g = glyph_bm(char, height=scale * 1.5, depth=0.26 * scale, bevel=0.048 * scale)
    g_lo = min(v.co.z for v in g.verts)
    # Seat the glyph's own bottom just inside the gel: measured off the glyph and
    # off the dome, never assumed. The previous version anchored a hand-drawn tail
    # and buried the dot inside the body, which is why the dot was never visible.
    merge_bm(bm, g, Vector((0.06 * scale, -0.05, top - g_lo - 0.06 * scale)))
    return bm


def make_hyperbole(kind, scale):
    """Register HIPERBOLE: there is no dome -- the body IS the glyph.

    Joan, 2026-08-09: for !!! and ??? the escalation has to be visible from the
    corner of the eye, and a small appendage cannot carry that. The face rides on
    the thickest part of the glyph so it still reads as the same creature.
    """
    bm = bmesh.new()
    char = "?" if kind == "question" else "!"
    # Fatter extrusion and a heavier bevel: at body scale the glyph has to read as
    # a gel mass, not as a letter someone stood up on the desk.
    # The camera frames a 0.5 m dome. A 1.6 m glyph overflowed it and cut off the
    # dot, which is the whole bottom half of both marks. Sized to the body's own
    # visual weight instead.
    g = glyph_bm(char, height=scale * 1.45, depth=0.55 * scale, bevel=0.085 * scale)
    merge_bm(bm, g)
    g_hi = max(v.co.z for v in bm.verts)
    if char == "?":
        face_r, face_h = scale * 0.46, g_hi * 0.58
    else:
        face_r, face_h = scale * 0.30, g_hi * 0.62
    # It has to stay the SAME creature, or the hyperbole reads as a prop someone
    # left on the desk. Two short strokes across the glyph's thickest span.
    for side in (-1, 1):
        add_eye_stroke(bm, side, face_r, arc=0.26,
                       height=face_h / face_r, thick=0.055, dip=0.16, n=9,
                       squash=1.0)
    return bm


def make_deflate(scene):
    """Melted: the mass gives up and spreads. Volume still conserved."""
    bm = new_bm_sphere(BODY_R)
    settle_dome(bm, BODY_R, squash=0.30, base_flat=-0.55)
    DEFLATE_SQUASH = 0.30
    for v in bm.verts:                      # eyes become flat resigned lines
        pass
    for side in (-1, 1):
        add_eye_stroke(bm, side, BODY_R, arc=0.26, height=0.20, thick=0.034,
                       dip=0.10, squash=DEFLATE_SQUASH)
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

# For a GAME asset the GLB is the product and EEVEE is the honest preview. Here
# the RENDER IS the product, so Cycles earns its cost: real contact shadow and gel
# translucency. The GTX 1080 sat idle through every previous pass.
# --factory-startup starts with the Cycles add-on DISABLED, so "CYCLES" is not in
# the engine enum and the previous run silently fell back to EEVEE while the log
# claimed otherwise. Enable it before asking.
try:
    import addon_utils
    addon_utils.enable("cycles", default_set=False, persistent=False)
except Exception as exc:
    print("[pet] could not enable cycles:", exc)

engines = scene.render.bl_rna.properties["engine"].enum_items.keys()
print("[pet] engines available:", list(engines))
if "CYCLES" in engines:
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 160
    scene.cycles.use_denoising = True
    try:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        for backend in ("OPTIX", "CUDA"):
            try:
                prefs.compute_device_type = backend
            except Exception:
                continue
            devs = prefs.get_devices_for_type(backend) or []
            if devs:
                for d in devs:
                    d.use = True
                scene.cycles.device = "GPU"
                print("[pet] cycles %s: %s" % (backend, [d.name for d in devs]))
                break
    except Exception as exc:
        print("[pet] GPU unavailable, cycles on CPU:", exc)
else:
    scene.render.engine = "BLENDER_EEVEE"
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
    DARK.clear()
    bm = fn(scene)
    obj = finalize(bm, "pet_" + key, scene)
    obj.data.materials.append(mat)
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    scene.render.filepath = os.path.join(REN_DIR, "pet_%s.png" % key)
    bpy.ops.render.render(write_still=True)
    print("[pet] %-16s verts=%4d tris=%4d  -> renders/pet_%s.png"
          % (key, len(obj.data.vertices), tris, key))

# THE BUILD IS ITS OWN GATE. A desktop pet lives at 72-120 px; the first pass was
# judged on a 512 px sheet where the eyes merely looked weak, and only a later
# check revealed the face vanishes entirely at real size. Under
# --python-exit-code 1 this raises and fails the build if the evidence cannot be
# produced, so no future pass can be judged at a flattering size by accident.
use_size.require_use_size(
    os.path.join(REN_DIR, "pet_idle.png"),
    sizes=[512, 200, 120, 72],
    out_path=os.path.join(REN_DIR, "_use_size.png"),
)

print("[pet] DONE")
