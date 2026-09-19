# build_rat.py — ruins/camp floor-1 rat. Mob style contract (_mob_style_contract.md):
# geometric-blob body (teardrop) + big round ears = the silhouette signature, same
# family as the slime (§5 "el motor genera: blobs, insectos, reptiles simples,
# criaturas de formas geometricas") — no articulated legs, no walk-cycle skeleton,
# motion lives in shape keys + object transform on ONE mesh, exactly like build_slime.py.
#
# Anims (standard 5-clip set, same names Godot auto-maps everywhere):
#   idle-loop   fast nervous sniff (snout twitch x3/cycle) + ear-perk pulse + slow tail sway
#   move-loop   scurry — rapid tiny body bobs + forward lean + tail streaming behind
#   attack      rear up (anticipation) -> nip forward (strike) -> recover
#   hit         sideways flinch squash + ears flatten
#   death       rolls onto its side (object roll), tail stops moving, small settle
#
# Rat is TWITCHY: higher cycle frequency than the slime's calm wobble (Joan's brief).
# "-loop" suffix => Godot auto-loops on import. Export mode: NLA tracks (shape keys +
# object transform as separate actions per clip, same pattern as build_slime.py).
# Run: blender -b --python build_rat.py
import bpy
import bmesh
import math
import os
import random
import sys
from mathutils import Vector

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
ANIM_DIR = os.path.join(REN_DIR, "anim")
os.makedirs(ANIM_DIR, exist_ok=True)

SEED = 3
rng = random.Random(SEED)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


def falloff(x, lo, hi):
    if hi == lo:
        return 0.0
    return max(0.0, min(1.0, (x - lo) / (hi - lo)))


# =============================================================================
# BODY — torso (teardrop blob), ears (big round discs), tail (tapered curved
# chain), paws (tiny tucked nubs). All built as separate objects, baked via
# transform_apply, then joined into ONE mesh so shape keys can drive everything
# (mirrors build_slime.py's single-object shape-key approach).
# =============================================================================

FUR_NAME = "rat_fur"
ACCENT_NAME = "rat_accent"
fur_mat_src = bpy.data.materials.new(FUR_NAME)
accent_mat_src = bpy.data.materials.new(ACCENT_NAME)


def make_torso():
    bpy.ops.mesh.primitive_uv_sphere_add(segments=36, ring_count=18, radius=0.095)
    ob = bpy.context.object
    ob.name = "torso"
    me = ob.data
    for v in me.vertices:
        y = v.co.y
        if y < 0.0:
            t = min(1.0, -y / 0.095)
            v.co.y -= 0.030 * (t ** 2.0)          # short, blunt-rounded snout (not a spike)
            s = 1.0 - 0.28 * t - 0.34 * (t ** 3.0)  # stays fuller longer, tapers near the tip
        else:
            t = min(1.0, y / 0.095)
            s = 1.0 + 0.34 * t                      # fatten toward the rump
        v.co.x *= max(0.10, s)
        v.co.z *= max(0.10, s) * 0.70               # flatten height — low to the ground
    for p in me.polygons:
        p.use_smooth = True
    ob.data.materials.append(fur_mat_src)   # slot 0 = fur
    ob.data.materials.append(accent_mat_src)  # slot 1 = accent (nose tip)
    y_min = min(v.co.y for v in me.vertices)
    y_max = max(v.co.y for v in me.vertices)
    nose_thresh = y_min * 0.62   # front-most ~38% of the taper = pink nose tip
    for poly in me.polygons:
        cy = sum(me.vertices[i].co.y for i in poly.vertices) / len(poly.vertices)
        poly.material_index = 1 if cy < nose_thresh else 0
    return ob, y_min, y_max


torso, TORSO_Y_MIN, TORSO_Y_MAX = make_torso()
NOSE_TIP_Y = TORSO_Y_MIN
SNOUT_START_Y = TORSO_Y_MIN * 0.42


def snout_t(v):
    return falloff(-v.y, -SNOUT_START_Y, -NOSE_TIP_Y)


def make_ear(name, side_sign):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=10, radius=0.060)
    ob = bpy.context.object
    ob.name = name
    me = ob.data
    for v in me.vertices:
        v.co.y *= 0.30    # flatten into a coin/disc (local Y = thickness before rotation)
    for p in me.polygons:
        p.use_smooth = True
    ob.data.materials.append(fur_mat_src)      # slot 0 = fur (outer/back — most of the ear)
    ob.data.materials.append(accent_mat_src)   # slot 1 = accent (small inner cup only)
    # tight inner-cup accent (not a 50/50 split — the camera-facing side after the
    # rotation below reads as local +Y, so keep fur on +Y and only cap the -Y side)
    for poly in me.polygons:
        cy = sum(me.vertices[i].co.y for i in poly.vertices) / len(poly.vertices)
        poly.material_index = 1 if cy < -0.006 else 0
    # BIG round ear, standing up and splayed OUTWARD to the side (not flat-facing
    # the camera) so both the fur rim and a hint of the inner cup read in the 3/4 view.
    ear_y = TORSO_Y_MIN * 0.48
    ob.rotation_euler = (math.radians(20), math.radians(side_sign * 55), math.radians(side_sign * 10))
    # base sunk into the skull: no visible gap between ear and body (floating-geometry rule)
    ob.location = (side_sign * 0.040, ear_y, 0.078)
    return ob


ear_L = make_ear("ear_L", -1)
ear_R = make_ear("ear_R", 1)
EAR_L_ANCHOR = Vector(ear_L.location)
EAR_R_ANCHOR = Vector(ear_R.location)
EAR_RADIUS = 0.078


def ear_factor(v):
    dl = (v - EAR_L_ANCHOR).length
    dr = (v - EAR_R_ANCHOR).length
    d = min(dl, dr)
    return max(0.0, 1.0 - d / EAR_RADIUS)


def make_paw(name, x_sign):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6, radius=0.022)
    ob = bpy.context.object
    ob.name = name
    for v in ob.data.vertices:
        v.co.y *= 0.85
        v.co.z *= 0.70
    for p in ob.data.polygons:
        p.use_smooth = True
    ob.data.materials.append(fur_mat_src)
    ob.location = (x_sign * 0.036, TORSO_Y_MIN * 0.35, 0.020)
    return ob


paw_L = make_paw("paw_L", -1)
paw_R = make_paw("paw_R", 1)


def make_tail():
    segs = 12
    length = 0.27
    base_r = 0.019
    tip_r = 0.0035
    rings = 8
    bm = bmesh.new()
    loops = []
    for i in range(segs + 1):
        t = i / segs
        y = t * length
        r = base_r * (1.0 - t) + tip_r * t
        # baked resting curve: gentle sideways C + droop-then-curl-up at the tip
        cx = 0.045 * math.sin(math.pi * 0.85 * t)
        cz = -0.035 * (t ** 1.4) + 0.05 * (t ** 3.2)
        loop = []
        for k in range(rings):
            ang = 2.0 * math.pi * k / rings
            x = r * math.cos(ang) + cx
            z = r * math.sin(ang) + cz
            loop.append(bm.verts.new((x, y, z)))
        loops.append(loop)
    for i in range(segs):
        a, b = loops[i], loops[i + 1]
        for k in range(rings):
            k2 = (k + 1) % rings
            bm.faces.new((a[k], a[k2], b[k2], b[k]))
    bm.faces.new(loops[-1])   # tip cap
    bm.faces.new(reversed(loops[0]))  # base cap (small, hidden inside the rump)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new("tail_mesh")
    bm.to_mesh(mesh)
    bm.free()
    for p in mesh.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new("tail", mesh)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(accent_mat_src)   # whole tail = pink accent (bare, no fur)
    ob.location = (0.0, TORSO_Y_MAX - 0.010, 0.026)
    return ob, length


tail, TAIL_LENGTH = make_tail()
TAIL_BASE_Y = tail.location.y
TAIL_TIP_Y = TAIL_BASE_Y + TAIL_LENGTH


def tail_t(v):
    return falloff(v.y, TAIL_BASE_Y, TAIL_TIP_Y)


# ---------- bake transforms + join into ONE mesh ----------
parts = [torso, ear_L, ear_R, paw_L, paw_R, tail]
for o in parts:
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.object.select_all(action="DESELECT")
for o in parts:
    o.select_set(True)
bpy.context.view_layer.objects.active = torso
bpy.ops.object.join()
body = bpy.context.view_layer.objects.active
body.name = "rat"
me = body.data
me.validate(verbose=False)

# ground the lowest point to Z=0 (belly/paws touch the floor)
z_shift = min(v.co.z for v in me.vertices)
for v in me.vertices:
    v.co.z -= z_shift

TRIS = sum(len(p.vertices) - 2 for p in me.polygons)
print(f"[rat] tris={TRIS}")

Z_MIN = min(v.co.z for v in me.vertices)
Z_MAX = max(v.co.z for v in me.vertices)


# =============================================================================
# MATERIALS — vertex-color driven (survives glTF export, unlike node textures
# per contract §5). Warm grey-brown fur (2-tone jitter) + pink accent (nose/
# ears-inner/tail). Max 2 material slots = well inside the "3 colors" budget;
# eyes deliberately SKIPPED (a 3rd color would blow the budget — ears + teardrop
# silhouette already read "rat" without them, ponytail: do the ears sell it alone).
# =============================================================================
# POINT domain (one color per VERTEX, GPU-interpolated across each face) instead of
# CORNER/per-face flat fill — per-face flat colors read as a harsh checkerboard
# mosaic (tried first, failed eye-review); per-vertex gives a smooth, subtle 2-tone
# grain that doesn't fight the silhouette (contract §2/§5).
me.color_attributes.new(name="Col", type="BYTE_COLOR", domain="POINT")
ca = me.color_attributes[0]
vert_mat = {}
for poly in me.polygons:
    for vi in poly.vertices:
        vert_mat[vi] = poly.material_index
prng = random.Random(SEED * 11 + 5)
FUR_BASE = (0.30, 0.20, 0.14)
ACCENT_BASE = (0.78, 0.40, 0.44)


def _smooth_noise(co):
    return (math.sin(co.x * 19.0 + 1.7) * math.sin(co.y * 14.0 + 3.1)
            * math.sin(co.z * 23.0 + 0.6))


for i, v in enumerate(me.vertices):
    n = _smooth_noise(v.co)
    if vert_mat.get(i, 0) == 1:
        j = n * 0.035
        col = (min(1.0, max(0.0, ACCENT_BASE[0] + j)),
               min(1.0, max(0.0, ACCENT_BASE[1] + j * 0.6)),
               min(1.0, max(0.0, ACCENT_BASE[2] + j * 0.6)), 1.0)
    else:
        j = n * 0.06
        h = n * 0.02
        col = (min(1.0, max(0.0, FUR_BASE[0] + j + h)),
               min(1.0, max(0.0, FUR_BASE[1] + j)),
               min(1.0, max(0.0, FUR_BASE[2] + j - h)), 1.0)
    ca.data[i].color = col


def wire_vertex_color_material(mat, roughness):
    mat.use_nodes = True
    nt = mat.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Roughness"].default_value = roughness
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    nt.links.new(attr.outputs["Color"], n.inputs["Base Color"])


wire_vertex_color_material(fur_mat_src, 0.75)      # matte fur — no shiny highlight
wire_vertex_color_material(accent_mat_src, 0.42)   # bare skin, a touch glossier


# =============================================================================
# SHAPE KEYS — the twitchy vocabulary. All computed from continuous position
# fields (Y = front/back, Z = height, radial distance from ear anchors, distance
# along the tail) so no manual vertex-index bookkeeping is needed, same idiom
# as build_slime.py's z-height fields.
# =============================================================================
body.shape_key_add(name="Basis")
basis_co = [Vector(v.co) for v in me.vertices]

# NOTE: first pass used subtle deltas (mirroring the slime's ~0.15-0.20 fractional
# moves) and the animation was near-invisible in stills — a rat this small needs
# LARGER fractional deformation to read at all. Roughly doubled/tripled every key
# after eye-review caught idle/move/attack frames looking identical to rest.
sk = body.shape_key_add(name="squash")     # whole-body compress + spread (sit down)
for i, v in enumerate(basis_co):
    zn = falloff(v.z, Z_MIN, Z_MAX)
    nz = Z_MIN + (v.z - Z_MIN) * 0.62
    spread = 1.0 + 0.16 * (1.0 - zn)
    sk.data[i].co = Vector((v.x * spread, v.y * spread, nz))

sk = body.shape_key_add(name="lean")       # forward tilt (nose dips+pushes, rump lifts)
for i, v in enumerate(basis_co):
    tf = falloff(v.y, TORSO_Y_MIN, TORSO_Y_MAX)   # 0 nose .. 1 rump
    excl = 1.0 - tail_t(v)
    dz = (-0.048 * (1.0 - tf) + 0.020 * tf) * excl
    dy = (-0.032 * (1.0 - tf)) * excl
    sk.data[i].co = v + Vector((0.0, dy, dz))

sk = body.shape_key_add(name="sniff")      # snout tip twitch up
for i, v in enumerate(basis_co):
    st = snout_t(v)
    sk.data[i].co = v + Vector((0.0, 0.028 * st, 0.052 * st))

sk = body.shape_key_add(name="ear_perk")   # ears lift upright (mostly Z, less pure
for i, v in enumerate(basis_co):           # radial scale — a scale alone barely
    et = ear_factor(v)                     # reads on an already-round ear)
    anchor = EAR_L_ANCHOR if (v - EAR_L_ANCHOR).length <= (v - EAR_R_ANCHOR).length else EAR_R_ANCHOR
    dirv = v - anchor
    sk.data[i].co = v + dirv * (0.26 * et) + Vector((0.0, 0.0, 0.048 * et))

sk = body.shape_key_add(name="ear_flat")   # ears fold back/down
for i, v in enumerate(basis_co):
    et = ear_factor(v)
    sk.data[i].co = v + Vector((0.0, 0.078 * et, -0.085 * et))

sk = body.shape_key_add(name="tail_sway")  # lateral wag, whip falloff along the tail
for i, v in enumerate(basis_co):
    tt = tail_t(v)
    sk.data[i].co = v + Vector((0.17 * tt ** 1.6, 0.0, 0.0))

sk = body.shape_key_add(name="tail_stream")  # tail extends/straightens (scurry)
for i, v in enumerate(basis_co):
    tt = tail_t(v)
    sk.data[i].co = v + Vector((0.0, 0.085 * tt, 0.034 * tt))

sk = body.shape_key_add(name="rear_up")    # front torso+head rear up on the haunches
for i, v in enumerate(basis_co):
    tf = falloff(v.y, TORSO_Y_MIN, TORSO_Y_MAX)
    excl = 1.0 - tail_t(v)
    front_w = (1.0 - tf) * excl
    sk.data[i].co = v + Vector((0.0, 0.055 * front_w, 0.130 * front_w))

sk = body.shape_key_add(name="nip")        # snout lunges forward hard (the bite)
for i, v in enumerate(basis_co):
    st = snout_t(v)
    sk.data[i].co = v + Vector((0.0, -0.095 * st, -0.018 * st))

sk = body.shape_key_add(name="flinch")     # sideways squash/shove — the hit reaction
for i, v in enumerate(basis_co):
    zn = falloff(v.z, Z_MIN, Z_MAX)
    sk.data[i].co = v + Vector((0.085 * (1.0 - 0.3 * zn), 0.0, -0.030))

kb = me.shape_keys.key_blocks
ALL_KEYS = ("squash", "lean", "sniff", "ear_perk", "ear_flat",
            "tail_sway", "tail_stream", "rear_up", "nip", "flinch")

FPS = 24
scene.render.fps = FPS


# =============================================================================
# ANIMATION SAMPLERS — nervous/twitchy: idle has 3 quick sniffs per cycle
# (vs. the slime's single calm wobble), move-loop bounces 4x per cycle.
# =============================================================================
def anim_idle(t):
    sniff = abs(math.sin(2 * math.pi * t * 3.0))
    ear = 0.5 + 0.5 * math.sin(2 * math.pi * t * 3.0 + 0.5)
    tail = 0.5 * math.sin(2 * math.pi * t * 0.9)
    return {"sniff": sniff, "ear_perk": ear * 0.55, "tail_sway": tail}


def anim_move(t):
    bob = abs(math.sin(2 * math.pi * t * 4.0))
    tail = 0.30 * math.sin(2 * math.pi * t * 4.0 + 1.0)
    return {"squash": bob * 0.55, "lean": 0.85, "tail_stream": 0.80,
            "tail_sway": tail, "z": 0.022 * bob}


def anim_attack(t):
    v = {}
    if t < 0.35:                       # rear up — anticipation
        u = t / 0.35
        v["rear_up"] = lerp(0.0, 1.0, u)
        v["tail_sway"] = 0.30 * u
    elif t < 0.55:                     # nip forward — strike
        u = (t - 0.35) / 0.20
        v["rear_up"] = lerp(1.0, 0.10, u)
        v["nip"] = lerp(0.0, 1.0, u)
    else:                               # recover
        u = (t - 0.55) / 0.45
        v["rear_up"] = lerp(0.10, 0.0, u)
        v["nip"] = lerp(1.0, 0.0, u)
    return v


def anim_hit(t):
    return {"flinch": math.sin(math.pi * t),
            "ear_flat": math.sin(math.pi * min(1.0, t * 1.3))}


def anim_death(t):
    v = {}
    if t < 0.55:                        # quick fall onto its side
        u = (t / 0.55) ** 0.7
        v["squash"] = 0.18 * (1.0 - u)
        v["roll"] = lerp(0.0, 92.0, u)
    else:                                # settled — tiny decaying wobble
        u = (t - 0.55) / 0.45
        v["roll"] = 92.0
        v["squash"] = 0.06 * math.sin(2 * math.pi * u) * (1.0 - u)
    return v


ANIMS = {
    "idle-loop": (36, anim_idle),
    "move-loop": (18, anim_move),
    "attack": (20, anim_attack),
    "hit": (10, anim_hit),
    "death": (30, anim_death),
}

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
        body.location.z = vals.get("z", 0.0)
        body.keyframe_insert("location", frame=f)
        body.rotation_euler.y = math.radians(vals.get("roll", 0.0))
        body.keyframe_insert("rotation_euler", frame=f)
    actions[name] = (frames, act_sk, act_obj)
sk_ad.action = None
obj_ad.action = None

# ---------- showcase-ficha scene (mirrors build_slime.py exactly) ----------
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


# Object is ~6x smaller than the slime (which used 110/30/130 at ~2.5 units away).
# Irradiance ~ energy/distance^2 — keep the SAME ratios but scale energy down hard
# so a light this close to a tiny creature doesn't blow every pixel to white.
add_light("key", (-0.55, -0.55, 0.55), 9.0, 0.5)
add_light("fill", (0.55, -0.45, 0.25), 2.5, 0.5)
add_light("rim", (0.10, 0.65, 0.40), 11.0, 0.5)

# SIDE 3/4 profile (not front-on): the rat is NOT radially symmetric like the slime
# — a front-on camera foreshortens the pointed snout AND hides the tail directly
# behind the torso. Camera sits mostly along -X (side) with a little -Y (3/4 turn)
# so nose (-Y) and tail (+Y) both read in profile. Target = midpoint of the full
# nose-to-tail-tip span so the long tail isn't cropped out.
target = bpy.data.objects.new("target", None)
target.location = (0, (NOSE_TIP_Y + TAIL_TIP_Y) * 0.5, 0.07)
bpy.context.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 35
cam = bpy.data.objects.new("cam", cd)
cam.location = (-0.85, -0.24, 0.34)
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
for name, (frames, act_sk, act_obj) in actions.items():
    sk_ad.action = act_sk
    obj_ad.action = act_obj
    for f in range(1, frames + 1, 2):
        scene.frame_set(f)
        scene.render.filepath = os.path.join(ANIM_DIR, f"{name.replace('-loop', '')}_{f:03d}.png")
        bpy.ops.render.render(write_still=True)
    print("[rat] frames", name)
sk_ad.action = None
obj_ad.action = None

# gotcha (contract §5): actions leave the last evaluated values behind — reset
# shape keys AND object transform to rest before the hero still.
body.location = (0, 0, 0)
body.rotation_euler = (0, 0, 0)
for k in ALL_KEYS:
    kb[k].value = 0.0

# ---------- hero still: scale silhouette (mob style contract §4, Pokedex rule) ----------
sys.path.insert(0, os.path.dirname(OUT_DIR))
import _ficha_common as ficha

MOB_HX, MOB_HY, MOB_ZMAX = 0.15, 0.42, 0.18  # rat ears/paws / nose-to-tail-tip / low profile
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
scene.render.filepath = os.path.join(REN_DIR, "rat_hero.png")
bpy.ops.render.render(write_still=True)

ficha.restore_hero_camera(cam, target, old_target_loc, old_cam_loc)
ficha.remove_scale_silhouette(sil)

# ---------- push all actions to NLA tracks (one glTF animation per track name) ----------
for name, (frames, act_sk, act_obj) in actions.items():
    tr = sk_ad.nla_tracks.new()
    tr.name = name
    tr.strips.new(name, 1, act_sk)
    tr.mute = False
    tro = obj_ad.nla_tracks.new()
    tro.name = name
    tro.strips.new(name, 1, act_obj)
    tro.mute = False

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "rat_wip.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "rat.glb"),
    use_selection=False,
    export_animations=True,
    export_morph=True,
    export_animation_mode='NLA_TRACKS',
)
print(f"[rat] tris={TRIS}")
print("[rat] DONE")
