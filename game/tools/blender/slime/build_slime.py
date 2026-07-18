# build_slime.py — faceless slime defined by MOTION: full gameplay animation set.
# Joan approved the viscous wobble (2026-07-18); this adds the gameplay set:
#   idle-loop  breathing wobble (approved)
#   hop-loop   locomotion — slimes don't walk, they hop (approach AND retreat)
#   hit        flinch on taking a blow
#   attack     crouch + forward lunge
#   death      melts into a puddle
# Fast/slow variants are playback speed in Godot (speed_scale), not extra anims.
# Elemental steam (water slime killed by fire) is Godot particles, not mesh anim.
# "-loop" suffix => Godot glTF import auto-loops. Export mode: NLA tracks.
# Run: blender -b --python build_slime.py
import bpy
import math
import os
from mathutils import Vector

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
ANIM_DIR = os.path.join(REN_DIR, "anim")
os.makedirs(ANIM_DIR, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# ---------- body: gelatinous dome (dense mesh, no subsurf: shape keys must export) ----------
bpy.ops.mesh.primitive_uv_sphere_add(segments=96, ring_count=48, radius=0.5)
body = bpy.context.object
body.name = "slime"
me = body.data
for v in me.vertices:
    z = v.co.z
    v.co.z = z * (0.78 if z > 0.0 else 0.55)
    t = max(0.0, min(1.0, (0.08 - v.co.z) / 0.35))
    s = 1.0 + 0.20 * t
    v.co.x *= s
    v.co.y *= s
for p in me.polygons:
    p.use_smooth = True

Z_MIN = min(v.co.z for v in me.vertices)
Z_MAX = max(v.co.z for v in me.vertices)
H = Z_MAX - Z_MIN

# ---------- shape keys: the viscous vocabulary ----------
body.shape_key_add(name="Basis")

sk = body.shape_key_add(name="squash")     # sat-down blob, mass pushed out
for i, v in enumerate(me.vertices):
    zn = (v.co.z - Z_MIN) / H
    nz = Z_MIN + (v.co.z - Z_MIN) * 0.80
    spread = 1.0 + 0.14 * (1.0 - zn)
    sk.data[i].co = Vector((v.co.x * spread, v.co.y * spread, nz))

sk = body.shape_key_add(name="stretch")    # gel pulls upward, waist narrows
for i, v in enumerate(me.vertices):
    nz = Z_MIN + (v.co.z - Z_MIN) * 1.16
    sk.data[i].co = Vector((v.co.x * 0.93, v.co.y * 0.93, nz))

sk = body.shape_key_add(name="sway")       # top mass lags sideways (viscous lag)
for i, v in enumerate(me.vertices):
    zn = (v.co.z - Z_MIN) / H
    sk.data[i].co = v.co + Vector((0.10 * zn ** 1.6, 0.0, 0.0))

sk = body.shape_key_add(name="lunge")      # top mass throws FORWARD (-Y = face side)
for i, v in enumerate(me.vertices):
    zn = (v.co.z - Z_MIN) / H
    sk.data[i].co = v.co + Vector((0.0, -0.22 * zn ** 1.5, 0.0))

sk = body.shape_key_add(name="melt")       # collapses into a wide puddle
for i, v in enumerate(me.vertices):
    nz = Z_MIN + (v.co.z - Z_MIN) * 0.16
    sk.data[i].co = Vector((v.co.x * 1.45, v.co.y * 1.45, nz))

kb = me.shape_keys.key_blocks
FPS = 24
scene.render.fps = FPS


def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


# ---------- animation definitions: name -> (frames, sampler(t) -> {key: value, z: obj_z}) ----------
def anim_idle(t):
    w = math.sin(2 * math.pi * t)
    return {"squash": max(0.0, w) * 0.55, "stretch": max(0.0, -w) * 0.40,
            "sway": 0.5 + 0.5 * math.sin(4 * math.pi * t + math.pi / 3)}


def anim_hop(t):
    v = {"squash": 0.0, "stretch": 0.0, "sway": 0.0, "z": 0.0}
    if t < 0.20:                    # anticipation: crouch
        v["squash"] = lerp(0.0, 0.75, t / 0.20)
    elif t < 0.30:                  # launch
        u = (t - 0.20) / 0.10
        v["squash"] = lerp(0.75, 0.0, u)
        v["stretch"] = lerp(0.0, 0.55, u)
    elif t < 0.70:                  # airborne: parabola, stretch relaxes
        u = (t - 0.30) / 0.40
        v["z"] = 0.45 * (1.0 - (2 * u - 1.0) ** 2)
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
    v = {"melt": min(1.0, t * 1.25), "sway": 0.0, "squash": 0.0}
    if t > 0.6:                     # final soft ripple as the puddle settles
        v["squash"] = 0.15 * math.sin(2 * math.pi * (t - 0.6) / 0.4)
    return v


ANIMS = {
    "idle-loop": (72, anim_idle),
    "hop-loop": (48, anim_hop),
    "hit": (12, anim_hit),
    "attack": (22, anim_attack),
    "death": (28, anim_death),
}

ALL_KEYS = ("squash", "stretch", "sway", "lunge", "melt")
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
    actions[name] = (frames, act_sk, act_obj)
sk_ad.action = None
obj_ad.action = None

# ---------- habitat materials (canon PO 2026-07-17; Joan 2026-07-18: each habitat
# gets its PHYSICS, not just its color — water reads as water, earth as mud,
# prairie as jelly. "Too solid" was the rejected look.) ----------
# Joan (2026-07-18): solid flat color reads dead — each habitat gets procedural
# texture so it looks like ITS material: jelly = inner variation + bubbles + rim,
# water = depth gradient + ripple, mud = patches + chunky grit.
# NOTE: node textures do NOT survive glTF export — a bake pass (to image textures)
# is required before the GLB carries these into Godot. Look-approval first.

def _mix_rgba(nt):
    """ShaderNodeMix has float/vector/color sockets all named A/B — grab the RGBA ones."""
    node = nt.nodes.new("ShaderNodeMix")
    node.data_type = 'RGBA'
    a = [s for s in node.inputs if s.name == 'A' and s.type == 'RGBA'][0]
    b = [s for s in node.inputs if s.name == 'B' and s.type == 'RGBA'][0]
    out = [o for o in node.outputs if o.type == 'RGBA'][0]
    return node, a, b, out


def _base(name, alpha):
    m = bpy.data.materials.new(f"slime_{name}")
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["IOR"].default_value = 1.33
    n.inputs["Alpha"].default_value = alpha
    if alpha < 1.0:
        if hasattr(m, "surface_render_method"):
            m.surface_render_method = 'BLENDED'
        if hasattr(m, "blend_method"):
            m.blend_method = 'BLEND'
        # closed blob + alpha blend: cull backfaces or the far side sorts in front
        m.use_backface_culling = True
    return m, nt, n


def mat_jelly():
    m, nt, n = _base("green", 0.75)
    n.inputs["Roughness"].default_value = 0.18
    n.inputs["Subsurface Weight"].default_value = 0.35
    n.inputs["Subsurface Radius"].default_value = (0.10, 0.30, 0.10)
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 4.0
    noise.inputs["Detail"].default_value = 3.0
    ramp, ra, rb, rout = _mix_rgba(nt)
    ra.default_value = (0.03, 0.32, 0.055, 1.0)   # deep jelly
    rb.default_value = (0.10, 0.60, 0.15, 1.0)    # bright jelly
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Factor"])
    # suspended bubbles: sparse voronoi dots, slightly lighter
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = 16.0
    thr = nt.nodes.new("ShaderNodeMath")
    thr.operation = 'LESS_THAN'
    thr.inputs[1].default_value = 0.12
    nt.links.new(vor.outputs["Distance"], thr.inputs[0])
    bub, ba, bb, bout = _mix_rgba(nt)
    bb.default_value = (0.35, 0.85, 0.45, 1.0)     # bubble glint
    nt.links.new(rout, ba)
    nt.links.new(thr.outputs["Value"], bub.inputs["Factor"])
    # gel rim: edges catch light
    fres = nt.nodes.new("ShaderNodeLayerWeight")
    fres.inputs["Blend"].default_value = 0.25
    rim, ma, mb, mout = _mix_rgba(nt)
    mb.default_value = (0.45, 0.95, 0.55, 1.0)
    nt.links.new(bout, ma)
    nt.links.new(fres.outputs["Facing"], rim.inputs["Factor"])
    nt.links.new(mout, n.inputs["Base Color"])
    return m


def mat_water():
    m, nt, n = _base("blue", 0.42)
    n.inputs["Roughness"].default_value = 0.04
    # depth gradient: dark deep blue below, light cyan up top
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Position"], sep.inputs["Vector"])
    mapr = nt.nodes.new("ShaderNodeMapRange")
    mapr.inputs["From Min"].default_value = -0.30
    mapr.inputs["From Max"].default_value = 0.40
    nt.links.new(sep.outputs["Z"], mapr.inputs["Value"])
    grad, ga, gb, gout = _mix_rgba(nt)
    ga.default_value = (0.03, 0.15, 0.40, 1.0)    # deep
    gb.default_value = (0.25, 0.60, 0.85, 1.0)    # surface
    nt.links.new(mapr.outputs["Result"], grad.inputs["Factor"])
    nt.links.new(gout, n.inputs["Base Color"])
    # fine ripple
    rip = nt.nodes.new("ShaderNodeTexNoise")
    rip.inputs["Scale"].default_value = 14.0
    rip.inputs["Detail"].default_value = 4.0
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.12
    nt.links.new(rip.outputs["Fac"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], n.inputs["Normal"])
    return m


def mat_mud():
    m, nt, n = _base("brown", 1.0)
    n.inputs["Subsurface Weight"].default_value = 0.0
    # mud patches: two earths mixed by big noise
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 3.5
    noise.inputs["Detail"].default_value = 4.0
    patch, pa, pb, pout = _mix_rgba(nt)
    pa.default_value = (0.045, 0.028, 0.014, 1.0)  # wet dark mud
    pb.default_value = (0.13, 0.085, 0.045, 1.0)   # dry earth
    nt.links.new(noise.outputs["Fac"], patch.inputs["Factor"])
    nt.links.new(pout, n.inputs["Base Color"])
    # roughness varies: wet patches shinier
    rmap = nt.nodes.new("ShaderNodeMapRange")
    rmap.inputs["To Min"].default_value = 0.45
    rmap.inputs["To Max"].default_value = 0.9
    nt.links.new(noise.outputs["Fac"], rmap.inputs["Value"])
    nt.links.new(rmap.outputs["Result"], n.inputs["Roughness"])
    # chunky grit
    grit = nt.nodes.new("ShaderNodeTexVoronoi")
    grit.inputs["Scale"].default_value = 9.0
    bump = nt.nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.5
    nt.links.new(grit.outputs["Distance"], bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], n.inputs["Normal"])
    return m


mats = {"green": mat_jelly(), "blue": mat_water(), "brown": mat_mud()}
body.data.materials.append(mats["green"])

# ---------- showcase-ficha scene ----------
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
scene.view_settings.view_transform = 'Standard'

# ---------- renders: preview frames per animation (green) ----------
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
for k in ALL_KEYS:      # actions leave the last evaluated values behind — reset to rest
    kb[k].value = 0.0

scene.frame_set(1)
scene.render.resolution_x = 1024
scene.render.resolution_y = 1280
for name, mat in mats.items():
    body.data.materials[0] = mat
    scene.render.filepath = os.path.join(REN_DIR, f"slime_{name}.png")
    bpy.ops.render.render(write_still=True)
body.data.materials[0] = mats["green"]

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

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "slime_wip.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "slime.glb"),
    use_selection=False,
    export_animations=True,
    export_morph=True,
    export_animation_mode='NLA_TRACKS',
)
print("[slime] DONE")
