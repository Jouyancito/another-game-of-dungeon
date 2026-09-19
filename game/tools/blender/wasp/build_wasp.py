# build_wasp.py — prairie wasp: 3-segment insect body + 2 wing pairs, defined by
# a fast hover-and-dart flight and a stinger-leading strike.
#   idle-loop   hover bob (object z sine) + wings flapping (~4 flaps per bob)
#   move-loop   darting bob, forward tilt, faster wingbeat
#   attack      rear back (cock) -> dart forward, stinger leading (one-shot)
#   hit         knocked sideways flinch (one-shot)
#   death       wings stop, drops to ground and tips over (one-shot)
# Mirrors game/tools/blender/slime/build_slime.py: shape-key + object-transform
# actions pushed to NLA tracks (same names per data-block), showcase ficha rig.
# Run: blender -b --python build_wasp.py
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

HOVER_Z = 0.5  # floats above the origin ground plane, per contract


def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


# ---------------------------------------------------------------------------
# BODY — head / thorax / thin waist / pointed abdomen (the abdomen cone IS the
# stinger — no separate part) + tiny bent legs. Built along local -Y = front
# (matches the slime ficha rig: camera sits at -Y, "forward" faces the viewer).
# ---------------------------------------------------------------------------
def make_part(op, **kwargs):
    op(**kwargs)
    return bpy.context.object


def make_leg(root, side, length_scale=0.7, seed_tag=0):
    """Two-segment bent leg: short coxa angled out+down, thinner tibia beyond
    it angled further out. Aligned via to_track_quat, same idiom as the ficha
    rig's light-aim code. Kept thin/short — accent detail, not a silhouette
    dominator."""
    rx, ry, rz = root
    up_end = Vector((rx + side * 0.020 * length_scale, ry - 0.004, rz - 0.028 * length_scale))
    lo_end = Vector((up_end.x + side * 0.015 * length_scale, up_end.y + 0.007, up_end.z - 0.024 * length_scale))
    parts = []

    def segment(name, start, end, radius):
        start = Vector(start)
        d = end - start
        length = d.length
        mid = start + d * 0.5
        cyl = make_part(bpy.ops.mesh.primitive_cylinder_add, radius=radius, depth=length,
                         location=mid, vertices=6)
        cyl.name = name
        cyl.rotation_mode = 'QUATERNION'
        cyl.rotation_quaternion = d.to_track_quat('Z', 'Y')
        return cyl

    parts.append(segment(f"leg_up_{seed_tag}", Vector(root), up_end, 0.0038))
    parts.append(segment(f"leg_lo_{seed_tag}", up_end, lo_end, 0.0026))
    return parts


def build_body():
    parts = []

    head = make_part(bpy.ops.mesh.primitive_uv_sphere_add, radius=0.045,
                      location=(0.0, -0.155, 0.0), segments=20, ring_count=12)
    head.name = "head"
    parts.append(head)

    thorax = make_part(bpy.ops.mesh.primitive_uv_sphere_add, radius=0.062,
                        location=(0.0, -0.075, 0.010), segments=22, ring_count=13)
    thorax.name = "thorax"
    thorax.scale = (1.0, 0.95, 0.92)
    parts.append(thorax)

    waist = make_part(bpy.ops.mesh.primitive_cylinder_add, radius=0.009, depth=0.048,
                       location=(0.0, 0.0, 0.005), rotation=(math.radians(90), 0.0, 0.0),
                       vertices=10)
    waist.name = "waist"
    parts.append(waist)

    abd_len = 0.19
    abdomen = make_part(bpy.ops.mesh.primitive_cone_add, radius1=0.060, radius2=0.0,
                         depth=abd_len, location=(0.0, 0.02 + abd_len / 2.0, 0.0),
                         rotation=(math.radians(-90), 0.0, 0.0), vertices=18)
    abdomen.name = "abdomen"
    parts.append(abdomen)

    # legs — 3 pairs, tiny, tucked under thorax/abdomen-base
    for i, ly in enumerate((-0.10, -0.05, 0.01)):
        for side in (-1, 1):
            parts.extend(make_leg((side * 0.045, ly, -0.045), side, seed_tag=i * 2 + (1 if side > 0 else 0)))

    return parts, head, thorax, abdomen


def build_eyes():
    eyes = []
    for side in (-1, 1):
        e = make_part(bpy.ops.mesh.primitive_uv_sphere_add, radius=0.011,
                       location=(side * 0.026, -0.185, 0.010), segments=10, ring_count=6)
        e.name = f"eye_{'L' if side < 0 else 'R'}"
        eyes.append(e)
    return eyes


# ---------------------------------------------------------------------------
# WINGS — one object, 2 pairs (fore/hind x L/R). Each wing is a flat leaf
# n-gon built TWICE (forward + reversed winding, same verts) so it reads from
# both sides under backface culling with no z-fight. The "flap" shape key
# rigidly swings each wing's own verts up around ITS OWN hinge (root at the
# thorax attach point), computed directly at build time — no per-object pivot
# math needed after export.
# ---------------------------------------------------------------------------
def wing_outline_local(span, chord):
    """Closed leaf loop, root (0,0) -> around the tip -> back to root."""
    right = [
        (0.0, 0.0),
        (0.15 * span, 0.34 * chord),
        (0.42 * span, 0.48 * chord),
        (0.72 * span, 0.36 * chord),
        (0.95 * span, 0.13 * chord),
        (span, 0.0),
    ]
    left = [(x, -y) for (x, y) in reversed(right[1:-1])]
    return right + left


def build_wing(hinge, span, chord, sweep_deg, dihedral_deg, side, flap_deg, thickness=0.0006):
    """Returns (rest_positions[], flap_positions[]) — front ring (n verts) then
    a back ring offset by `thickness` along the wing's local normal, so the
    double-sided card is a real (if paper-thin) shell instead of two perfectly
    coincident faces (which Blender flags as invalid non-manifold geometry)."""
    outline = wing_outline_local(span, chord)
    sweep = math.radians(sweep_deg)
    dihedral = math.radians(dihedral_deg)
    cy, sy = math.cos(dihedral), math.sin(dihedral)
    cz, sz = math.cos(sweep), math.sin(sweep)
    cf, sf = math.cos(math.radians(flap_deg)), math.sin(math.radians(flap_deg))

    def place(local):
        lx, ly, lz = local
        # dihedral: rotate (x,z) around Y axis
        x1 = lx * cy + lz * sy
        z1 = -lx * sy + lz * cy
        y1 = ly
        # sweep: rotate (x,y) around Z axis
        x2 = x1 * cz - y1 * sz
        y2 = x1 * sz + y1 * cz
        z2 = z1
        return Vector(hinge) + Vector((x2, y2, z2))

    rest, flap = [], []
    for lz in (thickness * 0.5, -thickness * 0.5):
        for (lx, ly) in outline:
            base = (side * lx, ly, lz)
            rest.append(place(base))
            lifted = (side * lx * cf, ly, lx * sf + lz)  # rigid up-swing around the hinge line
            flap.append(place(lifted))
    return rest, flap


def build_wings():
    specs = [
        # hinge, span, chord, sweep_deg, dihedral_deg, flap_deg
        # dihedral kept HIGH (readability > strict anatomy, contract rule 1):
        # a near-flat wing is edge-on and invisible from a level camera.
        dict(hinge=(0.050, -0.090, 0.045), span=0.17, chord=0.095, sweep=14, dihedral=40, flap=50),  # fore R
        dict(hinge=(0.045, -0.048, 0.035), span=0.12, chord=0.065, sweep=20, dihedral=34, flap=44),  # hind R
    ]
    verts_rest, verts_flap, faces = [], [], []
    for spec in specs:
        for side in (1, -1):
            hinge = (spec["hinge"][0] * side, spec["hinge"][1], spec["hinge"][2])
            rest, flap = build_wing(hinge, spec["span"], spec["chord"], spec["sweep"],
                                     spec["dihedral"], side, spec["flap"])
            base_idx = len(verts_rest)
            verts_rest.extend(rest)
            verts_flap.extend(flap)
            n = len(rest) // 2
            faces.append([base_idx + i for i in range(n)])                      # front ring
            faces.append([base_idx + n + i for i in reversed(range(n))])        # back ring, reversed winding

    mesh = bpy.data.meshes.new("wasp_wings_mesh")
    mesh.from_pydata(verts_rest, [], faces)
    mesh.update()
    for p in mesh.polygons:
        p.use_smooth = False
    obj = bpy.data.objects.new("wasp_wings", mesh)
    bpy.context.collection.objects.link(obj)
    return obj, verts_flap


# ---------------------------------------------------------------------------
# assembly helpers
# ---------------------------------------------------------------------------
def join_objects(objs, final_name):
    for o in objs:
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    joined = bpy.context.view_layer.objects.active
    joined.name = final_name
    return joined


def _mix_rgba(nt):
    node = nt.nodes.new("ShaderNodeMix")
    node.data_type = 'RGBA'
    a = [s for s in node.inputs if s.name == 'A' and s.type == 'RGBA'][0]
    b = [s for s in node.inputs if s.name == 'B' and s.type == 'RGBA'][0]
    out = [o for o in node.outputs if o.type == 'RGBA'][0]
    return node, a, b, out


def _base_mat(name, alpha=1.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Alpha"].default_value = alpha
    if alpha < 1.0:
        if hasattr(m, "surface_render_method"):
            m.surface_render_method = 'BLENDED'
        if hasattr(m, "blend_method"):
            m.blend_method = 'BLEND'
        m.use_backface_culling = True
    return m, nt, n


def mat_body():
    # warm chitin: yellow base, dark-brown bands on the abdomen via a
    # position-based (object-space Y) periodic mix — the signature material.
    m, nt, n = _base_mat("wasp_chitin")
    n.inputs["Roughness"].default_value = 0.35

    coord = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(coord.outputs["Object"], sep.inputs["Vector"])

    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = 'MULTIPLY'
    mul.inputs[1].default_value = 130.0  # ~4-5 bands across the abdomen's Y span
    nt.links.new(sep.outputs["Y"], mul.inputs[0])
    sine = nt.nodes.new("ShaderNodeMath")
    sine.operation = 'SINE'
    nt.links.new(mul.outputs[0], sine.inputs[0])
    band = nt.nodes.new("ShaderNodeMath")
    band.operation = 'GREATER_THAN'
    band.inputs[1].default_value = 0.15
    nt.links.new(sine.outputs[0], band.inputs[0])

    mask = nt.nodes.new("ShaderNodeMath")
    mask.operation = 'GREATER_THAN'
    mask.inputs[1].default_value = 0.02  # abdomen starts past the waist
    nt.links.new(sep.outputs["Y"], mask.inputs[0])

    both = nt.nodes.new("ShaderNodeMath")
    both.operation = 'MINIMUM'
    nt.links.new(band.outputs[0], both.inputs[0])
    nt.links.new(mask.outputs[0], both.inputs[1])

    stripe, sa, sb, sout = _mix_rgba(nt)
    sa.default_value = (0.95, 0.68, 0.13, 1.0)   # warm yellow
    sb.default_value = (0.16, 0.09, 0.045, 1.0)  # dark brown
    nt.links.new(both.outputs[0], stripe.inputs["Factor"])

    # subtle noise mottling so the yellow isn't flat (contract rule 2)
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 9.0
    noise.inputs["Detail"].default_value = 2.0
    mott, ma, mb, mout = _mix_rgba(nt)
    ma.default_value = (1.0, 1.0, 1.0, 1.0)
    mb.default_value = (0.88, 0.86, 0.84, 1.0)
    fac = nt.nodes.new("ShaderNodeMath")
    fac.operation = 'MULTIPLY'
    fac.inputs[1].default_value = 0.10
    nt.links.new(noise.outputs["Fac"], fac.inputs[0])
    nt.links.new(fac.outputs[0], mott.inputs["Factor"])
    mult = nt.nodes.new("ShaderNodeVectorMath")
    mult.operation = 'MULTIPLY'
    nt.links.new(sout, mult.inputs[0])
    nt.links.new(mout, mult.inputs[1])
    nt.links.new(mult.outputs[0], n.inputs["Base Color"])
    return m


def mat_eye():
    m, nt, n = _base_mat("wasp_eye")
    n.inputs["Base Color"].default_value = (0.03, 0.03, 0.035, 1.0)
    n.inputs["Roughness"].default_value = 0.12
    return m


def mat_wing():
    m, nt, n = _base_mat("wasp_wing", alpha=0.35)
    n.inputs["Roughness"].default_value = 0.20
    n.inputs["Base Color"].default_value = (0.95, 0.95, 0.92, 1.0)
    # faint vein network (Voronoi threshold, same idiom as the slime's bubbles)
    coord = nt.nodes.new("ShaderNodeTexCoord")
    vor = nt.nodes.new("ShaderNodeTexVoronoi")
    vor.inputs["Scale"].default_value = 22.0
    nt.links.new(coord.outputs["Object"], vor.inputs["Vector"])
    thr = nt.nodes.new("ShaderNodeMath")
    thr.operation = 'LESS_THAN'
    thr.inputs[1].default_value = 0.045
    nt.links.new(vor.outputs["Distance"], thr.inputs[0])
    fac = nt.nodes.new("ShaderNodeMath")
    fac.operation = 'MULTIPLY'
    fac.inputs[1].default_value = 0.18
    nt.links.new(thr.outputs[0], fac.inputs[0])
    vein, va, vb, vout = _mix_rgba(nt)
    va.default_value = (0.95, 0.95, 0.92, 1.0)
    vb.default_value = (0.55, 0.48, 0.35, 1.0)
    nt.links.new(fac.outputs[0], vein.inputs["Factor"])
    nt.links.new(vout, n.inputs["Base Color"])
    return m


# ---------------------------------------------------------------------------
# MAIN BUILD
# ---------------------------------------------------------------------------
body_parts, head_obj, thorax_obj, abdomen_obj = build_body()
eye_parts = build_eyes()

chitin_mat = mat_body()
eye_mat = mat_eye()
for o in body_parts:
    o.data.materials.append(chitin_mat)
for o in eye_parts:
    o.data.materials.append(eye_mat)

for o in body_parts + eye_parts:
    for p in o.data.polygons:
        p.use_smooth = True

body = join_objects(body_parts + eye_parts, "wasp_body")
me = body.data

wings, wing_flap_targets = build_wings()
wings.data.materials.append(mat_wing())
wings.parent = body  # inherits body's animated location/rotation for free

# ---------- body shape keys: curl (attack) + flinch (hit) ----------
body.shape_key_add(name="Basis")
WAIST_Y, TIP_Y = 0.02, 0.21
Z_MIN = min(v.co.z for v in me.vertices)
Z_MAX = max(v.co.z for v in me.vertices)
H = max(1e-6, Z_MAX - Z_MIN)

sk = body.shape_key_add(name="curl")  # abdomen swings forward+down, stinger leading
for i, v in enumerate(me.vertices):
    if v.co.y > WAIST_Y:
        s = min(1.0, (v.co.y - WAIST_Y) / (TIP_Y - WAIST_Y))
        dy = -0.11 * s ** 1.4
        dz = -0.075 * s ** 1.2
        sk.data[i].co = v.co + Vector((0.0, dy, dz))
    else:
        sk.data[i].co = v.co

sk = body.shape_key_add(name="flinch")  # top mass lags sideways (knock reaction)
for i, v in enumerate(me.vertices):
    zn = (v.co.z - Z_MIN) / H
    sk.data[i].co = v.co + Vector((0.085 * zn ** 1.5, 0.0, 0.0))

body_kb = me.shape_keys.key_blocks

# ---------- wing shape key: flap ----------
wings.shape_key_add(name="Basis")
wsk = wings.shape_key_add(name="flap")
for i, co in enumerate(wing_flap_targets):
    wsk.data[i].co = co
wing_kb = wings.data.shape_keys.key_blocks

FPS = 24
scene.render.fps = FPS


# ---------- animation samplers: body (shape keys + object transform), wing (flap) ----------
def anim_idle_body(t):
    return {"z": HOVER_Z + 0.035 * math.sin(2 * math.pi * t)}


def anim_idle_wing(t):
    return {"flap": 0.5 + 0.5 * math.sin(2 * math.pi * 4 * t)}


def anim_move_body(t):
    return {"z": HOVER_Z + 0.05 * math.sin(2 * math.pi * t),
            "y": 0.03 * math.sin(4 * math.pi * t),
            "rx": -0.33}


def anim_move_wing(t):
    return {"flap": 0.5 + 0.5 * math.sin(2 * math.pi * 5 * t)}


def anim_attack_body(t):
    v = {"z": HOVER_Z}
    if t < 0.28:
        u = t / 0.28
        v["y"] = lerp(0.0, 0.10, u)
        v["rx"] = lerp(0.0, 0.18, u)
        v["curl"] = lerp(0.0, 0.25, u)
    elif t < 0.55:
        u = (t - 0.28) / 0.27
        v["y"] = lerp(0.10, -0.14, u)
        v["rx"] = lerp(0.18, -0.45, u)
        v["curl"] = lerp(0.25, 1.0, u)
        v["z"] = HOVER_Z - 0.03 * math.sin(math.pi * u)
    else:
        u = (t - 0.55) / 0.45
        v["y"] = lerp(-0.14, 0.0, u)
        v["rx"] = lerp(-0.45, 0.0, u)
        v["curl"] = lerp(1.0, 0.0, u)
    return v


def anim_attack_wing(t):
    return {"flap": 0.5 + 0.5 * math.sin(2 * math.pi * 6 * t)}


def anim_hit_body(t):
    return {"z": HOVER_Z,
            "x": 0.09 * math.sin(math.pi * t),
            "rz": 0.35 * math.sin(math.pi * min(1.0, t * 1.4)),
            "flinch": 0.6 * math.sin(math.pi * t)}


def anim_hit_wing(t):
    return {"flap": 0.5 + 0.5 * math.sin(2 * math.pi * 4 * t)}


def anim_death_body(t):
    if t < 0.65:
        u = t / 0.65
        return {"z": HOVER_Z * (1.0 - u), "rz": lerp(0.0, math.radians(75), u)}
    u = (t - 0.65) / 0.35
    bounce = 0.025 * math.sin(math.pi * u) * (1.0 - u)
    return {"z": bounce, "rz": lerp(math.radians(75), math.radians(88), u)}


def anim_death_wing(t):
    return {"flap": 0.0}


ANIMS = {
    "idle-loop": (48, anim_idle_body, anim_idle_wing),
    "move-loop": (36, anim_move_body, anim_move_wing),
    "attack": (26, anim_attack_body, anim_attack_wing),
    "hit": (12, anim_hit_body, anim_hit_wing),
    "death": (32, anim_death_body, anim_death_wing),
}

BODY_KEYS = ("curl", "flinch")

body_sk_ad = me.shape_keys.animation_data_create()
body_obj_ad = body.animation_data_create()
wing_sk_ad = wings.data.shape_keys.animation_data_create()

actions = {}
for name, (frames, bsamp, wsamp) in ANIMS.items():
    act_bsk = bpy.data.actions.new(f"{name}_body_sk")
    act_bobj = bpy.data.actions.new(f"{name}_body_obj")
    act_wsk = bpy.data.actions.new(f"{name}_wing_sk")
    body_sk_ad.action = act_bsk
    body_obj_ad.action = act_bobj
    wing_sk_ad.action = act_wsk
    for f in range(1, frames + 1, 2):
        t = (f - 1) / (frames - 1)
        bv = bsamp(t)
        wv = wsamp(t)
        for k in BODY_KEYS:
            body_kb[k].value = bv.get(k, 0.0)
            body_kb[k].keyframe_insert("value", frame=f)
        body.location.x = bv.get("x", 0.0)
        body.location.y = bv.get("y", 0.0)
        body.location.z = bv.get("z", HOVER_Z)
        body.keyframe_insert("location", frame=f)
        body.rotation_euler.x = bv.get("rx", 0.0)
        body.rotation_euler.z = bv.get("rz", 0.0)
        body.keyframe_insert("rotation_euler", frame=f)
        wing_kb["flap"].value = wv.get("flap", 0.0)
        wing_kb["flap"].keyframe_insert("value", frame=f)
    actions[name] = (frames, act_bsk, act_bobj, act_wsk)
body_sk_ad.action = None
body_obj_ad.action = None
wing_sk_ad.action = None


def reset_rest_pose():
    body.location = (0.0, 0.0, HOVER_Z)
    body.rotation_euler = (0.0, 0.0, 0.0)
    for k in BODY_KEYS:
        body_kb[k].value = 0.0
    wing_kb["flap"].value = 0.0


reset_rest_pose()

# ---------- showcase-ficha scene (contract §4) ----------
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
    lo.rotation_quaternion = (Vector(loc) - Vector((0, 0, HOVER_Z))).to_track_quat('Z', 'Y')


add_light("key", (-0.35, -0.55, HOVER_Z + 0.30), 9, 0.6)
add_light("fill", (0.35, -0.45, HOVER_Z + 0.05), 3, 0.55)
add_light("rim", (0.05, 0.55, HOVER_Z + 0.25), 11, 0.55)

target = bpy.data.objects.new("target", None)
target.location = (0.0, 0.0, HOVER_Z)
bpy.context.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 50
cam = bpy.data.objects.new("cam", cd)
cam.location = (-0.28, -0.58, HOVER_Z + 0.12)
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

BASE_TARGET_Z = HOVER_Z
BASE_CAM_LOC = Vector((-0.28, -0.58, HOVER_Z + 0.12))


def frame_camera_for_clip(name):
    """death drops the body from HOVER_Z to the ground — the base hover-framed
    camera loses it entirely past mid-fall. Pull back + re-center vertically
    for that clip only so the whole fall stays in frame."""
    if name == "death":
        target.location = (0.0, 0.0, HOVER_Z * 0.5)
        cam.location = (-0.42, -0.95, HOVER_Z * 0.5 + 0.30)
    else:
        target.location = (0.0, 0.0, BASE_TARGET_Z)
        cam.location = BASE_CAM_LOC


# ---------- renders: preview frames per animation ----------
scene.render.resolution_x = 512
scene.render.resolution_y = 640
for name, (frames, act_bsk, act_bobj, act_wsk) in actions.items():
    body_sk_ad.action = act_bsk
    body_obj_ad.action = act_bobj
    wing_sk_ad.action = act_wsk
    frame_camera_for_clip(name)
    for f in range(1, frames + 1, 2):
        scene.frame_set(f)
        scene.render.filepath = os.path.join(ANIM_DIR, f"{name.replace('-loop', '')}_{f:03d}.png")
        bpy.ops.render.render(write_still=True)
    print("[wasp] frames", name)
body_sk_ad.action = None
body_obj_ad.action = None
wing_sk_ad.action = None
reset_rest_pose()  # gotcha: actions leave last evaluated values behind
target.location = (0.0, 0.0, BASE_TARGET_Z)
cam.location = BASE_CAM_LOC

# ---------- hero still: scale silhouette (mob style contract §4, Pokedex rule) ----------
# Wasp HOVERS (HOVER_Z=0.5) — the silhouette stands on the ground (z=0) so the
# still shows the TRUE height comparison (wasp floating around knee height),
# not just a side-by-side same-baseline trick.
sys.path.insert(0, os.path.dirname(OUT_DIR))
import _ficha_common as ficha

MOB_HX, MOB_HY = 0.20, 0.21  # wasp wingspan half-extent / head-to-abdomen-tip
MOB_ZMAX = HOVER_Z + 0.20    # silhouette stands at z=0, wasp hovers — combined top is generous
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
scene.render.filepath = os.path.join(REN_DIR, "wasp_hero.png")
bpy.ops.render.render(write_still=True)

ficha.restore_hero_camera(cam, target, old_target_loc, old_cam_loc)
ficha.remove_scale_silhouette(sil)

# ---------- push all actions to NLA tracks (same name across data-blocks) ----------
for name, (frames, act_bsk, act_bobj, act_wsk) in actions.items():
    tr = body_sk_ad.nla_tracks.new()
    tr.name = name
    tr.strips.new(name, 1, act_bsk)
    tro = body_obj_ad.nla_tracks.new()
    tro.name = name
    tro.strips.new(name, 1, act_bobj)
    trw = wing_sk_ad.nla_tracks.new()
    trw.name = name
    trw.strips.new(name, 1, act_wsk)

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "wasp_wip.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "wasp.glb"),
    use_selection=False,
    export_animations=True,
    export_morph=True,
    export_animation_mode='NLA_TRACKS',
)
print("[wasp] DONE")
