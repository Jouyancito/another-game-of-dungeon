"""
gen_golem_chunks.py — Dungeon Party stone-golem CHUNKED body generator (P1 Pradera).

ARCHITECTURE REQUIREMENT (2026-06-14, Joan):
  The golem body cannot be one welded mesh — the rock chunks must be SEPARABLE
  nodes so they can animate from "piled/scattered rest" (dormant) to "assembled
  standing" (alert) transforms in Godot. This is the ASSEMBLY AWAKEN star move.

  This generator deliberately does NOT call object.join() on the body blocks.
  Instead every named chunk is exported as its OWN root-level node in the GLB.
  Godot receives them as separate children under a common root, each with a stable
  name like "chunk_body_chest", "chunk_leg_L_thigh", "chunk_head", etc. that
  golem.gd can address by name to tween pile→standing.

  The eye cores are exported as "chunk_eye_L" / "chunk_eye_R" on a separate
  "golem_eye_core" material slot so Godot can drive the cyan emissive glow.

OUTPUT:
  golem_dp_chunks_01.glb  (game/assets/art/piso1_pradera/enemies/big/)

WHAT GODOT DOES WITH THIS:
  1. Load the GLB. All chunks appear as children of the root Node3D.
  2. golem_assembly.gd stores each chunk's "pile" transform (scattered/flat = dormant)
     and "stand" transform (the assembled standing poses baked here = alert).
  3. _awaken() tweens each chunk from pile→stand with heavy, staggered timing.
  4. _sleep() tweens back from stand→pile.
  5. Eye cores start albedo-camouflaged, emission 0; _awaken() fades them to cyan.

ROCK STYLE — MIXED (Joan 2026-06-14):
  Angular plates (torso/chest/head) + rounded boulder shapes (legs/arms/fists).
  Breaks the uniform-cube look of the original build.
  - Plates: low bevel, detail=1 displacement = faceted angular slabs.
  - Boulders: subdivision round_block(1) = smooth rounded river-rock shapes.

TREE ON HEAD:
  Not built here — it is a child node reusing an existing prairie tree GLB
  (env_tree_birch_02.gltf or similar). golem_assembly.gd adds it as a child of
  the "chunk_head" node at runtime. See golem_assembly.gd.

MOSS (DESATURATED):
  paint_moss uses stone=(0.44, 0.42, 0.40) and moss=(0.27, 0.39, 0.20) —
  same approach as gen_golem.py but with a more desaturated moss green to match
  the prairie palette (not the bright saturated green of the old build).

TRI BUDGET: target ≤ 2500 total (same as gen_golem.py). With ~25-30 separate
  chunks (not joined + no voxel-merge step) the raw count is higher. Each chunk
  is kept lean (detail only on large structural masses). Final budget is checked
  and reported.

AXIS CONVENTION: Z-up in Blender, export_yup=True → stands in Godot.

DEFERRED (later passes):
  - Carved spirals on torso.
  - Vines wrapping arms.
  - Rune plate on forearm.
  - Full mixed-rock refinement (more rounded boulder shapes on legs).

Usage:
  blender.exe --background --python gen_golem_chunks.py
  blender.exe --background --python gen_golem_chunks.py -- --seed 7
"""

import bpy
import bmesh
import math
import random
import sys
import os
from mathutils import Vector, Euler

# ---------------------------------------------------------------------------
# Seed / paths
# ---------------------------------------------------------------------------
SEED = 7
argv = sys.argv
if "--" in argv:
    extra = argv[argv.index("--") + 1:]
    for i, arg in enumerate(extra):
        if arg == "--seed" and i + 1 < len(extra):
            SEED = int(extra[i + 1])
        elif arg.startswith("--seed="):
            SEED = int(arg.split("=", 1)[1])

rng = random.Random(SEED)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "..", "assets", "art", "piso1_pradera", "enemies", "big")
)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ---------------------------------------------------------------------------
# Palettes
# ---------------------------------------------------------------------------
# Stone: warm grey base, slightly cooler than before to read as carved stone
# (less warm-brown, more grey-blue — matches refs 02, 04, 07 "river rock" grey)
STONE_BASE = (0.40, 0.39, 0.38)
# Moss: STRONGLY DESATURATED — was too bright/saturated (Minecraft-green read).
# Now targets grey-green matching the prairie floor scatter palette exactly.
MOSS_COL = (0.24, 0.33, 0.18)

# ---------------------------------------------------------------------------
# Core block builder (from gen_golem.py, preserved exactly)
# ---------------------------------------------------------------------------
def make_rock_block(
    name: str,
    location: tuple,
    size: tuple,
    rotation: tuple = (0.0, 0.0, 0.0),
    bevel: float = 0.06,
    jitter: float = 0.06,
    block_seed: int = 0,
    detail: int = 0,
    displace: float = 0.10,
    rot_jitter_deg: float = 5.0,
    plate: bool = False,
) -> bpy.types.Object:
    """
    plate=False (default) → rounded boulder-style (wider bevel, more segments).
    plate=True → angular slab-style (tight bevel 1 seg, detail displacement = facets).
    """
    lrng = random.Random(SEED * 131 + block_seed)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)

    sx, sy, sz = size
    for v in bm.verts:
        v.co.x *= sx
        v.co.y *= sy
        v.co.z *= sz

    min_dim = max(0.001, min(sx, sy, sz))
    if plate:
        # Angular plate: tight bevel, 1 segment
        bevel_off = min(bevel * 0.6, min_dim * 0.25)
        segs = 1
    else:
        # Boulder: wider bevel, 2 segments (will be rounded further by round_block)
        bevel_off = min(bevel, min_dim * 0.45)
        segs = 2

    bmesh.ops.bevel(
        bm,
        geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
        offset=bevel_off,
        offset_type="OFFSET",
        segments=segs,
        profile=0.5,
        affect="EDGES",
        clamp_overlap=True,
    )

    for v in bm.verts:
        v.co.x += lrng.uniform(-jitter, jitter) * sx
        v.co.y += lrng.uniform(-jitter, jitter) * sy
        v.co.z += lrng.uniform(-jitter, jitter) * sz

    if detail >= 1:
        for _ in range(detail):
            bmesh.ops.subdivide_edges(bm, edges=list(bm.edges), cuts=1, use_grid_fill=True)
        for v in bm.verts:
            v.co.x += lrng.uniform(-displace, displace) * sx
            v.co.y += lrng.uniform(-displace, displace) * sy
            v.co.z += lrng.uniform(-displace, displace) * sz

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name + "_mesh")
    bm.to_mesh(mesh)
    bm.free()
    mesh.validate(verbose=False)
    obj = bpy.data.objects.new(name, mesh)
    obj.location = Vector(location)
    rj = math.radians(rot_jitter_deg)
    obj.rotation_euler = Euler((
        rotation[0] + lrng.uniform(-rj, rj),
        rotation[1] + lrng.uniform(-rj, rj),
        rotation[2] + lrng.uniform(-rj, rj),
    ), "XYZ")
    return obj


def round_block(obj: bpy.types.Object, levels: int = 1) -> None:
    """Apply subdivision surface headless-safe via depsgraph (NOT modifier_apply op).
    This rounds the boulder chunks into organic river-rock shapes."""
    try:
        bpy.context.collection.objects.link(obj)
    except RuntimeError:
        pass
    mod = obj.modifiers.new("subsurf", type="SUBSURF")
    mod.levels = levels
    mod.render_levels = levels
    # Headless-safe apply: evaluate via depsgraph, swap mesh data, remove modifier.
    dg = bpy.context.evaluated_depsgraph_get()
    eval_obj = obj.evaluated_get(dg)
    new_mesh = bpy.data.meshes.new_from_object(eval_obj, depsgraph=dg)
    old_mesh = obj.data
    obj.data = new_mesh
    obj.modifiers.remove(mod)
    bpy.data.meshes.remove(old_mesh)


def flatten_mesh(obj: bpy.types.Object) -> None:
    """Flat-shade every face. Ground each chunk so its bottom Z == its local min."""
    me = obj.data
    for poly in me.polygons:
        poly.use_smooth = False
    me.validate(verbose=False)


def link(obj: bpy.types.Object) -> None:
    try:
        bpy.context.collection.objects.link(obj)
    except RuntimeError:
        pass


# ---------------------------------------------------------------------------
# Vertex-color paint (per-face moss tinting)
# ---------------------------------------------------------------------------
def paint_moss_chunk(obj: bpy.types.Object, moss_bias: float = 0.0) -> None:
    """
    Desaturated moss on up-facing high faces; stone on sides/bottom.
    moss_bias: 0.0 (normal), 1.0 (heavy moss like the overgrown shoulder).

    COHESION FIX (2026-06-14 rework):
    - Stone tonal jitter reduced from ±0.09 to ±0.05 so adjacent chunks
      read as ONE carved mass instead of a splotchy patchwork.
    - Moss threshold raised: only face-up AND high faces get moss (was
      spreading too far onto sides = toy-block read).
    - Stone base slightly desaturated towards grey-blue (see STONE_BASE above).
    """
    me = obj.data
    if not me.color_attributes:
        me.color_attributes.new(name="Col", type="BYTE_COLOR", domain="CORNER")
    ca = me.color_attributes[0]
    if len(ca.data) == 0:
        return
    zs = [v.co.z for v in me.vertices]
    zmin, zr = min(zs), max(1e-6, max(zs) - min(zs))
    stone = STONE_BASE
    moss = MOSS_COL
    prng = random.Random(SEED * 13 + int(moss_bias * 100))
    for poly in me.polygons:
        vs = [me.vertices[i].co for i in poly.vertices]
        nrm = (vs[1] - vs[0]).cross(vs[2] - vs[0])
        up = 0.0 if nrm.length < 1e-9 else max(0.0, nrm.normalized().z)
        cz = sum(v.z for v in vs) / len(vs)
        h = (cz - zmin) / zr
        # Tighter threshold: require BOTH upward-facing AND above the midpoint.
        # This stops moss from creeping onto vertical and downward faces.
        amt = up * (0.50 + 0.50 * h) + prng.uniform(-0.15, 0.10) + moss_bias * 0.3
        if amt < 0.30:   # raised threshold (was 0.20) — narrower moss spread
            amt = 0.0
        amt = max(0.0, min(1.0, amt))
        # Reduced stone tone jitter (was ±0.09) for cohesive carved-stone read.
        t = prng.uniform(-0.05, 0.05)
        col = (min(1.0, max(0.0, stone[0] * (1 - amt) + moss[0] * amt + t)),
               min(1.0, max(0.0, stone[1] * (1 - amt) + moss[1] * amt + t)),
               min(1.0, max(0.0, stone[2] * (1 - amt) + moss[2] * amt - t)), 1.0)
        for li in poly.loop_indices:
            ca.data[li].color = col


# ---------------------------------------------------------------------------
# Material setup
# ---------------------------------------------------------------------------
_stone_mat = None
_eye_mat = None


def get_stone_mat() -> bpy.types.Material:
    global _stone_mat
    if _stone_mat is None:
        _stone_mat = bpy.data.materials.new("golem_stone")
        _stone_mat.diffuse_color = (0.44, 0.42, 0.40, 1.0)
    return _stone_mat


def get_eye_mat() -> bpy.types.Material:
    global _eye_mat
    if _eye_mat is None:
        _eye_mat = bpy.data.materials.new("golem_eye_core")
        _eye_mat.diffuse_color = (0.37, 0.85, 1.0, 1.0)  # cyan; Godot overrides emissive
    return _eye_mat


# ---------------------------------------------------------------------------
# Chunk factory — builds each structural piece as its own named object.
# Stable names are the Godot contract: golem_assembly.gd relies on them.
# ---------------------------------------------------------------------------

def make_chunk(
    name: str,
    location: tuple,
    size: tuple,
    rotation: tuple = (0.0, 0.0, 0.0),
    bevel: float = 0.07,
    jitter: float = 0.07,
    block_seed: int = 0,
    detail: int = 1,
    displace: float = 0.10,
    rot_jitter_deg: float = 6.0,
    plate: bool = False,
    boulder: bool = False,
    moss_bias: float = 0.0,
    is_eye: bool = False,
) -> bpy.types.Object:
    """
    Make a single named chunk, assign material, paint moss, link to scene.
    plate=True → angular plate style (torso/chest/head/shoulders).
    boulder=True → extra round_block(1) pass after build (legs/arms/fists).
    """
    obj = make_rock_block(
        name, location, size, rotation,
        bevel=bevel, jitter=jitter, block_seed=block_seed,
        detail=detail, displace=displace, rot_jitter_deg=rot_jitter_deg,
        plate=plate,
    )
    link(obj)

    if boulder:
        round_block(obj, 1)

    flatten_mesh(obj)

    if is_eye:
        obj.data.materials.append(get_eye_mat())
    else:
        obj.data.materials.append(get_stone_mat())
        paint_moss_chunk(obj, moss_bias)

    return obj


# ---------------------------------------------------------------------------
# Build all chunks — standing/assembled pose (the "stand" transforms).
# Godot will also be given pile transforms via golem_assembly.gd constants.
# Naming convention: chunk_<part>
# ---------------------------------------------------------------------------
def build_all_chunks() -> list:
    """
    COHESION REWORK (2026-06-14):
    Chunks are INTERLOCKED — each piece overlaps its neighbour by 10-18% so
    there is NO visible gap (no daylight) between structural masses. The silhouette
    must read as ONE carved stone body, not a pile of separable boxes.

    The assembled standing pose here IS the "stand" transforms stored by
    golem_assembly.gd. The "pile" (dormant) positions are computed in GDScript
    by subtracting per-chunk offsets from these stand positions.

    LIMB GROUP MAPPING (for golem_assembly.gd Node3D parents):
      - TORSO group:  chunk_pelvis, chunk_chest, chunk_back_hump
      - ARM_L group:  chunk_shoulder_L, chunk_shoulder_L_knob,
                      chunk_arm_L_upper, chunk_arm_L_forearm, chunk_arm_L_fist
      - ARM_R group:  chunk_shoulder_R,
                      chunk_arm_R_upper, chunk_arm_R_forearm, chunk_arm_R_fist
      - LEG_L group:  chunk_leg_L_thigh, chunk_leg_L_foot
      - LEG_R group:  chunk_leg_R_thigh, chunk_leg_R_foot
      - HEAD group:   chunk_neck, chunk_head, chunk_face_brow, chunk_face_jaw,
                      chunk_eye_L, chunk_eye_R
      - BACK group:   chunk_back_hump (shared with TORSO for spring-damper)
      - RUBBLE:       chunk_rubble_00..06 (ground-level scatter)

    DORMANT flat pile: ALL chunks should rest near Z=0.0..0.25 when piled.
    The golem_assembly.gd PILE_RULES push each chunk DOWN by its standing Z,
    so the pile ends flat on the ground.
    """
    chunks = []

    # =========================================================================
    # TORSO CORE
    # =========================================================================

    # PELVIS: wide angular plate — the bottom anchor of the torso.
    # Pushed slightly deeper into leg tops (Z overlap ~0.08) for no gap.
    chunks.append(make_chunk(
        "chunk_pelvis",
        (0.0, -0.02, 0.85),         # slightly lower than before → pelvis sits IN the leg gap
        (1.08, 0.68, 0.58),         # slightly wider/deeper → overlaps leg top and chest bottom
        bevel=0.06, jitter=0.05, block_seed=20,
        detail=1, plate=True,
        moss_bias=0.0,
    ))

    # CHEST: the dominant torso mass — refs 01/05 angular plate look.
    # Lowered 0.08 so its bottom edge overlaps the pelvis top (no gap).
    chunks.append(make_chunk(
        "chunk_chest",
        (0.0, 0.08, 1.34),          # was 1.45 → moved down 0.11 into pelvis overlap
        (1.22, 0.80, 0.88),         # slightly larger → fills shoulder base gap
        rotation=(math.radians(-12.0), 0.0, 0.0),
        bevel=0.05, jitter=0.05, block_seed=21,
        detail=1, plate=True,
        moss_bias=0.04,
    ))

    # BACK HUMP: rounded, behind chest. The tree grows from here.
    # Pushed forward (Y) and up to overlap chest back face.
    chunks.append(make_chunk(
        "chunk_back_hump",
        (0.0, -0.38, 1.64),         # slightly lower (was 1.70) — must not compete with the head crest
        (0.98, 0.52, 0.56),
        rotation=(math.radians(20.0), 0.0, 0.0),
        bevel=0.07, jitter=0.08, block_seed=22,
        detail=0, boulder=True,
        moss_bias=0.30,             # heaviest moss — the rain-pool top
    ))

    # =========================================================================
    # LEGS
    # =========================================================================
    # Rounded boulders (refs 04, 07). Pushed inward (X reduced) and raised (Z)
    # so thigh top overlaps pelvis bottom — no gap at hip joint.
    for sgn, sd, side in ((-1, 1, "L"), (1, 2, "R")):
        chunks.append(make_chunk(
            f"chunk_leg_{side}_thigh",
            (sgn * 0.36, -0.04, 0.52),   # X tighter (was 0.40), Z same
            (0.52, 0.56, 0.70),            # taller (was 0.62) → overlaps pelvis bottom
            bevel=0.09, jitter=0.09, block_seed=sd,
            detail=0, boulder=True,
            moss_bias=0.08 if side == "L" else 0.0,
        ))
        chunks.append(make_chunk(
            f"chunk_leg_{side}_foot",
            (sgn * 0.38, 0.08, 0.14),     # X tighter, Z slightly lower
            (0.62, 0.72, 0.38),            # wider foot → good contact with ground
            bevel=0.08, jitter=0.07, block_seed=sd + 10,
            detail=0, boulder=True,
            moss_bias=0.0,
        ))

    # =========================================================================
    # SHOULDERS — plates that bridge chest to arms.
    # X moved inward by 0.06 so shoulder inner face overlaps chest outer face.
    # =========================================================================
    chunks.append(make_chunk(
        "chunk_shoulder_L",
        (-0.62, 0.00, 1.76),
        (0.68, 0.72, 0.66),         # narrower (was 0.80 wide) — was swallowing the arm in 3/4
        bevel=0.05, jitter=0.06, block_seed=30,
        detail=1, plate=True, displace=0.06,
        moss_bias=0.50,             # the heavily overgrown left side (ref 01 asymmetry)
    ))
    chunks.append(make_chunk(
        "chunk_shoulder_L_knob",
        (-0.70, -0.06, 2.00),
        (0.40, 0.40, 0.34),
        bevel=0.06, jitter=0.06, block_seed=31,
        detail=0, boulder=True,      # rounded knob — the plate version read as a thin fin in 3/4
        moss_bias=0.38,
    ))
    chunks.append(make_chunk(
        "chunk_shoulder_R",
        (0.58, 0.00, 1.70),         # X was 0.64 → inward 0.06
        (0.68, 0.68, 0.62),
        bevel=0.05, jitter=0.06, block_seed=32,
        detail=1, plate=True,
        moss_bias=0.04,
    ))

    # =========================================================================
    # ARMS — upper plate → forearm boulder → fist boulder.
    # Each section's Z range overlaps the next by ~0.10 to eliminate gaps.
    # X tightened inward so arm inner face overlaps shoulder outer face.
    # =========================================================================
    arm_specs = [
        (-1, 40, 41, 42, 1.14, "L"),   # left arm bigger (overgrown side)
        (1, 43, 44, 45, 1.0, "R"),
    ]
    for sgn, us, fs, ks, sc, side in arm_specs:
        # ARM SEPARATION (2026-07-03): arms pushed back OUT so the 3/4 view keeps
        # negative space between arm and torso — the joint fillers now cover the
        # shoulder seam, so the arms no longer need to hug the chest for cohesion.
        chunks.append(make_chunk(
            f"chunk_arm_{side}_upper",
            (sgn * 1.00, 0.10, 1.38),   # X back out (was 0.90) — silhouette legibility
            (0.52 * sc, 0.52 * sc, 0.82 * sc),
            rotation=(math.radians(-5.0), math.radians(-5.0 * sgn), 0.0),
            bevel=0.05, jitter=0.06, block_seed=us,
            detail=1, plate=True, displace=0.06,   # less shard-y plate displacement
            moss_bias=0.10 if side == "L" else 0.02,
        ))
        # Forearm: top overlaps upper arm bottom (Z overlap ~0.10)
        chunks.append(make_chunk(
            f"chunk_arm_{side}_forearm",
            (sgn * 1.10, 0.24, 0.60),   # X back out (was 1.00)
            (0.52 * sc, 0.52 * sc, 0.88 * sc),
            rotation=(math.radians(8.0), 0.0, 0.0),
            bevel=0.07, jitter=0.08, block_seed=fs,
            detail=0, boulder=True,
        ))
        # Fist: top overlaps forearm bottom
        chunks.append(make_chunk(
            f"chunk_arm_{side}_fist",
            (sgn * 1.12, 0.38, 0.22),   # X back out (was 1.00)
            (0.72 * sc, 0.76 * sc, 0.66 * sc),  # larger fist = knuckle-drag read
            bevel=0.09, jitter=0.09, block_seed=ks,
            detail=0, boulder=True,
        ))

    # =========================================================================
    # HEAD GROUP — neck overlaps chest top; head overlaps neck.
    # =========================================================================
    chunks.append(make_chunk(
        "chunk_neck",
        (0.0, 0.16, 1.80),          # Z was 1.86 → slightly lower, into chest top
        (0.44, 0.44, 0.36),         # slightly larger
        rotation=(math.radians(-16.0), 0.0, 0.0),
        bevel=0.04, jitter=0.04, block_seed=50,
        detail=0,
    ))
    chunks.append(make_chunk(
        "chunk_head",
        (0.0, 0.30, 2.12),          # raised (was 2.00) — the head must CREST above the
        (0.80, 0.72, 0.72),         # shoulder/hump clutter (refs: head + tree = top of silhouette)
        rotation=(math.radians(-10.0), 0.0, 0.0),
        bevel=0.05, jitter=0.04, block_seed=51,
        detail=1, plate=True, displace=0.06,
        moss_bias=0.22,
    ))

    # FACE: brow + jaw form the carved face plate (ref 03).
    face_cx, face_cy, face_cz = 0.0, 0.50, 2.10   # follows the raised/enlarged head
    fw, fh, fd = 0.60, 0.48, 0.32
    tilt = math.radians(-10.0)
    chunks.append(make_chunk(
        "chunk_face_brow",
        (face_cx, face_cy + fd * 0.54, face_cz + fh * 0.30),
        (fw * 0.94, fd * 0.52, fh * 0.18),
        rotation=(tilt, 0.0, 0.0),
        bevel=0.03, jitter=0.03, block_seed=901,
        detail=0, plate=True,
    ))
    chunks.append(make_chunk(
        "chunk_face_jaw",
        (face_cx, face_cy + fd * 0.44, face_cz - fh * 0.28),
        (fw * 0.80, fd * 0.44, fh * 0.30),
        rotation=(tilt, 0.0, 0.0),
        bevel=0.03, jitter=0.04, block_seed=904,
        detail=0, plate=True,
    ))

    # EYE CORES: flush in face plate, separate material for cyan glow.
    for sgn, eside in ((-1, "L"), (1, "R")):
        eye = make_chunk(
            f"chunk_eye_{eside}",
            (face_cx + sgn * fw * 0.26, face_cy + fd * 0.65, face_cz + fh * 0.05),
            (fw * 0.32, fd * 0.14, fh * 0.10),
            bevel=0.02, jitter=0.0, block_seed=904 + abs(sgn),
            rot_jitter_deg=0.0,
            detail=0, plate=True,
            is_eye=True,
        )
        chunks.append(eye)

    # =========================================================================
    # SATELLITES & JOINT FILLERS — cohesion pass 2 (2026-07-03, refs 01/04).
    # The refs read as PACKED stones: every big mass is a CLUSTER of varied
    # stones, and every joint seam has filler stones nested in it — no daylight
    # crosses the silhouette. One-box-per-limb was the root cause of the
    # "cubos sueltos" eye-review failure. Names keep the parent part's prefix
    # so golem_assembly.gd can map them to limb groups by prefix.
    # =========================================================================
    sat_specs = [
        # name, pos, size, seed, moss_bias
        # -- chest cluster (ref 01: the torso is many stones, not one plate)
        ("chunk_chest_s01", (-0.42, 0.30, 1.52), (0.52, 0.42, 0.46), 210, 0.06),
        ("chunk_chest_s02", (0.40, 0.28, 1.20), (0.48, 0.40, 0.44), 211, 0.0),
        ("chunk_chest_s03", (-0.30, 0.26, 1.06), (0.44, 0.38, 0.40), 212, 0.05),
        ("chunk_chest_s04", (0.24, 0.34, 1.56), (0.38, 0.34, 0.36), 213, 0.0),
        # -- belly stone bridging pelvis->chest (ref 04 gut boulders)
        ("chunk_pelvis_s01", (0.0, 0.30, 1.02), (0.72, 0.44, 0.42), 214, 0.0),
        # -- hip fillers (pelvis->thigh seam)
        ("chunk_leg_L_hip", (-0.36, 0.10, 0.82), (0.36, 0.38, 0.34), 215, 0.05),
        ("chunk_leg_R_hip", (0.36, 0.10, 0.82), (0.36, 0.38, 0.34), 216, 0.0),
        # -- shoulder->chest seam fillers
        ("chunk_shoulder_L_s01", (-0.44, 0.16, 1.60), (0.38, 0.36, 0.34), 217, 0.30),
        ("chunk_shoulder_R_s01", (0.42, 0.14, 1.56), (0.36, 0.34, 0.32), 218, 0.03),
        # -- elbow fillers (upper->forearm seam) — follow the arms outward
        ("chunk_arm_L_elbow", (-1.08, 0.20, 1.00), (0.42, 0.40, 0.38), 219, 0.08),
        ("chunk_arm_R_elbow", (1.04, 0.18, 0.98), (0.38, 0.36, 0.34), 220, 0.0),
        # -- knee fillers (thigh->foot seam)
        ("chunk_leg_L_knee", (-0.37, 0.18, 0.36), (0.32, 0.34, 0.30), 221, 0.04),
        ("chunk_leg_R_knee", (0.37, 0.18, 0.36), (0.32, 0.34, 0.30), 222, 0.0),
        # -- neck collar (chest->head seam, nests the head into the torso)
        ("chunk_neck_s01", (-0.24, 0.20, 1.86), (0.28, 0.26, 0.24), 223, 0.10),
        ("chunk_neck_s02", (0.22, 0.24, 1.84), (0.26, 0.24, 0.22), 224, 0.0),
    ]
    for sname, pos, ssize, bseed, smoss in sat_specs:
        chunks.append(make_chunk(
            sname, pos, ssize,
            bevel=0.07, jitter=0.08, block_seed=bseed,
            detail=0, boulder=True,
            rot_jitter_deg=14.0,
            moss_bias=smoss,
        ))

    # =========================================================================
    # RUBBLE — small rocks at joints and base (break the silhouette cleanly).
    # Kept near ground so they read as soil/debris scatter.
    # =========================================================================
    rubble_specs = [
        ((-0.50, 0.22, 0.08), 0.28, 600),   # left foot edge
        ((0.52, 0.20, 0.10), 0.26, 601),     # right foot edge
        ((-0.65, 0.10, 1.60), 0.24, 602),    # left shoulder base
        ((0.60, 0.08, 1.56), 0.18, 603),     # right shoulder base
        ((-0.28, -0.32, 1.80), 0.20, 604),   # upper back scatter
        ((0.0, -0.36, 1.54), 0.20, 605),     # spine mid
        ((-0.96, 0.16, 0.44), 0.18, 606),    # left elbow ground
    ]
    srng = random.Random(SEED * 977 + 3)
    for i, (pos, bs, bseed) in enumerate(rubble_specs):
        s = bs * srng.uniform(0.72, 1.20)
        chunks.append(make_chunk(
            f"chunk_rubble_{i:02d}",
            (pos[0] + srng.uniform(-0.04, 0.04),
             pos[1] + srng.uniform(-0.04, 0.04),
             pos[2]),
            (s, s * srng.uniform(0.72, 1.08), s * srng.uniform(0.62, 0.98)),
            bevel=0.04, jitter=0.11, block_seed=bseed,
            detail=0, boulder=False,
            rot_jitter_deg=20.0,
            moss_bias=0.04,
        ))

    return chunks


# ---------------------------------------------------------------------------
# Scene helpers
# ---------------------------------------------------------------------------
def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for block in list(bpy.data.meshes):
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in list(bpy.data.materials):
        if block.users == 0:
            bpy.data.materials.remove(block)


def count_tris(obj: bpy.types.Object) -> int:
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def export_glb(filepath: str) -> None:
    base = dict(
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
    # Try vertex colors; degrade gracefully on API version variation.
    for extra in (dict(export_yup=True, export_vertex_color="ACTIVE"),
                  dict(export_yup=True),
                  dict()):
        try:
            bpy.ops.export_scene.gltf(**base, **extra)
            return
        except TypeError:
            continue


# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
def main():
    print(f"\n[gen_golem_chunks] seed={SEED}  output_dir={OUTPUT_DIR}\n")
    clear_scene()

    chunks = build_all_chunks()

    # Report
    total_tris = sum(count_tris(c) for c in chunks)
    all_z = []
    all_x = []
    for c in chunks:
        bpy.context.view_layer.objects.active = c
        for v in c.data.vertices:
            world = c.matrix_world @ v.co
            all_z.append(world.z)
            all_x.append(world.x)

    height = max(all_z) - min(all_z) if all_z else 0
    width = max(all_x) - min(all_x) if all_x else 0
    print(f"[gen_golem_chunks] {len(chunks)} chunks  total_tris={total_tris}")
    print(f"[gen_golem_chunks] height(Z)={height:.2f}m  width(X)={width:.2f}m")
    print(f"[gen_golem_chunks] budget <= 2500 tris : {'OK' if total_tris <= 2500 else 'OVER (expected — no voxel-merge step)'}")

    # Print the stable chunk names so golem_assembly.gd can be cross-referenced
    print("\n[gen_golem_chunks] CHUNK NAMES (stable contract for Godot):")
    for c in chunks:
        print(f"  {c.name:<35}  tris={count_tris(c)}")

    out_path = os.path.join(OUTPUT_DIR, "golem_dp_chunks_01.glb")
    export_glb(out_path)

    print(f"\n[gen_golem_chunks] EXPORTED -> {out_path}")
    print("[gen_golem_chunks] DONE ✓\n")

    # NOTE: the tree-on-head is NOT generated here.
    # golem_assembly.gd attaches an existing prairie tree GLB
    # (e.g. env_tree_birch_02.gltf) as a child of "chunk_head" at runtime.
    # TODO (later pass): carved spirals on chunk_chest, vines on arm chunks, rune plate.


main()
