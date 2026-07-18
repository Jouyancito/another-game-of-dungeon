# build_slime.py — faceless slime defined by MOTION: viscous idle wobble + habitat colors.
# Joan (2026-07-18): drop the face for now; the slime reads through liquid movement.
# Canon (PO 2026-07-17): color by habitat — green prairie, blue water, brown earth.
# Animation: shape keys (squash/stretch breath + lateral sway at a different frequency),
# action named "idle-loop" so Godot's glTF import auto-loops it.
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

sk_squash = body.shape_key_add(name="squash")   # sat-down blob, mass pushed out
for i, v in enumerate(me.vertices):
    zn = (v.co.z - Z_MIN) / H
    nz = Z_MIN + (v.co.z - Z_MIN) * 0.80
    spread = 1.0 + 0.14 * (1.0 - zn)
    sk_squash.data[i].co = Vector((v.co.x * spread, v.co.y * spread, nz))

sk_stretch = body.shape_key_add(name="stretch")  # gel pulls upward, waist narrows
for i, v in enumerate(me.vertices):
    nz = Z_MIN + (v.co.z - Z_MIN) * 1.16
    sk_stretch.data[i].co = Vector((v.co.x * 0.93, v.co.y * 0.93, nz))

sk_sway = body.shape_key_add(name="sway")        # top mass lags sideways (viscous lag)
for i, v in enumerate(me.vertices):
    zn = (v.co.z - Z_MIN) / H
    sk_sway.data[i].co = v.co + Vector((0.10 * zn ** 1.6, 0.0, 0.0))

# ---------- keyframe the loop: breath at 1x, sway at 2x, phase-shifted ----------
FPS, FRAMES = 24, 72
scene.render.fps = FPS
scene.frame_start, scene.frame_end = 1, FRAMES
kb = me.shape_keys.key_blocks
for f in range(1, FRAMES + 2, 3):
    t = (f - 1) / FRAMES
    w = math.sin(2 * math.pi * t)
    kb["squash"].value = max(0.0, w) * 0.55
    kb["stretch"].value = max(0.0, -w) * 0.40
    kb["sway"].value = 0.5 + 0.5 * math.sin(2 * math.pi * 2 * t + math.pi / 3)
    for name in ("squash", "stretch", "sway"):
        kb[name].keyframe_insert("value", frame=f)
me.shape_keys.animation_data.action.name = "idle-loop"

# ---------- habitat materials (canon PO 2026-07-17) ----------
HABITATS = {
    "green": (0.10, 0.52, 0.16),   # prairie / grass
    "blue": (0.08, 0.34, 0.60),    # near water
    "brown": (0.34, 0.20, 0.11),   # earth / rock
}


def gel_material(name, rgb):
    m = bpy.data.materials.new(f"slime_{name}")
    m.use_nodes = True
    n = m.node_tree.nodes["Principled BSDF"]
    for inp, val in [("Base Color", (*rgb, 1.0)), ("Roughness", 0.28),
                     ("Transmission Weight", 0.25), ("IOR", 1.33),
                     ("Subsurface Weight", 0.6),
                     ("Subsurface Radius", (0.08, 0.25, 0.08))]:
        s = n.inputs.get(inp)
        if s is not None:
            s.default_value = val
    return m


mats = {k: gel_material(k, rgb) for k, rgb in HABITATS.items()}
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


add_light("key", (-1.6, -1.0, 1.2), 260, 1.6)
add_light("fill", (1.4, -0.9, 0.4), 55, 1.5)
add_light("rim", (0.3, 1.6, 1.0), 260, 1.5)

target = bpy.data.objects.new("target", None)
target.location = (0, 0, 0.02)
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

# ---------- renders: animation frames (green) + one still per habitat ----------
scene.render.resolution_x = 512
scene.render.resolution_y = 640
for f in range(1, FRAMES + 1, 3):
    scene.frame_set(f)
    scene.render.filepath = os.path.join(ANIM_DIR, f"idle_{f:03d}.png")
    bpy.ops.render.render(write_still=True)
print("[slime] anim frames done")

scene.frame_set(1)
scene.render.resolution_x = 1024
scene.render.resolution_y = 1280
for name, mat in mats.items():
    body.data.materials[0] = mat
    scene.render.filepath = os.path.join(REN_DIR, f"slime_{name}.png")
    bpy.ops.render.render(write_still=True)
    print("[slime] still", name)

# ---------- save + export (green, with idle-loop animation) ----------
body.data.materials[0] = mats["green"]
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "slime_wip.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "slime.glb"),
    use_selection=False,
    export_animations=True,
    export_morph=True,
)
print("[slime] DONE")
