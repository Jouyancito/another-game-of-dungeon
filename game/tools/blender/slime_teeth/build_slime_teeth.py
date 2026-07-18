# build_slime_teeth.py — slime with a carved jack-o-lantern face (pumpkin-with-teeth ref).
# Motor-blender job: gelatinous prairie slime (canon: Tensura-gel, habitat green) whose
# eyes/mouth are carved openings revealing an inner glow, plus ivory teeth.
# Refs: organic_modeling_style ref_06 (a_iwaac pumpkin breakdown), PO slime canon 2026-07-17.
# Run: blender -b --python build_slime_teeth.py
import bpy
import bmesh
import math
import sys
import os

sys.path.insert(0, r"C:\Users\the_j\motor-blender\recetas")
from bvh_glue import glue_to_surface

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
os.makedirs(REN_DIR, exist_ok=True)

# ---------- clean scene ----------
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# ---------- body: gelatinous dome ----------
bpy.ops.mesh.primitive_uv_sphere_add(segments=64, ring_count=32, radius=0.5)
body = bpy.context.object
body.name = "slime_body"
me = body.data
for v in me.vertices:
    z = v.co.z
    # squash: dome on top, sat-down base
    v.co.z = z * (0.78 if z > 0.0 else 0.55)
    # droop: widen the lower half so the gel reads heavy
    t = max(0.0, min(1.0, (0.08 - v.co.z) / 0.35))
    s = 1.0 + 0.20 * t
    v.co.x *= s
    v.co.y *= s
for p in me.polygons:
    p.use_smooth = True
sub = body.modifiers.new("subsurf", type='SUBSURF')
sub.levels = 2
sub.render_levels = 2

# ---------- inner glow core (the candle inside the pumpkin) ----------
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.20, location=(0, 0, 0.05))
core = bpy.context.object
core.name = "slime_core"
for p in core.data.polygons:
    p.use_smooth = True


def flat_plate(name, verts2d, center, cuts=3):
    """Build a flat plate (local XZ plane, facing -Y) from a 2D outline, subdivided so
    it can conform to the body when glued."""
    mesh = bpy.data.meshes.new(name)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bm = bmesh.new()
    vs = [bm.verts.new((x, 0.0, z)) for x, z in verts2d]
    bm.faces.new(vs)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=cuts, use_grid_fill=True)
    bm.to_mesh(mesh)
    bm.free()
    obj.location = center
    return obj


# face sits on the -Y side of the body
FACE_Y = -0.55

# ---------- angry carved eyes (slanted triangles, outer corner up) ----------
eye_shape_L = [(-0.075, -0.035), (0.075, 0.055), (0.075, -0.035)]
eye_shape_R = [(0.075, -0.035), (-0.075, 0.055), (-0.075, -0.035)]
eye_L = flat_plate("slime_eye_L", eye_shape_L, (-0.17, FACE_Y, 0.14))
eye_R = flat_plate("slime_eye_R", eye_shape_R, (0.17, FACE_Y, 0.14))

# ---------- grin mouth: wide band pre-bent around the body ----------
mouth_mesh = bpy.data.meshes.new("slime_mouth")
mouth = bpy.data.objects.new("slime_mouth", mouth_mesh)
bpy.context.collection.objects.link(mouth)
bm = bmesh.new()
COLS, ROWS = 24, 3
R = 0.52
Z_C, H = -0.04, 0.10
grid = []
for i in range(COLS + 1):
    u = i / COLS                      # 0..1 across the grin
    theta = math.radians(-45 + 90 * u)
    smile = 0.09 * (2 * u - 1) ** 2   # corners curl up
    col = []
    for j in range(ROWS + 1):
        zz = Z_C + smile + H * (j / ROWS - 0.5)
        col.append(bm.verts.new((R * math.sin(theta), -R * math.cos(theta), zz)))
    grid.append(col)
for i in range(COLS):
    for j in range(ROWS):
        bm.faces.new((grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]))
bm.to_mesh(mouth_mesh)
bm.free()

# ---------- ivory teeth: 5 hanging down, 2 pointing up (jagged grin) ----------
teeth = []
TOOTH_W, TOOTH_H = 0.055, 0.07
tooth_spots = [(0.14, -1), (0.32, -1), (0.5, -1), (0.68, -1), (0.86, -1),
               (0.24, +1), (0.72, +1)]
for k, (u, sign) in enumerate(tooth_spots):
    theta = math.radians(-45 + 90 * u)
    smile = 0.09 * (2 * u - 1) ** 2
    z_edge = Z_C + smile + sign * (H * 0.5 - 0.005)
    tm = bpy.data.meshes.new(f"tooth_{k}")
    to = bpy.data.objects.new(f"slime_tooth_{k}", tm)
    bpy.context.collection.objects.link(to)
    bmt = bmesh.new()
    half = math.atan2(TOOTH_W * 0.5, R)
    for dth, dz in [(-half, 0.0), (half, 0.0), (0.0, -sign * TOOTH_H)]:
        th = theta + dth
        bmt.verts.new((R * math.sin(th), -R * math.cos(th), z_edge + dz))
    bmt.faces.new(bmt.verts[:])
    bmesh.ops.subdivide_edges(bmt, edges=bmt.edges[:], cuts=2, use_grid_fill=True)
    bmt.to_mesh(tm)
    bmt.free()
    teeth.append(to)

# ---------- glue face onto the evaluated body surface ----------
for plate, proud in [(eye_L, 0.004), (eye_R, 0.004), (mouth, 0.004)]:
    glue_to_surface(plate, body, proud=proud)
for to in teeth:
    glue_to_surface(to, body, proud=0.008)   # teeth ride ON TOP of the mouth band

# ---------- materials ----------
def new_mat(name):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    return m, m.node_tree.nodes["Principled BSDF"]


def set_in(node, name, value):
    s = node.inputs.get(name)
    if s is not None:
        s.default_value = value


m_body, n = new_mat("slime_body")
set_in(n, "Base Color", (0.10, 0.52, 0.16, 1.0))
set_in(n, "Roughness", 0.15)
set_in(n, "Transmission Weight", 0.25)
set_in(n, "IOR", 1.33)
set_in(n, "Subsurface Weight", 0.6)
set_in(n, "Subsurface Radius", (0.08, 0.25, 0.08))
body.data.materials.append(m_body)

m_core = bpy.data.materials.new("slime_core")
m_core.use_nodes = True
nc = m_core.node_tree
nc.nodes.clear()
em = nc.nodes.new("ShaderNodeEmission")
em.inputs["Color"].default_value = (0.75, 1.0, 0.30, 1.0)
em.inputs["Strength"].default_value = 5.0
out = nc.nodes.new("ShaderNodeOutputMaterial")
nc.links.new(em.outputs["Emission"], out.inputs["Surface"])
core.data.materials.append(m_core)

m_carve = bpy.data.materials.new("slime_carve")   # carved openings: warm glow from inside
m_carve.use_nodes = True
ncv = m_carve.node_tree
ncv.nodes.clear()
em2 = ncv.nodes.new("ShaderNodeEmission")
em2.inputs["Color"].default_value = (1.0, 0.55, 0.08, 1.0)
em2.inputs["Strength"].default_value = 2.2
out2 = ncv.nodes.new("ShaderNodeOutputMaterial")
ncv.links.new(em2.outputs["Emission"], out2.inputs["Surface"])
for plate in (eye_L, eye_R, mouth):
    plate.data.materials.append(m_carve)

m_tooth, nt = new_mat("slime_tooth")
set_in(nt, "Base Color", (0.93, 0.90, 0.80, 1.0))
set_in(nt, "Roughness", 0.35)
for to in teeth:
    to.data.materials.append(m_tooth)

# ---------- showcase-ficha scene (a_iwaac style: flat purple bg) ----------
world = bpy.data.worlds.new("ficha")
scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes["Background"]
bg.inputs["Color"].default_value = (0.30, 0.22, 0.48, 1.0)
bg.inputs["Strength"].default_value = 1.0


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


add_light("key", (-1.2, -1.5, 1.4), 220, 2.0)
add_light("fill", (1.4, -0.9, 0.5), 70, 1.5)
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

# ---------- render (Eevee) ----------
try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.eevee.taa_render_samples = 128
# AgX desaturates strong emission to pastel — the ficha look needs the vivid pop
scene.view_settings.view_transform = 'Standard'
scene.render.resolution_x = 1024
scene.render.resolution_y = 1280
scene.render.film_transparent = False

for cam, tag in [(cam_hero, "hero"), (cam_front, "front")]:
    scene.camera = cam
    scene.render.filepath = os.path.join(REN_DIR, f"slime_teeth_{tag}.png")
    bpy.ops.render.render(write_still=True)
    print("[slime_teeth] rendered", tag)

# ---------- save + export ----------
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "slime_teeth_wip.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "slime_teeth.glb"),
    use_selection=False,
)
print("[slime_teeth] DONE")
