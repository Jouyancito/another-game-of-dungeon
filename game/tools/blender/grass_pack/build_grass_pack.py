# build_grass_pack.py — ground-detail GRASS pack, floor-1 prairie biome.
# 6 clump variants (lawn / wispy-seedhead / broad / sparse-dry / windswept / wildflower-mix),
# built as cheap flat tapered-blade strips (no solidify — double-sided material instead,
# per task scope: "a handful of curved/tapered planes... is enough, keep CHEAP").
# Painterly material language (ref foliage_painterly/_synthesis.md): dark-base to
# light-tip vertex-color gradient PER CLUMP (not flat green), max 2-3 hues per variant.
#
# 2026-07-29 — migrated onto the shared motor (motor-blender). The geometry recipes,
# FLOAT_COLOR pipeline, render rig and export contract now live in the motor; this file
# keeps only what is project-specific: the palettes, the variant table, the showcase
# composition and the output naming.
#
# Grass is deliberately the odd one out in the biome family, and each divergence is
# passed EXPLICITLY rather than relying on a motor default:
#   - smooth-shaded  -> finalize_vcol_mesh(flat=False)   (every other pack is flat)
#   - no weld        -> finalize_vcol_mesh(weld_dist=None)  (None SKIPS it; 0.0 does not)
#   - no validate    -> finalize_vcol_mesh(validate=False)
#   - mesh name != object name -> finalize_vcol_mesh(mesh_name=...)
#   - SUN lights, not AREA     -> showcase_ficha.sun_light
#   - subsurface in the material, and show_transparent_back=False
#   - export omits the animations/cameras/lights flags entirely (None == omit), so
#     export_animations keeps the exporter's own default
#   - SEED is a module constant with no --seed CLI flag
#
# Run: blender --background --python build_grass_pack.py
import bpy
import bmesh
import math
import os
import random
import sys
from mathutils import Vector

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = SCRIPT_DIR
REN_DIR = os.path.join(OUT_DIR, "renders")
os.makedirs(REN_DIR, exist_ok=True)

SEED = 20260720

# _motor must be imported before any biome_* / lookdev module: it is what puts the
# motor's flat module directories on sys.path.
sys.path.insert(0, os.path.dirname(SCRIPT_DIR))
import _motor  # noqa: E402,F401
import biome_mass  # noqa: E402
import biome_stem  # noqa: E402
import biome_vcol  # noqa: E402
import glb_export  # noqa: E402
import showcase_ficha as rig  # noqa: E402
import _ficha_common as ficha  # noqa: E402

print(f"[grass_pack] motor rev {_motor.rev()} @ {_motor.ROOT}")

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


# ---------- clump assembly (data-driven per variant) ----------
def build_clump(spec, seed):
    rng = random.Random(seed)
    bm = bmesh.new()
    vcol = {}
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
        cb = biome_vcol.jitter3(spec["color_base"], rng, 0.035)
        ct = biome_vcol.jitter3(spec["color_tip"], rng, 0.035)
        tip = biome_stem.add_blade_strip(bm, vcol, (bx, by), height, width_base, width_tip,
                                         blade_az, bend_amount, bend_az, cb, ct)
        tips.append((tip, height))

    if spec.get("seed_head"):
        frac = spec.get("seed_head_frac", 0.5)
        count = max(1, round(n * frac))
        for idx in rng.sample(range(n), min(count, n)):
            tip, h = tips[idx]
            r = rng.uniform(0.007, 0.010)
            depth = rng.uniform(0.045, 0.065)
            col = biome_vcol.jitter3(spec["seed_head_color"], rng, 0.04)
            biome_stem.add_seed_spike(bm, vcol, tip, r, depth, col)

    if spec.get("flower_bud"):
        count = spec.get("flower_count", 2)
        for idx in rng.sample(range(n), min(count, n)):
            tip, h = tips[idx]
            r = rng.uniform(0.018, 0.024)
            col = biome_vcol.jitter3(spec["flower_color"], rng, 0.03)
            biome_mass.add_accent_blob(bm, vcol, tip + Vector((0, 0, r * 0.8)), r, col,
                                       squash_z=1.05)
            hl = tuple(min(1.0, c + 0.18) for c in col)
            biome_mass.add_accent_blob(bm, vcol, tip + Vector((0, 0, r * 1.7)), r * 0.4, hl,
                                       squash_z=1.0)

    # flat=False: smooth-shaded curve reads like a brush stroke, not hard facets.
    # weld_dist=None / validate=False: grass has no coincident-vert seams to weld and
    # no degenerate faces to strip; both would alter the mesh if switched on.
    return biome_vcol.finalize_vcol_mesh(
        f"grass_{spec['key']}", bm, vcol,
        scene=scene,
        mesh_name=f"grass_{spec['key']}_mesh",
        weld_dist=None,
        flat=False,
        validate=False,
    )


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
# Grass is the only pack using subsurface: the blades are single-sided planes and a
# little translucency is what stops them reading as flat paper from the back.
mat_grass = biome_vcol.vcol_material(
    "mat_grass_pack",
    roughness=0.72,
    specular=0.2,
    double_sided=True,                      # -> use_backface_culling = False
    subsurface=(0.15, (0.03, 0.05, 0.02)),
    show_transparent_back=False,
)
for obj in clump_objs:
    obj.data.materials.append(mat_grass)


# ---------- showcase layout ----------
SPACING = 0.50
CENTER_X = (len(clump_objs) - 1) * SPACING / 2.0
for i, obj in enumerate(clump_objs):
    obj.location = (i * SPACING, 0.0, 0.0)

# align_y='TOP' at z<0: grass's ficha has NO ground plane, so labels hanging below
# the clumps are not occluded the way flower_pack's were.
labels = rig.add_labels(
    scene,
    [(spec["key"], spec["label"], i * SPACING) for i, spec in enumerate(VARIANTS)],
    size=0.045, y=0.03, z=-0.05, extrude=0.0015, rot_x=68,
    align_x='CENTER', align_y='TOP',
    color=(0.92, 0.92, 0.88), roughness=0.55,
)

# ---------- lighting + world (matches render_preview.py: warm key + cool fill, dark bg) ----------
key = rig.sun_light(scene, "key", 3.2, (1.0, 0.86, 0.62),
                    (math.radians(55), 0, math.radians(35)))
fill = rig.sun_light(scene, "fill", 1.1, (0.52, 0.64, 0.86),
                     (math.radians(60), 0, math.radians(-130)))

world = bpy.data.worlds.new("w")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.06, 0.07, 1.0)

# ---------- camera: reuse the pipeline's tested reframe helper ----------
cam, target = rig.track_camera(
    scene, "cam",
    loc=(CENTER_X - 0.5, -1.4, 0.62),
    target_loc=(CENTER_X, 0.0, 0.15),
    lens=50,
)

max_height = max(spec["height"][1] + 0.05 for spec in VARIANTS)  # + accent headroom
ficha.frame_hero_camera(
    cam, target,
    x_min=-0.12, x_max=CENTER_X * 2 + 0.12,
    y_min=-0.09, y_max=0.09,
    z_min=-0.10, z_max=max_height,
    margin=1.12,
)

rig.eevee_standard(scene, samples=64, raytracing=True, resolution=(2048, 900))

scene.render.filepath = os.path.join(REN_DIR, "grass_showcase.png")
bpy.ops.render.render(write_still=True)
print("[grass_pack] showcase rendered")

# ---------- cleanup ficha-only props + reset transforms before export ----------
rig.remove_labels(labels)
glb_export.reset_transforms(clump_objs)  # drop-in ready: local origin, no showcase offset

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "grass_pack_wip.blend"))

# combined pack: all variants as separate named objects, one file.
# animations/cameras/lights are passed as None => the kwargs are OMITTED, so
# export_animations keeps the exporter's default. Do not "tidy" these to False:
# that changes the exported bytes.
glb_export.export_glb(
    os.path.join(OUT_DIR, "grass_pack.glb"), clump_objs,
    animations=None, cameras=None, lights=None,
)
print("[grass_pack] combined GLB exported")

# per-variant GLBs, named to match the vegetation folder's env_<cat>_<name>_01 convention
glb_export.export_variants(
    OUT_DIR, clump_objs,
    lambda o: f"env_grass_{o['variant_key']}_01.glb",
    animations=None, cameras=None, lights=None,
)
print("[grass_pack] per-variant GLBs exported")
print("[grass_pack] DONE")
