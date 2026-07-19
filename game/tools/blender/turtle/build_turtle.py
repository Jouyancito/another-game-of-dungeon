# build_turtle.py — pond/water-edge turtle: heavy plod, "flinch IS hiding" retract, fast bite.
# Mirrors build_slime.py structure: single joined mesh, shape-key vocabulary per body part,
# object-transform (rotation/location) for whole-body weight, NLA export, ficha render rig.
#   idle-loop   slow breathing + head looking side to side
#   move-loop   slow heavy plod — body rocks as diagonal leg pairs step
#   attack      long anticipation, fast forward bite snap
#   hit         head + legs retract into shell, then peek back out
#   death       legs splay, shell settles flat, head droops
# "-loop" suffix => Godot glTF import auto-loops. Export mode: NLA tracks.
# Run: blender -b --python build_turtle.py
import bpy
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

# ---------- geometry: single mesh, built part by part, joins recorded as index ranges ----------
R = 0.25          # shell base radius -> ~0.5m dome width
PARTS = {}         # name -> (start_idx, end_idx) in the final joined mesh


def finish_part(obj):
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def join_part(base, part):
    bpy.ops.object.select_all(action='DESELECT')
    part.select_set(True)
    base.select_set(True)
    bpy.context.view_layer.objects.active = base
    start = len(base.data.vertices)
    bpy.ops.object.join()
    end = len(base.data.vertices)
    return start, end


# ---------- shell (dome, base object) ----------
bpy.ops.mesh.primitive_uv_sphere_add(segments=56, ring_count=28, radius=R)
turtle = bpy.context.object
turtle.name = "turtle"
me = turtle.data
for v in me.vertices:
    z = v.co.z
    if z >= 0.0:
        v.co.z = z * 0.62          # low dome
    else:
        v.co.z = z * 0.10          # nearly flat hidden underside
    t = max(0.0, 1.0 - abs(z) / (R * 0.6))
    s = 1.0 + 0.09 * t              # flare: shell overhangs its base (subtle)
    v.co.x *= s
    v.co.y *= s
for p in me.polygons:
    p.use_smooth = True
PARTS["shell"] = (0, len(me.vertices))
SHELL_ZMIN = min(v.co.z for v in me.vertices)
SHELL_ZMAX = max(v.co.z for v in me.vertices)


# ---------- belly rim ----------
bpy.ops.mesh.primitive_cylinder_add(vertices=28, radius=R * 1.18, depth=0.03, location=(0, 0, -0.028))
belly = bpy.context.object
belly.name = "belly"
for p in belly.data.polygons:
    p.use_smooth = True
finish_part(belly)
start, end = join_part(turtle, belly)
PARTS["belly"] = (start, end)

# ---------- neck (short, angled up-forward; front = -Y) ----------
bpy.ops.mesh.primitive_cone_add(radius1=0.040, radius2=0.033, depth=0.13,
                                 location=(0, -0.32, 0.02), rotation=(math.radians(80), 0, 0))
neck = bpy.context.object
neck.name = "neck"
for p in neck.data.polygons:
    p.use_smooth = True
finish_part(neck)
start, end = join_part(turtle, neck)
PARTS["neck"] = (start, end)

# ---------- head ----------
bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=0.066, location=(0, -0.445, 0.055))
head = bpy.context.object
head.name = "head"
hd = head.data
for v in hd.vertices:
    v.co.y *= 1.20   # elongate snout-ward
    v.co.z *= 0.82   # flatten top
for p in hd.polygons:
    p.use_smooth = True
finish_part(head)
start, end = join_part(turtle, head)
PARTS["head"] = (start, end)

NECK_BASE_Y = -0.27
HEAD_TIP_Y = -0.51

# ---------- legs (4 stubby cones, corners under the shell) ----------
LEG_DEF = {
    "leg_FL": (-0.175, -0.155, -0.06, 12, -18),
    "leg_FR": (0.175, -0.155, -0.06, -12, -18),
    "leg_BL": (-0.175, 0.155, -0.06, 12, 18),
    "leg_BR": (0.175, 0.155, -0.06, -12, 18),
}
for name, (lx, ly, lz, ry_deg, rz_deg) in LEG_DEF.items():
    bpy.ops.mesh.primitive_cone_add(radius1=0.052, radius2=0.040, depth=0.16,
                                     location=(lx, ly, lz),
                                     rotation=(math.radians(155), math.radians(ry_deg), math.radians(rz_deg)))
    leg = bpy.context.object
    leg.name = name
    for p in leg.data.polygons:
        p.use_smooth = True
    finish_part(leg)
    start, end = join_part(turtle, leg)
    PARTS[name] = (start, end)

# ---------- tail ----------
bpy.ops.mesh.primitive_cone_add(radius1=0.035, radius2=0.008, depth=0.09,
                                 location=(0, 0.275, -0.01), rotation=(math.radians(-100), 0, 0))
tail = bpy.context.object
tail.name = "tail"
for p in tail.data.polygons:
    p.use_smooth = True
finish_part(tail)
start, end = join_part(turtle, tail)
PARTS["tail"] = (start, end)

me = turtle.data  # refresh after joins

# ---------- ground the whole body at Z=0 ----------
zmin = min(v.co.z for v in me.vertices)
for v in me.vertices:
    v.co.z -= zmin
SHELL_ZMIN -= zmin
SHELL_ZMAX -= zmin

LEG_RANGES = [PARTS["leg_FL"], PARTS["leg_FR"], PARTS["leg_BL"], PARTS["leg_BR"]]
DIAG_A = [PARTS["leg_FL"], PARTS["leg_BR"]]
DIAG_B = [PARTS["leg_FR"], PARTS["leg_BL"]]


def in_ranges(i, ranges):
    return any(a <= i < b for a, b in ranges)


# ---------- shape keys: the turtle vocabulary ----------
# GOTCHA (paid for hard, 2026-07-18): shape_key_add() defaults value=1.0 AND from_mix
# copies the CURRENT blended mesh. Every previously-created key is still sitting at
# value=1.0 at that moment, so each new key's "untouched" vertices silently inherit
# the SUM of every prior key's delta instead of pure Basis -- compounding into wild
# multi-metre spikes on parts a later key never even targets. Fix: force from_mix=False
# (pin the copy source to Basis) AND immediately zero .value after every add.
def add_key(name):
    k = turtle.shape_key_add(name=name, from_mix=False)
    k.value = 0.0
    return k


add_key("Basis")
base_co = [v.co.copy() for v in me.vertices]

HEAD_RANGE = [PARTS["neck"], PARTS["head"]]


def head_factor(y):
    # 0 at neck base, 1 at head tip — head/snout moves more than the neck root
    return max(0.0, min(1.0, (NECK_BASE_Y - y) / (NECK_BASE_Y - HEAD_TIP_Y)))


sk = add_key(name="head_bite")     # quick forward snap
for i, co in enumerate(base_co):
    if in_ranges(i, HEAD_RANGE):
        f = head_factor(co.y)
        sk.data[i].co = co + Vector((0.0, -0.14 * f, -0.015 * f))

sk = add_key(name="head_retract")  # pulled back into the shell
for i, co in enumerate(base_co):
    if in_ranges(i, HEAD_RANGE):
        f = head_factor(co.y)
        target = co + Vector((0.0, 0.16 * f, -0.05 * f))
        target.x *= (1.0 - 0.35 * f)
        sk.data[i].co = target

sk = add_key(name="head_droop")    # dead weight, hangs down-forward
for i, co in enumerate(base_co):
    if in_ranges(i, HEAD_RANGE):
        f = head_factor(co.y)
        sk.data[i].co = co + Vector((0.0, -0.02 * f, -0.11 * f))

sk = add_key(name="head_look_L")
for i, co in enumerate(base_co):
    if in_ranges(i, HEAD_RANGE):
        f = head_factor(co.y)
        sk.data[i].co = co + Vector((-0.075 * f, 0.0, 0.0))

sk = add_key(name="head_look_R")
for i, co in enumerate(base_co):
    if in_ranges(i, HEAD_RANGE):
        f = head_factor(co.y)
        sk.data[i].co = co + Vector((0.075 * f, 0.0, 0.0))

sk = add_key(name="breathe")       # subtle chest rise
for i, co in enumerate(base_co):
    if in_ranges(i, [PARTS["shell"]]):
        f = max(0.0, (co.z - SHELL_ZMIN) / (SHELL_ZMAX - SHELL_ZMIN))
        sk.data[i].co = co + Vector((0.0, 0.0, 0.02 * f))

sk = add_key(name="leg_diagA")     # front-left + back-right step
for i, co in enumerate(base_co):
    if in_ranges(i, DIAG_A):
        sk.data[i].co = co + Vector((0.0, -0.045, 0.045))

sk = add_key(name="leg_diagB")     # front-right + back-left step
for i, co in enumerate(base_co):
    if in_ranges(i, DIAG_B):
        sk.data[i].co = co + Vector((0.0, -0.045, 0.045))

sk = add_key(name="legs_retract")  # pulled up into the shell
for i, co in enumerate(base_co):
    if in_ranges(i, LEG_RANGES):
        target = co + Vector((0.0, 0.0, 0.10))
        target.x *= 0.55
        target.y = co.y * 0.55
        sk.data[i].co = target

sk = add_key(name="legs_splay")    # flat, splayed out (death)
for i, co in enumerate(base_co):
    if in_ranges(i, LEG_RANGES):
        target = co.copy()
        target.x *= 1.45
        target.y *= 1.25
        target.z = SHELL_ZMIN + 0.01
        sk.data[i].co = target

sk = add_key(name="shell_settle")  # dome compresses + widens (death)
for i, co in enumerate(base_co):
    if in_ranges(i, [PARTS["shell"], PARTS["belly"]]):
        f = max(0.0, (co.z - SHELL_ZMIN) / max(0.001, (SHELL_ZMAX - SHELL_ZMIN)))
        target = co.copy()
        target.z = SHELL_ZMIN + (co.z - SHELL_ZMIN) * 0.45
        target.x *= (1.0 + 0.08 * f)
        target.y *= (1.0 + 0.08 * f)
        sk.data[i].co = target

kb = me.shape_keys.key_blocks
ALL_KEYS = ("head_bite", "head_retract", "head_droop", "head_look_L", "head_look_R",
            "breathe", "leg_diagA", "leg_diagB", "legs_retract", "legs_splay", "shell_settle")
FPS = 24
scene.render.fps = FPS


def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


# ---------- animation samplers: t in [0,1) -> {shapekey: value, rot_y:, loc_z:} ----------
def anim_idle(t):
    breathe = 0.5 + 0.5 * math.sin(2 * math.pi * t)
    look = math.sin(2 * math.pi * t + math.pi / 2)
    return {
        "breathe": 0.65 * breathe,
        "head_look_L": max(0.0, look) * 0.75,
        "head_look_R": max(0.0, -look) * 0.75,
    }


def anim_move(t):
    phase = t % 1.0
    if phase < 0.5:
        u = phase / 0.5
        diagA = math.sin(math.pi * u)
        diagB = 0.0
    else:
        u = (phase - 0.5) / 0.5
        diagB = math.sin(math.pi * u)
        diagA = 0.0
    rot = math.radians(5.5) * math.sin(2 * math.pi * t)
    return {"leg_diagA": diagA, "leg_diagB": diagB, "rot_y": rot}


def anim_attack(t):
    v = {}
    if t < 0.55:                        # long anticipation: brace back
        u = t / 0.55
        v["head_retract"] = 0.32 * math.sin(math.pi * 0.5 * u)
    elif t < 0.72:                      # fast snap forward
        u = (t - 0.55) / 0.17
        v["head_retract"] = lerp(0.32, 0.0, u)
        v["head_bite"] = lerp(0.0, 1.0, u)
    else:                               # recover
        u = (t - 0.72) / 0.28
        v["head_bite"] = lerp(1.0, 0.0, u)
    return v


def anim_hit(t):
    v = {}
    if t < 0.28:
        u = t / 0.28
        v["head_retract"] = lerp(0.0, 1.0, u)
        v["legs_retract"] = lerp(0.0, 1.0, u)
    elif t < 0.50:
        v["head_retract"] = 1.0
        v["legs_retract"] = 1.0
    else:
        u = (t - 0.50) / 0.50
        v["head_retract"] = lerp(1.0, 0.0, u)
        v["legs_retract"] = lerp(1.0, 0.0, u)
    return v


def anim_death(t):
    u = min(1.0, t / 0.85)
    return {"legs_splay": u, "shell_settle": u, "head_droop": u}


ANIMS = {
    "idle-loop": (72, anim_idle),
    "move-loop": (64, anim_move),
    "attack": (26, anim_attack),
    "hit": (16, anim_hit),
    "death": (36, anim_death),
}

sk_ad = me.shape_keys.animation_data_create()
obj_ad = turtle.animation_data_create()
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
        turtle.rotation_euler.y = vals.get("rot_y", 0.0)
        turtle.keyframe_insert("rotation_euler", frame=f)
        turtle.location.z = vals.get("loc_z", 0.0)
        turtle.keyframe_insert("location", frame=f)
    actions[name] = (frames, act_sk, act_obj)
sk_ad.action = None
obj_ad.action = None

# ---------- materials: shell voronoi plates (2 greens), olive skin, lighter belly ----------


def _mix_rgba(nt):
    node = nt.nodes.new("ShaderNodeMix")
    node.data_type = 'RGBA'
    a = [s for s in node.inputs if s.name == 'A' and s.type == 'RGBA'][0]
    b = [s for s in node.inputs if s.name == 'B' and s.type == 'RGBA'][0]
    out = [o for o in node.outputs if o.type == 'RGBA'][0]
    return node, a, b, out


def _base(name, alpha):
    m = bpy.data.materials.new(f"turtle_{name}")
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Alpha"].default_value = alpha
    return m, nt, n


def mat_shell():
    m, nt, n = _base("shell", 1.0)
    n.inputs["Roughness"].default_value = 0.55
    voro = nt.nodes.new("ShaderNodeTexVoronoi")
    voro.feature = 'F1'
    voro.inputs["Scale"].default_value = 8.0
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(voro.outputs["Color"], sep.inputs["Color"])
    ramp, ra, rb, rout = _mix_rgba(nt)
    ra.default_value = (0.06, 0.15, 0.06, 1.0)    # deep moss green
    rb.default_value = (0.17, 0.32, 0.12, 1.0)    # lighter olive green
    nt.links.new(sep.outputs["Red"], ramp.inputs["Factor"])

    edge = nt.nodes.new("ShaderNodeTexVoronoi")
    edge.feature = 'DISTANCE_TO_EDGE'
    edge.inputs["Scale"].default_value = 8.0
    thr = nt.nodes.new("ShaderNodeMath")
    thr.operation = 'LESS_THAN'
    thr.inputs[1].default_value = 0.045
    nt.links.new(edge.outputs["Distance"], thr.inputs[0])
    seam, sa, sb, sout = _mix_rgba(nt)
    sb.default_value = (0.03, 0.08, 0.03, 1.0)    # plate seam
    nt.links.new(rout, sa)
    nt.links.new(thr.outputs["Value"], seam.inputs["Factor"])
    nt.links.new(sout, n.inputs["Base Color"])
    return m


def mat_skin():
    m, nt, n = _base("skin", 1.0)
    n.inputs["Roughness"].default_value = 0.6
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 12.0
    noise.inputs["Detail"].default_value = 2.0
    ramp, ra, rb, rout = _mix_rgba(nt)
    ra.default_value = (0.19, 0.22, 0.09, 1.0)
    rb.default_value = (0.27, 0.31, 0.13, 1.0)
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Factor"])
    nt.links.new(rout, n.inputs["Base Color"])
    return m


def mat_belly():
    m, nt, n = _base("belly", 1.0)
    n.inputs["Roughness"].default_value = 0.5
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 6.0
    ramp, ra, rb, rout = _mix_rgba(nt)
    ra.default_value = (0.34, 0.28, 0.15, 1.0)
    rb.default_value = (0.44, 0.38, 0.22, 1.0)
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Factor"])
    nt.links.new(rout, n.inputs["Base Color"])
    return m


mat_shell_data = mat_shell()
mat_skin_data = mat_skin()
mat_belly_data = mat_belly()
me.materials.append(mat_shell_data)   # slot 0
me.materials.append(mat_skin_data)    # slot 1
me.materials.append(mat_belly_data)   # slot 2

SKIN_RANGES = [PARTS["neck"], PARTS["head"], PARTS["leg_FL"], PARTS["leg_FR"],
               PARTS["leg_BL"], PARTS["leg_BR"], PARTS["tail"]]
BELLY_RANGES = [PARTS["belly"]]
for p in me.polygons:
    idx0 = p.vertices[0]
    if in_ranges(idx0, BELLY_RANGES):
        p.material_index = 2
    elif in_ranges(idx0, SKIN_RANGES):
        p.material_index = 1
    else:
        p.material_index = 0

# ---------- showcase-ficha scene (contract §4: purple bg, 50mm, key/fill/rim 110/30/130) ----------
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


add_light("key", (-0.9, -0.55, 0.65), 28, 0.9)
add_light("fill", (0.8, -0.5, 0.22), 8, 0.85)
add_light("rim", (0.17, 0.9, 0.55), 32, 0.85)

target = bpy.data.objects.new("target", None)
target.location = (0, 0, 0.07)
bpy.context.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 50
cam = bpy.data.objects.new("cam", cd)
cam.location = (-0.62, -1.60, 0.32)
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
scene.render.use_motion_blur = False   # shape-key velocity streaks otherwise smear fast poses (retract/step)

# ---------- renders: preview frames per animation ----------
scene.render.resolution_x = 512
scene.render.resolution_y = 640
scene.frame_set(1)
for k in ALL_KEYS:
    kb[k].value = 0.0

for name, (frames, act_sk, act_obj) in actions.items():
    sk_ad.action = act_sk
    obj_ad.action = act_obj
    for f in range(1, frames + 1, 2):
        scene.frame_set(f)
        scene.render.filepath = os.path.join(ANIM_DIR, f"{name.replace('-loop', '')}_{f:03d}.png")
        bpy.ops.render.render(write_still=True)
    print("[turtle] frames", name)
sk_ad.action = None
obj_ad.action = None
turtle.location = (0, 0, 0)
turtle.rotation_euler = (0, 0, 0)
for k in ALL_KEYS:          # actions leave the last evaluated values behind — reset to rest
    kb[k].value = 0.0

# ---------- hero still: scale silhouette (mob style contract §4, Pokedex rule) ----------
sys.path.insert(0, os.path.dirname(OUT_DIR))
import _ficha_common as ficha

MOB_HX, MOB_HY, MOB_ZMAX = 0.28, 0.52, 0.16  # turtle half-width / head-to-tail / low dome
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
scene.render.filepath = os.path.join(REN_DIR, "turtle_hero.png")
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

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "turtle_wip.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "turtle.glb"),
    use_selection=False,
    export_animations=True,
    export_morph=True,
    export_animation_mode='NLA_TRACKS',
)
print("[turtle] DONE")
