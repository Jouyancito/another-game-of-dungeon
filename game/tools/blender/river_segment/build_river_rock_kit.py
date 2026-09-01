# build_river_rock_kit.py -- loose worn river stones for the RUNTIME stream
# generator (floor1_prairie.gd _scatter_stream_channel_rocks). Option B of the
# 2026-08-31 decision: the v5 segment stays a lookdev bench; the game gets the
# same stone family as a kit the seeded scatter can mix, rotate and scale, so
# no two worlds share a bed.
#
# Each stone = make_worn_block (the v5 fracture-block-worn-selectively recipe,
# unchanged). Differences vs the segment build, both deliberate:
#   - vertex colour carries ONLY self-AO x crack darkening. The segment's
#     sun/shade tint is directional and a rotated instance would wear the sun
#     on the wrong side; moss belongs to in-game placement, not the asset.
#   - every stone is centred at origin with its base at z=0 (the scatter sinks
#     it 0.04-0.14 m itself).
#
# One GLB, COUNT objects named river_rock_worn_01.., one shared material set
# (limestone albedo/normal/rough reloaded from the PNGs the segment build
# already bakes into props/water) so textures ship once, not per stone.
#
#   blender.exe --background --factory-startup --python-exit-code 1 \
#       --python game/tools/blender/river_segment/build_river_rock_kit.py -- [--count 6]
#   python game/tools/blender/river_segment/compose_sheets.py kit
import math
import os
import random
import sys

import bmesh
import bpy
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
GAME = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
RECETAS = os.path.join(os.path.expanduser("~"), "motor-blender", "recetas")
for p in (RECETAS, TOOLS, HERE, os.path.join(TOOLS, "golem_guardian")):
    if p not in sys.path:
        sys.path.insert(0, p)

from worn_block import make_worn_block, textured_material  # noqa: E402
from biome_ao import bake_vertex_ao  # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
COUNT = 6
SEED = 7
WEAR = 0.50          # w2 -- Joan's standing read until he picks on the page
CRACK_DARK = 0.55    # d2 -- same
NO_RENDER = False
i = 0
while i < len(argv):
    if argv[i] == "--count":
        COUNT = int(argv[i + 1]); i += 2
    elif argv[i] == "--seed":
        SEED = int(argv[i + 1]); i += 2
    elif argv[i] == "--wear":
        WEAR = float(argv[i + 1]); i += 2
    elif argv[i] == "--crackdark":
        CRACK_DARK = float(argv[i + 1]); i += 2
    elif argv[i] == "--no-render":
        NO_RENDER = True; i += 1
    else:
        i += 1

OUT_GLB_DIR = os.path.join(GAME, "assets", "art", "piso1_pradera", "props", "water")
RENDER_DIR = os.path.join(HERE, "renders")
os.makedirs(RENDER_DIR, exist_ok=True)
# denser than the segment's 2.0: a 0.5 m stone samples a bigger slice of the
# pattern, otherwise the pale low-contrast limestone reads as flat white
LIME_PERIOD = 1.2
TRI_BUDGET_PER_ROCK = 2500

# --factory-startup default scene: drop the Cube, keep nothing implicit
for ob in list(bpy.data.objects):
    bpy.data.objects.remove(ob, do_unlink=True)
scene = bpy.context.scene

# ------------------------------------------------- shared material (from PNGs)
def load_img(name, srgb):
    path = os.path.join(OUT_GLB_DIR, name + ".png")
    if not os.path.exists(path):
        raise SystemExit(f"[kit] FAIL: missing texture {path} -- run build_river_segment.py first")
    im = bpy.data.images.load(path)
    im.colorspace_settings.name = "sRGB" if srgb else "Non-Color"
    return im

img_lime = load_img("river_limestone_albedo", True)
img_lime_n = load_img("river_limestone_normal", False)
img_rough = load_img("river_limestone_rough", False)
MAT = textured_material("river_limestone_dry", img_lime, img_lime_n, 0.80, rough_img=img_rough)

# --------------------------------------------------------------- build stones
rng = random.Random(SEED)
objects = []
for k in range(COUNT):
    rng_k = random.Random(SEED * 1000 + k)
    radius = rng_k.uniform(0.36, 0.58)
    wear = max(0.05, min(0.95, WEAR + rng_k.uniform(-0.08, 0.08)))
    # coarser subdivision + fewer smoothing passes than the segment walls: a
    # small stone has few verts, so the wall recipe rounds it into an egg --
    # the flats have to survive (first kit run: 6/6 domes, gate failed)
    tb = make_worn_block(radius, wear, rng_k, cuts=7,
                         bedding=rng_k.choice([1, 2]),
                         elongate=rng_k.uniform(1.15, 1.45),
                         flatten=rng_k.uniform(0.80, 1.00),
                         subth=0.22, passes=3, jitter=0.11)
    lay_ck = tb.verts.layers.int.get("crackdark")

    # rest pose: base at z=0, centred in xy
    xs = [v.co.x for v in tb.verts]; ys = [v.co.y for v in tb.verts]
    zmin = min(v.co.z for v in tb.verts)
    cx = (min(xs) + max(xs)) / 2; cy = (min(ys) + max(ys)) / 2
    for v in tb.verts:
        v.co.x -= cx; v.co.y -= cy; v.co.z -= zmin

    # vertex colour: grey stone base (the raw limestone albedo averages ~0.72
    # and reads near-white under game lighting -- Joan's 2026-08-31 in-game
    # screenshot), self-AO, crack sediment -- NO directional tint
    tone = rng_k.uniform(0.72, 0.88)
    base = (tone, tone * 0.985, tone * 0.955)
    vcol = {v: base for v in tb.verts}
    bake_vertex_ao(tb, vcol, samples=16, max_dist=0.6, strength=0.7, min_factor=0.35)
    ring_f = CRACK_DARK ** 0.5
    n_seam = 0
    for v in tb.verts:
        mark = v[lay_ck]
        if mark == 2:
            vcol[v] = tuple(c * CRACK_DARK for c in vcol[v]); n_seam += 1
        elif mark == 1:
            vcol[v] = tuple(c * ring_f for c in vcol[v])
    if n_seam == 0:
        raise SystemExit(f"[kit] FAIL: rock {k + 1} has no crack seam verts")

    # box-projected UVs per face (same recipe as the segment walls)
    from mathutils import Vector
    uv_layer = tb.loops.layers.uv.new("UVMap")
    for f in tb.faces:
        n = f.normal.copy()
        if n.length < 1e-6:
            n = Vector((0, 0, 1))
        ax = Vector((0, 0, 1)).cross(n)
        if ax.length < 1e-4:
            ax = Vector((1, 0, 0))
        ax.normalize()
        ay = n.cross(ax).normalized()
        for loop in f.loops:
            co = loop.vert.co
            loop[uv_layer].uv = (co.dot(ax) / LIME_PERIOD, co.dot(ay) / LIME_PERIOD)

    col_layer = tb.loops.layers.float_color.new("Col")
    for f in tb.faces:
        for loop in f.loops:
            c = vcol.get(loop.vert, (1.0, 1.0, 1.0))
            loop[col_layer] = (c[0], c[1], c[2], 1.0)

    bmesh.ops.triangulate(tb, faces=tb.faces[:])
    name = f"river_rock_worn_{k + 1:02d}"
    me = bpy.data.meshes.new(name)
    tb.to_mesh(me)
    tb.free()
    me.validate(verbose=False)
    me.materials.append(MAT)
    tris = len(me.polygons)
    dims = [max(xs) - min(xs), max(ys) - min(ys)]
    print(f"[kit] {name}: r={radius:.2f} wear={wear:.2f} across={max(dims):.2f} m "
          f"tris={tris} seam_verts={n_seam}")
    if tris > TRI_BUDGET_PER_ROCK:
        raise SystemExit(f"[kit] FAIL: {name} over budget ({tris} > {TRI_BUDGET_PER_ROCK})")
    ob = bpy.data.objects.new(name, me)
    ob.location.x = k * 1.2   # board layout only; the game uses mesh data, not node transforms
    scene.collection.objects.link(ob)
    objects.append(ob)

total = sum(len(o.data.polygons) for o in objects)
print(f"[kit] {COUNT} stones, {total} tris total")

# ------------------------------------------------------------------- export
glb_path = os.path.join(OUT_GLB_DIR, "river_rock_worn_kit.glb")
bpy.ops.object.select_all(action='DESELECT')
for o in objects:
    o.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
kw = dict(filepath=glb_path, export_format='GLB', use_selection=True,
          export_yup=True, export_apply=True, export_tangents=True,
          export_image_format='AUTO', export_animations=False, export_skins=False)
try:
    bpy.ops.export_scene.gltf(export_vertex_color='ACTIVE', **kw)
except TypeError:
    bpy.ops.export_scene.gltf(**kw)
print(f"[export] {glb_path}  ({os.path.getsize(glb_path) // 1024} KB)")

if NO_RENDER:
    raise SystemExit(0)

# ------------------------------------------------------------------ showcase
# ground plane so AO/shadows read
gm = bpy.data.meshes.new("ground"); gbm = bmesh.new()
bmesh.ops.create_grid(gbm, x_segments=1, y_segments=1, size=14.0)
gbm.to_mesh(gm); gbm.free()
gmat = bpy.data.materials.new("ground_mat"); gmat.use_nodes = True
gmat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.30, 0.32, 0.24, 1.0)
gm.materials.append(gmat)
ob_g = bpy.data.objects.new("ground", gm); scene.collection.objects.link(ob_g)

# 1.8 m player reference post (mandatory on every showcase render)
ref_mesh = bpy.data.meshes.new("player_ref"); ref_bm = bmesh.new()
bmesh.ops.create_cube(ref_bm, size=1.0)
for v in ref_bm.verts:
    v.co.x *= 0.36; v.co.y *= 0.36; v.co.z = v.co.z * 1.8 + 0.9
ref_bm.to_mesh(ref_mesh); ref_bm.free()
ref_mat = bpy.data.materials.new("player_ref_mat"); ref_mat.use_nodes = True
ref_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.85, 0.22, 0.18, 1.0)
ref_mesh.materials.append(ref_mat)
ob_ref = bpy.data.objects.new("player_ref", ref_mesh)
ob_ref.location = (-1.6, 0.0, 0.0)
scene.collection.objects.link(ob_ref)

# raking sun + low ambient: the limestone is pale and low-contrast, and a
# high flat sun washes the normal map -- the first kit run rendered pure white
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", 'SUN'))
sun.data.energy = 3.5
sun.rotation_euler = (math.radians(62), 0.0, math.radians(-35))
scene.collection.objects.link(sun)
scene.world = bpy.data.worlds.new("w")
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.65, 0.75, 1.0)
scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.4

try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x = 1280; scene.render.resolution_y = 800

cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
scene.collection.objects.link(cam)
scene.camera = cam

def shoot(name, loc, target, lens):
    cam.data.lens = lens
    cam.location = loc
    d = (Vector(target) - Vector(loc)).normalized()
    cam.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
    path = os.path.join(RENDER_DIR, f"river_rock_kit_{name}.png")
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print(f"[render] {path}")
    return path

from mathutils import Vector
mid = (COUNT - 1) * 1.2 / 2
shoot("board_34", (mid - 4.5, -5.5, 3.2), (mid, 0.0, 0.35), 32)
shoot("board_front", (mid, -6.5, 0.9), (mid, 0.0, 0.35), 40)
shoot("board_low", (mid + 4.0, -4.0, 0.5), (mid, 0.0, 0.30), 35)
for k in range(COUNT):
    shoot(f"close_{k + 1:02d}", (k * 1.2 + 0.9, -1.1, 0.75), (k * 1.2, 0.0, 0.25), 45)
print("[kit] done")
