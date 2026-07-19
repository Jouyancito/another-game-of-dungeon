# build_snake.py — prairie floor-1 snake: limbless reptile defined by MOTION.
# Mirrors game/tools/blender/slime/build_slime.py structure exactly (per
# _mob_style_contract.md): shape-key vocabulary -> NLA actions -> ficha
# showcase render -> GIF frames -> GLB export.
#
# Body: curve-swept tube (15 rings x 10 segments) along a resting S-curve
# backbone, tapering thin at the tail to a wedge-shaped head at the front.
# NO limbs, NO separate head mesh — head is the same tube, just wider/flatter.
#
# Animations (same clip names as every mob, Godot maps them identically):
#   idle-loop   breathing + head bob (tongue-flick suggestion)
#   move-loop   slither: 2 phase-shifted lateral shape keys (wave_a/wave_b)
#               combined as cos(t)*wave_a + sin(t)*wave_b = traveling S-wave
#   attack      coil back (anticipation) -> strike forward -> recover
#   hit         sharp lateral flinch
#   death       body flattens + straightens (goes limp)
#
# Run: blender -b --python build_snake.py
import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
ANIM_DIR = os.path.join(REN_DIR, "anim")
os.makedirs(ANIM_DIR, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def lerp(a, b, t):
    return a + (b - a) * t


def clamp01(x):
    return max(0.0, min(1.0, x))


def smoothstep(edge0, edge1, x):
    t = clamp01((x - edge0) / (edge1 - edge0))
    return t * t * (3.0 - 2.0 * t)


def bell(u):
    return math.sin(math.pi * clamp01(u))


# ---------- backbone: resting S-curve, low to the ground, head at -Y ----------
LENGTH = 0.70
AMP_S = 0.085
S_CYCLES = 1.35
S_PHASE = 0.30
HEAD_START = 0.72


def x_spine(u):
    return AMP_S * math.sin(2 * math.pi * S_CYCLES * u + S_PHASE)


def y_spine(u):
    return (0.5 - u) * LENGTH   # u=0 tail (+Y) -> u=1 nose (-Y, faces camera)


def z_spine(u):
    return 0.035 * smoothstep(0.80, 1.0, u)  # subtle alert lift; big lifts exposed the belly cream as a white 'beak'


# cross-section radius(u) + vertical squash(u): thin tail -> thick body ->
# tapered neck -> wide wedge head -> nose point.
RADIUS_CTRL = [
    (0.00, 0.000, 1.00),
    (0.10, 0.008, 0.95),
    (0.30, 0.026, 0.90),
    (0.50, 0.046, 0.88),
    (0.64, 0.045, 0.86),
    (0.74, 0.038, 0.82),
    (0.82, 0.070, 0.60),
    (0.95, 0.040, 0.55),
    (1.00, 0.014, 0.52),
]


def radius_profile(u):
    for i in range(len(RADIUS_CTRL) - 1):
        u0, r0, s0 = RADIUS_CTRL[i]
        u1, r1, s1 = RADIUS_CTRL[i + 1]
        if u0 <= u <= u1:
            t = 0.0 if u1 == u0 else (u - u0) / (u1 - u0)
            return lerp(r0, r1, t), lerp(s0, s1, t)
    return RADIUS_CTRL[-1][1], RADIUS_CTRL[-1][2]


# ---------- build mesh: chain of rings bridged into a tube ----------
RING_SEGMENTS = 10
N_RINGS = 15
ring_us = [(i + 0.5) / N_RINGS for i in range(N_RINGS)]

verts = []
V_U = []
V_RAD = []       # unit radial direction from spine center (0 for tips)
V_RADIUS = []    # distance from spine center (0 for tips)

verts.append(Vector((x_spine(0.0), y_spine(0.0), z_spine(0.0))))
V_U.append(0.0); V_RAD.append(Vector((0, 0, 0))); V_RADIUS.append(0.0)
TAIL_IDX = 0

ring_start = []
for u in ring_us:
    c = Vector((x_spine(u), y_spine(u), z_spine(u)))
    r, sq = radius_profile(u)
    du = 0.001
    u2 = min(1.0, u + du)
    c2 = Vector((x_spine(u2), y_spine(u2), z_spine(u2)))
    tangent = (c2 - c)
    tangent.z = 0.0
    if tangent.length < 1e-9:
        tangent = Vector((0, -1, 0))
    tangent.normalize()
    right = Vector((0, 0, 1)).cross(tangent)
    if right.length < 1e-9:
        right = Vector((1, 0, 0))
    right.normalize()

    ring_start.append(len(verts))
    for k in range(RING_SEGMENTS):
        theta = 2 * math.pi * k / RING_SEGMENTS
        ct, st = math.cos(theta), math.sin(theta)
        belly = 0.55 if st < 0 else 1.0     # flatten the underside (rests on ground)
        pos = c + right * (r * ct) + Vector((0, 0, r * sq * st * belly))
        verts.append(pos)
        V_U.append(u)
        radial = pos - c
        V_RADIUS.append(radial.length)
        V_RAD.append(radial.normalized() if radial.length > 1e-9 else Vector((0, 0, 1)))

verts.append(Vector((x_spine(1.0), y_spine(1.0), z_spine(1.0))))
V_U.append(1.0); V_RAD.append(Vector((0, 0, 0))); V_RADIUS.append(0.0)
NOSE_IDX = len(verts) - 1

faces = []
r0 = ring_start[0]
for k in range(RING_SEGMENTS):
    a = r0 + k
    b = r0 + (k + 1) % RING_SEGMENTS
    faces.append((TAIL_IDX, a, b))

for ri in range(len(ring_start) - 1):
    ra, rb = ring_start[ri], ring_start[ri + 1]
    for k in range(RING_SEGMENTS):
        a0, a1 = ra + k, ra + (k + 1) % RING_SEGMENTS
        b0, b1 = rb + k, rb + (k + 1) % RING_SEGMENTS
        faces.append((a0, a1, b1, b0))

rl = ring_start[-1]
for k in range(RING_SEGMENTS):
    a = rl + k
    b = rl + (k + 1) % RING_SEGMENTS
    faces.append((NOSE_IDX, b, a))

# ground: shift the whole tube up so the flattened belly touches Z=0
GROUND_SHIFT = -min(v.z for v in verts)
for v in verts:
    v.z += GROUND_SHIFT

me = bpy.data.meshes.new("snake_mesh")
me.from_pydata([tuple(v) for v in verts], [], faces)
me.update()

bm = bmesh.new()
bm.from_mesh(me)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(me)
bm.free()
for p in me.polygons:
    p.use_smooth = True

body = bpy.data.objects.new("snake", me)
bpy.context.collection.objects.link(body)

# ---------- shape keys: the slither vocabulary ----------
body.shape_key_add(name="Basis")

BREATHE_AMT = 0.006
HEADBOB_AMT = 0.018
WAVE_AMT = 0.05
WAVE_CYCLES = 1.4
COIL_CURL_AMT = 0.06
COIL_BACK_AMT = 0.10
COIL_LIFT_AMT = 0.03
STRAIGHTEN_AMT = 1.15
STRIKE_FWD_AMT = 0.17
FLINCH_AMT = 0.08
FLINCH_BACK_AMT = 0.035
FLATTEN_SQUASH = 0.55
FLATTEN_STRAIGHTEN = 0.55
FLATTEN_SPREAD = 0.35


def headweight(u):
    # wider than the neck alone -- half the body should read as coiling/
    # striking, not just the last few centimeters near the nose.
    return smoothstep(0.46, 0.80, u)


def frontweight(u):
    return smoothstep(0.35, 0.75, u)


def wave_envelope(u):
    return lerp(1.5, 0.6, u)


def sk_breathe(i):
    u = V_U[i]
    return V_RAD[i] * (BREATHE_AMT * bell(u))


def sk_head_bob(i):
    u = V_U[i]
    return Vector((0.0, 0.0, HEADBOB_AMT * headweight(u)))


def sk_wave_a(i):
    u = V_U[i]
    return Vector((WAVE_AMT * wave_envelope(u) * math.cos(2 * math.pi * WAVE_CYCLES * u), 0.0, 0.0))


def sk_wave_b(i):
    u = V_U[i]
    return Vector((WAVE_AMT * wave_envelope(u) * math.sin(2 * math.pi * WAVE_CYCLES * u), 0.0, 0.0))


def sk_coil(i):
    u = V_U[i]
    hw = headweight(u)
    curl = COIL_CURL_AMT * math.sin(2 * math.pi * 2.0 * u) * bell(u)
    return Vector((curl, COIL_BACK_AMT * hw, COIL_LIFT_AMT * hw))


def sk_strike(i):
    u = V_U[i]
    hw = headweight(u)
    straighten = -x_spine(u) * STRAIGHTEN_AMT * (0.4 + 0.6 * hw)
    forward = -STRIKE_FWD_AMT * hw
    return Vector((straighten, forward, 0.0))


def sk_flinch(i):
    u = V_U[i]
    fw = frontweight(u)
    return Vector((FLINCH_AMT * fw, FLINCH_BACK_AMT * fw, 0.0))


def sk_flatten(i):
    u = V_U[i]
    b = max(bell(u), 0.15)
    vertical = -V_RAD[i].z * V_RADIUS[i] * FLATTEN_SQUASH * b
    straighten = -x_spine(u) * FLATTEN_STRAIGHTEN
    spread_dir = Vector((V_RAD[i].x, V_RAD[i].y, 0.0))
    if spread_dir.length > 1e-6:
        spread_dir.normalize()
    spread = spread_dir * (V_RADIUS[i] * FLATTEN_SPREAD * max(bell(u), 0.2))
    return Vector((straighten, 0.0, vertical)) + spread


SHAPE_DEFS = [
    ("breathe", sk_breathe),
    ("head_bob", sk_head_bob),
    ("wave_a", sk_wave_a),
    ("wave_b", sk_wave_b),
    ("coil", sk_coil),
    ("strike", sk_strike),
    ("flinch", sk_flinch),
    ("flatten", sk_flatten),
]

for name, fn in SHAPE_DEFS:
    sk = body.shape_key_add(name=name)
    for i in range(len(verts)):
        sk.data[i].co = me.vertices[i].co + fn(i)

kb = me.shape_keys.key_blocks
# GOTCHA: ShapeKey.value hard-clamps to [slider_min, slider_max], default
# [0.0, 1.0] -- NOT just a UI restriction. Any negative sample assigned via
# Python silently clamps to 0, which breaks the wave_a/wave_b quadrature
# traveling-wave technique (needs bipolar cos/sin). Widen the sliders BEFORE
# keyframing so negative values actually stick.
kb["wave_a"].slider_min, kb["wave_a"].slider_max = -1.2, 1.2
kb["wave_b"].slider_min, kb["wave_b"].slider_max = -1.2, 1.2
ALL_KEYS = tuple(name for name, _ in SHAPE_DEFS)
FPS = 24
scene.render.fps = FPS


# ---------- animation definitions: name -> (frames, sampler(t) -> {key: value}) ----------
def anim_idle(t):
    w = math.sin(2 * math.pi * t)
    return {
        "breathe": max(0.0, w) * 0.55,
        # non-negative: quick double-nod "flick" pulses, not a symmetric bob
        # (head_bob's slider stays default [0,1] -- see clamp gotcha below)
        "head_bob": max(0.0, math.sin(2 * math.pi * t * 2.0 + math.pi / 6)) * 0.4,
    }


def anim_move(t):
    theta = 2 * math.pi * t
    return {
        "wave_a": math.cos(theta),
        "wave_b": math.sin(theta),
        "breathe": 0.15 * math.sin(4 * math.pi * t),
    }


def anim_attack(t):
    v = {"coil": 0.0, "strike": 0.0}
    if t < 0.35:                        # anticipation: coil back
        v["coil"] = lerp(0.0, 1.0, t / 0.35)
    elif t < 0.60:                      # strike forward
        u = (t - 0.35) / 0.25
        v["coil"] = lerp(1.0, 0.0, u)
        v["strike"] = lerp(0.0, 1.0, u)
    else:                               # recover
        u = (t - 0.60) / 0.40
        v["strike"] = lerp(1.0, 0.0, u)
    return v


def anim_hit(t):
    return {"flinch": math.sin(math.pi * t)}


def anim_death(t):
    v = {"flatten": min(1.0, t * 1.3)}
    if t > 0.55:
        decay = 1.0 - min(1.0, (t - 0.55) / 0.45)
        v["wave_a"] = 0.12 * math.sin(2 * math.pi * (t - 0.55) / 0.45) * decay
    return v


ANIMS = {
    "idle-loop": (60, anim_idle),
    "move-loop": (48, anim_move),
    "attack": (30, anim_attack),
    "hit": (14, anim_hit),
    "death": (32, anim_death),
}

sk_ad = me.shape_keys.animation_data_create()
actions = {}
for name, (frames, sampler) in ANIMS.items():
    act_sk = bpy.data.actions.new(f"{name}_sk")
    sk_ad.action = act_sk
    for f in range(1, frames + 1, 2):
        t = (f - 1) / (frames - 1)
        vals = sampler(t)
        for k in ALL_KEYS:
            kb[k].value = vals.get(k, 0.0)
            kb[k].keyframe_insert("value", frame=f)
    actions[name] = (frames, act_sk)
sk_ad.action = None

# ---------- material: prairie greens, 2-tone scale pattern, belly lighter ----------
# Max 3 colors (contract): deep green base + olive green secondary + cream belly
# accent. Scale seams are a MULTIPLY shading pass on the base two colors (not a
# 4th hue). Node textures do NOT survive glTF export as-is — acceptable for now
# (matches slime precedent; a bake pass is a future step if Godot needs it).


def _mix_rgba(nt):
    node = nt.nodes.new("ShaderNodeMix")
    node.data_type = 'RGBA'
    a = [s for s in node.inputs if s.name == 'A' and s.type == 'RGBA'][0]
    b = [s for s in node.inputs if s.name == 'B' and s.type == 'RGBA'][0]
    out = [o for o in node.outputs if o.type == 'RGBA'][0]
    return node, a, b, out


def mat_snake():
    m = bpy.data.materials.new("snake_prairie")
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Roughness"].default_value = 0.58
    n.inputs["IOR"].default_value = 1.45

    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 16.0
    noise.inputs["Detail"].default_value = 2.0
    base_mix, ba, bb, base_out = _mix_rgba(nt)
    ba.default_value = (0.07, 0.22, 0.07, 1.0)   # deep green
    bb.default_value = (0.18, 0.40, 0.14, 1.0)   # olive green
    nt.links.new(noise.outputs["Fac"], base_mix.inputs["Factor"])

    # subtle scale-seam pattern via voronoi distance-to-edge, crisp threshold
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = 42.0
    vor.feature = 'DISTANCE_TO_EDGE'
    seam = nt.nodes.new("ShaderNodeMath")
    seam.operation = 'LESS_THAN'
    seam.inputs[1].default_value = 0.035
    nt.links.new(vor.outputs["Distance"], seam.inputs[0])

    mult, ma, mb, mout = _mix_rgba(nt)
    mult.blend_type = 'MULTIPLY'
    mb.default_value = (0.45, 0.45, 0.40, 1.0)   # darkening shade, not a new hue
    nt.links.new(base_out, ma)
    nt.links.new(seam.outputs["Value"], mult.inputs["Factor"])

    # belly lighter: local Z near the ground -> cream accent
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Position"], sep.inputs["Vector"])
    # reversed From Min/Max on purpose: z=0 (belly touching ground) -> factor 1
    # (cream, input B); z>=0.045 (upper body/back) -> factor 0 (green, input A)
    mapr = nt.nodes.new("ShaderNodeMapRange")
    mapr.inputs["From Min"].default_value = 0.05
    mapr.inputs["From Max"].default_value = 0.0
    nt.links.new(sep.outputs["Z"], mapr.inputs["Value"])

    belly_mix, bea, beb, belly_out = _mix_rgba(nt)
    beb.default_value = (0.58, 0.58, 0.34, 1.0)  # cream belly accent
    nt.links.new(mout, bea)
    nt.links.new(mapr.outputs["Result"], belly_mix.inputs["Factor"])
    nt.links.new(belly_out, n.inputs["Base Color"])
    return m


mat = mat_snake()
body.data.materials.append(mat)

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


add_light("key", (-1.62, -1.76, 1.35), 110, 1.6)
add_light("fill", (1.49, -1.35, 0.47), 30, 1.5)
add_light("rim", (0.27, 1.76, 1.22), 130, 1.5)

target = bpy.data.objects.new("target", None)
target.location = (0, -0.05, 0.06)
bpy.context.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 50
cam = bpy.data.objects.new("cam", cd)
cam.location = (-0.95, -0.62, 0.52)
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
scene.view_settings.view_transform = 'Standard'

# ---------- renders: preview frames per animation ----------
scene.render.resolution_x = 512
scene.render.resolution_y = 640
for name, (frames, act_sk) in actions.items():
    sk_ad.action = act_sk
    for f in range(1, frames + 1, 2):
        scene.frame_set(f)
        scene.render.filepath = os.path.join(ANIM_DIR, f"{name.replace('-loop', '')}_{f:03d}.png")
        bpy.ops.render.render(write_still=True)
    print("[snake] frames", name)
sk_ad.action = None
for k in ALL_KEYS:      # actions leave the last evaluated values behind -- reset to rest
    kb[k].value = 0.0

# ---------- hero still: scale silhouette (mob style contract §4, Pokedex rule) ----------
# NOTE (2026-07-19): a naive world-X offset landed the silhouette almost on
# top of the snake here — this camera is a genuine 3/4 view (cam offset on
# BOTH X and Y), so world-X != screen-right. Placing along the camera's
# ACTUAL right vector (ficha.camera_right_vector) fixed it.
sys.path.insert(0, os.path.dirname(OUT_DIR))
import _ficha_common as ficha

MOB_HX, MOB_HY, MOB_ZMAX = 0.16, 0.36, 0.10  # snake lateral wiggle / nose-tail length / low profile
SIL_DIST = (MOB_HX ** 2 + MOB_HY ** 2) ** 0.5 + 0.4 + 0.254
right_dir = ficha.camera_right_vector(cam, target)
sil_loc = (right_dir * SIL_DIST)
sil_loc.z = 0.0
sil = ficha.add_scale_silhouette(location=tuple(sil_loc))
sil_xmin, sil_xmax, sil_ymin, sil_ymax, sil_zmin, sil_zmax = ficha.silhouette_bbox(location=tuple(sil_loc))
old_target_loc, old_cam_loc = ficha.frame_hero_camera(
    cam, target,
    x_min=min(-MOB_HX, sil_xmin), x_max=max(MOB_HX, sil_xmax),
    y_min=min(-MOB_HY, sil_ymin), y_max=max(MOB_HY, sil_ymax),
    z_min=0.0, z_max=max(MOB_ZMAX, sil_zmax))

scene.frame_set(1)
scene.render.resolution_x = 1024
scene.render.resolution_y = 1280
scene.render.filepath = os.path.join(REN_DIR, "snake_hero.png")
bpy.ops.render.render(write_still=True)

ficha.restore_hero_camera(cam, target, old_target_loc, old_cam_loc)
ficha.remove_scale_silhouette(sil)

# ---------- push all actions to NLA tracks (one glTF animation per track name) ----------
for name, (frames, act_sk) in actions.items():
    tr = sk_ad.nla_tracks.new()
    tr.name = name
    tr.strips.new(name, 1, act_sk)
    tr.mute = False

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "snake_wip.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "snake.glb"),
    use_selection=False,
    export_animations=True,
    export_morph=True,
    export_animation_mode='NLA_TRACKS',
)
print("[snake] DONE")
