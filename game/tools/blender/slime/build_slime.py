# build_slime.py — gelatinous prairie slime, motor tier M3.
#
# Motion set (approved by Joan 2026-07-18, unchanged):
#   idle-loop  breathing wobble
#   hop-loop   locomotion — slimes don't walk, they hop
#   hit        flinch on taking a blow
#   attack     crouch + forward lunge
#   death      bursts into droplets that fall, flatten and soak into the ground
# Fast/slow variants are playback speed in Godot (speed_scale), not extra anims.
# "-loop" suffix => Godot glTF import auto-loops. Export mode: NLA tracks.
#
# Plus two shape keys NO clip touches — lean_x / lean_y — which slime.gd drives
# from live velocity so the gel deforms toward wherever the mob is travelling.
#
# M3 REWORK (2026-07-30). The previous build shaded the gel with procedural
# shader nodes (TexNoise / TexVoronoi / LayerWeight). glTF cannot express
# procedurals, so the exporter dropped them and wrote baseColorFactor 1,1,1 —
# the GLB reaching Godot was an untinted WHITE dome, while the showcase render
# showed green jelly with bubbles. The old code even said so in a comment
# ("a bake pass is required before the GLB carries these into Godot") and the
# bake never happened. See docs/art/_motor_tiers.md.
#
# What changed, per the M3 checklist:
#   * All colour now lives in a FLOAT_COLOR vertex layer, which DOES export.
#     Depth gradient + suspended bubbles + equator rim + socket occlusion are
#     baked per-vertex instead of evaluated by nodes.
#   * Perlin surface displacement so the body is a settled gel mass, not a
#     mathematically perfect dome.
#   * Facial relief available but OFF for the common slime (Joan, 2026-07-30 —
#     "se siente raro"); kept opt-in via --face for the king slime, where an
#     expressive face is canon. When on it follows the Tensura rule in
#     _references/slime_tensura/_synthesis.md: relief only, no teeth, no nose,
#     no pupils.
#   * Seeded shape variants (the seed changes FORM, not just colour).
#   * Habitat palettes are vertex-colour swaps: prairie green, water blue.
#   * Tri budget asserted and printed at build time.
#   * shape_key_add wrapped to force from_mix=False (see gotcha below).
#
# Run: blender -b --factory-startup --python-exit-code 1 --python build_slime.py
#      [-- --seed N] [--no-face]
import bpy
import bmesh
import math
import os
import random
import sys
from mathutils import Vector, Matrix, noise as mnoise

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
ANIM_DIR = os.path.join(REN_DIR, "anim")
os.makedirs(ANIM_DIR, exist_ok=True)

TRI_BUDGET = 7600

# ---------- CLI ----------
_argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SEED = 20260730
# FACELESS by default (Joan, 2026-07-30): with sockets the common slime "se
# siente raro" — it reads as a creature watching you, which is not what a
# roadside blob should be. It goes back to being defined by HOW IT MOVES
# (_mob_style_contract.md §3). Facial relief is reserved for the KING slime,
# where an expressive face is canon (PO 2026-07-17). The relief code stays and
# is opt-in via --face, because king_slime is built from this same vocabulary.
WANT_FACE = False
for _i, _a in enumerate(_argv):
    if _a == "--seed" and _i + 1 < len(_argv):
        SEED = int(_argv[_i + 1])
    elif _a == "--face":
        WANT_FACE = True
    elif _a == "--no-face":
        WANT_FACE = False
rng = random.Random(SEED)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# ---------- body: gelatinous dome ----------
# Dense-but-not-wasteful: shape keys must export, so no subsurf — the vert count
# is the deformation resolution AND the vertex-colour resolution.
SEGMENTS, RINGS = 80, 40
bpy.ops.mesh.primitive_uv_sphere_add(segments=SEGMENTS, ring_count=RINGS, radius=0.5)
body = bpy.context.object
body.name = "slime"
me = body.data

# Seeded proportion: some slimes sit low and wide, others hold a taller mound.
squat = rng.uniform(0.72, 0.86)          # top compression
spread_amt = rng.uniform(0.16, 0.26)     # how much mass pools at the base
lean_x = rng.uniform(-0.05, 0.05)        # one asymmetric break (contract §1)

for v in me.vertices:
    z = v.co.z
    v.co.z = z * (squat if z > 0.0 else 0.55)
    # Mass pools toward the bottom — bottom-weighted silhouette.
    t = max(0.0, min(1.0, (0.08 - v.co.z) / 0.35))
    s = 1.0 + spread_amt * t
    v.co.x *= s
    v.co.y *= s
    v.co.x += lean_x * (v.co.z + 0.3)

# ---------- Perlin settling: a gel mass, not a perfect dome ----------
# Low frequency, low amplitude. Enough to break the mathematical silhouette,
# far below the level that would read as a rocky/noisy surface.
NOISE_SCALE = rng.uniform(1.7, 2.3)
NOISE_AMP = 0.022
noise_off = Vector((rng.uniform(-8, 8), rng.uniform(-8, 8), rng.uniform(-8, 8)))
for v in me.vertices:
    n = mnoise.noise(v.co * NOISE_SCALE + noise_off)
    # Fade the displacement out at the very bottom so the slime keeps a clean
    # contact with the ground instead of developing a wavy skirt.
    ground_fade = min(1.0, max(0.0, (v.co.z + 0.28) / 0.18))
    v.co += v.normal * (n * NOISE_AMP * ground_fade)

# ---------- facial features as RELIEF (Tensura rule) ----------
# Sunken sockets and a faint mouth pressed INTO the gel. No separate pieces, no
# teeth, no nose, no pupils — the face reads by its own shadow.
# -Y is the facing direction (the lunge shape key throws that way).
#
# Placement matters more than depth here. Pass 1 put the sockets close together
# and low on the face with a round dimple under them: read as a pig snout —
# two nostrils and a muzzle. Fix is geometric, not a depth tweak: push the
# sockets WIDE and UP into the upper dome, flatten them into lidded almonds,
# and turn the mouth into a wide shallow crease instead of a round hole.
FACE_PARTS = []
if WANT_FACE:
    eye_z = 0.150
    eye_x = 0.255
    FACE_PARTS = [
        # (centre, radius, depth, x_stretch, z_stretch)
        (Vector((-eye_x, -0.40, eye_z)), 0.125, 0.042, 1.35, 0.52),
        (Vector((eye_x, -0.40, eye_z)), 0.125, 0.042, 1.35, 0.52),
        (Vector((0.0, -0.46, 0.005)), 0.185, 0.019, 2.40, 0.30),
    ]

    def relief_at(co):
        """Returns (displacement_metres, shade_0_to_1) for this vertex.

        The two are deliberately separate. Displacement is absolute depth, but
        SHADE is normalised per feature: dividing every feature's shade by the
        eyes' depth (as the first version did) meant the shallow mouth — a third
        as deep by design, because a deep mouth reads as a hole — could only ever
        reach a third of the darkening, and it stayed invisible.
        """
        best_disp = 0.0
        best_shade = 0.0
        for centre, radius, depth, xs, zs in FACE_PARTS:
            d = co - centre
            d.x /= xs
            d.z /= zs
            dist = d.length
            if dist < radius:
                # Smooth cosine falloff — a hard edge would read as a cut, not
                # a socket in something soft.
                fall = 0.5 + 0.5 * math.cos(math.pi * (dist / radius))
                if fall * depth > best_disp:
                    best_disp = fall * depth
                best_shade = max(best_shade, fall)
        return best_disp, best_shade

    for v in me.vertices:
        disp, _ = relief_at(v.co)
        if disp > 0.0:
            v.co -= v.normal * disp

for p in me.polygons:
    p.use_smooth = True

# Sit the body ON the origin instead of straddling it. The sphere is built
# centred, so without this the mesh's base lands ~0.28 below its own origin —
# 0.40 m under the floor once Godot scales it, with the opaque ground hiding the
# bottom third and every "landed" droplet burying itself out of sight. The style
# contract asks for base at Y=0 precisely so Godot can drop an asset on terrain.
_base_offset = min(v.co.z for v in me.vertices)
for v in me.vertices:
    v.co.z -= _base_offset

BODY_VERT_COUNT = len(me.vertices)
Z_MIN = 0.0
Z_MAX = max(v.co.z for v in me.vertices)
H = Z_MAX - Z_MIN
R_MAX = max(math.hypot(v.co.x, v.co.y) for v in me.vertices)

# ---------- death droplets: separate islands living inside the body ----------
# Joan (2026-07-30): the slime should BURST into droplets that fall, flatten and
# soak into the ground — not squash flat and vanish.
#
# Shape keys cannot tear a connected surface apart: pulling one region away from
# another on a single continuous mesh stretches strands between them. So the
# droplets exist from the start as their own disconnected islands, parked at a
# near-zero radius inside the body where nothing can see them (8 mm across
# inside a 1.1 m translucent blob), and the death keys blow them outward.
#
# They are kept tiny rather than fully collapsed on purpose: a degenerate island
# with every vertex on one point produces zero-area faces, which break normal
# recalculation and can trip the exporter.
N_DROPS = 12
DROP_HIDDEN_RADIUS = 0.004
drops = []          # (vertex indices, flight position, floor position, radius)

_bm = bmesh.new()
_bm.from_mesh(me)
_hidden_centre = Vector((0.0, 0.0, Z_MIN + H * 0.45))
for _i in range(N_DROPS):
    _ang = math.tau * (_i + rng.uniform(0.15, 0.85)) / N_DROPS
    _radius = rng.uniform(0.055, 0.115)
    _existing = set(v.index for v in _bm.verts) if _bm.verts else set()
    _before = len(_bm.verts)
    # subdivisions=2: at 1 a droplet is a bare icosahedron and reads as a green
    # gem rather than a blob of gel, which is very visible at this size.
    _res = bmesh.ops.create_icosphere(
        _bm, subdivisions=2, radius=DROP_HIDDEN_RADIUS,
        matrix=Matrix.Translation(_hidden_centre))
    _new_verts = _res["verts"]
    # Where it flies to at the peak of the burst, and where it lands after.
    # Kept close: a 1.5 m slime throwing droplets 2.3 m reads as an explosion,
    # and the puddles ended up outside the frame entirely.
    _fly_dist = R_MAX * rng.uniform(0.30, 0.62)
    _fly = Vector((math.cos(_ang) * _fly_dist,
                   math.sin(_ang) * _fly_dist,
                   Z_MIN + H * rng.uniform(0.55, 0.95)))
    _floor_dist = _fly_dist * rng.uniform(1.10, 1.30)
    # Resting ON the ground plane (z = 0), squashed, so the flattened puddle
    # still shows above it.
    _floor = Vector((math.cos(_ang) * _floor_dist,
                     math.sin(_ang) * _floor_dist,
                     _radius * 0.22))
    drops.append({"verts": _new_verts, "fly": _fly, "floor": _floor,
                  "radius": _radius, "centre": _hidden_centre.copy()})
_bm.verts.index_update()
_bm.faces.ensure_lookup_table()
# Droplet faces shade smooth like the body — a faceted droplet next to a smooth
# blob reads as a different material.
for _f in _bm.faces:
    _f.smooth = True
_bm.to_mesh(me)
_bm.free()

# Index lists have to be resolved AFTER to_mesh: BMVert.index is stale right
# after creation (the flower_pack lesson), and the shape keys address vertices
# by index into me.vertices.
DROP_INDEX_SETS = []
_cursor = BODY_VERT_COUNT
for _d in drops:
    _count = len(_d["verts"])
    DROP_INDEX_SETS.append(list(range(_cursor, _cursor + _count)))
    _cursor += _count
DROP_VERT_TOTAL = _cursor - BODY_VERT_COUNT

# ---------- vertex colour: the gel, baked so it actually ships ----------
# Everything the old node graph did, evaluated per-vertex instead:
#   depth gradient   deep tone low in the body, bright tone up top
#   bubbles          light blooms where a suspended bubble meets the surface
#   equator rim      the widest band catches light (view-independent stand-in
#                    for the old Fresnel rim, which cannot be baked)
#   socket occlusion slight darkening inside the facial relief
# Palettes are (deep, bright, bubble) triplets — habitat = palette swap.
#
# Values are tuned for the contract's ficha rig (key/fill/rim 110/30/130 W,
# view_transform Standard), which multiplies them up hard — pass 1 used albedo
# picked as if it were the final screen colour and rendered as pale mint. These
# are deliberately deep so the lit result lands on saturated jelly.
PALETTES = {
    "green": ((0.014, 0.105, 0.028), (0.055, 0.330, 0.085), (0.230, 0.620, 0.290)),
    "blue": ((0.012, 0.055, 0.150), (0.075, 0.230, 0.400), (0.300, 0.560, 0.720)),
}

# Fewer but LARGER bubbles. Vertex colour cannot resolve a feature smaller than
# the vertex spacing, and at 80 segments on a 0.55 m radius that spacing is
# ~0.043 m — the previous 0.032-0.075 m radii were one or two vertices across,
# so each bubble tinted ~2 verts and read as a faint smudge (measured: 24 of
# 2699 verts above green 0.55). Radii from ~1.3x to ~3.4x the spacing give each
# bubble 3-7 vertices to sit on, and the size spread is what the contract asks
# for ("varied sizes drifting through the gel").
N_BUBBLES = rng.randint(12, 17)
bubbles = []
# Anchor each bubble just under an actual surface vertex instead of sampling a
# cylinder of "inside the body". The cylinder did not match a squashed dome, so
# bubbles landed either OUTSIDE the mesh near the top (where the body's radius
# is small) or too deep in the middle to reach the surface at all.
#
# The burial depth is the part that has to be small. At 0.4-0.6r the nearest
# surface point sits half a radius from the centre, so the falloff there is only
# ~0.5 of its peak — and squaring it for a crisp edge cut that to ~0.25.
# Measured result: 2 of 2699 vertices tinted at all, peak green 0.41 against a
# 0.62 target. Keeping the centre just beneath the skin puts the falloff's PEAK
# on the surface, and the cosine curve already falls to zero at the rim, so the
# edge stays defined without squaring it.
_surface_pool = [v for v in me.vertices[:BODY_VERT_COUNT]
                 if (v.co.z - Z_MIN) / H > 0.22]   # skip the ground contact ring
# Body vertices only: the death droplets sit at the body's centre, so anchoring a
# bubble to one would paint a bloom in mid-air that appears when they burst out.
for _ in range(N_BUBBLES):
    v = _surface_pool[rng.randrange(len(_surface_pool))]
    radius = rng.uniform(0.058, 0.145)
    centre = v.co - v.normal * (radius * rng.uniform(0.05, 0.20))
    bubbles.append((centre.copy(), radius))


def lerp3(a, b, t):
    t = max(0.0, min(1.0, t))
    return (a[0] + (b[0] - a[0]) * t,
            a[1] + (b[1] - a[1]) * t,
            a[2] + (b[2] - a[2]) * t)


def gel_color(co, palette):
    deep, bright, bubble = palette
    zn = (co.z - Z_MIN) / H
    # Depth gradient. Exponent > 1 keeps the deep tone across the lower body so
    # the mass reads as thick gel; pass 1's 0.72 let the bright tone flood
    # almost the whole dome and the body came out uniform.
    col = lerp3(deep, bright, zn ** 1.25)
    # Equator rim: brightest where the body is widest.
    r = math.hypot(co.x, co.y) / R_MAX
    rim = max(0.0, (r - 0.80) / 0.20) * (1.0 - abs(zn - 0.42) * 1.5)
    if rim > 0.0:
        col = lerp3(col, bright, min(1.0, rim) * 0.55)
    # Bubbles: distance to the nearest suspended bubble centre. The raised
    # cosine already reaches zero at the rim, so the edge is defined without
    # squaring it — squaring only crushed the peak (see the anchoring note).
    best = 0.0
    for centre, radius in bubbles:
        d = (co - centre).length
        if d < radius:
            best = max(best, 0.5 + 0.5 * math.cos(math.pi * (d / radius)))
    if best > 0.0:
        col = lerp3(col, bubble, best * 0.95)
    # Socket occlusion — reinforces the relief's own shadow, never a feature
    # colour of its own (Tensura rule: the face is not painted on).
    if WANT_FACE:
        _, shade = relief_at(co)
        if shade > 0.0:
            # Carries most of the face's read: baked occlusion is fixed data, so
            # the sockets stay legible from any angle. Relying on the relief's
            # own lit shadow alone made the key-lit side visible and the fill
            # side almost disappear.
            col = (col[0] * (1.0 - 0.46 * shade),
                   col[1] * (1.0 - 0.46 * shade),
                   col[2] * (1.0 - 0.46 * shade))
    return col


def bake_vcol(palette_name):
    """(Re)write the FLOAT_COLOR layer for a habitat palette.

    FLOAT_COLOR, never BYTE_COLOR: BYTE_COLOR applies an implicit sRGB decode
    on readback with no matching encode on write, crushing hand-picked tones
    ~12x darker. Confirmed project-wide bug (golem_guardian, 2026-07-20).
    """
    palette = PALETTES[palette_name]
    bm = bmesh.new()
    bm.from_mesh(me)
    layer = bm.loops.layers.float_color.get("Col") or bm.loops.layers.float_color.new("Col")
    for face in bm.faces:
        for loop in face.loops:
            c = gel_color(loop.vert.co, palette)
            loop[layer] = (c[0], c[1], c[2], 1.0)
    bm.to_mesh(me)
    bm.free()


bake_vcol("green")

# ---------- tri budget ----------
me.calc_loop_triangles()
TRIS = len(me.loop_triangles)
print(f"[slime] tris={TRIS} budget={TRI_BUDGET} "
      f"{'OK' if TRIS <= TRI_BUDGET else '!! OVER BUDGET !!'}")
print(f"[slime] seed={SEED} height={H:.3f}m width={R_MAX * 2:.3f}m face={WANT_FACE}")


# ---------- shape keys: the viscous vocabulary ----------
def add_key(name):
    """shape_key_add defaults to value=1.0 + from_mix=True, which makes each new
    key's untouched vertices inherit the SUM of every prior key at full weight —
    silent multi-metre corruption on any mob with several keys (cost hours on
    the turtle, 2026-07-18). Force both off, always."""
    k = body.shape_key_add(name=name, from_mix=False)
    k.value = 0.0
    return k


add_key("Basis")

sk = add_key("squash")      # sat-down blob, mass pushed out
for i, v in enumerate(me.vertices):
    zn = (v.co.z - Z_MIN) / H
    nz = Z_MIN + (v.co.z - Z_MIN) * 0.80
    spread = 1.0 + 0.14 * (1.0 - zn)
    sk.data[i].co = Vector((v.co.x * spread, v.co.y * spread, nz))

sk = add_key("stretch")     # gel pulls upward, waist narrows
for i, v in enumerate(me.vertices):
    nz = Z_MIN + (v.co.z - Z_MIN) * 1.16
    sk.data[i].co = Vector((v.co.x * 0.93, v.co.y * 0.93, nz))

sk = add_key("sway")        # top mass lags sideways (viscous lag)
for i, v in enumerate(me.vertices):
    zn = (v.co.z - Z_MIN) / H
    sk.data[i].co = v.co + Vector((0.10 * zn ** 1.6, 0.0, 0.0))

sk = add_key("lunge")       # top mass throws FORWARD (-Y = face side)
for i, v in enumerate(me.vertices):
    zn = (v.co.z - Z_MIN) / H
    sk.data[i].co = v.co + Vector((0.0, -0.22 * zn ** 1.5, 0.0))

# ---------- death: burst into droplets, they land, flatten and soak away ------
# Three keys sequenced by the death clip, replacing the old single "melt" that
# just squashed the body flat (Joan, 2026-07-30: it should burst, not deflate).
#
# The body and the droplets move in opposite directions in the SAME key: as the
# blob collapses through the floor, the droplets fly out. Interpolating burst ->
# settle then gives the arc for free, because a shape key is a straight line
# between two poses and two poses is exactly what an arc needs.


def _collapse_body(key):
    """The body is gone in all three death poses — it only has to leave once."""
    for i in range(BODY_VERT_COUNT):
        v = me.vertices[i]
        key.data[i].co = Vector((v.co.x * 0.18, v.co.y * 0.18,
                                 -0.14 + v.co.z * 0.10))


def _drop_offset(idx, meta):
    """This vertex's direction within its own island, normalised out of the
    hidden radius so a droplet can be re-inflated to any size."""
    return (me.vertices[idx].co - meta["centre"]) / DROP_HIDDEN_RADIUS


sk = add_key("burst")       # body drops away, droplets fly outward and up
_collapse_body(sk)
for meta, indices in zip(drops, DROP_INDEX_SETS):
    for idx in indices:
        sk.data[idx].co = meta["fly"] + _drop_offset(idx, meta) * meta["radius"]

sk = add_key("settle")      # droplets have landed and spread into flat puddles
_collapse_body(sk)
for meta, indices in zip(drops, DROP_INDEX_SETS):
    for idx in indices:
        offset = _drop_offset(idx, meta)
        # Wider than the airborne droplet and pressed thin: surface tension lost
        # against the ground.
        sk.data[idx].co = meta["floor"] + Vector((
            offset.x * meta["radius"] * 1.55,
            offset.y * meta["radius"] * 1.55,
            offset.z * meta["radius"] * 0.22))

sk = add_key("soak")        # puddles sink into the ground and shrink to nothing
_collapse_body(sk)
for meta, indices in zip(drops, DROP_INDEX_SETS):
    for idx in indices:
        offset = _drop_offset(idx, meta)
        # Just under the ground plane: the puddle is drawn INTO the floor rather
        # than deleted, which is what makes it read as soaking away.
        sunk = Vector((meta["floor"].x, meta["floor"].y, -meta["radius"] * 0.45))
        sk.data[idx].co = sunk + Vector((
            offset.x * meta["radius"] * 0.75,
            offset.y * meta["radius"] * 0.75,
            offset.z * meta["radius"] * 0.10))


# ---------- directional lean: the gel spills the way it travels ----------
# Joan (2026-07-30): "si se mueve hacia el frente, que se deforme hacia esa
# dirección". That depends on the mob's live velocity, so it CANNOT be a clip —
# per the motor's division of labour, a fixed loop belongs in bpy and anything
# driven by a gameplay variable belongs in Godot. These two keys are the
# vocabulary; slime.gd drives their weights every frame.
#
# They are deliberately NOT in ALL_KEYS, so no clip writes a track for them and
# the AnimationPlayer cannot fight the script for control.
#
# Signed weights give all four directions from two keys: Godot accepts blend
# shape values outside 0..1, and a morph target is a vertex delta, so weight -1
# is exactly the opposite lean. No need for four separate keys.
#
# Volume is conserved rather than translated (the squash-and-stretch rule from
# _references/slime_tensura/motion/_motion.md): as the upper mass carries over,
# the body loses a little height and gains a little width at the base, the way
# a gel blob actually spills. Pure translation reads as a solid sliding.
def _lean_key(name, axis):
    """axis: 0 = +X, 1 = -Y (which is the model's facing direction)."""
    k = add_key(name)
    for i, v in enumerate(me.vertices):
        zn = (v.co.z - Z_MIN) / H
        # Top leads, base drags along. Raised from 0.185 after the first pass
        # read as a tilt rather than a gel spilling — at this size the shape key
        # is the ceiling on how much wobble the driver can ever express.
        carry = 0.235 * (zn ** 1.35) + 0.045
        x, y = v.co.x, v.co.y
        if axis == 0:
            x += carry
            widen_axis_y = 1.0 + 0.05 * (1.0 - zn)
            y *= widen_axis_y
        else:
            y -= carry
            widen_axis_x = 1.0 + 0.05 * (1.0 - zn)
            x *= widen_axis_x
        # Spilling costs height — a leaning blob settles, it does not stay tall.
        nz = Z_MIN + (v.co.z - Z_MIN) * (1.0 - 0.07 * zn)
        k.data[i].co = Vector((x, y, nz))
    return k


_lean_key("lean_x", 0)
_lean_key("lean_y", 1)

kb = me.shape_keys.key_blocks
FPS = 24
scene.render.fps = FPS


def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


# ---------- animation definitions ----------
def anim_idle(t):
    w = math.sin(2 * math.pi * t)
    return {"squash": max(0.0, w) * 0.55, "stretch": max(0.0, -w) * 0.40,
            "sway": 0.5 + 0.5 * math.sin(4 * math.pi * t + math.pi / 3)}


def anim_hop(t):
    """Deformation ONLY — the arc belongs to physics.

    This clip used to raise the body 0.45 m itself, which double-jumped the
    slime in game: slime.gd already drives the hop with `velocity.y =
    hop_force` on the CharacterBody3D, so the animation's lift stacked on top
    (0.45 x 1.45 scale = 0.65 m extra) and floated the mesh off its own
    collision shape. Measured in the GLB: hop-loop was the only clip carrying a
    `translation` channel; every other clip animates weights alone.

    Keeping the squash/stretch here and the travel in physics is also the better
    split — real gravity gives weight for free, and the clip stays correct at any
    hop_force the designer tunes to.
    """
    v = {"squash": 0.0, "stretch": 0.0, "sway": 0.0}
    if t < 0.20:                    # anticipation: crouch
        v["squash"] = lerp(0.0, 0.75, t / 0.20)
    elif t < 0.30:                  # launch: gel pulls up off the ground
        u = (t - 0.20) / 0.10
        v["squash"] = lerp(0.75, 0.0, u)
        v["stretch"] = lerp(0.0, 0.55, u)
    elif t < 0.70:                  # airborne: stretch relaxes toward the apex
        u = (t - 0.30) / 0.40
        v["stretch"] = lerp(0.55, 0.25, u)
    elif t < 0.80:                  # impact
        u = (t - 0.70) / 0.10
        v["squash"] = lerp(0.0, 0.80, u)
    else:                           # settle wobble
        u = (t - 0.80) / 0.20
        v["squash"] = lerp(0.80, 0.0, u)
        v["sway"] = 0.4 * math.sin(2 * math.pi * u)
    return v


def anim_hit(t):
    return {"squash": 0.6 * math.sin(math.pi * t),
            "sway": 0.9 * math.sin(math.pi * min(1.0, t * 1.6))}


def anim_attack(t):
    v = {"squash": 0.0, "stretch": 0.0, "lunge": 0.0}
    if t < 0.30:                    # crouch back
        v["squash"] = lerp(0.0, 0.6, t / 0.30)
    elif t < 0.55:                  # throw forward
        u = (t - 0.30) / 0.25
        v["squash"] = lerp(0.6, 0.0, u)
        v["lunge"] = lerp(0.0, 1.0, u)
        v["stretch"] = 0.35 * math.sin(math.pi * u)
    else:                           # recover
        u = (t - 0.55) / 0.45
        v["lunge"] = lerp(1.0, 0.0, u)
    return v


def anim_death(t):
    """Burst -> fall -> flatten -> soak away.

    The three poses are exclusive rather than additive: each phase blends from
    one to the next, since summing two full poses would place a droplet at the
    sum of two positions instead of somewhere between them.
    """
    v = {"squash": 0.0, "stretch": 0.0, "burst": 0.0, "settle": 0.0, "soak": 0.0}
    if t < 0.07:
        # Anticipation: the blob swells for an instant before it goes. Without
        # this the burst reads as a cut rather than a rupture.
        u = t / 0.07
        v["stretch"] = 0.45 * math.sin(math.pi * u * 0.5)
    elif t < 0.22:
        # Rupture. Fast — this is the moment that has to land.
        u = (t - 0.07) / 0.15
        v["burst"] = u * u * (3.0 - 2.0 * u)     # smoothstep
    elif t < 0.42:
        # Falling: burst -> settle carries the droplets down and outward along
        # the straight line between the two poses, which reads as the arc.
        u = (t - 0.22) / 0.20
        # Squared so they accelerate downward instead of drifting linearly —
        # droplets fall under gravity, they do not glide.
        fall = u * u
        v["burst"] = 1.0 - fall
        v["settle"] = fall
    elif t < 0.52:
        v["settle"] = 1.0                        # puddles hold for a beat
    else:
        # Soaking gets the whole back half. It is the slowest beat by design:
        # absorption is the thing being read here, and at a fifth of the clip it
        # played as the puddles simply blinking out.
        u = (t - 0.52) / 0.48
        v["settle"] = 1.0 - u
        v["soak"] = u                            # absorbed into the ground
    return v


ANIMS = {
    "idle-loop": (72, anim_idle),
    "hop-loop": (48, anim_hop),
    "hit": (12, anim_hit),
    "attack": (22, anim_attack),
    # Longer than the others on purpose: burst, fall, flatten and soak are four
    # readable beats, and at the old 28 frames they blurred into one event.
    "death": (44, anim_death),
}

ALL_KEYS = ("squash", "stretch", "sway", "lunge", "burst", "settle", "soak")
sk_ad = me.shape_keys.animation_data_create()
obj_ad = body.animation_data_create()
actions = {}
for name, (frames, sampler) in ANIMS.items():
    act_sk = bpy.data.actions.new(f"{name}_sk")
    sk_ad.action = act_sk
    act_obj = bpy.data.actions.new(f"{name}_obj")
    obj_ad.action = act_obj
    for f in range(1, frames + 1, 2):
        t = (f - 1) / (frames - 1)
        vals = sampler(t)
        for k in ALL_KEYS:
            kb[k].value = vals.get(k, 0.0)
            kb[k].keyframe_insert("value", frame=f)
        # Object translation is keyed ONLY if a sampler asks for it. No sampler
        # does any more (see anim_hop): travel is physics' job, and an unwanted
        # translation channel fights the CharacterBody3D that owns the movement.
        if "z" in vals:
            body.location.z = vals["z"]
            body.keyframe_insert("location", frame=f)
    actions[name] = (frames, act_sk, act_obj)
sk_ad.action = None
obj_ad.action = None

# ---------- material: thin, and it EXPORTS ----------
# The gel colour is in the vertex layer, so the material only has to carry what
# glTF can actually represent: translucency (alphaMode BLEND + alpha), a low
# roughness for the wet highlight, and baseColor left WHITE so COLOR_0
# multiplies through untouched (glTF guarantees COLOR_0 x baseColorFactor).
# No SSS, no transmission: Godot 4 ignores KHR_materials_transmission, and SSS
# has no glTF equivalent at all.
def mat_gel(alpha=0.78):
    m = bpy.data.materials.new("slime_gel")
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Base Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    # Gel, not polished plastic. At 0.16 the key light produced one small hard
    # white blowout across the top of the dome; a wetter-looking gel wants a
    # broad soft highlight, so the roughness goes up and the specular level
    # comes down.
    n.inputs["Roughness"].default_value = 0.38
    if "Specular IOR Level" in n.inputs:
        n.inputs["Specular IOR Level"].default_value = 0.35
    n.inputs["IOR"].default_value = 1.33
    n.inputs["Alpha"].default_value = alpha
    # Drive Base Color from the exported vertex layer so the Blender preview
    # matches what Godot will show — same data, same result, no divergence.
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    nt.links.new(attr.outputs["Color"], n.inputs["Base Color"])
    if hasattr(m, "surface_render_method"):
        m.surface_render_method = 'BLENDED'
    if hasattr(m, "blend_method"):
        m.blend_method = 'BLEND'
    # Closed blob + alpha blend: cull backfaces or the far side sorts in front.
    m.use_backface_culling = True
    return m


gel = mat_gel()
me.materials.append(gel)

# ---------- showcase-ficha scene (mob style contract §4) ----------
world = bpy.data.worlds.new("ficha")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.30, 0.22, 0.48, 1.0)


def add_light(name, loc, energy, size):
    ld = bpy.data.lights.new(name, type='AREA')
    ld.energy = energy
    ld.size = size
    lo = bpy.data.objects.new(name, ld)
    lo.location = loc
    bpy.context.collection.objects.link(lo)
    lo.rotation_mode = 'QUATERNION'
    lo.rotation_quaternion = (lo.location.to_track_quat('Z', 'Y'))
    return lo


add_light("key", (-1.6, -1.0, 1.2), 110, 1.6)
add_light("fill", (1.4, -0.9, 0.4), 30, 1.5)
add_light("rim", (0.3, 1.6, 1.0), 130, 1.5)

target = bpy.data.objects.new("target", None)
target.location = (0, 0, 0.10)
bpy.context.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 50
cam = bpy.data.objects.new("cam", cd)
cam.location = (-0.9, -2.3, 0.75)
bpy.context.collection.objects.link(cam)
cam.constraints.new(type='TRACK_TO').target = target
scene.camera = cam

try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.eevee.taa_render_samples = 64
scene.view_settings.view_transform = 'Standard'   # AgX washes everything to pastel

# ---------- renders: preview frames per animation ----------
scene.render.resolution_x = 512
scene.render.resolution_y = 640
for name, (frames, act_sk, act_obj) in actions.items():
    sk_ad.action = act_sk
    obj_ad.action = act_obj
    for f in range(1, frames + 1, 2):
        scene.frame_set(f)
        scene.render.filepath = os.path.join(ANIM_DIR, f"{name.replace('-loop', '')}_{f:03d}.png")
        bpy.ops.render.render(write_still=True)
    print("[slime] frames", name)
sk_ad.action = None
obj_ad.action = None
body.location = (0, 0, 0)
for k in ALL_KEYS:      # actions leave the last evaluated values behind
    kb[k].value = 0.0
scene.frame_set(1)

# ---------- hero stills + close-ups (never a single overview render) ----------
sys.path.insert(0, os.path.dirname(OUT_DIR))
import _ficha_common as ficha

MOB_HX = R_MAX + 0.06
MOB_HY = R_MAX + 0.06
SIL_DIST = (MOB_HX ** 2 + MOB_HY ** 2) ** 0.5 + 0.4 + 0.254
right_dir = ficha.camera_right_vector(cam, target)
sil_loc = (right_dir * SIL_DIST)
sil_loc.z = 0.0
sil = ficha.add_scale_silhouette(location=tuple(sil_loc))
sil_bb = ficha.silhouette_bbox(location=tuple(sil_loc))
old_target_loc, old_cam_loc = ficha.frame_hero_camera(
    cam, target,
    x_min=min(-MOB_HX, sil_bb[0]), x_max=max(MOB_HX, sil_bb[1]),
    y_min=min(-MOB_HY, sil_bb[2]), y_max=max(MOB_HY, sil_bb[3]),
    z_min=0.0, z_max=max(Z_MAX, sil_bb[5]))

scene.render.resolution_x = 1024
scene.render.resolution_y = 1280
for pal in PALETTES:
    bake_vcol(pal)
    scene.render.filepath = os.path.join(REN_DIR, f"slime_{pal}.png")
    bpy.ops.render.render(write_still=True)
bake_vcol("green")

ficha.restore_hero_camera(cam, target, old_target_loc, old_cam_loc)
ficha.remove_scale_silhouette(sil)

# Multi-angle + macro: the wide ficha shot hid an oversized-dab failure on
# flower_pack and a scale bug on tree_pack. Judge at BOTH distances, and from
# more than one side.
scene.render.resolution_x = 800
scene.render.resolution_y = 800
#
# Distances are derived, not guessed: a 36mm sensor at focal f sees
# (36/f) x D metres across, so framing a 1.11m-wide body with margin needs
# D >= 1.5 * f / 36. Pass 2 sat at 1.35m with a 50mm lens (0.97m visible) and
# cropped the slime's own base off every frame.
ANGLES = [
    ("face", (0.0, -2.10, 0.42), 50),        # straight at the relief
    ("threequarter", (-1.60, -1.60, 0.56), 50),
    ("side", (-2.10, 0.05, 0.42), 50),
    # Long lens from OUTSIDE the body — at 0.62m the camera sat inside the mesh
    # (R_MAX alone is ~0.55) and rendered flat interior green.
    ("macro_face", (0.0, -1.75, 0.30), 85),
    ("playereye", (0.0, -2.60, 1.65), 35),   # what the player actually sees
]
for label, loc, lens in ANGLES:
    cam.location = loc
    cd.lens = lens
    target.location = (0.0, 0.0, Z_MIN + H * (0.55 if label != "playereye" else 0.35))
    bpy.context.view_layer.update()          # settle TRACK_TO before rendering
    scene.render.filepath = os.path.join(REN_DIR, f"slime_view_{label}.png")
    bpy.ops.render.render(write_still=True)

# ---------- push all actions to NLA tracks (one glTF animation per track) ----------
for name, (frames, act_sk, act_obj) in actions.items():
    tr = sk_ad.nla_tracks.new()
    tr.name = name
    tr.strips.new(name, 1, act_sk)
    tr.mute = False
    tro = obj_ad.nla_tracks.new()
    tro.name = name
    tro.strips.new(name, 1, act_obj)
    tro.mute = False

# Creating NLA tracks while action=None makes them active evaluators at the
# CURRENT frame — re-assert rest as the LAST step before saving (golem_guardian
# lesson, 2026-07-19).
scene.frame_set(1)
body.location = (0, 0, 0)
for k in ALL_KEYS:
    kb[k].value = 0.0

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "slime_wip.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "slime.glb"),
    use_selection=False,
    export_animations=True,
    export_morph=True,
    export_animation_mode='NLA_TRACKS',
)
print(f"[slime] DONE tris={TRIS} seed={SEED}")
