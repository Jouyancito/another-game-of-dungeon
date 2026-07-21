# build_grass_pack.py — ground-detail GRASS pack, floor-1 prairie biome.
# 6 clump variants (lawn / wispy-seedhead / broad / sparse-dry / windswept / wildflower-mix),
# built as cheap flat tapered-blade strips (no solidify — double-sided material instead,
# per task scope: "a handful of curved/tapered planes... is enough, keep CHEAP").
# Painterly material language (ref foliage_painterly/_synthesis.md): dark-base to
# light-tip vertex-color gradient PER CLUMP (not flat green), max 2-3 hues per variant.
# Mirrors slime/build_slime.py's scene/material/export pattern (Standard view transform,
# NLA-free here since grass is static — no animation needed).
# Run: blender --background --python build_grass_pack.py
import bpy
import bmesh
import math
import os
import random
import sys
from mathutils import Vector, Matrix

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
os.makedirs(REN_DIR, exist_ok=True)

SEED = 20260720

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


# ---------- color helpers ----------
def lerp(a, b, t):
    return a + (b - a) * t


def lerp_color(c1, c2, t):
    return (lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t), 1.0)


def jitter_color(c, rng, amt):
    return tuple(max(0.0, min(1.0, ch + rng.uniform(-amt, amt))) for ch in c)


# ---------- blade builder: flat tapered/curved strip, vertex-color gradient ----------
def add_blade(bm, color_layer, base_xy, height, width_base, width_tip, azimuth_deg,
              bend_amount, bend_azimuth_deg, color_base, color_tip,
              segments=4, curve_power=2.2, taper_power=1.3):
    """Builds ONE blade as a chain of `segments` quads growing along +Z, tapering
    width_base -> width_tip, bending laterally toward bend_azimuth_deg with an
    accelerating curve (curve_power) so it reads like a real blade arc, not a
    straight ramp. Colors each loop by height fraction (dark base -> light tip).
    Returns the tip-center Vector (for accent placement)."""
    az = math.radians(azimuth_deg)
    width_dir = Vector((math.cos(az), math.sin(az), 0.0))
    bend_rad = math.radians(bend_azimuth_deg)
    bend_dir = Vector((math.cos(bend_rad), math.sin(bend_rad), 0.0))
    bx, by = base_xy
    rows = []
    for i in range(segments + 1):
        u = i / segments
        z = height * u
        half_w = 0.5 * lerp(width_base, width_tip, u ** taper_power)
        bend = bend_amount * (u ** curve_power)
        cx = bx + bend_dir.x * bend
        cy = by + bend_dir.y * bend
        left = bm.verts.new((cx - width_dir.x * half_w, cy - width_dir.y * half_w, z))
        right = bm.verts.new((cx + width_dir.x * half_w, cy + width_dir.y * half_w, z))
        rows.append((left, right))
    for i in range(segments):
        a, b = rows[i]
        c, d = rows[i + 1]
        f = bm.faces.new((a, c, d, b))
        for loop in f.loops:
            u = max(0.0, min(1.0, loop.vert.co.z / height)) if height > 1e-6 else 0.0
            loop[color_layer] = lerp_color(color_base, color_tip, u)
    tip_left, tip_right = rows[-1]
    return (tip_left.co + tip_right.co) * 0.5


def add_accent_blob(bm, color_layer, pos, radius, color, squash_z=1.6):
    """Tiny icosphere (flower bud) — subdivisions=1 keeps it ~20 tris."""
    res = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=radius,
                                      matrix=Matrix.Translation(pos))
    new_verts = res["verts"]
    for v in new_verts:
        v.co.z = pos.z + (v.co.z - pos.z) * squash_z
    faces = set()
    for v in new_verts:
        for f in v.link_faces:
            faces.add(f)
    for f in faces:
        for loop in f.loops:
            loop[color_layer] = (color[0], color[1], color[2], 1.0)


def add_seed_spike(bm, color_layer, base_pos, radius, depth, color):
    """Slim tapered cone (grass/sedge seed panicle) — reads as a plume, not a
    round berry. ~8 tris (segments=6, capped)."""
    center = Vector((base_pos.x, base_pos.y, base_pos.z + depth * 0.5))
    res = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=True, segments=6,
                                 radius1=radius, radius2=radius * 0.12, depth=depth,
                                 matrix=Matrix.Translation(center))
    new_verts = res["verts"]
    faces = set()
    for v in new_verts:
        for f in v.link_faces:
            faces.add(f)
    for f in faces:
        for loop in f.loops:
            loop[color_layer] = (color[0], color[1], color[2], 1.0)


# ---------- clump assembly (data-driven per variant) ----------
def build_clump(spec, seed):
    rng = random.Random(seed)
    bm = bmesh.new()
    color_layer = bm.loops.layers.float_color.new("Col")
    n = spec["blade_count"]
    az_center = spec.get("azimuth_center")
    az_spread = spec.get("azimuth_spread", 360)
    bend_az_center = spec.get("bend_azimuth_center", 0.0)
    bend_az_spread = spec.get("bend_azimuth_spread", 360)
    radius = spec["radius"]
    tips = []
    for i in range(n):
        r = radius * math.sqrt(rng.uniform(0.0, 1.0))
        theta = rng.uniform(0.0, 2 * math.pi)
        bx, by = r * math.cos(theta), r * math.sin(theta)
        height = rng.uniform(*spec["height"])
        width_base = rng.uniform(*spec["width_base"])
        width_tip = width_base * rng.uniform(*spec["width_tip_frac"])
        bend_amount = rng.uniform(*spec["bend_amount"])
        blade_az = rng.uniform(0.0, 360.0) if az_center is None \
            else az_center + rng.uniform(-az_spread, az_spread)
        bend_az = bend_az_center + rng.uniform(-bend_az_spread, bend_az_spread)
        cb = jitter_color(spec["color_base"], rng, 0.035)
        ct = jitter_color(spec["color_tip"], rng, 0.035)
        tip = add_blade(bm, color_layer, (bx, by), height, width_base, width_tip,
                         blade_az, bend_amount, bend_az, cb, ct)
        tips.append((tip, height))

    if spec.get("seed_head"):
        frac = spec.get("seed_head_frac", 0.5)
        count = max(1, round(n * frac))
        for idx in rng.sample(range(n), min(count, n)):
            tip, h = tips[idx]
            r = rng.uniform(0.007, 0.010)
            depth = rng.uniform(0.045, 0.065)
            col = jitter_color(spec["seed_head_color"], rng, 0.04)
            add_seed_spike(bm, color_layer, tip, r, depth, col)

    if spec.get("flower_bud"):
        count = spec.get("flower_count", 2)
        for idx in rng.sample(range(n), min(count, n)):
            tip, h = tips[idx]
            r = rng.uniform(0.018, 0.024)
            col = jitter_color(spec["flower_color"], rng, 0.03)
            add_accent_blob(bm, color_layer, tip + Vector((0, 0, r * 0.8)), r, col, squash_z=1.05)
            hl = tuple(min(1.0, c + 0.18) for c in col)
            add_accent_blob(bm, color_layer, tip + Vector((0, 0, r * 1.7)), r * 0.4, hl, squash_z=1.0)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(f"grass_{spec['key']}_mesh")
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True  # smooth-shaded curve reads like a brush stroke, not hard facets
    obj = bpy.data.objects.new(f"grass_{spec['key']}", me)
    scene.collection.objects.link(obj)
    return obj


# ---------- variant table ----------
VARIANTS = [
    dict(key="lawn_dense", label="Lawn Dense", blade_count=16,
         height=(0.10, 0.16), width_base=(0.012, 0.018), width_tip_frac=(0.15, 0.30),
         radius=0.055, bend_amount=(0.010, 0.028),
         color_base=(0.035, 0.13, 0.045), color_tip=(0.30, 0.54, 0.16)),

    dict(key="wispy_seedhead", label="Wispy Seedhead", blade_count=8,
         height=(0.32, 0.46), width_base=(0.006, 0.009), width_tip_frac=(0.10, 0.20),
         radius=0.05, bend_amount=(0.05, 0.09),
         color_base=(0.03, 0.11, 0.04), color_tip=(0.44, 0.60, 0.20),
         seed_head=True, seed_head_frac=0.6, seed_head_color=(0.74, 0.62, 0.28)),

    dict(key="broad_clump", label="Broad Clump", blade_count=13,
         height=(0.20, 0.24), width_base=(0.030, 0.042), width_tip_frac=(0.25, 0.40),
         radius=0.042, bend_amount=(0.012, 0.030),
         color_base=(0.04, 0.15, 0.05), color_tip=(0.30, 0.55, 0.18)),

    dict(key="sparse_dry", label="Sparse Dry", blade_count=4,
         height=(0.26, 0.36), width_base=(0.006, 0.009), width_tip_frac=(0.30, 0.40),
         radius=0.07, bend_amount=(0.015, 0.030),
         color_base=(0.16, 0.17, 0.06), color_tip=(0.58, 0.52, 0.22)),

    dict(key="windswept", label="Windswept", blade_count=10,
         height=(0.18, 0.26), width_base=(0.012, 0.017), width_tip_frac=(0.15, 0.25),
         radius=0.055, bend_amount=(0.09, 0.15),
         azimuth_center=90, azimuth_spread=55,
         bend_azimuth_center=25, bend_azimuth_spread=12,
         color_base=(0.035, 0.13, 0.05), color_tip=(0.32, 0.55, 0.16)),

    dict(key="wildflower_mix", label="Wildflower Mix", blade_count=9,
         height=(0.14, 0.20), width_base=(0.011, 0.016), width_tip_frac=(0.15, 0.28),
         radius=0.055, bend_amount=(0.015, 0.035),
         color_base=(0.035, 0.13, 0.045), color_tip=(0.30, 0.53, 0.16),
         flower_bud=True, flower_count=2, flower_color=(0.92, 0.78, 0.18)),
]

clump_objs = []
for i, spec in enumerate(VARIANTS):
    obj = build_clump(spec, SEED + i)
    obj["variant_key"] = spec["key"]
    clump_objs.append(obj)


# ---------- shared painterly material: vertex color drives base color ----------
def build_material():
    m = bpy.data.materials.new("mat_grass_pack")
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    nt.links.new(attr.outputs["Color"], n.inputs["Base Color"])
    n.inputs["Roughness"].default_value = 0.72
    sw = n.inputs.get("Subsurface Weight")
    if sw is not None:
        sw.default_value = 0.15
        n.inputs["Subsurface Radius"].default_value = (0.03, 0.05, 0.02)
    spec = n.inputs.get("Specular IOR Level")
    if spec is not None:
        spec.default_value = 0.2
    m.use_backface_culling = False  # flat single-sided planes: must read from both sides
    if hasattr(m, "show_transparent_back"):
        m.show_transparent_back = False
    return m


mat_grass = build_material()
for obj in clump_objs:
    obj.data.materials.append(mat_grass)


# ---------- showcase layout ----------
SPACING = 0.50
CENTER_X = (len(clump_objs) - 1) * SPACING / 2.0
for i, obj in enumerate(clump_objs):
    obj.location = (i * SPACING, 0.0, 0.0)


def add_label(spec, x):
    curve = bpy.data.curves.new(f"label_{spec['key']}", type='FONT')
    curve.body = spec["label"]
    curve.size = 0.045
    curve.align_x = 'CENTER'
    curve.align_y = 'TOP'
    curve.extrude = 0.0015
    obj = bpy.data.objects.new(f"label_{spec['key']}", curve)
    obj.location = (x, 0.03, -0.05)
    obj.rotation_euler = (math.radians(68), 0.0, 0.0)
    scene.collection.objects.link(obj)
    mat = bpy.data.materials.new(f"mat_label_{spec['key']}")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.92, 0.92, 0.88, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.55
    curve.materials.append(mat)
    return obj


labels = [add_label(spec, i * SPACING) for i, spec in enumerate(VARIANTS)]

# ---------- lighting + world (matches render_preview.py: warm key + cool fill, dark bg) ----------
key_d = bpy.data.lights.new("key", "SUN")
key_d.energy = 3.2
key_d.color = (1.0, 0.86, 0.62)
key = bpy.data.objects.new("key", key_d)
scene.collection.objects.link(key)
key.rotation_euler = (math.radians(55), 0, math.radians(35))

fill_d = bpy.data.lights.new("fill", "SUN")
fill_d.energy = 1.1
fill_d.color = (0.52, 0.64, 0.86)
fill = bpy.data.objects.new("fill", fill_d)
scene.collection.objects.link(fill)
fill.rotation_euler = (math.radians(60), 0, math.radians(-130))

world = bpy.data.worlds.new("w")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.06, 0.07, 1.0)

# ---------- camera: reuse the pipeline's tested reframe helper ----------
sys.path.insert(0, os.path.dirname(OUT_DIR))
import _ficha_common as ficha  # noqa: E402

cam_data = bpy.data.cameras.new("cam")
cam_data.lens = 50
cam = bpy.data.objects.new("cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
target = bpy.data.objects.new("target", None)
scene.collection.objects.link(target)
cam.constraints.new(type='TRACK_TO').target = target

target.location = (CENTER_X, 0.0, 0.15)
cam.location = (CENTER_X - 0.5, -1.4, 0.62)

max_height = max(spec["height"][1] + 0.05 for spec in VARIANTS)  # + accent headroom
ficha.frame_hero_camera(
    cam, target,
    x_min=-0.12, x_max=CENTER_X * 2 + 0.12,
    y_min=-0.09, y_max=0.09,
    z_min=-0.10, z_max=max_height,
    margin=1.12,
)

try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.eevee.taa_render_samples = 64
scene.view_settings.view_transform = 'Standard'

scene.render.resolution_x = 2048
scene.render.resolution_y = 900
scene.render.filepath = os.path.join(REN_DIR, "grass_showcase.png")
bpy.ops.render.render(write_still=True)
print("[grass_pack] showcase rendered")

# ---------- cleanup ficha-only props + reset transforms before export ----------
for lbl in labels:
    me = lbl.data
    bpy.data.objects.remove(lbl, do_unlink=True)
    bpy.data.curves.remove(me)

for obj in clump_objs:
    obj.location = (0.0, 0.0, 0.0)  # drop-in ready: local origin, no baked showcase offset

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "grass_pack_wip.blend"))

# combined pack: all variants as separate named objects, one file
bpy.ops.object.select_all(action='DESELECT')
for obj in clump_objs:
    obj.select_set(True)
bpy.context.view_layer.objects.active = clump_objs[0]
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "grass_pack.glb"),
    use_selection=True,
    export_format='GLB',
    export_yup=True,
    export_apply=True,
)
print("[grass_pack] combined GLB exported")

# per-variant GLBs, named to match the vegetation folder's env_<cat>_<name>_01 convention
for obj in clump_objs:
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    fname = f"env_grass_{obj['variant_key']}_01.glb"
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUT_DIR, fname),
        use_selection=True,
        export_format='GLB',
        export_yup=True,
        export_apply=True,
    )
print("[grass_pack] per-variant GLBs exported")
print("[grass_pack] DONE")
