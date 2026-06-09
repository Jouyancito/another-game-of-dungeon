"""
gen_crystal.py — Dungeon Party faceted low-poly crystal generator.

Generates two GLB files:
  crystal_dp_single_01.glb   — one shard, <= 500 tris
  crystal_dp_cluster_01.glb  — cluster of 3-5 shards, <= 1500 tris

Style contract (D2-LoD-grounded, warm-cozy biome):
  - Faceted, FLAT-SHADED (hard normals via edge-split / custom normals).
  - Angular quartz prism: 5-7 sided base tapering to a pointed tip.
  - Slightly irregular / asymmetric silhouette.
  - Bottom-weighted (wide base, narrow tip).
  - OPAQUE neutral-gray material slot — Godot applies material_override.
  - Y-up, base at Y=0 (bottom at origin).

Usage:
  blender.exe --background --python gen_crystal.py
  blender.exe --background --python gen_crystal.py -- --seed 42

Export destination: game/assets/art/piso1_pradera/crystals/
(resolved relative to this script's location: ../../assets/art/piso1_pradera/crystals/)
"""

import bpy
import bmesh
import math
import random
import sys
import os

# ---------------------------------------------------------------------------
# Parse optional --seed argument passed after '--' in the blender CLI
# ---------------------------------------------------------------------------
SEED = 1337
argv = sys.argv
if "--" in argv:
    extra = argv[argv.index("--") + 1:]
    for i, arg in enumerate(extra):
        if arg == "--seed" and i + 1 < len(extra):
            SEED = int(extra[i + 1])
        elif arg.startswith("--seed="):
            SEED = int(arg.split("=", 1)[1])

rng = random.Random(SEED)

# ---------------------------------------------------------------------------
# Output directory — sibling of this script: ../../assets/art/piso1_pradera/crystals
# ---------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "..", "assets", "art", "piso1_pradera", "crystals")
)
os.makedirs(OUTPUT_DIR, exist_ok=True)


# ---------------------------------------------------------------------------
# Core crystal builder
# ---------------------------------------------------------------------------
def make_crystal_mesh(
    sides: int,
    height: float,
    base_radius: float,
    tip_radius: float,
    tip_offset_xz: tuple[float, float],
    twist_deg: float,
    base_taper: float,
    chamfer_segments: int = 1,
) -> bpy.types.Object:
    """
    Build one crystal shard as a Blender Object.

    Geometry (Y-up):
      - A prism from Y=0 to Y=height.
      - Bottom cap: polygon with `sides` verts at Y=0, radius=base_radius.
      - Top cap: polygon with `sides` verts at Y=height, radius=tip_radius,
        optionally offset in X/Z for asymmetry.
      - A single pointed apex vert above the top cap (quartz tip).
      - Optionally twisted around Y.
      - All normals FLAT (angle=0 in edge-split → every face is its own island).

    Returns the object (not yet linked to any collection).
    """
    mesh = bpy.data.meshes.new("crystal_mesh")
    bm = bmesh.new()

    angle_step = 2 * math.pi / sides
    # slight per-vert radius jitter for organic feel
    base_jitter  = [rng.uniform(0.82, 1.0) for _ in range(sides)]
    tip_jitter   = [rng.uniform(0.75, 1.0) for _ in range(sides)]

    # --- bottom ring (Y=0)
    bottom_verts = []
    for i in range(sides):
        a = angle_step * i
        r = base_radius * base_jitter[i]
        v = bm.verts.new((r * math.cos(a), 0.0, r * math.sin(a)))
        bottom_verts.append(v)

    # --- upper ring (Y = height * base_taper … height - small step)
    upper_y = height * 0.72  # ring sits at ~72% up — bottom-heavy silhouette
    twist_rad = math.radians(twist_deg)
    upper_verts = []
    ox, oz = tip_offset_xz
    for i in range(sides):
        a = angle_step * i + twist_rad
        r = tip_radius * tip_jitter[i]
        v = bm.verts.new((r * math.cos(a) + ox, upper_y, r * math.sin(a) + oz))
        upper_verts.append(v)

    # --- apex tip
    apex_y = height + rng.uniform(-0.04, 0.04) * height
    tip_x = ox * 0.5 + rng.uniform(-0.05, 0.05) * base_radius
    tip_z = oz * 0.5 + rng.uniform(-0.05, 0.05) * base_radius
    apex = bm.verts.new((tip_x, apex_y, tip_z))

    bm.verts.ensure_lookup_table()

    # --- bottom cap (single face, wound CW seen from below → normal faces -Y)
    bm.faces.new(bottom_verts)

    # --- side quad walls: bottom ring → upper ring
    for i in range(sides):
        ni = (i + 1) % sides
        bm.faces.new([bottom_verts[i], bottom_verts[ni],
                      upper_verts[ni], upper_verts[i]])

    # --- upper facets: upper ring → apex (triangles)
    for i in range(sides):
        ni = (i + 1) % sides
        bm.faces.new([upper_verts[i], upper_verts[ni], apex])

    # Recalculate normals inside bmesh so all faces point outward.
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    bm.to_mesh(mesh)
    bm.free()

    # --- FLAT SHADING: set all polygon smoothing to False
    for poly in mesh.polygons:
        poly.use_smooth = False

    # Validate mesh (removes degenerate geometry, updates normals cache).
    mesh.validate(verbose=False)

    obj = bpy.data.objects.new("crystal", mesh)
    return obj


def add_neutral_material(obj: bpy.types.Object) -> None:
    """Add a single opaque neutral-gray material slot. Godot overrides this."""
    mat = bpy.data.materials.new(name="crystal_neutral")
    # Keep nodes enabled (Blender 5 default) but set a neutral base color.
    mat.diffuse_color = (0.6, 0.65, 0.7, 1.0)  # cool-gray, Godot discards it anyway
    obj.data.materials.append(mat)


def count_tris(obj: bpy.types.Object) -> int:
    """Count triangles after triangulation (matches GLB export tri count)."""
    me = obj.data
    total = 0
    for poly in me.polygons:
        total += len(poly.vertices) - 2  # quads=2 tris, tris=1 tri, ngon=n-2
    return total


# ---------------------------------------------------------------------------
# Scene helpers
# ---------------------------------------------------------------------------
def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    # Remove orphan meshes/mats
    for block in list(bpy.data.meshes):
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in list(bpy.data.materials):
        if block.users == 0:
            bpy.data.materials.remove(block)


def link_to_scene(obj: bpy.types.Object) -> None:
    bpy.context.collection.objects.link(obj)


def export_glb(filepath: str) -> None:
    # Blender 5.x gltf exporter — export_colors was removed; use export_attributes.
    # export_yup became export_import_convert_lighting_space in 4.x+ but the
    # simpler form still works via the Y-up toggle.
    kwargs = dict(
        filepath=filepath,
        export_format="GLB",
        export_apply=True,
        export_materials="EXPORT",
        export_normals=True,
        export_tangents=False,
        export_texcoords=False,
        export_cameras=False,
        export_lights=False,
    )
    # Try Y-up flag (name changed across Blender versions; try both).
    try:
        bpy.ops.export_scene.gltf(**kwargs, export_yup=True)
    except TypeError:
        try:
            bpy.ops.export_scene.gltf(**kwargs, export_import_convert_lighting_space=True)
        except TypeError:
            bpy.ops.export_scene.gltf(**kwargs)


# ---------------------------------------------------------------------------
# Build SINGLE shard
# ---------------------------------------------------------------------------
def build_single(seed_offset: int = 0) -> tuple[bpy.types.Object, str]:
    """Returns (object, glb_path)."""
    local_rng = random.Random(SEED + seed_offset)

    sides      = local_rng.randint(5, 7)
    height     = local_rng.uniform(1.0, 1.5)
    base_r     = local_rng.uniform(0.18, 0.28)
    tip_r      = base_r * local_rng.uniform(0.12, 0.22)
    twist      = local_rng.uniform(-8.0, 8.0)
    off_x      = local_rng.uniform(-0.04, 0.04) * base_r
    off_z      = local_rng.uniform(-0.04, 0.04) * base_r
    base_taper = 0.72

    obj = make_crystal_mesh(
        sides=sides,
        height=height,
        base_radius=base_r,
        tip_radius=tip_r,
        tip_offset_xz=(off_x, off_z),
        twist_deg=twist,
        base_taper=base_taper,
    )
    add_neutral_material(obj)
    tris = count_tris(obj)
    print(f"[gen_crystal] single shard: sides={sides} height={height:.2f} "
          f"base_r={base_r:.3f} tris={tris}")
    return obj, tris


# ---------------------------------------------------------------------------
# Build CLUSTER (3-5 shards, bottom-weighted grouping, varying sizes)
# ---------------------------------------------------------------------------
def build_cluster(seed_offset: int = 100) -> list[tuple[bpy.types.Object, str]]:
    """Returns list of (object, local_label) for each shard in cluster."""
    local_rng = random.Random(SEED + seed_offset)

    count = local_rng.randint(3, 5)
    objects = []

    for i in range(count):
        sides  = local_rng.randint(5, 7)
        # Size variation: one hero shard + smaller satellites
        scale  = 1.0 if i == 0 else local_rng.uniform(0.35, 0.75)
        height = local_rng.uniform(0.9, 1.6) * scale
        base_r = local_rng.uniform(0.14, 0.26) * scale
        tip_r  = base_r * local_rng.uniform(0.10, 0.20)
        twist  = local_rng.uniform(-12.0, 12.0)
        off_x  = local_rng.uniform(-0.05, 0.05) * base_r
        off_z  = local_rng.uniform(-0.05, 0.05) * base_r

        obj = make_crystal_mesh(
            sides=sides,
            height=height,
            base_radius=base_r,
            tip_radius=tip_r,
            tip_offset_xz=(off_x, off_z),
            twist_deg=twist,
            base_taper=0.72,
        )

        # --- Position in cluster (bottom at Y=0, spread in XZ disk)
        #     Hero at center, satellites around it with partial overlap
        if i == 0:
            px, pz = 0.0, 0.0
            lean_x, lean_z = 0.0, 0.0
        else:
            angle  = local_rng.uniform(0, 2 * math.pi)
            dist   = local_rng.uniform(base_r * 0.6, base_r * 2.2)
            px     = math.cos(angle) * dist
            pz     = math.sin(angle) * dist
            # Slight lean away from center (tilt via rotation) — keeps base at Y=0
            lean_amt = local_rng.uniform(0.0, 8.0)   # degrees
            lean_x   = math.sin(angle + math.pi) * math.radians(lean_amt)
            lean_z   = math.cos(angle + math.pi) * math.radians(lean_amt)

        obj.location    = (px, 0.0, pz)
        obj.rotation_euler = (lean_x, 0.0, lean_z)
        obj.name        = f"crystal_cluster_shard_{i:02d}"

        add_neutral_material(obj)
        tris = count_tris(obj)
        print(f"[gen_crystal] cluster shard {i}: sides={sides} h={height:.2f} "
              f"scale={scale:.2f} tris={tris}")
        objects.append((obj, tris))

    return objects


# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
def main():
    print(f"\n[gen_crystal] seed={SEED}  output_dir={OUTPUT_DIR}\n")

    # ---- SINGLE ----
    clear_scene()
    single_obj, single_tris = build_single(seed_offset=0)
    link_to_scene(single_obj)

    single_path = os.path.join(OUTPUT_DIR, "crystal_dp_single_01.glb")
    export_glb(single_path)
    print(f"[gen_crystal] EXPORTED single  → {single_path}  ({single_tris} tris)")

    # ---- CLUSTER ----
    clear_scene()
    shards = build_cluster(seed_offset=100)
    total_tris = 0
    for obj, tris in shards:
        link_to_scene(obj)
        total_tris += tris

    cluster_path = os.path.join(OUTPUT_DIR, "crystal_dp_cluster_01.glb")
    export_glb(cluster_path)
    print(f"[gen_crystal] EXPORTED cluster → {cluster_path}  ({total_tris} tris total, {len(shards)} shards)")

    print("\n[gen_crystal] DONE ✓")
    print(f"  single  tri count : {single_tris}")
    print(f"  cluster tri count : {total_tris}")
    print(f"  budget  single    : <= 500  {'OK' if single_tris <= 500 else 'OVER BUDGET!'}")
    print(f"  budget  cluster   : <= 1500 {'OK' if total_tris <= 1500 else 'OVER BUDGET!'}")


main()
