# build_slime_tensura.py — slime whose face is RELIEF in the gel itself (Tensura rule).
# Joan's verdict on the toothy version (2026-07-18): features must SUGGEST a face —
# eye-socket hollows, a hint of mouth — sculpted into the surface. No teeth, no
# separate plates, one homogeneous material.
# Refs: slime_tensura/_synthesis.md (gap doc with Joan's criteria), PO slime canon 2026-07-17.
# Run: blender -b --python build_slime_tensura.py
import bpy
import math
import os
from mathutils import Vector

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
os.makedirs(REN_DIR, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# ---------- body: gelatinous dome (denser sphere: relief needs vertices) ----------
bpy.ops.mesh.primitive_uv_sphere_add(segments=96, ring_count=48, radius=0.5)
body = bpy.context.object
body.name = "slime_body"
me = body.data
for v in me.vertices:
    z = v.co.z
    v.co.z = z * (0.78 if z > 0.0 else 0.55)
    t = max(0.0, min(1.0, (0.08 - v.co.z) / 0.35))
    s = 1.0 + 0.20 * t
    v.co.x *= s
    v.co.y *= s

# ---------- face as relief: radial indentations with smooth falloff ----------
def indent_sphere(center, radius, depth):
    """Push vertices near `center` inward (toward body origin) with smooth falloff."""
    c = Vector(center)
    for v in me.vertices:
        d = (v.co - c).length
        if d < radius:
            t = (1.0 - (d / radius) ** 2) ** 2
            v.co -= v.co.normalized() * depth * t


def surface_point(direction):
    """Closest vertex to a given direction — anchors features on the deformed surface."""
    dnorm = Vector(direction).normalized()
    best = max(me.vertices, key=lambda v: v.co.normalized().dot(dnorm))
    return best.co.copy()


# eye sockets: soft hollows, slightly slanted apart (front = -Y)
eye_L = surface_point((-0.32, -1.0, 0.30))
eye_R = surface_point((0.32, -1.0, 0.30))
indent_sphere(eye_L, 0.10, 0.05)
indent_sphere(eye_R, 0.10, 0.05)

# mouth: continuous shallow groove — indent by distance to a dense smile polyline
arc = []
for i in range(61):
    u = i / 60.0
    ang = math.radians(-32 + 64 * u)
    smile_z = -0.10 + 0.05 * (2 * u - 1) ** 2
    arc.append(surface_point((math.sin(ang), -math.cos(ang), smile_z)))
GROOVE_R, GROOVE_D = 0.045, 0.018
for v in me.vertices:
    if v.co.y > 0.0:            # face side only
        continue
    d = min((v.co - p).length for p in arc)
    if d < GROOVE_R:
        t = (1.0 - (d / GROOVE_R) ** 2) ** 2
        v.co -= v.co.normalized() * GROOVE_D * t

for p in me.polygons:
    p.use_smooth = True
sub = body.modifiers.new("subsurf", type='SUBSURF')
sub.levels = 2
sub.render_levels = 2

# ---------- single homogeneous gel material ----------
m_body = bpy.data.materials.new("slime_gel")
m_body.use_nodes = True
n = m_body.node_tree.nodes["Principled BSDF"]


def set_in(node, name, value):
    s = node.inputs.get(name)
    if s is not None:
        s.default_value = value


set_in(n, "Base Color", (0.10, 0.52, 0.16, 1.0))
set_in(n, "Roughness", 0.28)
set_in(n, "Transmission Weight", 0.25)
set_in(n, "IOR", 1.33)
set_in(n, "Subsurface Weight", 0.6)
set_in(n, "Subsurface Radius", (0.08, 0.25, 0.08))
body.data.materials.append(m_body)

# ---------- showcase-ficha scene ----------
world = bpy.data.worlds.new("ficha")
scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes["Background"]
bg.inputs["Color"].default_value = (0.30, 0.22, 0.48, 1.0)


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


# key raked from the side so the hollows shadow and read
add_light("key", (-1.6, -1.0, 1.2), 260, 1.6)
add_light("fill", (1.4, -0.9, 0.4), 55, 1.5)
add_light("rim", (0.3, 1.6, 1.0), 260, 1.5)

target = bpy.data.objects.new("target", None)
target.location = (0, 0, 0.02)
bpy.context.collection.objects.link(target)


def add_cam(name, loc):
    cd = bpy.data.cameras.new(name)
    cd.lens = 50
    co = bpy.data.objects.new(name, cd)
    co.location = loc
    bpy.context.collection.objects.link(co)
    tr = co.constraints.new(type='TRACK_TO')
    tr.target = target
    return co


cam_hero = add_cam("cam_hero", (-1.1, -2.2, 0.85))
cam_front = add_cam("cam_front", (0.0, -2.5, 0.45))

try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.eevee.taa_render_samples = 128
scene.view_settings.view_transform = 'Standard'
scene.render.resolution_x = 1024
scene.render.resolution_y = 1280

for cam, tag in [(cam_hero, "hero"), (cam_front, "front")]:
    scene.camera = cam
    scene.render.filepath = os.path.join(REN_DIR, f"slime_tensura_{tag}.png")
    bpy.ops.render.render(write_still=True)
    print("[slime_tensura] rendered", tag)

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "slime_tensura_wip.blend"))
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT_DIR, "slime_tensura.glb"), use_selection=False)
print("[slime_tensura] DONE")
