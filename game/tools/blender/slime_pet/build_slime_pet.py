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
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.join(os.path.expanduser("~"), "motor-blender", "recetas"))
import use_size  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(HERE, "renders")
os.makedirs(REN_DIR, exist_ok=True)

SEED = 20260809

# --style=gel|toon, and --lookdev to render a handful of frames for an A/B look
# instead of the whole set. Args come after Blender's own `--`.
_argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
# CEL is the shipping look. Joan, 2026-08-10: *"porque al estar en una pantalla
# 2d, como escritorio, no necesita profundidad, el otro me parece mas para el
# tema de juego porque lo podrias imaginar en 3d."* The distinction is the useful
# part and it is not about taste: this pet lives on a flat screen at a fixed
# camera, where depth buys nothing and hard shapes buy legibility at 72 px. The
# PBR gel path is kept, not deleted, because it is the direction for the GAME
# slime -- there the camera moves and the light changes, and depth is the point.
STYLE = "gel" if "--style=gel" in _argv else "toon"
LOOKDEV = "--lookdev" in _argv
LOOKDEV_FRAMES = [0, 10, 17, 22]

# ---------------------------------------------------------------- palette ----
# FLOAT_COLOR is LINEAR (motor lesson, 2026-08-08: an sRGB-looking value renders
# near-white). These are linear values for the pale blue-white gel of the frames.
# Saturated on purpose, and deeper than they "look right" when picked in
# isolation. The rig multiplies albedo up hard, and the first blue-grey set
# rendered as wet concrete -- the same mistake the game slime recorded on
# 2026-07-30 (albedo picked as if it were the final screen colour came out pale
# mint). Tensura's slime is a SATURATED pale blue, not a grey one.
# Tuned for the CEL look, which is the one that ships (Joan, 2026-08-10). Under
# cel the bands supply the lighting, so the albedo has to stay a readable light
# blue across the whole body -- the deep saturated set these replaced was picked
# for a PBR rig that multiplied it up, and under flat bands it crushed the lower
# half to mud. The vertical gradient's job here is subtle: the bright thin edge
# is carried by the Fresnel crescent, not by the albedo.
GEL_GLOW_LOW = (0.400, 0.680, 0.920)  # the THIN lower edge -- light gets through
GEL_DEEP = (0.200, 0.440, 0.740)      # the dense middle, where the mass is thickest
GEL_LIGHT = (0.300, 0.560, 0.840)     # upper dome
GEL_MID = GEL_DEEP                    # kept: the expression builders name it

TOON_BUBBLE = (0.52, 0.78, 0.97, 1.0)   # a drawn shape, one tone step lighter
TOON_SHADE = (0.070, 0.220, 0.520, 1.0)  # cool HUE shift, not a value crush
TOON_CRESCENT = (0.46, 0.80, 1.0, 1.0)   # the thin edge light crosses
EYE_DARK = (0.030, 0.050, 0.080)      # carved stroke, reads as its own shadow

BODY_R = 0.50                          # metres -- a desk pet, not a mob


def lerp3(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def gel_tone(z, z_lo, z_hi):
    """Vertical gradient for a TRANSLUCENT mass -- brightest at the bottom.

    This was upside down for three passes and it is most of why the creature kept
    reading as a balloon. Dark base and lit crown is how a SOLID is shaded: the
    underside receives less light, so it goes dark. A translucent mass does the
    opposite. Its lower edge is the THINNEST part, light crosses it and comes back
    out, so that edge is the brightest and most saturated thing on the body -- a
    gummy sweet on a table, glowing along the line where it meets the surface.

    Painting solid-object shading into a material that is trying to be gel is a
    contradiction no amount of subsurface or Fresnel can win against, because the
    albedo says "opaque" louder than the shader says "translucent".
    """
    t = (z - z_lo) / max(z_hi - z_lo, 1e-6)
    if t < 0.35:
        return lerp3(GEL_GLOW_LOW, GEL_DEEP, t / 0.35)
    return lerp3(GEL_DEEP, GEL_LIGHT, (t - 0.35) / 0.65)


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

# Vertices belonging to shed gel. Tinted deeper than the body they hang off, so a
# drip is a VALUE step and not just a change of curvature -- curvature alone is
# read by the light, and light-read detail is exactly what dies on downscale.
WET = set()

# Vertices belonging to beads that CLING (sweat). Tinted DEEPER, the opposite of
# WET, and the difference is not a contradiction: contrast is against the LOCAL
# tone, never a fixed direction. Shed gel hangs off the dark underside, so it has
# to brighten; sweat sits high on the lit dome, so brightening it merged it with
# the cel highlight and it read as one more glint instead of a drop.
BEAD = set()


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
    wet_co = {(round(v.co.x, 5), round(v.co.y, 5), round(v.co.z, 5))
              for v in WET if v.is_valid}
    bead_co = {(round(v.co.x, 5), round(v.co.y, 5), round(v.co.z, 5))
               for v in BEAD if v.is_valid}
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
        if key in wet_co:
            # BRIGHTER than the mass it left, not darker. The drip hangs off the
            # lip and lives against the body's own underside, which is the dark
            # end of the gradient -- tinting it deeper (the first thing tried)
            # buried it in exactly the tone it needed to separate from. A wet bead
            # catching light on a shadowed belly is also how the frames draw it.
            c = lerp3(c, GEL_LIGHT, 0.55)
        elif key in bead_co:
            c = lerp3(c, GEL_DEEP, 0.55)
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


# ------------------------------------------------------------------ drips ----
# Joan, closing the 2026-08-09 session: "me gustaria que igual se sintiera como
# viscoso, esa textura de que esta goteando... si no, no se siente como un slime
# vivo, se siente como una imagen nomas que hace una animacion".
#
# Reading that as a texture note would waste the pass. What separates a living
# creature from a drawing that moves is SECONDARY MOTION: the body moves, and shed
# material arrives LATE, on its own timing. So a drip here is geometry with its
# OWN phase, and that phase reads the body's shape from a few frames ago -- never
# the body's current keyframe.
#
# WHERE the drip lives was measured, not assumed. This body is a squashed dome
# sitting on a desk: rim at z = -0.116 m, ground at z = -0.187 m, so a drop that
# detaches at the rim falls 7 cm inside a 1.36 m frame -- 5% of the picture, and
# nothing at all once the pet is 72 px wide. A detach-and-fall drip is not
# available on this silhouette. What IS available is the way gel actually behaves
# on a dome: it beads high on the FRONT FACE, runs down, necks at the rim, lets go
# and merges into a foot pool. That path is ~24 cm and it is silhouetted against
# the lit body the whole way down.
SHED_LAG = 0.075                        # loop fractions the shed gel lags the body by
G = 6.0                                 # m/s^2 -- heavier than a water droplet on
                                        # purpose: this is gel, and _motion.md is
                                        # explicit that the creature is torpe.

WORLD_BASIS = (Vector((1.0, 0.0, 0.0)), Vector((0.0, 1.0, 0.0)),
               Vector((0.0, 0.0, 1.0)))


def body_axes(squash):
    """Semi-axes of the body AFTER settle_dome. Same widen rule, one source."""
    widen = 1.0 / math.sqrt(squash)
    return BODY_R * widen, BODY_R * widen, BODY_R * squash


def body_ground(squash, base_flat=-0.34):
    """Where the contact patch ends up -- settle_dome's own arithmetic, replayed.

    Recomputed rather than hardcoded because the body deforms every frame: a
    constant here drops splats through the desk on half the cycle.
    """
    floor = base_flat * BODY_R
    return floor + (-BODY_R * squash - floor) * 0.12


# The desk does not move. settle_dome's clamp lands the underside at a height that
# depends on the CURRENT squash, so letting each frame define its own floor slides
# the whole creature up and down as it breathes -- and drops every splat onto a
# different plane. One constant, and every frame is placed against it.
DESK_Z = body_ground(0.62)


def viscous(signal, t, lag=SHED_LAG):
    """Read a shape signal LATE, and let it go PAST -- viscous lag with overshoot.

    A pure delay only makes the gel late; it still tracks the body exactly, one
    beat behind, which is how a rigid body on a delay line moves. Extrapolating
    from two delayed samples also makes it overshoot and settle, and _motion.md
    records that overshoot as the thing separating gel from a painted solid.

    This is the single line that decides whether the creature reads as alive. The
    body follows `signal(t)`; everything it sheds or wears follows THIS.
    """
    a = signal(t - lag)
    b = signal(t - 2.0 * lag)
    return max(0.20, min(1.30, a + 0.35 * (a - b)))


def surf_point(ax, ay, az, theta, phi):
    return Vector((ax * math.cos(phi) * math.cos(theta),
                   ay * math.cos(phi) * math.sin(theta),
                   az * math.sin(phi)))


def surf_frame(ax, ay, az, theta, phi):
    """Position, outward normal and down-slope tangent on the body's surface.

    The outward normal of an ellipsoid is (x/ax^2, y/ay^2, z/az^2), NOT the
    position vector -- the same trap add_eye_stroke documents, and the reason a
    bead placed with the position vector floats off the surface at the flanks.

    Used by anything that CLINGS to the body rather than flying off it: the sweat
    drops today, and the idle drips before movement took that job over.
    """
    p = surf_point(ax, ay, az, theta, phi)
    n = Vector((p.x / (ax * ax), p.y / (ay * ay), p.z / (az * az)))
    if n.length > 1e-9:
        n.normalize()
    d = Vector((-ax * math.sin(phi) * math.cos(theta),
                -ay * math.sin(phi) * math.sin(theta),
                az * math.cos(phi)))
    t = -d                               # decreasing phi is downhill
    t -= n * t.dot(n)                    # keep it tangent after the flip
    if t.length > 1e-9:
        t.normalize()
    return p, n, t


def basis_from(direction):
    """Orthonormal frame whose LAST axis is `direction`. add_blob stretches along
    its third axis, so this is what points a droplet along its own velocity."""
    n = direction.normalized()
    helper = Vector((0.0, 0.0, 1.0))
    if abs(n.dot(helper)) > 0.9:
        helper = Vector((1.0, 0.0, 0.0))
    t = n.cross(helper).normalized()
    b = n.cross(t).normalized()
    return (t, b, n)


def add_blob(bm, centre, basis, scale, segments=12):
    """An oriented ellipsoid: unit sphere through a (tangent, binormal, normal)
    frame. A droplet has to lie ALONG its velocity, so an axis-aligned squash is
    not enough."""
    t, b, n = basis
    rot = Matrix(((t.x, b.x, n.x),
                  (t.y, b.y, n.y),
                  (t.z, b.z, n.z))).to_4x4()
    m = (Matrix.Translation(centre) @ rot
         @ Matrix.Diagonal(Vector((scale[0], scale[1], scale[2], 1.0))))
    bmesh.ops.create_uvsphere(bm, u_segments=segments,
                              v_segments=max(segments // 2, 4),
                              radius=1.0, matrix=m)


# --------------------------------------------------------------------- hop ----
# Joan, 2026-08-10: "quizas el tema de las gotas pueda ser efecto de cuando se
# mueve, mas que siempre en todo momento."
#
# That settles a problem three passes of idle drips could not, and the geometry
# says why he is right. AT REST this body has nowhere to drip from: it is widest
# at radius 0.635 m and its contact patch is 0.531 m, so there is 10 cm of
# overhang and 18 cm of air under the lip -- while a drop that still reads at
# 72 px has to be ~11 cm across. It does not fit, and below the equator the
# surface curves back inward, so a pendant hung there is inside the creature.
# Measured three ways; every idle drip read as an ear, an egg or a wart.
#
# IN THE AIR the whole frame is clearance. It is also the physically true moment:
# the reference sheet's leap frame (_leap_aggressive.png) shows droplets thrown
# off BEHIND a fast-moving body, and the standing rule from those same frames is
# that deformation scales with inertia. Gel is shed where there is acceleration,
# so this cycle sheds at exactly the two moments that have any -- the launch,
# where the mass is thrown up and the surface is left behind, and the impact,
# where the mass stops dead and the surface keeps going.
HOP_CROUCH, HOP_LAUNCH, HOP_LAND = 0.20, 0.30, 0.70
HOP_HEIGHT = 0.38


def hop_height(t):
    """Ballistic arc, zero at both ends so the loop closes back on the desk."""
    t = t % 1.0
    if t < HOP_LAUNCH or t >= HOP_LAND:
        return 0.0
    k = (t - HOP_LAUNCH) / (HOP_LAND - HOP_LAUNCH)
    return HOP_HEIGHT * 4.0 * k * (1.0 - k)


def hop_squash(t):
    """The DRIVEN shape. What gets built is this, read through viscous().

    Squash > 1 is taller than wide, < 1 flatter -- settle_dome's widen rule
    conserves volume either way, which is the hard rule from _motion.md: a mass
    that flattens MUST spread, or it reads as having lost material.
    """
    t = t % 1.0
    if t < HOP_CROUCH:                          # anticipation: gather and flatten
        k = t / HOP_CROUCH
        return 0.62 - 0.16 * k * k
    if t < HOP_LAUNCH:                          # extension: throw the mass upward
        k = (t - HOP_CROUCH) / (HOP_LAUNCH - HOP_CROUCH)
        return 0.46 + 0.62 * k
    if t < HOP_LAND:
        # Airborne. The shape follows the VELOCITY, not the height: stretched
        # leaving the ground, round at the apex where velocity is zero, stretched
        # again on the way down. Keying it to height instead is the classic
        # mistake that makes a jump read as a balloon on a string.
        k = (t - HOP_LAUNCH) / (HOP_LAND - HOP_LAUNCH)
        return 0.85 + 0.35 * abs(1.0 - 2.0 * k) ** 1.4
    # Impact, then a decaying wobble back to rest. The step down from the falling
    # stretch is meant to be one frame -- an impact IS instantaneous, and viscous()
    # spreads it over about three frames by itself.
    k = (t - HOP_LAND) / (1.0 - HOP_LAND)
    return 0.62 - 0.20 * math.cos(math.tau * 1.5 * k) * math.exp(-3.2 * k)


def shed_burst(t0, count, speed, out_z, r0, up, lat):
    """One burst of droplets, thrown from the rim of the body as it is at t0.

    Azimuths cover the FRONT 200 degrees rather than a full circle: droplets
    thrown backwards sit behind the body and cost geometry to render nothing.
    They are also unevenly spaced -- an even ring reads as a sprinkler, not as
    material torn off a surface.
    """
    s = viscous(hop_squash, t0)
    ax, _, az = body_axes(s)
    ground = DESK_Z
    centre_z = DESK_Z + hop_height(t0) + az     # the body is placed by its underside
    base_z = centre_z + out_z * az
    out = []
    for i in range(count):
        f = i / max(count - 1, 1)
        ang = math.radians(-178.0 + 200.0 * f + 11.0 * math.sin(i * 2.4))
        wob = 0.78 + 0.44 * abs(math.sin(i * 1.7))      # deterministic, seedless
        # `lat` is what keeps a droplet from reading as a flat lentil. A drop is
        # stretched along its OWN velocity, so a nearly horizontal throw draws a
        # pill lying on its side. The launch shed has to fall almost straight
        # down -- the body left it behind, it was not flung sideways.
        d = Vector((math.cos(ang) * lat, math.sin(ang) * lat * 0.55, up))
        d.normalize()
        p0 = Vector((math.cos(ang) * ax * 0.92, math.sin(ang) * ax * 0.55, base_z))
        v0 = d * (speed * wob)
        r = r0 * (0.72 + 0.5 * wob)
        # When it reaches the desk is SOLVED, not stepped: the splat has to key to
        # the real landing frame or droplets sink through the surface.
        zt = ground + r * 0.55
        disc = v0.z * v0.z + 2.0 * G * (p0.z - zt)
        t_land = (v0.z + math.sqrt(max(disc, 0.0))) / G
        out.append((t0, p0, v0, r, t_land, ground))
    return out


def hop_droplets():
    """The two bursts, sized by how hard their moment actually is.

    The impact throws more and bigger than the launch, because stopping a falling
    mass dead is the more violent of the two events. Count and size scaling with
    inertia is the reference sheet's own rule, not a look chosen here.
    """
    return (shed_burst(HOP_LAUNCH, 3, 0.70, -0.55, 0.065, up=-0.88, lat=0.32)
            + shed_burst(HOP_LAND, 6, 1.45, -0.95, 0.075, up=0.72, lat=1.0))


SPLAT_DUR = 0.13
DROPLETS = hop_droplets()


def add_droplets(bm, t):
    """Every droplet at its own point in its own flight. Nothing here reads the
    body's current frame, and that independence IS the secondary motion."""
    for (t0, p0, v0, r, t_land, ground) in DROPLETS:
        dt = (t - t0) % 1.0
        if dt > t_land + SPLAT_DUR:
            continue
        before = set(bm.verts)
        if dt <= t_land:
            v = Vector((v0.x, v0.y, v0.z - G * dt))
            p = Vector((p0.x + v0.x * dt, p0.y + v0.y * dt,
                        p0.z + v0.z * dt - 0.5 * G * dt * dt))
            # Stretch along the velocity, narrow across it. Volume conservation
            # again: a droplet that only lengthens is gaining mass in mid-air.
            stretch = 1.0 + min(v.length * 0.35, 0.9)
            narrow = 1.0 / math.sqrt(stretch)
            add_blob(bm, p, basis_from(v), (r * narrow, r * narrow, r * stretch),
                     segments=14)
        else:
            k = (dt - t_land) / SPLAT_DUR
            spread = 1.0 + 1.5 * k
            h = max(r * 0.45 * (1.0 - k), 1e-3)
            centre = Vector((p0.x + v0.x * t_land, p0.y + v0.y * t_land, ground))
            add_blob(bm, centre, WORLD_BASIS, (r * spread, r * spread, h),
                     segments=14)
            for v in set(bm.verts) - before:
                # No floor object in this scene (film_transparent -- the pet sits
                # on the user's wallpaper), so half a splat would hang in the air.
                if v.co.z < ground:
                    v.co.z = ground
        WET.update(set(bm.verts) - before)


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
    face_h = g_hi * (0.58 if char == "?" else 0.62)
    # MEASURE the glyph's own half-width at the face band instead of deriving it
    # from `scale`. Derived, the strokes stuck out past the silhouette like
    # whiskers -- an exclamation mark's bar is simply narrower than two eyes side
    # by side, and no constant guessed from the glyph's HEIGHT can know that.
    # add_eye_stroke's outermost point lands at (0.46 + arc) * face_r, so solving
    # for that keeps the whole face inside the mark with a margin.
    band = [abs(v.co.x) for v in bm.verts if abs(v.co.z - face_h) < 0.12 * g_hi]
    half_w = max(band) if band else scale * 0.30
    ARC = 0.42
    face_r = 0.78 * half_w / (0.46 + ARC)
    # It has to stay the SAME creature, or the hyperbole reads as a prop someone
    # left on the desk. Two short strokes across the glyph's thickest span.
    # Bigger and heavier than the dome's strokes, because they are competing with
    # a whole glyph instead of sitting on a blank dome. At arc 0.26 / thick 0.055
    # they rendered as two faint dashes and the hyperbole read as a signboard --
    # which is exactly the failure this function's own docstring warns about, a
    # prop someone left on the desk rather than the same creature.
    for side in (-1, 1):
        add_eye_stroke(bm, side, face_r, arc=ARC,
                       height=face_h / face_r, thick=0.115, dip=0.16, n=11,
                       squash=1.0)
    return bm


DEFLATE_SQUASH = 0.45


def make_deflate(scene):
    """Melted: the mass gives up and spreads. Volume still conserved.

    Squash was 0.30, which conserves volume by widening 1/sqrt(0.30) = 1.83x --
    a body 1.83 m across inside a frame 1.57 m wide. It overflowed left AND right
    and shipped as a crop of a slab for three commits. 0.45 still reads as clearly
    collapsed against the 0.62 rest pose and fits with margin, so the fix costs a
    little droop and breaks no rule; capping the widen would have been the version
    that quietly abandons volume conservation to save a pose.
    """
    bm = new_bm_sphere(BODY_R)
    settle_dome(bm, BODY_R, squash=DEFLATE_SQUASH, base_flat=-0.50)
    for side in (-1, 1):                    # eyes become flat resigned lines
        add_eye_stroke(bm, side, BODY_R, arc=0.26, height=0.20, thick=0.034,
                       dip=0.10, squash=DEFLATE_SQUASH)
    return bm


def make_sweat(scene):
    """Strain: fat drops CLINGING to the head, not hovering over it.

    The first version placed them with raw offsets that put every drop above the
    dome's own top, so they read as soap bubbles floating past a calm creature --
    the opposite of the tension the pose is for. Anime sweat touches the head.
    These reuse the drip bead recipe: seated on the surface with surf_frame,
    fractionally proud, and stretched down-slope so each one is a teardrop
    about to run.
    """
    s = 0.66
    bm = make_idle(scene, squint_eyes=True, squash=s)
    ax, ay, az = body_axes(s)
    for theta_deg, phi_deg, r in ((-150.0, 32.0, 0.075), (-30.0, 26.0, 0.055)):
        p, n, t = surf_frame(ax, ay, az, math.radians(theta_deg),
                             math.radians(phi_deg))
        b = n.cross(t)
        before = set(bm.verts)
        add_blob(bm, p + n * (r * 0.18), (t, b, n),
                 (r * 1.70, r * 0.95, r * 0.62))
        BEAD.update(set(bm.verts) - before)
    return bm


def place(bm, height):
    """Seat the mesh on the desk (or `height` above it), by its own underside.

    Measured placement, not an assumed one: settle_dome's clamp only bites when
    the shape is flatter than rest, so a stretched body ends up with its bottom
    far below the floor it was drawn against. Reading the real minimum and moving
    the whole mesh is the only version that survives a squash cycle.
    """
    lo = min(v.co.z for v in bm.verts)
    dz = (DESK_Z + height) - lo
    for v in bm.verts:
        v.co.z += dz
    return bm


def idle_squash(t):
    """Rest: one slow breath. The creature is torpe, never nervous."""
    return 0.62 + 0.040 * math.sin(math.tau * t)


def make_idle_frame(scene, t):
    """Rest, and NOTHING sheds here.

    Three passes tried to hang drips off the resting body and all three read as
    ears, eggs or warts -- there is no clearance under this silhouette. Joan's
    call (2026-08-10) is that shedding belongs to MOVEMENT, so idle is a breath
    and only a breath.
    """
    s = idle_squash(t)
    bm = new_bm_sphere(BODY_R)
    settle_dome(bm, BODY_R, squash=s)
    for side in (-1, 1):
        add_eye_stroke(bm, side, BODY_R, squash=s)
    return place(bm, 0.0)


def make_hop_frame(scene, t):
    """One frame of the hop: the body on its arc, the gel arriving late.

    The two clocks never touch. The body's HEIGHT is hop_height(t) -- the mass
    goes where physics sends it, on time. The body's SHAPE is hop_squash read
    through viscous(), so the surface is always a beat behind and always goes a
    little past. And the droplets read neither: each one is on its own ballistic
    flight from the instant it was torn off.
    """
    s = viscous(hop_squash, t)
    h = hop_height(t)
    bm = new_bm_sphere(BODY_R)
    # No contact patch in mid-air. Flattening the underside of an airborne body is
    # the tell that its shape was copied from the resting pose.
    settle_dome(bm, BODY_R, squash=s,
                base_flat=(-10.0 if h > 1e-6 else -0.34))
    for side in (-1, 1):
        add_eye_stroke(bm, side, BODY_R, squash=s)
    place(bm, h)
    add_droplets(bm, t)
    return bm


def frame_grid(paths, cell, cols, out_path, pad=8, card=(0.93, 0.94, 0.92),
               bg=(0.20, 0.22, 0.24)):
    """Contact grid of a frame sequence, composited over a light card.

    Same Blender-image approach as use_size (this Python has no Pillow). Motion is
    judged on a SEQUENCE, never on one frame -- a single still of an animation is
    exactly the evidence that let the last pass ship a face that vanished.
    """
    rows = (len(paths) + cols - 1) // cols
    width = cols * cell + pad * (cols + 1)
    height = rows * cell + pad * (rows + 1)
    sheet = bpy.data.images.new("frame_grid", width=width, height=height,
                                alpha=False)
    buf = [0.0] * (width * height * 4)
    for i in range(width * height):
        buf[i * 4] = bg[0]
        buf[i * 4 + 1] = bg[1]
        buf[i * 4 + 2] = bg[2]
        buf[i * 4 + 3] = 1.0
    for idx, p in enumerate(paths):
        r, c = divmod(idx, cols)
        tile = bpy.data.images.load(p, check_existing=False)
        tile.scale(cell, cell)
        px = [0.0] * (cell * cell * 4)
        tile.pixels.foreach_get(px)
        x0 = pad + c * (cell + pad)
        # bpy rows run bottom-up; fill the grid top-down so frame 0 reads first.
        y0 = height - (pad + (r + 1) * cell + r * pad)
        for ty in range(cell):
            for tx in range(cell):
                si = (ty * cell + tx) * 4
                a = px[si + 3]
                di = ((y0 + ty) * width + (x0 + tx)) * 4
                for ch in range(3):
                    buf[di + ch] = card[ch] * (1.0 - a) + px[si + ch] * a
        bpy.data.images.remove(tile)
    sheet.pixels.foreach_set(buf)
    sheet.filepath_raw = out_path
    sheet.file_format = "PNG"
    sheet.save()
    bpy.data.images.remove(sheet)
    return out_path


# ------------------------------------------------------------- reactions ----
# Joan, 2026-08-11: *"ver fisicamente como cambia o se mueve ante x situacion."*
#
# So a reaction is not a pose, it is a TRANSITION, and the clips are named for
# the SITUATION rather than for the face they end on. The eight expressions were
# always stills; what was missing is the part between them, which is where all
# the character lives.
#
# Every clip obeys the three rules the hop already proved: anticipation before
# the move, the shape arriving LATE and going PAST, and a settle rather than a
# stop. And they return to rest by the last frame, because a desktop pet plays
# its reaction and then has to be idle again.
TENDRIL_SCALE = 0.34
HYPER_SCALE = 0.62


def back_out(k, over=1.9):
    """Ease that overshoots its target and settles. Gel never stops dead."""
    k = max(0.0, min(1.0, k))
    c1 = over
    c3 = c1 + 1.0
    return 1.0 + c3 * (k - 1.0) ** 3 + c1 * (k - 1.0) ** 2


def smooth(k):
    k = max(0.0, min(1.0, k))
    return k * k * (3.0 - 2.0 * k)


def make_curious(scene, t):
    """SITUATION: something unfamiliar -- it wonders, mildly.

    The soft register: the dome stays whole and the glyph GROWS OUT of it. The
    growth overshoots because it is being pushed up through gel, not switched on.
    """
    s = idle_squash(t)
    bm = make_idle(scene, squash=s)
    if t < 0.10:
        sc = 0.0
    elif t < 0.34:
        sc = TENDRIL_SCALE * back_out((t - 0.10) / 0.24)
    elif t < 0.78:
        # Holding, but not frozen: the tendril breathes a beat behind the body.
        sc = TENDRIL_SCALE * (1.0 + 0.05 * math.sin(math.tau * (t - 0.34) * 1.6))
    else:
        sc = TENDRIL_SCALE * (1.0 - smooth((t - 0.78) / 0.22))
    if sc > 0.05:
        with_tendril(bm, "question", sc)
    return place(bm, 0.0)


def make_escalate(scene, t):
    """SITUATION: something goes wrong, and then it sinks in.

    The one clip that shows the design's whole point -- the ESCALATION between
    the two registers. A small "!" on an intact dome, then the body itself
    becomes the glyph. The file header calls that escalation the expressiveness,
    and one register alone going stale on a desktop in three days.

    The jump from dome to glyph is a hard CUT on purpose. An impact is
    instantaneous and anime cuts on the snap; what sells it is the anticipation
    crouch immediately before and the overshoot immediately after, not a morph.
    """
    if t < 0.40:
        # Soft register on a body that flinches first.
        if t < 0.08:
            s, sc = idle_squash(t), 0.0
        elif t < 0.24:
            k = (t - 0.08) / 0.16
            s = 0.62 + 0.10 * math.sin(math.pi * k)      # a small startle
            sc = TENDRIL_SCALE * back_out(k)
        else:
            s = idle_squash(t)
            sc = TENDRIL_SCALE
        bm = make_idle(scene, squint_eyes=True, squash=s)
        if sc > 0.05:
            with_tendril(bm, "bang", sc)
        return place(bm, 0.0)
    if t < 0.48:
        # ANTICIPATION: it gathers and flattens before the escalation. Without
        # this frame the cut reads as a glitch instead of as a reaction.
        k = (t - 0.40) / 0.08
        bm = make_idle(scene, squint_eyes=True, squash=0.62 - 0.18 * smooth(k))
        return place(bm, 0.0)
    if t < 0.86:
        k = (t - 0.48) / 0.10
        scale = HYPER_SCALE * (back_out(k, over=2.4) if k < 1.0 else 1.0)
        if t >= 0.58:
            # Held, wobbling off the overshoot rather than standing still.
            w = (t - 0.58) / 0.28
            scale = HYPER_SCALE * (1.0 + 0.05 * math.cos(math.tau * 1.5 * w)
                                   * math.exp(-2.6 * w))
        return place(make_hyperbole("bang", max(scale, 0.08)), 0.0)
    # Collapse back to rest, landing flat and rebounding -- the same impact
    # signature as the hop, because it is the same event: a mass dropping.
    k = (t - 0.86) / 0.14
    s = 0.62 - 0.16 * math.cos(math.tau * 1.2 * k) * math.exp(-3.0 * k)
    return place(make_idle(scene, squash=s), 0.0)


def make_strain(scene, t):
    """SITUATION: a long job is running and it is holding on.

    Squinting, breathing faster than rest, and shedding sweat that actually RUNS:
    each drop swells on the temple, slides down the flank and is gone by the lip.
    Two drops on different phases, so the head is never symmetric.
    """
    s = 0.66 + 0.020 * math.sin(math.tau * 2.0 * t)
    bm = make_idle(scene, squint_eyes=True, squash=s)
    ax, ay, az = body_axes(s)
    # On the TEMPLE, high on the front dome, not out at the silhouette. At theta
    # -150/-30 the drops sat on the outline and read as nubs on the rim -- the
    # same failure the idle drips hit, for the same reason: a bead seen edge-on
    # is a lump, not a drop. Brought round to the front and kept ABOVE the eye
    # strokes (which sit at phi ~19 deg), so the run never crosses the face.
    for theta_deg, r, off in ((-128.0, 0.085, 0.0), (-46.0, 0.065, 0.45)):
        u = (t + off) % 1.0
        if u < 0.30:
            rr = r * (0.35 + 0.65 * (u / 0.30))
            phi = math.radians(48.0)
        elif u < 0.72:
            rr = r
            phi = math.radians(48.0 - 22.0 * smooth((u - 0.30) / 0.42))
        else:
            continue                        # gone: it ran off the lip
        pp, n, tt = surf_frame(ax, ay, az, math.radians(theta_deg), phi)
        b = n.cross(tt)
        before = set(bm.verts)
        add_blob(bm, pp + n * (rr * 0.18), (tt, b, n),
                 (rr * 1.70, rr * 0.95, rr * 0.62))
        BEAD.update(set(bm.verts) - before)
    return place(bm, 0.0)


def make_delighted(scene, t):
    """SITUATION: it worked. Two quick bounces, the second smaller.

    Deliberately NOT the hop: no shedding and barely any height. A hop is
    travel, this is a reaction -- the difference is that the body squashes far
    more than it rises, which is what reads as delight rather than as jumping.
    """
    beat = (t * 2.0) % 1.0
    decay = 1.0 if t < 0.5 else 0.62         # the second bounce is smaller
    if beat < 0.30:
        s = 0.55 - 0.10 * decay * math.sin(math.pi * (beat / 0.30))
        h = 0.0
    elif beat < 0.72:
        k = (beat - 0.30) / 0.42
        s = 0.55 + 0.34 * decay * math.sin(math.pi * k)
        h = 0.13 * decay * 4.0 * k * (1.0 - k)
    else:
        k = (beat - 0.72) / 0.28
        s = 0.55 - 0.12 * decay * math.cos(math.tau * 1.4 * k) * math.exp(-3.4 * k)
        h = 0.0
    bm = make_idle(scene, squash=max(s, 0.24))
    return place(bm, h)


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

# --------------------------------------------------------------- material ----
# Joan, 2026-08-10: "ahora se nota como un globo, mas que como una gelatina
# slime, similar a tenshura."
#
# Exactly right, and the diagnosis names the cause: on a BALLOON the light dies
# at the surface. The pet was an opaque Principled with one specular -- that is
# latex, no matter what colour it is. Gelatin reads through light that goes
# THROUGH the mass: an edge that transmits, an interior that is visible, bubbles
# suspended in it.
#
# The old note in this project said EEVEE could not do that and a Blender with
# Cycles was needed. That was an assumption, and probing the actual build killed
# it -- 5.1.2's EEVEE Next carries Subsurface Weight/Radius/Scale, Transmission
# Weight, and screen-space raytracing. No Cycles required; three sessions of
# "blocked on translucency" were blocked on an unmeasured claim.
#
# The vocabulary is borrowed from the game slime (Joan: "reutilizamos algunas
# cositas del slime del juego") -- depth gradient, bubbles suspended in the gel,
# a bright band at the widest point. There it had to be BAKED to vertex colour
# because glTF cannot express a node graph, and the equator band was a
# view-independent stand-in for a Fresnel rim that could not survive export.
# Here the RENDER is the product, so the nodes run for real and the rim can be
# an actual Fresnel.
GEL_BUBBLE = (0.62, 0.78, 0.86, 1.0)   # light blooming where a bubble meets skin
GEL_RIM = (0.72, 0.86, 0.95, 1.0)      # the transmitting edge


def gel_material():
    m = bpy.data.materials.new("mat_slime_pet")
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]

    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"

    # Bubbles, in OBJECT space so they stay put in the body while it deforms --
    # the mesh is rebuilt every frame, so anything in generated/world space would
    # make the bubbles swim through the gel as the creature breathes.
    tex = nt.nodes.new("ShaderNodeTexCoord")
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.feature = "F1"
    vor.inputs["Scale"].default_value = 6.5
    vor.inputs["Randomness"].default_value = 1.0
    nt.links.new(tex.outputs["Object"], vor.inputs["Vector"])
    # Only the cells' CORES become bubbles. Without this ramp a voronoi is a
    # cracked-tile pattern, which is the opposite of suspended spheres.
    bub = nt.nodes.new("ShaderNodeValToRGB")
    # Wide and SOFT. A tight ramp gave hard white dots and the body read as a
    # painted beach ball -- worse than no bubbles at all, because a hard-edged
    # spot sits ON a surface while a bubble is meant to be suspended UNDER one.
    # The ceiling is 0.42, not 1.0, for the same reason: a bubble seen through
    # gel is a soft bloom, never a full-strength highlight.
    bub.color_ramp.elements[0].position = 0.00
    bub.color_ramp.elements[1].position = 0.42
    bub.color_ramp.elements[0].color = (0.42, 0.42, 0.42, 1.0)
    bub.color_ramp.elements[1].color = (0.0, 0.0, 0.0, 1.0)
    nt.links.new(vor.outputs["Distance"], bub.inputs["Factor"])

    mix_b = nt.nodes.new("ShaderNodeMixRGB")
    mix_b.inputs["Color2"].default_value = GEL_BUBBLE
    nt.links.new(bub.outputs["Color"], mix_b.inputs["Factor"])
    nt.links.new(attr.outputs["Color"], mix_b.inputs["Color1"])

    # The real Fresnel the game slime had to fake. This is the single strongest
    # anti-balloon cue: a mass that brightens where you see through more of it.
    lw = nt.nodes.new("ShaderNodeLayerWeight")
    lw.inputs["Blend"].default_value = 0.42
    mix_r = nt.nodes.new("ShaderNodeMixRGB")
    mix_r.inputs["Color2"].default_value = GEL_RIM
    nt.links.new(lw.outputs["Fresnel"], mix_r.inputs["Factor"])
    nt.links.new(mix_b.outputs["Color"], mix_r.inputs["Color1"])
    nt.links.new(mix_r.outputs["Color"], bsdf.inputs["Base Color"])

    # THE FIX THAT ACTUALLY KILLED THE BALLOON. Brightening the albedo at the rim
    # does nothing where no light reaches -- the first attempt rendered with a
    # DARKER edge than centre, because the sides face away from every lamp. Real
    # gel does not get a paler edge, it GLOWS there: light entered the far side
    # and came out towards the eye. So the Fresnel drives EMISSION, which owes
    # nothing to the lighting, and the silhouette carries the transmission.
    glow = nt.nodes.new("ShaderNodeMath")
    glow.operation = "MULTIPLY"
    glow.inputs[1].default_value = 0.95
    nt.links.new(lw.outputs["Fresnel"], glow.inputs[0])
    nt.links.new(glow.outputs["Value"], bsdf.inputs["Emission Strength"])
    # Saturated cyan-blue, not white: a white rim reads as polished plastic, the
    # exact material this is trying to stop being.
    bsdf.inputs["Emission Color"].default_value = (0.26, 0.58, 0.86, 1.0)

    # Subsurface is what turns the shell into a MASS. Radius is deliberately
    # blue-longest: in a blue gel the blue channel is the one that survives the
    # trip, and that wavelength split is most of why jelly does not read as paint.
    bsdf.inputs["Subsurface Weight"].default_value = 0.85
    bsdf.inputs["Subsurface Radius"].default_value = (0.35, 0.62, 1.00)
    # Scale in METRES, and it is the risky number. The body is 0.5 m across and
    # the eye strokes are ~3 cm wide: scatter too far and the light bleeds through
    # the face, undoing the whole reason the strokes are geometry. Kept under the
    # stroke width on purpose -- verify on the use-size strip, not on the hero.
    bsdf.inputs["Subsurface Scale"].default_value = 0.055
    bsdf.inputs["Transmission Weight"].default_value = 0.12
    bsdf.inputs["Roughness"].default_value = 0.14
    bsdf.inputs["IOR"].default_value = 1.33
    # A wet skin over a soft interior: the coat gives the sharp bright specular a
    # gel surface has, while the body underneath stays soft. One material doing
    # both is what a single Principled cannot fake with roughness alone.
    bsdf.inputs["Coat Weight"].default_value = 0.45
    bsdf.inputs["Coat Roughness"].default_value = 0.06
    return m


def toon_material():
    """Anime cel gel. Joan picked this over the PBR version, 2026-08-10.

    The premise check behind it: three passes of physically-based translucency
    (subsurface, transmission, Fresnel emission, an inverted gradient) each got
    closer and none stopped the creature reading as a balloon. Tensura's slime is
    not a raytraced gummy -- it is CEL-SHADED, and its gel reads through
    HARD-EDGED shapes: a crisp highlight, a bright crescent along the thin edge,
    a clean silhouette. It is also what this project already decided;
    `_art_canon.md` is DP_ToonGrounded and the 2026-06-10 note says outright
    "anime look = SHADER, not polygons". Rendering the pet in PBR was off-canon.

    Everything is routed through Emission so the bands ARE the lighting. Leaving
    a lit BSDF anywhere in the chain shades the result twice and mushes every
    hard edge the look is made of.
    """
    m = bpy.data.materials.new("mat_slime_pet_toon")
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        if n.type != "OUTPUT_MATERIAL":
            nt.nodes.remove(n)
    out = [n for n in nt.nodes if n.type == "OUTPUT_MATERIAL"][0]

    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"

    # ---- bubbles, as DRAWN SHAPES ------------------------------------------
    # In OBJECT space so they stay put in the body while it deforms: the mesh is
    # rebuilt every frame, so generated or world space would make them swim.
    #
    # The first version soft-ramped a voronoi and got mottling; a tighter ramp got
    # hard white polka dots. Both were wrong for opposite reasons. Cel art draws a
    # bubble as a small solid shape of a LIGHTER tone -- so the edge should be
    # hard (it is a drawn shape) but the tone step small (it is under the surface,
    # not on it). Uniform cells read as a pattern, so a noise perturbs the
    # threshold and the shapes come out different sizes, some suppressed entirely.
    tex = nt.nodes.new("ShaderNodeTexCoord")
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.feature = "F1"
    vor.inputs["Scale"].default_value = 5.5
    vor.inputs["Randomness"].default_value = 1.0
    nt.links.new(tex.outputs["Object"], vor.inputs["Vector"])

    nz = nt.nodes.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value = 2.6
    nz.inputs["Detail"].default_value = 2.0
    nt.links.new(tex.outputs["Object"], nz.inputs["Vector"])
    nmul = nt.nodes.new("ShaderNodeMath")
    nmul.operation = "MULTIPLY"
    nmul.inputs[1].default_value = 0.22
    nt.links.new(nz.outputs["Fac"], nmul.inputs[0])
    dsum = nt.nodes.new("ShaderNodeMath")
    dsum.operation = "ADD"
    nt.links.new(vor.outputs["Distance"], dsum.inputs[0])
    nt.links.new(nmul.outputs["Value"], dsum.inputs[1])

    bramp = nt.nodes.new("ShaderNodeValToRGB")
    bramp.color_ramp.interpolation = "CONSTANT"
    bramp.color_ramp.elements[0].position = 0.0
    bramp.color_ramp.elements[0].color = (1.0, 1.0, 1.0, 1.0)
    bramp.color_ramp.elements[1].position = 0.17
    bramp.color_ramp.elements[1].color = (0.0, 0.0, 0.0, 1.0)
    nt.links.new(dsum.outputs["Value"], bramp.inputs["Factor"])

    base = nt.nodes.new("ShaderNodeMixRGB")
    base.inputs["Color2"].default_value = TOON_BUBBLE
    nt.links.new(bramp.outputs["Color"], base.inputs["Factor"])
    nt.links.new(attr.outputs["Color"], base.inputs["Color1"])

    # ---- light, quantised ---------------------------------------------------
    # CONSTANT interpolation is the whole point. Any smoothing here and it is a
    # soft gradient wearing a toon costume.
    lit = nt.nodes.new("ShaderNodeBsdfDiffuse")
    lit.inputs["Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    s2r = nt.nodes.new("ShaderNodeShaderToRGB")
    nt.links.new(lit.outputs["BSDF"], s2r.inputs["Shader"])
    bands = nt.nodes.new("ShaderNodeValToRGB")
    bands.color_ramp.interpolation = "CONSTANT"
    bands.color_ramp.elements[0].position = 0.0
    bands.color_ramp.elements[0].color = (0.0, 0.0, 0.0, 1.0)
    bands.color_ramp.elements[1].position = 0.30
    bands.color_ramp.elements[1].color = (0.55, 0.55, 0.55, 1.0)
    e3 = bands.color_ramp.elements.new(0.62)
    e3.color = (1.0, 1.0, 1.0, 1.0)
    nt.links.new(s2r.outputs["Color"], bands.inputs["Factor"])

    # Shadow is a MIX toward a saturated cool blue, NOT a multiply. Multiplying
    # the body colour was the first version and it crushed the lower half to mud:
    # a dark albedo times a dark shadow leaves nothing to read. Cel shadow shifts
    # HUE and keeps value, which is why anime shadows stay legible.
    shade = nt.nodes.new("ShaderNodeMixRGB")
    shade.inputs["Factor"].default_value = 0.62
    shade.inputs["Color2"].default_value = TOON_SHADE
    nt.links.new(base.outputs["Color"], shade.inputs["Color1"])

    body = nt.nodes.new("ShaderNodeMixRGB")
    nt.links.new(bands.outputs["Color"], body.inputs["Factor"])
    nt.links.new(shade.outputs["Color"], body.inputs["Color1"])
    nt.links.new(base.outputs["Color"], body.inputs["Color2"])

    # ---- the hard highlight -------------------------------------------------
    # A slime's signature is a crisp bright SHAPE sitting on the dome, not a soft
    # specular smear, so the glossy response is thresholded to a hard edge.
    gloss = nt.nodes.new("ShaderNodeBsdfGlossy")
    gloss.inputs["Roughness"].default_value = 0.16
    g2r = nt.nodes.new("ShaderNodeShaderToRGB")
    nt.links.new(gloss.outputs["BSDF"], g2r.inputs["Shader"])
    gramp = nt.nodes.new("ShaderNodeValToRGB")
    gramp.color_ramp.interpolation = "CONSTANT"
    gramp.color_ramp.elements[0].position = 0.0
    gramp.color_ramp.elements[0].color = (0.0, 0.0, 0.0, 1.0)
    gramp.color_ramp.elements[1].position = 0.62
    gramp.color_ramp.elements[1].color = (1.0, 1.0, 1.0, 1.0)
    nt.links.new(g2r.outputs["Color"], gramp.inputs["Factor"])

    # ANIME NEVER PUTS SPECULAR ON LINE ART. The eye strokes are dark geometry,
    # and a physically-correct glossy pass ran a bright white streak down each of
    # them -- the face read as two bent metal wires instead of two drawn strokes.
    # Masking by the albedo's own luminance kills the highlight wherever the
    # surface is ink, which is wrong for physics and right for the medium.
    bw = nt.nodes.new("ShaderNodeRGBToBW")
    nt.links.new(attr.outputs["Color"], bw.inputs["Color"])
    ink = nt.nodes.new("ShaderNodeValToRGB")
    ink.color_ramp.interpolation = "CONSTANT"
    ink.color_ramp.elements[0].position = 0.0
    ink.color_ramp.elements[0].color = (0.0, 0.0, 0.0, 1.0)
    ink.color_ramp.elements[1].position = 0.12
    ink.color_ramp.elements[1].color = (1.0, 1.0, 1.0, 1.0)
    nt.links.new(bw.outputs["Val"], ink.inputs["Factor"])
    gmask = nt.nodes.new("ShaderNodeMixRGB")
    gmask.blend_type = "MULTIPLY"
    gmask.inputs["Factor"].default_value = 1.0
    nt.links.new(gramp.outputs["Color"], gmask.inputs["Color1"])
    nt.links.new(ink.outputs["Color"], gmask.inputs["Color2"])

    spec = nt.nodes.new("ShaderNodeMixRGB")
    spec.inputs["Color2"].default_value = (0.95, 0.99, 1.0, 1.0)
    nt.links.new(gmask.outputs["Color"], spec.inputs["Factor"])
    nt.links.new(body.outputs["Color"], spec.inputs["Color1"])

    # ---- the translucent crescent -------------------------------------------
    # The strongest gel cue on a cel slime: a bright saturated band hugging the
    # silhouette where the mass is thinnest and light crosses it. Hard-edged,
    # like everything else here.
    fres = nt.nodes.new("ShaderNodeFresnel")
    fres.inputs["IOR"].default_value = 1.33
    framp = nt.nodes.new("ShaderNodeValToRGB")
    framp.color_ramp.interpolation = "CONSTANT"
    framp.color_ramp.elements[0].position = 0.0
    framp.color_ramp.elements[0].color = (0.0, 0.0, 0.0, 1.0)
    framp.color_ramp.elements[1].position = 0.58
    framp.color_ramp.elements[1].color = (1.0, 1.0, 1.0, 1.0)
    nt.links.new(fres.outputs["Fac"], framp.inputs["Factor"])
    # Masked by the same ink test: a stroke is a tube, so its own grazing edges
    # would catch the crescent and outline the eyes in bright cyan.
    fmask = nt.nodes.new("ShaderNodeMixRGB")
    fmask.blend_type = "MULTIPLY"
    fmask.inputs["Factor"].default_value = 1.0
    nt.links.new(framp.outputs["Color"], fmask.inputs["Color1"])
    nt.links.new(ink.outputs["Color"], fmask.inputs["Color2"])
    rim = nt.nodes.new("ShaderNodeMixRGB")
    rim.inputs["Color2"].default_value = TOON_CRESCENT
    nt.links.new(fmask.outputs["Color"], rim.inputs["Factor"])
    nt.links.new(spec.outputs["Color"], rim.inputs["Color1"])

    emit = nt.nodes.new("ShaderNodeEmission")
    emit.inputs["Strength"].default_value = 1.0
    nt.links.new(rim.outputs["Color"], emit.inputs["Color"])
    nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    return m


mat = toon_material() if STYLE == "toon" else gel_material()
print("[pet] material style: %s%s" % (STYLE, "  (LOOKDEV)" if LOOKDEV else ""))


def sun(name, energy, color, rot):
    d = bpy.data.lights.new(name, type="SUN")
    d.energy = energy
    d.color = color
    o = bpy.data.objects.new(name, d)
    o.rotation_euler = rot
    scene.collection.objects.link(o)


sun("key", 2.6, (1.0, 0.97, 0.92), (math.radians(52), 0, math.radians(28)))
sun("fill", 1.1, (0.72, 0.82, 1.0), (math.radians(66), 0, math.radians(-124)))
# The rim is now doing real work, not decorating an outline: subsurface only
# reads when there is light BEHIND the mass to come through it. On an opaque
# body this was a taste setting; on a translucent one it is the light that
# produces the effect, so it is the brightest lamp in the rig.
sun("rim", 4.2, (0.88, 0.94, 1.0), (math.radians(112), 0, math.radians(190)))

world = bpy.data.worlds.new("w")
scene.world = world
world.use_nodes = True
# Lifted off near-black: scattering needs some ambient to carry, and the world is
# never seen anyway (film_transparent), so this is pure lighting, not backdrop.
world.node_tree.nodes["Background"].inputs[0].default_value = (0.09, 0.11, 0.15, 1.0)

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
# Screen-space raytracing is what lets EEVEE Next carry refraction and proper
# subsurface instead of a flat approximation. Probed present on this build --
# the claim that translucency here needed Cycles was never measured.
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
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
# MEASURED framing, after every pose turned out to be clipped at the bottom.
# Alpha bounding boxes on the old rig: idle 94% wide and touching the bottom
# edge, deflate 100% wide and touching left, right AND bottom, both hyperbole
# glyphs cut off at the bottom -- which is the real reason the big "?" read as a
# seahorse. It was never the bevel. Its DOT was being cropped, and a question
# mark without its dot is a hook.
#
# The cause is perspective, not arithmetic: the frame is wide enough at the
# origin plane, but the body's near-bottom edge sits ~0.6 m closer to the camera,
# where the frame is proportionally smaller and its bottom edge is higher. So the
# rig backs off and looks down harder, which brings the whole contact line inside
# with margin at the cost of a little size.
# x nudged 0.15 -> 0.19 because the 4-degree yaw left the body sitting 13 px
# right of centre, which cost the widest pose (deflate) its right edge. Centring
# the frame is the fix; shrinking the pose to fit a crooked frame is not.
cam.location = (0.19, -2.70, 0.78)
cam.rotation_euler = (math.radians(79), 0.0, math.radians(4))
scene.collection.objects.link(cam)
scene.camera = cam

print("[pet] rendering %d expressions" % len(EXPRESSIONS))
for key, fn in ([] if LOOKDEV else EXPRESSIONS):
    for o in [o for o in scene.objects if o.type == "MESH"]:
        bpy.data.objects.remove(o, do_unlink=True)
    DARK.clear()
    WET.clear()
    BEAD.clear()
    # Every pose seated on the SAME desk line. Without this each expression sat
    # wherever its own squash happened to leave it -- the hyperbole glyphs in
    # particular floated, centred on z=0 rather than standing on anything. A
    # sprite set has to be registered to one box or the pet jumps when it changes
    # expression.
    bm = place(fn(scene), 0.0)
    obj = finalize(bm, "pet_" + key, scene)
    obj.data.materials.append(mat)
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    scene.render.filepath = os.path.join(REN_DIR, "pet_%s.png" % key)
    bpy.ops.render.render(write_still=True)
    print("[pet] %-16s verts=%4d tris=%4d  -> renders/pet_%s.png"
          % (key, len(obj.data.vertices), tris, key))

# ------------------------------------------------------------------- idle ----
# The expressions above are stills. Viscosity is not a still: a drop that lags the
# body cannot be shown in one frame, by definition. So the idle also ships as a
# frame SEQUENCE, and that sequence -- not a hero render -- is what gets judged.
ANIM_DIR = os.path.join(REN_DIR, "anim")
os.makedirs(ANIM_DIR, exist_ok=True)
FPS = 12
FRAMES = 24                              # 2.0 s per clip

CLIPS = ([("hop", make_hop_frame)] if LOOKDEV else [
    ("idle", make_idle_frame),
    ("hop", make_hop_frame),
    # Named for the SITUATION, not for the face they land on.
    ("curious", make_curious),        # something unfamiliar
    ("escalate", make_escalate),      # it goes wrong, then it sinks in
    ("strain", make_strain),          # a long job is running
    ("delighted", make_delighted),    # it worked
])
clip_paths = {}
for name, fn in CLIPS:
    paths = []
    frames = LOOKDEV_FRAMES if LOOKDEV else list(range(FRAMES))
    print("[pet] rendering %d %s frames (%d fps, %.1fs loop)"
          % (len(frames), name, FPS, FRAMES / FPS))
    for f in frames:
        t = f / FRAMES
        for o in [o for o in scene.objects if o.type == "MESH"]:
            bpy.data.objects.remove(o, do_unlink=True)
        DARK.clear()
        WET.clear()
        BEAD.clear()
        obj = finalize(fn(scene, t), "pet_%s_%02d" % (name, f), scene)
        obj.data.materials.append(mat)
        path = (os.path.join(REN_DIR, "_lookdev_%s_%02d.png" % (STYLE, f))
                if LOOKDEV else os.path.join(ANIM_DIR, "%s_%02d.png" % (name, f)))
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        paths.append(path)
    clip_paths[name] = paths
    if LOOKDEV:
        continue
    grid = os.path.join(REN_DIR, "_%s_grid.png" % name)
    frame_grid(paths[::2], cell=200, cols=4, out_path=grid)
    print("[pet] %s -> renders/anim/%s_*.png + %s" % (name, name, os.path.basename(grid)))

# THE BUILD IS ITS OWN GATE. A desktop pet lives at 72-120 px; the first pass was
# judged on a 512 px sheet where the eyes merely looked weak, and only a later
# check revealed the face vanishes entirely at real size. Under
# --python-exit-code 1 this raises and fails the build if the evidence cannot be
# produced, so no future pass can be judged at a flattering size by accident.
if LOOKDEV:
    # Said out loud rather than skipped quietly: a lookdev run produces no
    # shippable asset, so the use-size gate has nothing to gate. A silent skip is
    # how a gate quietly stops existing.
    print("[pet] LOOKDEV: use-size gate SKIPPED — this run ships nothing")
    print("[pet] DONE")
    sys.exit(0)

use_size.require_use_size(
    os.path.join(REN_DIR, "pet_idle.png"),
    sizes=[512, 200, 120, 72],
    out_path=os.path.join(REN_DIR, "_use_size.png"),
)

# The drip has to survive the same shrink the face had to. A viscous detail that
# only exists at 512 px is decoration for the build log, not for the desktop.
use_size.require_use_size(
    os.path.join(ANIM_DIR, "hop_18.png"),          # just after impact: full spray
    sizes=[512, 200, 120, 72],
    out_path=os.path.join(REN_DIR, "_use_size_shed.png"),
)

print("[pet] DONE")
