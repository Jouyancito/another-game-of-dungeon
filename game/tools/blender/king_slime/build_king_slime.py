# build_king_slime.py — King Slime: the approved slime's DNA at boss mass.
# Same clip names as every mob (style contract §3); everything reads HEAVIER:
# longer clips, lower sway frequency, bigger settle. A gold crown rides the
# top of the gel and follows squash/stretch/sway so it never floats.
# Run: blender -b --python build_king_slime.py
import bpy
import math
import os
import sys
from mathutils import Vector

S = 2.2                      # boss scale vs base slime
OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
ANIM_DIR = os.path.join(REN_DIR, "anim")
os.makedirs(ANIM_DIR, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# ---------- body ----------
bpy.ops.mesh.primitive_uv_sphere_add(segments=96, ring_count=48, radius=0.5)
body = bpy.context.object
body.name = "king_slime"
me = body.data
for v in me.vertices:
    z = v.co.z
    v.co.z = z * (0.78 if z > 0.0 else 0.55)
    t = max(0.0, min(1.0, (0.08 - v.co.z) / 0.35))
    s = 1.0 + 0.20 * t
    v.co.x *= s
    v.co.y *= s
    v.co *= S
for p in me.polygons:
    p.use_smooth = True

Z_MIN = min(v.co.z for v in me.vertices)
Z_MAX = max(v.co.z for v in me.vertices)
H = Z_MAX - Z_MIN

# ---------- shape keys ----------
body.shape_key_add(name="Basis")

sk = body.shape_key_add(name="squash")
for i, v in enumerate(me.vertices):
    zn = (v.co.z - Z_MIN) / H
    nz = Z_MIN + (v.co.z - Z_MIN) * 0.80
    spread = 1.0 + 0.14 * (1.0 - zn)
    sk.data[i].co = Vector((v.co.x * spread, v.co.y * spread, nz))

sk = body.shape_key_add(name="stretch")
for i, v in enumerate(me.vertices):
    nz = Z_MIN + (v.co.z - Z_MIN) * 1.16
    sk.data[i].co = Vector((v.co.x * 0.93, v.co.y * 0.93, nz))

sk = body.shape_key_add(name="sway")
for i, v in enumerate(me.vertices):
    zn = (v.co.z - Z_MIN) / H
    sk.data[i].co = v.co + Vector((0.10 * S * zn ** 1.6, 0.0, 0.0))

sk = body.shape_key_add(name="lunge")
for i, v in enumerate(me.vertices):
    zn = (v.co.z - Z_MIN) / H
    sk.data[i].co = v.co + Vector((0.0, -0.22 * S * zn ** 1.5, 0.0))

sk = body.shape_key_add(name="melt")
for i, v in enumerate(me.vertices):
    nz = Z_MIN + (v.co.z - Z_MIN) * 0.16
    sk.data[i].co = Vector((v.co.x * 1.45, v.co.y * 1.45, nz))

kb = me.shape_keys.key_blocks
FPS = 24
scene.render.fps = FPS

# ---------- crown: gold band + 5 spikes, parented logic via keyframes ----------
crown_parts = []
bpy.ops.mesh.primitive_cylinder_add(radius=0.36 * S / 2.2 * 1.0, depth=0.16, vertices=24)
band = bpy.context.object
band.name = "crown_band"
crown_parts.append(band)
for k in range(5):
    ang = 2 * math.pi * k / 5
    bpy.ops.mesh.primitive_cone_add(radius1=0.075, depth=0.20, vertices=12,
                                    location=(0.30 * math.sin(ang), 0.30 * math.cos(ang), 0.16))
    spike = bpy.context.object
    spike.name = f"crown_spike_{k}"
    spike.parent = band
    spike.location = (0.30 * math.sin(ang), 0.30 * math.cos(ang), 0.16)
    crown_parts.append(spike)
CROWN_Z = Z_MAX - 0.04
band.location = (0.0, 0.0, CROWN_Z)


def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


# ---------- animation samplers (heavier timing than the base slime) ----------
def anim_idle(t):
    w = math.sin(2 * math.pi * t)
    return {"squash": max(0.0, w) * 0.45, "stretch": max(0.0, -w) * 0.30,
            "sway": 0.5 + 0.5 * math.sin(2 * math.pi * t * 2 + math.pi / 3)}


def anim_hop(t):
    v = {"squash": 0.0, "stretch": 0.0, "sway": 0.0, "z": 0.0}
    if t < 0.25:
        v["squash"] = lerp(0.0, 0.85, t / 0.25)
    elif t < 0.34:
        u = (t - 0.25) / 0.09
        v["squash"] = lerp(0.85, 0.0, u)
        v["stretch"] = lerp(0.0, 0.5, u)
    elif t < 0.66:
        u = (t - 0.34) / 0.32
        v["z"] = 0.9 * (1.0 - (2 * u - 1.0) ** 2)
        v["stretch"] = lerp(0.5, 0.2, u)
    elif t < 0.78:
        u = (t - 0.66) / 0.12
        v["squash"] = lerp(0.0, 0.95, u)      # boss lands HARD
    else:
        u = (t - 0.78) / 0.22
        v["squash"] = lerp(0.95, 0.0, u)
        v["sway"] = 0.5 * math.sin(2 * math.pi * u)
    return v


def anim_hit(t):
    return {"squash": 0.4 * math.sin(math.pi * t),
            "sway": 0.6 * math.sin(math.pi * min(1.0, t * 1.6))}


def anim_attack(t):
    v = {"squash": 0.0, "stretch": 0.0, "lunge": 0.0}
    if t < 0.35:
        v["squash"] = lerp(0.0, 0.7, t / 0.35)
    elif t < 0.58:
        u = (t - 0.35) / 0.23
        v["squash"] = lerp(0.7, 0.0, u)
        v["lunge"] = lerp(0.0, 1.0, u)
        v["stretch"] = 0.3 * math.sin(math.pi * u)
    else:
        u = (t - 0.58) / 0.42
        v["lunge"] = lerp(1.0, 0.0, u)
    return v


def anim_death(t):
    v = {"melt": min(1.0, t * 1.2), "squash": 0.0, "sway": 0.0}
    if t > 0.6:
        v["squash"] = 0.12 * math.sin(2 * math.pi * (t - 0.6) / 0.4)
    return v


ANIMS = {
    "idle-loop": (96, anim_idle),
    "hop-loop": (72, anim_hop),
    "hit": (16, anim_hit),
    "attack": (30, anim_attack),
    "death": (40, anim_death),
}

ALL_KEYS = ("squash", "stretch", "sway", "lunge", "melt")
sk_ad = me.shape_keys.animation_data_create()
obj_ad = body.animation_data_create()
crown_ad = band.animation_data_create()
actions = {}
for name, (frames, sampler) in ANIMS.items():
    act_sk = bpy.data.actions.new(f"{name}_sk")
    sk_ad.action = act_sk
    act_obj = bpy.data.actions.new(f"{name}_obj")
    obj_ad.action = act_obj
    act_cr = bpy.data.actions.new(f"{name}_crown")
    crown_ad.action = act_cr
    for f in range(1, frames + 1, 2):
        t = (f - 1) / (frames - 1)
        vals = sampler(t)
        for k in ALL_KEYS:
            kb[k].value = vals.get(k, 0.0)
            kb[k].keyframe_insert("value", frame=f)
        body.location.z = vals.get("z", 0.0)
        body.keyframe_insert("location", frame=f)
        # crown rides the deforming top: height follows squash/stretch/melt, lean follows sway/lunge
        sq, st = vals.get("squash", 0.0), vals.get("stretch", 0.0)
        ml, sw = vals.get("melt", 0.0), vals.get("sway", 0.0)
        lg = vals.get("lunge", 0.0)
        # crown height measured from the body's floor, not from world zero —
        # otherwise it floats when the boss melts flat
        factor = 1.0 - 0.20 * sq + 0.16 * st - 0.84 * ml
        top = Z_MIN + (CROWN_Z - Z_MIN) * factor
        band.location = (0.10 * S * sw, -0.22 * S * lg, top + vals.get("z", 0.0))
        band.keyframe_insert("location", frame=f)
        band.rotation_euler = (0.25 * lg, 0.18 * sw, 0.0)
        band.keyframe_insert("rotation_euler", frame=f)
    actions[name] = (frames, act_sk, act_obj, act_cr)
sk_ad.action = None
obj_ad.action = None
crown_ad.action = None
for k in ALL_KEYS:
    kb[k].value = 0.0
body.location = (0, 0, 0)
band.location = (0, 0, CROWN_Z)
band.rotation_euler = (0, 0, 0)

# ---------- materials ----------
def _mix_rgba(nt):
    node = nt.nodes.new("ShaderNodeMix")
    node.data_type = 'RGBA'
    a = [s for s in node.inputs if s.name == 'A' and s.type == 'RGBA'][0]
    b = [s for s in node.inputs if s.name == 'B' and s.type == 'RGBA'][0]
    out = [o for o in node.outputs if o.type == 'RGBA'][0]
    return node, a, b, out


m = bpy.data.materials.new("king_gel")
m.use_nodes = True
nt = m.node_tree
n = nt.nodes["Principled BSDF"]
n.inputs["IOR"].default_value = 1.33
n.inputs["Alpha"].default_value = 0.78
n.inputs["Roughness"].default_value = 0.18
n.inputs["Subsurface Weight"].default_value = 0.35
n.inputs["Subsurface Radius"].default_value = (0.10, 0.30, 0.10)
if hasattr(m, "surface_render_method"):
    m.surface_render_method = 'BLENDED'
if hasattr(m, "blend_method"):
    m.blend_method = 'BLEND'
m.use_backface_culling = True
noise = nt.nodes.new("ShaderNodeTexNoise")
noise.inputs["Scale"].default_value = 3.0
noise.inputs["Detail"].default_value = 3.0
ramp, ra, rb, rout = _mix_rgba(nt)
ra.default_value = (0.015, 0.22, 0.045, 1.0)   # royal deep emerald
rb.default_value = (0.06, 0.45, 0.12, 1.0)
nt.links.new(noise.outputs["Fac"], ramp.inputs["Factor"])
coord = nt.nodes.new("ShaderNodeTexCoord")
bmap = nt.nodes.new("ShaderNodeMapping")
nt.links.new(coord.outputs["Object"], bmap.inputs["Vector"])
loc = bmap.inputs["Location"]
loc.default_value = (0, 0, 0)
loc.keyframe_insert("default_value", frame=1)
loc.default_value = (0, 0, -0.4)
loc.keyframe_insert("default_value", frame=96)


def bubble_layer(scale, thr_v):
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = scale
    nt.links.new(bmap.outputs["Vector"], vor.inputs["Vector"])
    thr = nt.nodes.new("ShaderNodeMath")
    thr.operation = 'LESS_THAN'
    thr.inputs[1].default_value = thr_v
    nt.links.new(vor.outputs["Distance"], thr.inputs[0])
    return thr


small = bubble_layer(9.0, 0.10)
big = bubble_layer(3.2, 0.20)
both = nt.nodes.new("ShaderNodeMath")
both.operation = 'MAXIMUM'
nt.links.new(small.outputs["Value"], both.inputs[0])
nt.links.new(big.outputs["Value"], both.inputs[1])
bub, ba, bb, bout = _mix_rgba(nt)
bb.default_value = (0.25, 0.75, 0.35, 1.0)
nt.links.new(rout, ba)
nt.links.new(both.outputs["Value"], bub.inputs["Factor"])
fres = nt.nodes.new("ShaderNodeLayerWeight")
fres.inputs["Blend"].default_value = 0.25
rim, ma, mb, mout = _mix_rgba(nt)
mb.default_value = (0.35, 0.85, 0.45, 1.0)
nt.links.new(bout, ma)
nt.links.new(fres.outputs["Facing"], rim.inputs["Factor"])
nt.links.new(mout, n.inputs["Base Color"])
body.data.materials.append(m)

m_gold = bpy.data.materials.new("crown_gold")
m_gold.use_nodes = True
ng = m_gold.node_tree.nodes["Principled BSDF"]
ng.inputs["Base Color"].default_value = (0.85, 0.60, 0.12, 1.0)
ng.inputs["Metallic"].default_value = 0.9
ng.inputs["Roughness"].default_value = 0.30
for part in crown_parts:
    part.data.materials.append(m_gold)

# ---------- ficha scene (contract rig, scaled for boss mass) ----------
world = bpy.data.worlds.new("ficha")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.30, 0.22, 0.48, 1.0)


def add_light(name, loc_v, energy, size):
    ld = bpy.data.lights.new(name, type='AREA')
    ld.energy = energy
    ld.size = size
    lo = bpy.data.objects.new(name, ld)
    lo.location = loc_v
    bpy.context.collection.objects.link(lo)
    lo.rotation_mode = 'QUATERNION'
    lo.rotation_quaternion = (lo.location.to_track_quat('Z', 'Y'))


add_light("key", (-3.5, -2.2, 2.6), 530, 3.5)
add_light("fill", (3.1, -2.0, 0.9), 145, 3.3)
add_light("rim", (0.7, 3.5, 2.2), 630, 3.3)

target = bpy.data.objects.new("target", None)
target.location = (0, 0, 0.35)
bpy.context.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 50
cam = bpy.data.objects.new("cam", cd)
cam.location = (-2.0, -5.1, 1.8)
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

# ---------- renders ----------
scene.render.resolution_x = 512
scene.render.resolution_y = 640
for name, (frames, act_sk, act_obj, act_cr) in actions.items():
    sk_ad.action = act_sk
    obj_ad.action = act_obj
    crown_ad.action = act_cr
    for f in range(1, frames + 1, 2):
        scene.frame_set(f)
        scene.render.filepath = os.path.join(ANIM_DIR, f"{name.replace('-loop', '')}_{f:03d}.png")
        bpy.ops.render.render(write_still=True)
    print("[king] frames", name)
sk_ad.action = None
obj_ad.action = None
crown_ad.action = None
for k in ALL_KEYS:
    kb[k].value = 0.0
body.location = (0, 0, 0)
band.location = (0, 0, CROWN_Z)
band.rotation_euler = (0, 0, 0)

# ---------- hero still: scale silhouette (mob style contract §4, Pokedex rule) ----------
sys.path.insert(0, os.path.dirname(OUT_DIR))
import _ficha_common as ficha

MOB_HX, MOB_HY, MOB_ZMAX = 1.34, 1.34, 1.90  # king slime bounding radius ~1.32m + margin
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
scene.render.filepath = os.path.join(REN_DIR, "king_slime_hero.png")
bpy.ops.render.render(write_still=True)

ficha.restore_hero_camera(cam, target, old_target_loc, old_cam_loc)
ficha.remove_scale_silhouette(sil)

# ---------- NLA push + export ----------
for name, (frames, act_sk, act_obj, act_cr) in actions.items():
    for ad, act in ((sk_ad, act_sk), (obj_ad, act_obj), (crown_ad, act_cr)):
        tr = ad.nla_tracks.new()
        tr.name = name
        tr.strips.new(name, 1, act)

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "king_slime_wip.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "king_slime.glb"),
    use_selection=False,
    export_animations=True,
    export_morph=True,
    export_animation_mode='NLA_TRACKS',
)
print("[king] DONE")
