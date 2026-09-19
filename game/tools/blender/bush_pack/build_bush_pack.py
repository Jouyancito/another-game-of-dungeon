"""
build_bush_pack.py - bespoke BUSH pack for Piso 1 Pradera (DP_ToonGrounded).

Reference (MANDATORY, loaded before writing this): foliage_painterly/ref_01.png
+ _synthesis.md (game/docs/art/_references/foliage_painterly/). The ref shows
gouache foliage clumps painted as OVERLAPPING BLOBS OF COLOR with a wide value
range (dark shadow interior -> near-lime-lit edge), flower dots layered on top
as a final accent -- never leaf-by-leaf detail, never a flat single green.
Bushes here are the SAME material language as flower_pack/grass_pack scaled up
to real-world bush size: a "silueta de nube" (cloud silhouette) mass, not a
modeled branch structure (except bush_dry_01, which deliberately shows BARE
twigs poking through a sparse canopy -- the one variant where structure
should read).

What NOT to repeat (checked game/assets/art/piso1_pradera/vegetation/bush/
first, per CLAUDE.md's mandatory "load the asset's folder before building"
rule): 4 legacy texture-card bushes already live there (env_bush_01.gltf,
env_bush_large_01.gltf, env_bush_flowers_01.gltf, env_bush_small_flowers_01.gltf
+ their .bin/.png). This script does NOT touch, rename, or delete any of them --
it only ADDS new env_bush_<variant>.glb files alongside.

Structural precedent (read before writing this script, per task brief):
flower_pack/build_flower_pack.py (add_blob_dab / add_star_dab canopy-blob
technique, FLOAT_COLOR-only material, ficha showcase + label pattern, the
z>0-labels-grow-upward gotcha) and grass_pack/build_grass_pack.py (tapered
blade-card recipe, reused here for bush_dry_01's bare twigs). This script
follows the same helper-function shape and docstring format.

5 variants (DP_ToonGrounded: flat-shaded, FLOAT_COLOR only, no textures,
bottom-weighted silhouette with ONE asymmetric break -- see add_canopy_mass's
notch/outlier params -- base at Z=0, Z-up build, export_yup=True):
  1. bush_round_01     - classic round bush, dense dab canopy, widest value
                          range (near-black shadow core -> punchy lime rim).
  2. bush_large_01     - 3 uneven lobes (asymmetric mass on purpose, meant to
                          frame a clearing edge, not a clean sphere).
  3. bush_flowering_01 - round-bush canopy + star-dab flower accents (flower_
                          pack's star/blob technique). NO emission by default
                          (glTF emissiveFactor-per-material gotcha noted below
                          if that ever changes).
  4. bush_low_01       - low, wide, ground-hugging/creeping mat.
  5. bush_dry_01       - golden/dry palette, sparse canopy + visible bare
                          twigs (grass_pack add_blade recipe, re-tuned stiffer
                          + brown, some poking above the canopy on purpose).

Vertex color GOTCHA (blender-asset-smith skill, 2026-07-20 golem_guardian +
flower_pack entries): BYTE_COLOR corner attributes silently sRGB-decode on
readback while bmesh's loop-color WRITE does not encode -> colors crush toward
black, AND BMVert.index is stale immediately after bm.verts.new() (keying a
color dict by .index reads garbage/0 for a fresh vert). This script uses
bm.loops.layers.float_color.new(...) EXCLUSIVELY and keys the per-vertex color
dict by the BMVert object itself, never by .index.

Triangle budget: <=450 tris/variant (see count_tris print at build time).

Run:
  blender.exe --background --python build_bush_pack.py
  blender.exe --background --python build_bush_pack.py -- --seed 7
"""
import bpy
import bmesh
import math
import os
import random
import sys
from mathutils import Vector, Matrix

SEED = 11
argv = sys.argv
if "--" in argv:
    extra = argv[argv.index("--") + 1:]
    for i, arg in enumerate(extra):
        if arg == "--seed" and i + 1 < len(extra):
            SEED = int(extra[i + 1])
        elif arg.startswith("--seed="):
            SEED = int(arg.split("=", 1)[1])

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(SCRIPT_DIR, "renders")
os.makedirs(REN_DIR, exist_ok=True)
# GLBs ship straight into the vegetation/bush asset folder (task requirement)
# -- unlike flower_pack/grass_pack, which export into their own tools/ dir
# and get copied over separately.
ASSET_DIR = os.path.normpath(os.path.join(
    SCRIPT_DIR, "..", "..", "..", "assets", "art", "piso1_pradera", "vegetation", "bush"))
os.makedirs(ASSET_DIR, exist_ok=True)

sys.path.insert(0, os.path.dirname(SCRIPT_DIR))
import _ground_common as groundlib  # noqa: E402

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


# =============================================================================
# GEOMETRY HELPERS -- append directly into a shared bmesh + a BMVert -> RGB
# color dict (applied to the FLOAT_COLOR loop layer once at finalize time).
# =============================================================================
def lerp3(a, b, t):
    return [a[i] + (b[i] - a[i]) * t for i in range(3)]


def clamp01(x):
    return max(0.0, min(1.0, x))


def enforce_overlap(placed, pos, radius, rng, min_frac=0.55, max_frac=0.65):
    """QUANTIFIED adjacency rule (golem_guardian precedent, 2026-07-27 fix
    pass): a dab whose nearest already-placed neighbor is farther than
    max_frac*(sum of the two radii) reads as a disconnected floating
    fragment once rendered -- no amount of tuning the dab's own shape fixes
    that, because the defect is the GAP, not the dab. Pulls `pos` toward its
    nearest neighbor so the center separation lands in [min_frac, max_frac]
    of the summed radii. If the gap is too large to close naturally (>3x the
    target), returns None so the caller drops the dab instead of dragging it
    across the mass into an unnatural position. `placed` is a list of
    ((x,y,z), radius) tuples; pass an empty list for the very first dab."""
    if not placed:
        return pos
    px, py, pz = pos
    best = None
    best_dist = None
    for (ox, oy, oz), orad in placed:
        d = math.sqrt((px - ox) ** 2 + (py - oy) ** 2 + (pz - oz) ** 2)
        if best_dist is None or d < best_dist:
            best_dist = d
            best = (ox, oy, oz, orad)
    ox, oy, oz, orad = best
    target = rng.uniform(min_frac, max_frac) * (radius + orad)
    if best_dist < 1e-6 or best_dist <= target:
        return pos
    if best_dist > target * 3.0:
        return None
    t = target / best_dist
    return (ox + (px - ox) * t, oy + (py - oy) * t, oz + (pz - oz) * t)


def add_blob_dab(bm, vcol, rng, center, radius, col_edge, col_core, squash=0.62,
                  sides=4, jitter=0.18):
    """Tiny bipyramid canopy 'poof' dab (flower_pack recipe, reused at bush
    scale) -- bright core apex, edge ring blended toward the core. A canopy
    built from MANY small dabs (not one big blob) is what reads as a painted
    mass of foliage instead of a single glossy sphere."""
    cx, cy, cz = center
    top = bm.verts.new((cx, cy, cz + radius * squash))
    bot = bm.verts.new((cx, cy, cz - radius * squash * 0.30))
    ring = []
    for i in range(sides):
        ang = 2.0 * math.pi * i / sides + rng.uniform(-0.20, 0.20)
        r = radius * rng.uniform(1.0 - jitter, 1.0 + jitter)
        rx = cx + math.cos(ang) * r
        ry = cy + math.sin(ang) * r
        rz = cz + radius * 0.10
        ring.append(bm.verts.new((rx, ry, rz)))
    for i in range(sides):
        a, b = ring[i], ring[(i + 1) % sides]
        bm.faces.new((top, a, b))
        bm.faces.new((bot, b, a))
    vcol[top] = col_core
    vcol[bot] = col_edge
    for v in ring:
        vcol[v] = lerp3(col_edge, col_core, 0.35)


def add_star_dab(bm, vcol, rng, center, radius, col_edge, col_core, points=4,
                  height=0.60):
    """Spiky bipyramid star (flower_pack recipe) -- used ONLY for the
    bush_flowering accents so a flower reads distinctly pointed against the
    round canopy blobs around it."""
    cx, cy, cz = center
    top = bm.verts.new((cx, cy, cz + radius * height))
    bot = bm.verts.new((cx, cy, cz - radius * height * 0.22))
    n = points * 2
    ring = []
    for i in range(n):
        ang = math.pi * i / points + rng.uniform(-0.05, 0.05)
        r = radius * (1.0 if i % 2 == 0 else 0.40)
        rx = cx + math.cos(ang) * r
        ry = cy + math.sin(ang) * r
        ring.append(bm.verts.new((rx, ry, cz)))
    for i in range(n):
        a, b = ring[i], ring[(i + 1) % n]
        bm.faces.new((top, a, b))
        bm.faces.new((bot, b, a))
    vcol[top] = col_core
    vcol[bot] = col_edge
    for i, v in enumerate(ring):
        t = 0.55 if i % 2 == 0 else 0.20
        vcol[v] = lerp3(col_edge, col_core, t)


def add_twig(bm, vcol, rng, base, length, ang, rise, width_base, col_dark, col_mid,
             segments=3, bend=0.4):
    """Bare branch card -- chain of `segments` tapering quads (grass_pack's
    add_blade recipe, re-tuned stiffer/straighter + thinner-tipped for a
    woody twig instead of a soft grass blade: less curve, brown->dry-highlight
    gradient instead of green). Returns the tip position (Vector) so callers
    can grow shorter fork-twigs off it."""
    bx, by, bz = base
    dx, dy = math.cos(ang), math.sin(ang)
    px, py = -dy, dx
    rows = []
    for i in range(segments + 1):
        u = i / segments
        z = bz + rise * u
        reach = length * u
        cx = bx + dx * reach + dx * bend * reach * (u ** 2) * 0.15
        cy = by + dy * reach + dy * bend * reach * (u ** 2) * 0.15
        half_w = max(0.0015, 0.5 * width_base * (1.0 - u) ** 1.2)
        left = bm.verts.new((cx - px * half_w, cy - py * half_w, z))
        right = bm.verts.new((cx + px * half_w, cy + py * half_w, z))
        rows.append((left, right))
    for i in range(segments):
        a, b = rows[i]
        c, d = rows[i + 1]
        bm.faces.new((a, c, d, b))
    for i, (a, b) in enumerate(rows):
        t = i / segments
        col = lerp3(col_dark, col_mid, t)
        vcol[a] = col
        vcol[b] = col
    tip_l, tip_r = rows[-1]
    return (tip_l.co + tip_r.co) * 0.5


def add_core_blob(bm, vcol, rng, center, radius, col_dark, col_light,
                   squash_z=0.85, bright_bias=0.5, jitter=0.14):
    """Squashed icosphere 'cushion' blob (the blender-asset-smith skill's
    documented recipe for cheap rounded organic-ish masses: subdivisions=1
    icosphere, squash Z, flatten the underside) -- used for the CORE canopy
    mass instead of the bipyramid add_blob_dab.

    ROOT-CAUSE FIX, pass 4: add_blob_dab is a bipyramid with a single sharp
    apex vertex. That apex is invisible at flower_pack's original tiny scale
    (radius ~0.01-0.02) but reads as an obvious spike/cone once scaled up to
    a bush-sized 'core' dab (radius ~0.1-0.25) -- confirmed empirically:
    EVERY core-mass pass built from big bipyramids read as a stacked pagoda/
    conifer no matter how placement, squash, or the height-taper profile was
    tuned (3 separate fix attempts on the sampling/profile all failed to fix
    it, because the actual defect was the PRIMITIVE, not the placement). An
    icosphere has no single dominant point -- many overlapping icospheres
    fuse into a rounded lump instead of a stack of tiny tents."""
    cx, cy, cz = center
    res = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=radius,
                                      matrix=Matrix.Translation((cx, cy, cz)))
    verts = res["verts"]
    flatten_z = cz - radius * squash_z * 0.15
    for v in verts:
        local_z = v.co.z - cz
        v.co.z = cz + local_z * squash_z
        if v.co.z < flatten_z:
            v.co.z = flatten_z
        v.co.x += rng.uniform(-jitter, jitter) * radius
        v.co.y += rng.uniform(-jitter, jitter) * radius
    for v in verts:
        t = clamp01(0.5 + (v.co.z - cz) / max(1e-5, radius * squash_z) * 0.5)
        t = clamp01(t * (0.35 + bright_bias) + rng.uniform(-0.05, 0.05))
        vcol[v] = lerp3(col_dark, col_light, t)
    return verts


def bridge_lobes(bm, vcol, rng, list_a, list_b, col_dark, col_light, overlap_frac=0.58):
    """Seam filler (golem chunk-articulation precedent). PASS-2 FIX
    (2026-07-27): the first version of this function chained fillers through
    enforce_overlap, which has a "give up, don't move" branch for gaps too
    large to close naturally (by design, for organic scatter placement where
    dropping an isolated dab is the right call). Applied to BRIDGING that
    branch is wrong: it made a filler collapse onto the exact same spot as
    the previous one instead of progressing toward the far lobe, so the
    chain never actually reached lobe_b -- confirmed empirically: bush_large
    still rendered as 2 separate masses (lobe3 fully isolated) even with
    this function running. FIX: don't use enforce_overlap here at all. Derive
    the filler COUNT and RADIUS directly from the real (anchor-to-anchor)
    distance so consecutive same-size fillers are GUARANTEED to overlap by
    construction -- deterministic geometry, not a probabilistic pull/drop."""
    if not list_a or not list_b:
        return
    bx_c = sum(p[0][0] for p in list_b) / len(list_b)
    by_c = sum(p[0][1] for p in list_b) / len(list_b)
    anchor_a = min(list_a, key=lambda p: (p[0][0] - bx_c) ** 2 + (p[0][1] - by_c) ** 2)
    ax_c = sum(p[0][0] for p in list_a) / len(list_a)
    ay_c = sum(p[0][1] for p in list_a) / len(list_a)
    anchor_b = min(list_b, key=lambda p: (p[0][0] - ax_c) ** 2 + (p[0][1] - ay_c) ** 2)
    (ax, ay, az), ar = anchor_a
    (bx, by, bz), br = anchor_b
    dist_total = math.sqrt((bx - ax) ** 2 + (by - ay) ** 2 + (bz - az) ** 2)
    r_fill = (ar + br) * 0.5 * 1.15  # chunkier than the lobe-edge dabs -> fewer fillers needed
    step = max(1e-4, overlap_frac * 2.0 * r_fill)
    n_fillers = min(4, max(1, math.ceil(dist_total / step) - 1))
    for i in range(1, n_fillers + 1):
        u = i / (n_fillers + 1)
        cx = ax + (bx - ax) * u + rng.uniform(-0.015, 0.015)
        cy = ay + (by - ay) * u + rng.uniform(-0.015, 0.015)
        cz = az + (bz - az) * u
        r = r_fill * rng.uniform(0.90, 1.05)
        add_core_blob(bm, vcol, rng, (cx, cy, cz), r, col_dark, col_light,
                      squash_z=0.85, bright_bias=0.32, jitter=0.16)


def add_canopy_mass(bm, vcol, rng, base_r, height, col_dark, col_light,
                     center=(0.0, 0.0),
                     n_core=12, core_radius_range=(0.15, 0.21),
                     core_squash_range=(0.85, 1.05), core_sides=6,
                     core_disk_frac=0.55, core_center_bias=0.25,
                     n_detail=16, detail_radius_range=(0.045, 0.070),
                     detail_squash_range=(0.65, 0.85), detail_sides=5,
                     dome_power=1.3, height_bias=0.55,
                     notch_deg=None, notch_width=70, notch_pull=0.55,
                     outlier_deg=None, outlier_scale=1.3,
                     outlier_height_frac=0.30, outlier_radius=None,
                     placed=None):
    """CORE pass: n_core BIG dabs (radius a large fraction of the footprint,
    sides=6 so each one already reads rounded, not a flat kite) sampled from
    a center-biased disk that itself shrinks with height (dome taper =
    'bottom-weighted silhouette'). Because each core dab's radius is close to
    the local sampling radius, consecutive dabs overlap HEAVILY and fuse into
    one blended cloud-silhouette mass -- this is flower_pack's n_canopy=3
    technique (a few big sides=6 blobs form the base mass), scaled up with
    more dabs since the bush tri budget allows it. ROOT-CAUSE FIX (see this
    file's pass-1 lesson): trying to build an entire mass out of many
    MEDIUM sides=4 dabs with too little overlap reads as a scatter of
    separate floating kite/diamond cards, not a mass -- the classic "kite"
    failure. The core pass is what prevents that.

    DETAIL pass: n_detail SMALL dabs riding on the core surface (same
    footprint, biased outward+upward) purely for texture + the dark-shadow-
    core -> lime-rim value pop. These must NEVER be relied on to fill volume
    alone -- they sit ON TOP of an already-solid core mass.

    Carries the mandatory ONE asymmetric break: an angular notch recesses
    the CORE silhouette on one side (notch_deg), and an optional single
    outlier core dab is pushed OUT past the rim on roughly the other side
    (outlier_deg) -- a real bush is never a clean circle.

    2026-07-27 fix pass: two changes on top of the above. (1) Dab radii
    across the whole pack were shrunk ~35% and counts nudged up -- the
    coordinator's independent render review confirmed the pack read as
    "rock_pack green" (big faceted boulders), not painterly gouache foliage;
    smaller, more numerous dabs read as granular masses instead of stacked
    rocks, the same fix that saved flower_pack pass 2. (2) EVERY dab (core,
    outlier, detail) now runs through enforce_overlap against `placed`
    before being added -- this is what actually kills floating/disconnected
    fragment triangles, which shrinking radius alone does NOT fix (a small
    isolated dab is still an isolated dab). Returns `placed` so callers that
    need to bridge separate masses (bush_large_01's lobes) can anchor to the
    REAL blob positions instead of guessing from logical centers."""
    if placed is None:
        placed = []
    ox, oy = center

    def dome_radius_at(h_frac, disk_r):
        # Ellipse/bulge cross-section (widest around the lower-middle,
        # tapering at BOTH the very base and the top) instead of a monotonic
        # cone-taper from the base. PASS-3 FIX: a cone-taper (full radius at
        # h=0, straight-line narrowing to a point at h=1) makes same-axis
        # concentric rings of dabs read as a stacked pagoda/wedding-cake no
        # matter how squash or dab count is tuned -- the SHAPE ENVELOPE
        # itself is a cone. Bulging at low-mid height and tapering at both
        # ends reads as a rounded puff instead.
        bulge_h = 0.42
        half_extent = 0.66
        v = (h_frac - bulge_h) / half_extent
        return disk_r * math.sqrt(max(0.08, 1.0 - v * v)) * max(0.0, 1.0 - max(0.0, h_frac - 0.98) * 30.0)

    def notch_scale(ang):
        if notch_deg is None:
            return 1.0
        d = abs(((ang - math.radians(notch_deg) + math.pi) % (2 * math.pi)) - math.pi)
        half_w = math.radians(notch_width) / 2.0
        if d >= half_w:
            return 1.0
        return 1.0 - notch_pull * (1.0 - d / half_w)

    core_disk_r = base_r * core_disk_frac
    for _ in range(n_core):
        t = rng.uniform(0.0, 1.0) ** (1.0 / (1.0 + height_bias))
        z = t * height
        h_frac = z / height if height > 1e-6 else 0.0
        ang = rng.uniform(0.0, 2.0 * math.pi)
        local_r = dome_radius_at(h_frac, core_disk_r) * notch_scale(ang)
        # TRUE uniform-AREA disk draw (sqrt, not a raw linear/pow draw) --
        # PASS-2 FIX: an earlier version biased r toward the CENTER at every
        # height band, which piled every core dab onto the same vertical
        # axis regardless of z -- read as a stacked pagoda/Christmas-tree of
        # tiered cones, not a rounded cloud mass. sqrt(rng()) spreads dabs
        # across the FULL local radius at each height slice instead, so
        # neighbouring dabs overlap sideways as well as vertically.
        r = local_r * math.sqrt(rng.uniform(0.0, 1.0)) * rng.uniform(0.75, 1.0)
        # extra XY jitter INDEPENDENT of the polar (ang, r) placement --
        # breaks up any residual concentric-ring alignment between dabs that
        # happen to land at similar heights, so the mass reads as an uneven
        # organic cluster rather than perfect stacked rings.
        cx = ox + math.cos(ang) * r + rng.uniform(-1.0, 1.0) * core_disk_r * 0.14
        cy = oy + math.sin(ang) * r + rng.uniform(-1.0, 1.0) * core_disk_r * 0.14
        # scale the individual blob's OWN radius down toward the tapered
        # top/edges of the envelope too, not just its placement -- otherwise
        # a full-size blob landing near the narrow top still pokes out as an
        # oversized lump dominating the silhouette on its own.
        envelope_scale = clamp01(0.55 + 0.45 * (local_r / max(1e-4, core_disk_r)))
        dab_r = rng.uniform(*core_radius_range) * envelope_scale
        squash = rng.uniform(*core_squash_range)
        outward = clamp01(r / max(1e-4, core_disk_r))
        bright_t = clamp01(0.28 * h_frac + 0.55 * outward + rng.uniform(-0.06, 0.06))
        # golem_guardian adjacency rule: pull toward nearest already-placed
        # dab (or drop it) rather than trust the raw sampled position -- a
        # dab that lands outside the overlap band reads as a floating kite
        # fragment no matter how good its own shape is.
        pulled = enforce_overlap(placed, (cx, cy, z), dab_r, rng)
        if pulled is None:
            continue
        cx, cy, z = pulled
        add_core_blob(bm, vcol, rng, (cx, cy, z), dab_r, col_dark, col_light,
                      squash_z=squash, bright_bias=bright_t, jitter=0.16)
        placed.append(((cx, cy, z), dab_r))

    if outlier_deg is not None:
        ang = math.radians(outlier_deg)
        r_out = (outlier_radius if outlier_radius is not None else core_disk_r) * outlier_scale
        cx = ox + math.cos(ang) * r_out
        cy = oy + math.sin(ang) * r_out
        z = height * outlier_height_frac
        dab_r = core_radius_range[0] * 0.85
        # the outlier is the ONE deliberate asymmetric break -- still must
        # stay anchored to the mass (not float free), just permitted to sit
        # near the far edge of the overlap band instead of buried inside it.
        pulled = enforce_overlap(placed, (cx, cy, z), dab_r, rng, min_frac=0.55, max_frac=0.65)
        if pulled is not None:
            cx, cy, z = pulled
            add_core_blob(bm, vcol, rng, (cx, cy, z), dab_r, col_dark, col_light,
                          squash_z=0.9, bright_bias=0.42, jitter=0.16)
            placed.append(((cx, cy, z), dab_r))

    for _ in range(n_detail):
        # same height distribution as the CORE pass (not a top-biased one) --
        # a top-biased detail pass combined with the ellipse envelope's
        # already-thin high-h_frac radius produced a few tiny dabs that
        # landed outside where the actual (randomly jittered) core blobs
        # ended up, reading as small stray floating triangles.
        t = rng.uniform(0.0, 1.0) ** (1.0 / (1.0 + height_bias))
        z = t * height
        h_frac = z / height if height > 1e-6 else 0.0
        ang = rng.uniform(0.0, 2.0 * math.pi)
        # pulled slightly INSIDE the nominal envelope (0.95x, not pushed out
        # past it) so detail dabs sit embedded in/on the core mass instead
        # of floating just past its real (jittered) surface.
        local_r = dome_radius_at(h_frac, core_disk_r) * notch_scale(ang) * 0.95
        r = local_r * math.sqrt(rng.uniform(0.30, 1.0))
        cx = ox + math.cos(ang) * r + rng.uniform(-1.0, 1.0) * core_disk_r * 0.05
        cy = oy + math.sin(ang) * r + rng.uniform(-1.0, 1.0) * core_disk_r * 0.05
        dab_r = rng.uniform(*detail_radius_range)
        squash = rng.uniform(*detail_squash_range)
        outward = clamp01(r / max(1e-4, core_disk_r))
        bright_t = clamp01(0.35 * h_frac + 0.65 * outward + rng.uniform(-0.05, 0.10))
        col_edge = lerp3(col_dark, col_light, bright_t * 0.65)
        col_core = lerp3(col_dark, col_light, clamp01(bright_t * 1.15 + 0.15))
        dz = z + dab_r * squash * 0.25
        pulled = enforce_overlap(placed, (cx, cy, dz), dab_r, rng)
        if pulled is None:
            continue
        cx, cy, dz = pulled
        add_blob_dab(bm, vcol, rng, (cx, cy, dz), dab_r,
                     col_edge, col_core, squash=squash, sides=detail_sides, jitter=0.20)
        placed.append(((cx, cy, dz), dab_r))

    return placed


def finalize_mesh(name, bm, vcol):
    # 2026-07-27 fix pass: many overlapping closed blobs share near-coincident
    # verts at their intersections -- a plausible cause of the dark/black
    # triangle artifact spotted on bush_dry_01 (z-fighting / degenerate faces
    # at an overlap seam, not fixable by recalc_face_normals alone since that
    # only re-orients existing faces, it doesn't merge geometry). Weld
    # near-coincident verts BEFORE recalculating normals on the final join.
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0006)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()
    col_layer = bm.loops.layers.float_color.new("Col")
    for f in bm.faces:
        for loop in f.loops:
            c = vcol.get(loop.vert, (0.3, 0.3, 0.3))
            loop[col_layer] = (c[0], c[1], c[2], 1.0)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.validate(verbose=False)
    for p in me.polygons:
        p.use_smooth = False  # flat-shaded -- DP_ToonGrounded family signature
    obj = bpy.data.objects.new(name, me)
    scene.collection.objects.link(obj)
    return obj


def count_tris(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


# =============================================================================
# MATERIAL -- Attribute("Col") drives Base Color, no texture/UV needed. Single
# non-emissive slot for the whole pack (task default: bush_flowering carries
# NO emission; the glTF emissiveFactor-is-one-constant-per-material gotcha
# only matters if a future variant adds glow, so it's just noted, not wired).
# =============================================================================
def make_vcol_material(name, roughness=0.94):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Roughness"].default_value = roughness
    spec = n.inputs.get("Specular IOR Level")
    if spec is not None:
        spec.default_value = 0.05
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    nt.links.new(attr.outputs["Color"], n.inputs["Base Color"])
    m.use_backface_culling = False
    return m


# =============================================================================
# PALETTES (linear-ish 0-1 tones, kept under 1.0 -- golem/flower convention)
# =============================================================================
ROUND_DARK = (0.022, 0.070, 0.028)
ROUND_LIGHT = (0.50, 0.70, 0.20)
ROUND_HILITE = (0.66, 0.86, 0.30)      # extra rim-highlight accent dabs

LARGE_DARK = (0.020, 0.060, 0.032)
LARGE_LIGHT = (0.36, 0.54, 0.18)

FLOWERING_DARK = (0.028, 0.078, 0.032)
FLOWERING_LIGHT = (0.42, 0.60, 0.20)
FLOWER_EDGE = (0.52, 0.11, 0.24)
FLOWER_CORE = (0.95, 0.56, 0.64)

LOW_DARK = (0.032, 0.075, 0.040)
LOW_LIGHT = (0.40, 0.56, 0.22)

DRY_DARK = (0.155, 0.115, 0.055)
DRY_LIGHT = (0.74, 0.58, 0.20)
TWIG_DARK = (0.085, 0.058, 0.032)
TWIG_MID = (0.30, 0.20, 0.10)


def build_lobe_mass(bm, vcol, rng, lobes, n_core, n_detail, col_dark, col_light,
                     ground_clamp=0.02, use_nucleus=True, nucleus_frac=0.75,
                     core_dist_range=(0.45, 0.90), detail_dist_range=(0.45, 0.95)):
    """UNION-OF-ENVELOPE-SPHERES canopy builder (2026-07-27 pass-2 rebuild
    recipe -- replaces per-lobe add_canopy_mass()+bridge_lobes() for masses
    that need a fat, rounded, genuinely-fused silhouette). The pass-1
    bush_large fix (independent per-lobe dome masses stitched together
    afterward with bridge_lobes) DID kill the floating-island defect but
    topped out at a thin "caterpillar/noodle" chain -- connected, but never
    reads as one full bush, because each lobe's own dome-taper envelope is
    still a separate silhouette underneath the bridge.

    This is a structurally different recipe: `lobes` is a list of
    ((cx,cy,cz), envelope_radius, dab_radius_range) tuples for FIXED lobe
    centers, positioned UP FRONT so every pair's center separation is
    already < 0.6x the sum of their envelope radii (guaranteed heavy
    overlap by construction -- no bridge pass needed, there's no seam to
    bridge). Dabs are then scattered INSIDE the union of those envelope
    spheres: position = lobe_center + random_direction * (envelope_radius *
    uniform(0.55, 0.95)), lobe picked per-dab weighted by volume (radius^3)
    so the big lobe gets proportionally more dabs. Direction is z-biased
    toward the lower hemisphere (elev in [-1.0, 0.5]) for the bottom-
    weighted silhouette the brief requires. Lobe centers are deliberately
    positioned with their bottom pole slightly below Z=0 -- `ground_clamp`
    is what turns that into a flat, dense, sitting-on-the-ground base
    instead of a floating sphere, instead of a separate dome-taper formula.
    PASS-2a FIX (tried, wrong): ran every dab through enforce_overlap
    against the GLOBAL placed list. That was actively harmful:
    enforce_overlap checks the nearest ALREADY-placed dab regardless of
    which lobe it belongs to, and early in generation a lobe with few dabs
    so far has no nearby neighbor except one in a DIFFERENT (overlapping-
    by-construction, but not necessarily dab-close) lobe -- tripped the
    "give up, drop it" branch constantly. Confirmed: bush_large tris
    cratered from an expected ~380 to 170 (~40% of dabs silently dropped).

    PASS-2b FIX (also tried, also wrong): removed enforce_overlap entirely,
    trusting that lobe-ENVELOPE overlap (guaranteed at design time) would
    be enough. It is NOT: envelope overlap only guarantees the abstract
    lobe SPHERES overlap, not that individual dabs sampled independently at
    random angles within a lobe (there are only ~5-8 per lobe at this tri
    budget) happen to land near each other -- confirmed: the render showed
    a scattered debris field, worse-looking than pass-1's connected-but-
    thin chain.

    FIX: keep enforce_overlap, but scope it PER LOBE (a separate `placed`
    list per lobe index) instead of one global list. This restores
    intra-lobe cohesion (a dab must land near an already-placed dab from
    ITS OWN lobe) without the false cross-lobe drops -- inter-lobe
    connectivity is still handled by the guaranteed envelope overlap, which
    is real (there IS a physical region where two lobes' 0.55-0.95x-radius
    shells intersect) even though it doesn't extend down to arbitrary
    individual dabs. Returns the merged placed list so callers needing
    surface-projected accents (flowers) or anchored twigs can use the REAL
    blob positions.

    PASS-2c FIX (2026-07-27, this round): coordinator's render review found
    large_01 reading as a hollow "croissant" arc (visible gap through the
    middle) plus one stray blob, and dry_01 similarly holed -- root cause:
    the whole recipe above only ever populates the SURFACE SHELL of each
    envelope (dist = R*uniform(0.55,0.95), i.e. always near the outer
    radius), so the interior is empty and a sparse shell reads as a thin
    arc, not a solid mass. FIX: seed each lobe with a NUCLEUS blob first,
    dead center, radius = envelope_radius*0.75 -- with lobe centers already
    guaranteed <0.6x-summed-envelope-radii apart, the nuclei (0.75x radius
    each) overlap each other even more reliably, so a solid connected core
    exists before a single decorative dab is placed. Decorative dabs then
    sample down to 0.45x (was 0.55x) so some of them land BETWEEN the
    nucleus and the outer shell instead of only ever right at the surface.

    `use_nucleus`/`nucleus_frac`/`core_dist_range`/`detail_dist_range` are
    exposed as params (not hardcoded) specifically so bush_flowering_01 --
    APPROVED and frozen by the coordinator on the pre-nucleus recipe -- can
    keep calling this shared function with its EXACT original values
    instead of silently inheriting a budget-breaking change made for
    bush_large/bush_dry."""
    weights = [r ** 3 for (_, r, _) in lobes]
    total_w = sum(weights)
    per_lobe_placed = [[] for _ in lobes]

    if use_nucleus:
        for idx, ((cx0, cy0, cz0), R, rad_range) in enumerate(lobes):
            ncz = max(ground_clamp, cz0)
            add_core_blob(bm, vcol, rng, (cx0, cy0, ncz), R * nucleus_frac, col_dark, col_light,
                          squash_z=0.90, bright_bias=0.30, jitter=0.10)
            per_lobe_placed[idx].append(((cx0, cy0, ncz), R * nucleus_frac))

    def pick_lobe():
        t = rng.uniform(0.0, total_w)
        acc = 0.0
        for i, w in enumerate(weights):
            acc += w
            if t <= acc:
                return i
        return len(lobes) - 1

    def sample_dir():
        az = rng.uniform(0.0, 2.0 * math.pi)
        elev = rng.uniform(-1.0, 0.5)
        horiz = math.sqrt(max(0.0, 1.0 - elev * elev))
        return math.cos(az) * horiz, math.sin(az) * horiz, elev

    for _ in range(n_core):
        idx = pick_lobe()
        (cx0, cy0, cz0), R, rad_range = lobes[idx]
        dx, dy, dz = sample_dir()
        dist = R * rng.uniform(*core_dist_range)
        cx = cx0 + dx * dist
        cy = cy0 + dy * dist
        cz = max(ground_clamp, cz0 + dz * dist)
        dab_r = rng.uniform(*rad_range)
        squash = rng.uniform(0.85, 1.05)
        bright_t = clamp01(0.35 + 0.35 * (dist / R) + rng.uniform(-0.08, 0.08))
        pulled = enforce_overlap(per_lobe_placed[idx], (cx, cy, cz), dab_r, rng)
        if pulled is None:
            continue
        cx, cy, cz = pulled
        add_core_blob(bm, vcol, rng, (cx, cy, cz), dab_r, col_dark, col_light,
                      squash_z=squash, bright_bias=bright_t, jitter=0.16)
        per_lobe_placed[idx].append(((cx, cy, cz), dab_r))

    for _ in range(n_detail):
        idx = pick_lobe()
        (cx0, cy0, cz0), R, rad_range = lobes[idx]
        dx, dy, dz = sample_dir()
        dist = R * rng.uniform(*detail_dist_range)
        cx = cx0 + dx * dist
        cy = cy0 + dy * dist
        cz = max(ground_clamp, cz0 + dz * dist)
        dab_r = rng.uniform(rad_range[0] * 0.45, rad_range[1] * 0.55)
        bright_t = clamp01(0.40 + 0.45 * (dist / R) + rng.uniform(-0.06, 0.10))
        col_edge = lerp3(col_dark, col_light, bright_t * 0.65)
        col_core = lerp3(col_dark, col_light, clamp01(bright_t * 1.15 + 0.15))
        pulled = enforce_overlap(per_lobe_placed[idx], (cx, cy, cz), dab_r, rng)
        if pulled is None:
            continue
        cx, cy, cz = pulled
        add_blob_dab(bm, vcol, rng, (cx, cy, cz), dab_r, col_edge, col_core,
                     squash=rng.uniform(0.65, 0.85), sides=5, jitter=0.20)
        per_lobe_placed[idx].append(((cx, cy, cz), dab_r))

    # SAFETY STITCH: per-lobe enforce_overlap fixes intra-lobe cohesion, and
    # the envelope centers are guaranteed to overlap as ABSTRACT spheres --
    # but that guarantee does NOT propagate down to individual dabs (with
    # only ~5-8 independently-angle-sampled dabs per lobe, one lobe can
    # easily land its whole cluster on the side FACING AWAY from its
    # overlap partner, reading as a genuine floating island even though the
    # envelope spheres do overlap on paper -- confirmed empirically on
    # bush_large's smallest/sparsest lobe). Fix: for every pair of lobes,
    # find their two CLOSEST real placed dabs; if that gap is still wider
    # than typical overlap distance, drop ONE bridging blob at the
    # midpoint. Cheap (lobes are already close by design -- this is a
    # single stitch, not a chain) and only fires when actually needed.
    for i in range(len(lobes)):
        for j in range(i + 1, len(lobes)):
            list_a, list_b = per_lobe_placed[i], per_lobe_placed[j]
            if not list_a or not list_b:
                continue
            best = None
            best_d = None
            for pa, ra in list_a:
                for pb, rb in list_b:
                    d = math.sqrt(sum((pa[k] - pb[k]) ** 2 for k in range(3)))
                    if best_d is None or d < best_d:
                        best_d, best = d, (pa, ra, pb, rb)
            pa, ra, pb, rb = best
            if best_d > 0.65 * (ra + rb):
                mx, my, mz = (pa[0] + pb[0]) * 0.5, (pa[1] + pb[1]) * 0.5, (pa[2] + pb[2]) * 0.5
                r = (ra + rb) * 0.5 * 1.1
                add_core_blob(bm, vcol, rng, (mx, my, mz), r, col_dark, col_light,
                              squash_z=0.85, bright_bias=0.32, jitter=0.16)
                per_lobe_placed[i].append(((mx, my, mz), r))

    placed = [p for lobe_list in per_lobe_placed for p in lobe_list]
    return placed


# =============================================================================
# VARIANT BUILDERS
# =============================================================================
def build_bush_round(rng):
    """1. Classic round bush -- dense overlapping core mass, widest value
    range (near-black shadow core -> punchy lime rim)."""
    bm = bmesh.new()
    vcol = {}
    placed = add_canopy_mass(bm, vcol, rng, base_r=0.34, height=0.58,
                     col_dark=ROUND_DARK, col_light=ROUND_LIGHT,
                     n_core=11, core_radius_range=(0.098, 0.130),
                     core_squash_range=(0.85, 1.05), core_sides=6,
                     core_disk_frac=0.60, core_center_bias=0.30,
                     n_detail=12, detail_radius_range=(0.029, 0.044),
                     detail_squash_range=(0.65, 0.85), detail_sides=5,
                     dome_power=1.3, height_bias=0.55,
                     notch_deg=205, notch_width=75, notch_pull=0.55,
                     outlier_deg=35, outlier_scale=1.30, outlier_height_frac=0.30)
    # rim-highlight accent pass: a handful of near-pure-lime dabs biased to
    # the outer/upper shell only -- pushes the "lime-bright rim" the brief
    # asks for beyond the base gradient, no 2nd material needed. Radius
    # shrunk with the rest of the pack (2026-07-27); each still runs through
    # enforce_overlap so a highlight can't land as an isolated floating chip.
    round_core_disk_r = 0.34 * 0.60
    for _ in range(6):
        ang = rng.uniform(0.0, 2.0 * math.pi)
        h_frac = rng.uniform(0.35, 1.0)
        z = h_frac * 0.58
        v = (h_frac - 0.42) / 0.66
        local_r = round_core_disk_r * math.sqrt(max(0.08, 1.0 - v * v))
        r = local_r * 1.12 * rng.uniform(0.85, 1.05)
        cx, cy = math.cos(ang) * r, math.sin(ang) * r
        dab_r = rng.uniform(0.021, 0.033)
        # tighter band than the default -- these are tiny accent chips, they
        # need to sit noticeably closer to their neighbor than a full-size
        # core dab does or their small rendered footprint doesn't visually
        # reach the neighboring mesh even when the center-distance check
        # nominally passes.
        pulled = enforce_overlap(placed, (cx, cy, z + dab_r * 0.3), dab_r, rng,
                                  min_frac=0.35, max_frac=0.48)
        if pulled is None:
            continue
        cx, cy, hz = pulled
        col_edge = lerp3(ROUND_LIGHT, ROUND_HILITE, 0.4)
        add_blob_dab(bm, vcol, rng, (cx, cy, hz), dab_r, col_edge,
                     ROUND_HILITE, squash=0.55, sides=5, jitter=0.20)
        placed.append(((cx, cy, hz), dab_r))
    return finalize_mesh("bush_round_01", bm, vcol)


def build_bush_large(rng):
    """2. Large asymmetric mass -- frames a clearing edge.

    2026-07-27 PASS-2 REBUILD (not a patch): pass-1's bridge_lobes() fix did
    kill the floating-island defect, but the coordinator's render review
    called the result correctly -- a thin "caterpillar/noodle" chain of
    similar-size blobs, connected but never reading as one fat rounded
    bush. Root cause: 3 independent dome-taper masses stitched together
    after the fact are still, underneath the stitching, 3 separate thin
    silhouettes. Switched to build_lobe_mass()'s union-of-envelope-spheres
    recipe: 3 FIXED lobe centers forming a flattened triangle, already
    overlapping by construction (each pair's center separation verified
    <0.6x the sum of their envelope radii at design time -- see the numbers
    below), then dabs scattered directly inside the union volume instead of
    inside 3 separate per-lobe envelopes.

    2026-07-27 PASS-2c FIX: coordinator caught this still reading as a
    hollow "croissant" (surface-only shell, empty interior) at only 310/450
    tris -- budget was sitting unused. build_lobe_mass now seeds a NUCLEUS
    blob per lobe first (kills the hollow-interior defect structurally),
    and counts bumped here to spend the available budget on density
    (420-450 target) instead of leaving it on the table."""
    bm = bmesh.new()
    vcol = {}
    # flattened-triangle lobe centers -- pairwise center-separation /
    # (r_a+r_b) checked at design time: L0-L1 = 0.444/0.90 = 0.49x,
    # L0-L2 = 0.377/0.85 = 0.44x, L1-L2 = 0.424/0.75 = 0.56x -- all < 0.6x.
    lobes = [
        ((0.0, 0.0, 0.42), 0.50, (0.100, 0.135)),
        ((0.42, 0.12, 0.34), 0.40, (0.085, 0.115)),
        ((0.24, -0.26, 0.29), 0.35, (0.075, 0.100)),
    ]
    build_lobe_mass(bm, vcol, rng, lobes, n_core=14, n_detail=11,
                     col_dark=LARGE_DARK, col_light=LARGE_LIGHT)
    return finalize_mesh("bush_large_01", bm, vcol)


def build_bush_flowering(rng):
    """3. Round-bush-style canopy + star-dab flower accents, NO emission.

    2026-07-27 PASS-2 REBUILD: the dome-taper canopy (base_r=0.32,
    height=0.54) read as a tall, thin "scrawny sapling" -- coordinator
    measured it at ~0.7:1 width:height against a ~1.3:1 target. Switched to
    build_lobe_mass()'s 2-lobe union-of-envelopes recipe (same technique as
    the bush_large rebuild) with LOW, WIDE lobe centers: lowers the center
    of mass and pushes the silhouette wide instead of tall.

    2026-07-27 PASS-2c NOTE: this variant is APPROVED and FROZEN by the
    coordinator as of the pre-nucleus build_lobe_mass recipe (402 tris).
    The nucleus-blob + lowered-floor fix added to build_lobe_mass for
    bush_large/bush_dry's hollow-interior defect is OPT-IN via parameters
    specifically so this call can keep passing the ORIGINAL values and
    reproduce the exact approved look/budget -- do not remove these
    explicit overrides even if build_lobe_mass's defaults change again."""
    bm = bmesh.new()
    vcol = {}
    lobes = [
        ((-0.11, 0.0, 0.18), 0.25, (0.075, 0.100)),
        ((0.12, 0.04, 0.15), 0.21, (0.065, 0.088)),
    ]
    placed = build_lobe_mass(bm, vcol, rng, lobes, n_core=9, n_detail=6,
                              col_dark=FLOWERING_DARK, col_light=FLOWERING_LIGHT,
                              use_nucleus=False,
                              core_dist_range=(0.55, 0.95),
                              detail_dist_range=(0.60, 1.0))
    # 2026-07-27 fix pass, ROOT-CAUSE rewrite: the previous idealized-
    # envelope placement (a separate bulge-profile formula trying to guess
    # where the canopy surface is) STILL produced flowers reading as
    # disconnected floating shards, because an idealized formula never
    # exactly matches the real jittered blob positions. Fix per coordinator
    # spec: project flowers directly onto the ACTUAL placed canopy blobs --
    # position = nearest_blob_center + normalized_direction * (blob_radius *
    # 0.95). This guarantees every flower sits embedded at a real mesh
    # surface, not a hypothetical one. Direction is biased to the blob's
    # upper hemisphere (elev 0.15-0.95) so flowers don't spawn facing into
    # the ground or on a blob's inner/hidden side; candidates are sorted by
    # height and the bottom 20% dropped so flowers favor the visually
    # prominent, actually-lit upper canopy instead of the shaded base.
    candidates = sorted(placed, key=lambda p: p[0][2])
    candidates = candidates[max(1, len(candidates) // 5):]
    for _ in range(12):
        (bx, by, bz), br = candidates[rng.randrange(len(candidates))]
        ang = rng.uniform(0.0, 2.0 * math.pi)
        elev = rng.uniform(0.15, 0.95)
        horiz = math.sqrt(max(0.0, 1.0 - elev * elev))
        dx, dy, dz = math.cos(ang) * horiz, math.sin(ang) * horiz, elev
        cx = bx + dx * br * 0.95
        cy = by + dy * br * 0.95
        cz = bz + dz * br * 0.95
        dab_r = rng.uniform(0.028, 0.042)
        add_star_dab(bm, vcol, rng, (cx, cy, cz), dab_r,
                     FLOWER_EDGE, FLOWER_CORE, points=4, height=0.60)
    return finalize_mesh("bush_flowering_01", bm, vcol)


def build_bush_low(rng):
    """4. Low, wide, ground-hugging/creeping mat -- full wide coverage,
    minimal height taper (already low, doesn't need a tall dome)."""
    bm = bmesh.new()
    vcol = {}
    add_canopy_mass(bm, vcol, rng, base_r=0.52, height=0.20,
                     col_dark=LOW_DARK, col_light=LOW_LIGHT,
                     n_core=13, core_radius_range=(0.100, 0.133),
                     core_squash_range=(0.30, 0.42), core_sides=6,
                     core_disk_frac=0.65, core_center_bias=0.30,
                     n_detail=9, detail_radius_range=(0.0325, 0.04875),
                     detail_squash_range=(0.28, 0.40), detail_sides=5,
                     dome_power=0.8, height_bias=0.85,
                     notch_deg=165, notch_width=80, notch_pull=0.55,
                     outlier_deg=350, outlier_scale=1.25, outlier_height_frac=0.4)
    return finalize_mesh("bush_low_01", bm, vcol)


def build_bush_dry(rng):
    """5. Dry/golden bush -- sparse-but-solid canopy + visible bare twigs
    poking through it.

    2026-07-27 pass-2 fix: twigs previously spawned with an independent
    ground-level base position uncorrelated with where the canopy blobs
    actually ended up -- several rendered as bare wires floating beside the
    mass instead of growing out of it. Fix: anchor each twig ROOT inside an
    actual canopy blob (root embedded >=30% of that blob's radius deep,
    checked against the blob's real sphere-surface height at the root's own
    (x,y) position, not a guessed offset), and size total twig rise so that
    AT MOST ~40% of its length pokes past the canopy surface (rise derived
    from the actual vertical distance-to-surface / a sampled 60-75% embed
    fraction, not picked independently of where the root sits). Candidates
    whose required rise to hit that ratio would be unnaturally tall (root
    landed too deep inside a big blob) are DROPPED rather than forced --
    fewer, better-anchored twigs beats more, worse ones.

    2026-07-27 PASS-2c: canopy switched from add_canopy_mass's dome-taper
    to build_lobe_mass's union-of-envelope-spheres recipe (2 fixed, nucleus-
    seeded lobes) -- same hollow-interior defect the coordinator caught on
    bush_large showed up here too. Twig anchoring logic below is unchanged;
    it only needs `placed` to be a real list of ((x,y,z), radius) blobs,
    which build_lobe_mass still returns."""
    bm = bmesh.new()
    vcol = {}
    lobes = [
        ((-0.08, 0.0, 0.19), 0.22, (0.068, 0.092)),
        ((0.10, 0.03, 0.16), 0.19, (0.058, 0.078)),
    ]
    placed = build_lobe_mass(bm, vcol, rng, lobes, n_core=10, n_detail=8,
                              col_dark=DRY_DARK, col_light=DRY_LIGHT)

    # bias candidates toward the upper/outer 2/3 of blobs -- a twig rooted
    # deep in the shaded base would need an absurdly tall rise to poke
    # through everything above it, and reads poorly even if geometrically
    # "valid".
    candidates = sorted(placed, key=lambda p: p[0][2])
    candidates = candidates[len(candidates) // 3:]
    tips = []
    attempts = 0
    while len(tips) < 6 and attempts < 40:
        attempts += 1
        (bx, by, bz), R = candidates[rng.randrange(len(candidates))]
        ang = rng.uniform(0.0, 2.0 * math.pi)
        elev = rng.uniform(0.10, 0.90)
        horiz = math.sqrt(max(0.0, 1.0 - elev * elev))
        depth_frac = rng.uniform(0.30, 0.75)          # >=30% depth, per spec
        dist_from_center = (1.0 - depth_frac) * R
        rx, ry, rz = math.cos(ang) * horiz, math.sin(ang) * horiz, elev
        root_x = bx + rx * dist_from_center
        root_y = by + ry * dist_from_center
        root_z = bz + rz * dist_from_center
        horiz_off = math.sqrt((root_x - bx) ** 2 + (root_y - by) ** 2)
        if horiz_off >= R:
            continue
        # real vertical distance from root to THIS blob's sphere surface at
        # the root's own (x,y) -- not a flat guess.
        top_local = bz + math.sqrt(max(0.0, R * R - horiz_off * horiz_off))
        to_surface = max(0.01, top_local - root_z)
        embed_frac = rng.uniform(0.60, 0.75)           # >=60% embedded -> <=40% poking
        total_rise = to_surface / embed_frac
        if total_rise > 0.22:
            continue  # would need an unnaturally tall twig -- drop it, don't force it
        lean = rng.uniform(0.015, 0.035)
        width_base = rng.uniform(0.010, 0.015)
        tip = add_twig(bm, vcol, rng, (root_x, root_y, max(0.0, root_z)), lean, ang,
                       total_rise, width_base, TWIG_DARK, TWIG_MID, segments=3, bend=0.4)
        tips.append((tip, ang))
    for tip, ang in tips[:3]:
        fork_ang = ang + rng.uniform(-0.8, 0.8)
        add_twig(bm, vcol, rng, (tip.x, tip.y, tip.z), rng.uniform(0.020, 0.035),
                 fork_ang, rng.uniform(0.025, 0.045), rng.uniform(0.006, 0.009),
                 TWIG_DARK, TWIG_MID, segments=2, bend=0.3)
    return finalize_mesh("bush_dry_01", bm, vcol)


# =============================================================================
# BUILD ALL VARIANTS
# =============================================================================
BUILDERS = [
    ("bush_round_01", build_bush_round),
    ("bush_large_01", build_bush_large),
    ("bush_flowering_01", build_bush_flowering),
    ("bush_low_01", build_bush_low),
    ("bush_dry_01", build_bush_dry),
]

mat_bush = make_vcol_material("bush_pack_mat")

objects = []
print(f"\n[bush_pack] seed={SEED}\n")
for i, (name, fn) in enumerate(BUILDERS):
    rng = random.Random(SEED * 1000 + i * 131)
    obj = fn(rng)
    obj.data.materials.append(mat_bush)
    tris = count_tris(obj)
    objects.append(obj)
    status = "OK" if tris <= 450 else "!! OVER 450-TRI BUDGET !!"
    print(f"[bush_pack] built {name}  tris={tris}  {status}")

# ---------- export: all 5 objects still at local origin (0,0,0) -- showcase
# layout offsets are applied AFTER export, same discipline as flower_pack. ----------
bpy.ops.object.select_all(action='DESELECT')
for o in objects:
    o.select_set(True)
export_kwargs = dict(
    filepath=os.path.join(ASSET_DIR, "bush_pack.glb"),
    use_selection=True,
    export_format='GLB',
    export_apply=True,
    export_animations=False,
    export_cameras=False,
    export_lights=False,
)
try:
    bpy.ops.export_scene.gltf(**export_kwargs, export_yup=True)
except TypeError:
    bpy.ops.export_scene.gltf(**export_kwargs)
print(f"[bush_pack] EXPORTED -> {os.path.join(ASSET_DIR, 'bush_pack.glb')}")

for o in objects:
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    variant_kwargs = dict(
        filepath=os.path.join(ASSET_DIR, f"env_{o.name}.glb"),
        use_selection=True,
        export_format='GLB',
        export_apply=True,
        export_animations=False,
        export_cameras=False,
        export_lights=False,
    )
    try:
        bpy.ops.export_scene.gltf(**variant_kwargs, export_yup=True)
    except TypeError:
        bpy.ops.export_scene.gltf(**variant_kwargs)
print(f"[bush_pack] per-variant GLBs exported -> {ASSET_DIR}")

# =============================================================================
# SHOWCASE RENDER -- ficha-style: sunlit-meadow stage, labels above each bush,
# plus a macro close-up of bush_round_01 judged at in-game viewing distance.
# =============================================================================
SPACING = 1.7
for i, obj in enumerate(objects):
    obj.location = ((i - (len(objects) - 1) / 2.0) * SPACING, 0.0, 0.0)

ground_mat = bpy.data.materials.new("bush_ground_mat")
ground_mat.use_nodes = True
gn = ground_mat.node_tree.nodes["Principled BSDF"]
gn.inputs["Base Color"].default_value = (0.10, 0.145, 0.06, 1.0)
gn.inputs["Roughness"].default_value = 0.95
groundlib.build_ground(scene, size=6.0, subdiv=40, roughness=0.10, scale=0.5,
                        material=ground_mat, name="bush_showcase_ground")

world = bpy.data.worlds.new("ficha")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.42, 0.56, 0.68, 1.0)


def add_light(name, loc, energy, size):
    ld = bpy.data.lights.new(name, type='AREA')
    ld.energy = energy
    ld.size = size
    lo = bpy.data.objects.new(name, ld)
    lo.location = loc
    scene.collection.objects.link(lo)
    lo.rotation_mode = 'QUATERNION'
    lo.rotation_quaternion = lo.location.to_track_quat('Z', 'Y')
    return lo


add_light("key", (-2.0, -6.0, 4.2), 240, 3.2)
add_light("fill", (3.6, -4.0, 2.2), 60, 3.0)
add_light("rim", (0.5, 4.2, 2.8), 160, 2.6)

target = bpy.data.objects.new("target", None)
target.location = (0.0, 0.0, 0.30)
scene.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 42
cam = bpy.data.objects.new("cam", cd)
cam.location = (0.0, -8.6, 2.1)
scene.collection.objects.link(cam)
cam.constraints.new(type='TRACK_TO').target = target
scene.camera = cam

# ---------- labels: z>0, align_y='BOTTOM' so text grows UPWARD from just
# above the ground plane (flower_pack gotcha -- a flat opaque ground fully
# occludes anything under its own z=0 surface from an elevated camera, and
# text hanging DOWN from a z<=0 origin renders invisible/clipped). ----------
LABELS = {
    "bush_round_01": "round",
    "bush_large_01": "large",
    "bush_flowering_01": "flowering",
    "bush_low_01": "low",
    "bush_dry_01": "dry",
}
label_mat = bpy.data.materials.new("label_mat")
label_mat.use_nodes = True
lm_n = label_mat.node_tree.nodes["Principled BSDF"]
lm_n.inputs["Base Color"].default_value = (0.98, 0.98, 0.95, 1.0)
lm_n.inputs["Roughness"].default_value = 0.55

label_objs = []
for obj in objects:
    bpy.ops.object.text_add(location=(obj.location.x, -0.55, 0.02))
    txt = bpy.context.object
    txt.data.body = LABELS[obj.name]
    txt.data.size = 0.11
    txt.data.align_x = 'CENTER'
    txt.data.align_y = 'BOTTOM'
    txt.data.extrude = 0.006
    txt.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    txt.data.materials.append(label_mat)
    label_objs.append(txt)

try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.eevee.taa_render_samples = 64
scene.view_settings.view_transform = 'Standard'
scene.render.resolution_x = 1920
scene.render.resolution_y = 1080
scene.render.filepath = os.path.join(REN_DIR, "bush_showcase.png")
bpy.ops.render.render(write_still=True)
print("[bush_pack] RENDERED -> renders/bush_showcase.png")

# ---------- macro close-up of bush_round_01, at the tight distance a
# first-person player would actually see a bush at (lesson from flower_pack:
# a wide ficha shot hides oversized/blown-out dabs that only show up in a
# tight crop). Hide the other 4 bushes + labels for a clean isolated crop. ----------
for obj in objects[1:]:
    obj.hide_render = True
for lbl in label_objs:
    lbl.hide_render = True

round_obj = objects[0]  # bush_round_01
macro_target = bpy.data.objects.new("macro_target", None)
macro_target.location = (round_obj.location.x, 0.0, 0.30)
scene.collection.objects.link(macro_target)
macro_cam_data = bpy.data.cameras.new("macro_cam")
macro_cam_data.lens = 32
macro_cam = bpy.data.objects.new("macro_cam", macro_cam_data)
macro_cam.location = (round_obj.location.x - 0.55, -1.05, 0.85)
scene.collection.objects.link(macro_cam)
macro_cam.constraints.new(type='TRACK_TO').target = macro_target
scene.camera = macro_cam

scene.render.resolution_x = 1200
scene.render.resolution_y = 1200
scene.render.filepath = os.path.join(REN_DIR, "bush_showcase_macro.png")
bpy.ops.render.render(write_still=True)
print("[bush_pack] RENDERED -> renders/bush_showcase_macro.png")

# ---------- macro close-ups of bush_large_01 and bush_flowering_01,
# specifically requested by the coordinator for the pass-2 REBUILD (lobe-
# envelope silhouette + widened flowering canopy) -- judged at in-game
# viewing distance, not just the wide ficha shot. ----------
def render_solo_macro(obj_index, cam_offset, out_name):
    target_obj = objects[obj_index]
    for o in objects:
        o.hide_render = (o is not target_obj)
    mt = bpy.data.objects.new(f"{out_name}_target", None)
    mt.location = (target_obj.location.x, 0.0, 0.30)
    scene.collection.objects.link(mt)
    cd_ = bpy.data.cameras.new(f"{out_name}_cam")
    cd_.lens = 32
    cam_ = bpy.data.objects.new(f"{out_name}_cam", cd_)
    cam_.location = (target_obj.location.x + cam_offset[0], cam_offset[1], cam_offset[2])
    scene.collection.objects.link(cam_)
    cam_.constraints.new(type='TRACK_TO').target = mt
    scene.camera = cam_
    scene.render.filepath = os.path.join(REN_DIR, out_name)
    bpy.ops.render.render(write_still=True)
    print(f"[bush_pack] RENDERED -> renders/{out_name}")


render_solo_macro(1, (-0.75, -1.55, 0.95), "bush_showcase_macro_large.png")
render_solo_macro(2, (-0.55, -1.05, 0.85), "bush_showcase_macro_flowering.png")

for obj in objects:
    obj.hide_render = False

# ---------- second macro close-up: bush_dry_01, specifically to verify the
# 2026-07-27 fix-pass item 5 (a dark/black triangle spotted mid-mass, fixed
# via remove_doubles-before-recalc in finalize_mesh + a lighter DRY_DARK
# floor) actually disappeared, instead of trusting the wide ficha shot where
# a small dark artifact could easily go unnoticed. ----------
dry_obj = objects[4]  # bush_dry_01
dry_obj.hide_render = False
for obj in objects:
    if obj is not dry_obj:
        obj.hide_render = True
dry_macro_target = bpy.data.objects.new("dry_macro_target", None)
dry_macro_target.location = (dry_obj.location.x, 0.0, 0.30)
scene.collection.objects.link(dry_macro_target)
dry_macro_cam_data = bpy.data.cameras.new("dry_macro_cam")
dry_macro_cam_data.lens = 32
dry_macro_cam = bpy.data.objects.new("dry_macro_cam", dry_macro_cam_data)
dry_macro_cam.location = (dry_obj.location.x - 0.55, -1.05, 0.85)
scene.collection.objects.link(dry_macro_cam)
dry_macro_cam.constraints.new(type='TRACK_TO').target = dry_macro_target
scene.camera = dry_macro_cam
scene.render.filepath = os.path.join(REN_DIR, "bush_showcase_macro_dry.png")
bpy.ops.render.render(write_still=True)
print("[bush_pack] RENDERED -> renders/bush_showcase_macro_dry.png")

for obj in objects:
    obj.hide_render = False
for lbl in label_objs:
    lbl.hide_render = False

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SCRIPT_DIR, "bush_pack_wip.blend"))
print("[bush_pack] DONE")
