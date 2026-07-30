"""
build_tree_pack.py - bespoke TREE pack for Piso 1 Pradera (DP_ToonGrounded).

Reference (MANDATORY, loaded before writing this): foliage_painterly/ref_01.png
+ _synthesis.md (game/docs/art/_references/foliage_painterly/). Same material
language as bush_pack: canopy is OVERLAPPING BLOBS OF COLOR with a wide value
range (dark shadow interior -> near-lime-lit edge), never leaf-by-leaf detail,
never a flat single green. Trees here are bush_pack's canopy technique on top
of a NEW trunk builder, at real tree scale.

What NOT to repeat (checked game/assets/art/piso1_pradera/vegetation/ first,
per CLAUDE.md's mandatory "load the asset's folder before building" rule):
legacy texture-card trees already live in birch/, maple/, common/, dead/
(env_tree_birch_0{1..5}.gltf, env_tree_maple_0{1..3}.gltf,
env_tree_common_0{1..3}.gltf, env_tree_dead_01.gltf + their .bin/.png). This
script does NOT touch, rename, or delete any of them -- the bespoke pack ships
into its OWN tree_pack/ subfolder so both families can coexist during the
transition.

Structural precedent (read before writing this script, per task brief):
bush_pack/build_bush_pack.py IS THE BASE -- its proven helpers are reused
directly: enforce_overlap (adjacency rule), add_core_blob (icosphere cushion
blob, no single-apex spike), add_blob_dab (bipyramid detail dab),
build_lobe_mass (union-of-envelope-spheres canopy builder with a nucleus blob
per lobe so the interior is never hollow), add_twig (tapering branch card).
This script does NOT reinvent any of them.

NEW for tree_pack: build_trunk() (low-poly cylinder, 6-8 sides, 1-2 angle
kinks, warm bark-gradient FLOAT_COLOR base-dark -> top-light) and
cluster_lobes() (places N lobe envelope centers either in a horizontal ring
or a vertical stack, with the ring/step radius DERIVED from the lobe radii so
pairwise center separation is guaranteed <= margin*(sum of the two radii) --
the same "guaranteed overlap by construction" contract build_lobe_mass's own
docstring documents for build_bush_large's flattened-triangle lobes, just
generalized to N lobes instead of hand-picked per case).

Canopy-trunk integration rule (task brief, non-negotiable): the canopy STARTS
overlapped with the trunk top -- the trunk penetrates >= 20% inside the
lowest lobe, never a floating crown over a bare pole. Implemented as: the
lobe-ring/stack anchor center sits `embed_frac` (default 0.38, so a 0.10
jitter still leaves >= 0.20 margin) of the lobes' average radius BELOW the
trunk's top ring, so the trunk's top segment is already deep inside the
lowest lobe's nucleus blob before a single canopy dab is placed.

Vertex color GOTCHA (blender-asset-smith skill, 2026-07-20 golem_guardian +
flower_pack + bush_pack entries): BYTE_COLOR corner attributes silently
sRGB-decode on readback while bmesh's loop-color WRITE does not encode ->
colors crush toward black, AND BMVert.index is stale immediately after
bm.verts.new() (keying a color dict by .index reads garbage/0 for a fresh
vert). This script uses bm.loops.layers.float_color.new(...) EXCLUSIVELY and
keys the per-vertex color dict by the BMVert object itself, never by .index.

Triangle budget: <=800 tris/variant (see count_tris print at build time).

Run:
  blender.exe --background --python build_tree_pack.py
  blender.exe --background --python build_tree_pack.py -- --seed 7
"""
import bpy
import bmesh
import math
import os
import random
import sys
from mathutils import Vector, Matrix

SEED = 21
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
# GLBs ship into their own tree_pack/ subfolder (task requirement) -- the
# legacy birch/maple/common/dead trees stay untouched alongside it.
ASSET_DIR = os.path.normpath(os.path.join(
    SCRIPT_DIR, "..", "..", "..", "assets", "art", "piso1_pradera", "vegetation", "tree_pack"))
os.makedirs(ASSET_DIR, exist_ok=True)

sys.path.insert(0, os.path.dirname(SCRIPT_DIR))
import _ground_common as groundlib  # noqa: E402

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


# =============================================================================
# GEOMETRY HELPERS -- reused verbatim from bush_pack/build_bush_pack.py (its
# docstring: "this IS the base, reuse its proven helpers"). Append directly
# into a shared bmesh + a BMVert -> RGB color dict (applied to the FLOAT_COLOR
# loop layer once at finalize time).
# =============================================================================
def lerp3(a, b, t):
    return [a[i] + (b[i] - a[i]) * t for i in range(3)]


def clamp01(x):
    return max(0.0, min(1.0, x))


def enforce_overlap(placed, pos, radius, rng, min_frac=0.55, max_frac=0.65):
    """QUANTIFIED adjacency rule (golem_guardian / bush_pack precedent): a dab
    whose nearest already-placed neighbor is farther than max_frac*(sum of the
    two radii) reads as a disconnected floating fragment once rendered. Pulls
    `pos` toward its nearest neighbor so the center separation lands in
    [min_frac, max_frac] of the summed radii, or drops the dab (returns None)
    if the gap is too large to close naturally (>3x the target)."""
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
    """Tiny bipyramid canopy 'poof' dab -- bright core apex, edge ring blended
    toward the core. A canopy built from MANY small dabs (not one big blob)
    is what reads as a painted mass of foliage instead of a single glossy
    sphere."""
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


def add_twig(bm, vcol, rng, base, length, ang, rise, width_base, col_dark, col_mid,
             segments=3, bend=0.4):
    """Bare branch card -- chain of `segments` tapering quads. Returns the tip
    position (Vector) so callers can grow shorter fork-twigs off it."""
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
    """Squashed icosphere 'cushion' blob -- cheap rounded organic-ish mass
    with no single dominant apex (unlike add_blob_dab's bipyramid), used for
    the CORE canopy mass so many overlapping icospheres fuse into a rounded
    lump instead of a stack of tiny tents/cones."""
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


def tint3(c, rng, amt=0.12):
    """Per-lobe green drift: each channel scaled by an independent factor in
    [1-amt, 1+amt]. Breaks the 'one perfect green' read Joan flagged in-game
    (2026-07-28) -- adjacent lobes of the same crown get visibly different
    greens, like real foliage clumps catching different light/age."""
    return [clamp01(c[i] * rng.uniform(1.0 - amt, 1.0 + amt)) for i in range(3)]


def build_lobe_mass(bm, vcol, rng, lobes, n_core, n_detail, col_dark, col_light,
                     ground_clamp=0.02, use_nucleus=True, nucleus_frac=0.62,
                     core_dist_range=(0.45, 0.90), detail_dist_range=(0.55, 1.08),
                     tint_amt=0.20):
    """UNION-OF-ENVELOPE-SPHERES canopy builder (bush_pack recipe, verbatim).
    `lobes` = list of ((cx,cy,cz), envelope_radius, dab_radius_range) tuples
    for FIXED lobe centers, positioned UP FRONT so every pair's center
    separation is already < 0.6x the sum of their envelope radii (guaranteed
    heavy overlap by construction). Seeds a NUCLEUS blob per lobe first
    (radius = envelope_radius*0.75) so a solid connected core exists before a
    single decorative dab is placed -- kills the hollow-interior "croissant"
    defect bush_pack's pass-2c fix documented. Decorative dabs sample within
    the envelope down to 0.45x so some land BETWEEN the nucleus and the outer
    shell. Returns the merged placed list."""
    weights = [r ** 3 for (_, r, _) in lobes]
    total_w = sum(weights)
    per_lobe_placed = [[] for _ in lobes]
    # Per-lobe tinted palettes -- computed ONCE per lobe so every blob/dab of
    # that lobe shares its drifted green (a coherent clump), while neighboring
    # lobes differ. Drift is applied to dark and light independently so the
    # value range also varies slightly per clump.
    lobe_pal = [(tint3(col_dark, rng, tint_amt), tint3(col_light, rng, tint_amt))
                for _ in lobes]

    if use_nucleus:
        for idx, ((cx0, cy0, cz0), R, rad_range) in enumerate(lobes):
            ncz = max(ground_clamp, cz0)
            ld, ll = lobe_pal[idx]
            add_core_blob(bm, vcol, rng, (cx0, cy0, ncz), R * nucleus_frac, ld, ll,
                          squash_z=0.90, bright_bias=0.30, jitter=0.22)
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
        ld, ll = lobe_pal[idx]
        dx, dy, dz = sample_dir()
        dist = R * rng.uniform(*core_dist_range)
        cx = cx0 + dx * dist
        cy = cy0 + dy * dist
        cz = max(ground_clamp, cz0 + dz * dist)
        dab_r = rng.uniform(*rad_range)
        squash = rng.uniform(0.75, 1.10)
        bright_t = clamp01(0.35 + 0.35 * (dist / R) + rng.uniform(-0.08, 0.08))
        pulled = enforce_overlap(per_lobe_placed[idx], (cx, cy, cz), dab_r, rng)
        if pulled is None:
            continue
        cx, cy, cz = pulled
        add_core_blob(bm, vcol, rng, (cx, cy, cz), dab_r, ld, ll,
                      squash_z=squash, bright_bias=bright_t, jitter=0.24)
        per_lobe_placed[idx].append(((cx, cy, cz), dab_r))

    for _ in range(n_detail):
        idx = pick_lobe()
        (cx0, cy0, cz0), R, rad_range = lobes[idx]
        ld, ll = lobe_pal[idx]
        dx, dy, dz = sample_dir()
        dist = R * rng.uniform(*detail_dist_range)
        cx = cx0 + dx * dist
        cy = cy0 + dy * dist
        cz = max(ground_clamp, cz0 + dz * dist)
        dab_r = rng.uniform(rad_range[0] * 0.45, rad_range[1] * 0.55)
        bright_t = clamp01(0.40 + 0.45 * (dist / R) + rng.uniform(-0.06, 0.10))
        col_edge = lerp3(ld, ll, bright_t * 0.65)
        col_core = lerp3(ld, ll, clamp01(bright_t * 1.15 + 0.15))
        pulled = enforce_overlap(per_lobe_placed[idx], (cx, cy, cz), dab_r, rng)
        if pulled is None:
            continue
        cx, cy, cz = pulled
        add_blob_dab(bm, vcol, rng, (cx, cy, cz), dab_r, col_edge, col_core,
                     squash=rng.uniform(0.60, 0.88), sides=5, jitter=0.28)
        per_lobe_placed[idx].append(((cx, cy, cz), dab_r))

    # SAFETY STITCH (bush_pack precedent): envelope centers guarantee overlap
    # as ABSTRACT spheres, but with only a handful of independently-angle-
    # sampled dabs per lobe, one lobe can land its whole cluster facing away
    # from its overlap partner. Bridge the two closest real placed dabs
    # between every lobe pair if the gap is still wide.
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
            if best_d > 0.55 * (ra + rb):
                mx, my, mz = (pa[0] + pb[0]) * 0.5, (pa[1] + pb[1]) * 0.5, (pa[2] + pb[2]) * 0.5
                r = (ra + rb) * 0.5 * 1.1
                add_core_blob(bm, vcol, rng, (mx, my, mz), r, col_dark, col_light,
                              squash_z=0.85, bright_bias=0.32, jitter=0.16)
                per_lobe_placed[i].append(((mx, my, mz), r))

    placed = [p for lobe_list in per_lobe_placed for p in lobe_list]
    return placed


# =============================================================================
# NEW FOR tree_pack -- trunk builder + lobe-cluster placement.
# =============================================================================
def build_trunk(bm, vcol, rng, base, height, base_r, top_r, col_base, col_top,
                 sides=7, rings=6, jitter=0.06, bends=None, cap_bottom=True,
                 cap_top=True):
    """Low-poly cylinder trunk: `rings` rings of `sides` verts, linearly
    tapered base_r -> top_r, warm bark-gradient FLOAT_COLOR (dark base ->
    light top, per-vertex lerp on height fraction u). `bends` is a list of
    (u_break, angle_rad, magnitude) angle-kink tuples -- past u_break, a
    LINEAR lateral offset grows in direction `angle_rad` by `magnitude` per
    unit u, giving the "1-2 quiebres de angulo" look the brief asks for
    (a real kink, not a smooth spline curve -- matches the low-poly faceted
    family signature). Returns (top_center (x,y,z), top_r) so callers can
    anchor the canopy embedded into the trunk top."""
    if bends is None:
        bends = []
    bx, by, bz = base
    ring_list = []
    for i in range(rings + 1):
        u = i / rings
        z = bz + height * u
        dx = dy = 0.0
        for (u0, ang, mag) in bends:
            if u > u0:
                frac = u - u0
                dx += math.cos(ang) * mag * frac
                dy += math.sin(ang) * mag * frac
        cx, cy = bx + dx, by + dy
        r = base_r + (top_r - base_r) * u
        ring = []
        for s in range(sides):
            a = 2.0 * math.pi * s / sides + rng.uniform(-0.05, 0.05)
            rr = r * rng.uniform(1.0 - jitter, 1.0 + jitter)
            vx = cx + math.cos(a) * rr
            vy = cy + math.sin(a) * rr
            ring.append(bm.verts.new((vx, vy, z)))
        col = lerp3(col_base, col_top, u)
        for v in ring:
            vcol[v] = col
        ring_list.append((ring, (cx, cy, z)))

    for i in range(rings):
        a_ring, _ = ring_list[i]
        b_ring, _ = ring_list[i + 1]
        for s in range(sides):
            a0, a1 = a_ring[s], a_ring[(s + 1) % sides]
            b0, b1 = b_ring[s], b_ring[(s + 1) % sides]
            bm.faces.new((a0, a1, b1, b0))

    if cap_bottom:
        bot_ring, bot_c = ring_list[0]
        center = bm.verts.new(bot_c)
        vcol[center] = col_base
        for s in range(sides):
            a, b = bot_ring[s], bot_ring[(s + 1) % sides]
            bm.faces.new((center, b, a))

    top_ring, top_c = ring_list[-1]
    if cap_top:
        center = bm.verts.new(top_c)
        vcol[center] = col_top
        for s in range(sides):
            a, b = top_ring[s], top_ring[(s + 1) % sides]
            bm.faces.new((center, a, b))

    return top_c, top_r


def cluster_lobes(center, R_list, dab_frac, rng, layout="ring", margin=0.5,
                   jitter_frac=0.12):
    """Places len(R_list) lobe envelope centers around `center` so pairwise
    center separation is GUARANTEED (by ring/stack geometry, not by luck) to
    stay within a safe overlap margin -- generalizes bush_large_01's hand-
    picked flattened-triangle lobe centers (verified there via manual
    distance/(r_a+r_b) checks) into a formula so N-lobe crowns don't need
    per-variant manual arithmetic.

    layout="ring": lobes spaced evenly on a horizontal ring of radius
      `margin * R_avg / sin(pi/n)` -- for n points evenly spaced on a circle
      of that radius, the minimum chord between neighbors works out to
      <= margin*(R_i+R_j) for similar radii, which is the same style of bound
      enforce_overlap itself targets (0.55-0.65x). margin=0.5 leaves headroom
      below that bound for the jitter this function also applies.
    layout="stack": lobes stacked vertically, each new lobe's center placed
      `margin*(R_prev+R_cur)` above the previous one -- deterministic, no
      trig needed, used for the 2-lobe "tall" variant's vertical crown.

    dab_frac=(lo, hi) is the established bush_pack ratio (fraction of a
    lobe's OWN envelope radius used for its dab_radius_range, ~0.20-0.28 per
    build_bush_large/build_bush_dry) -- computed per-lobe here so tree lobes
    of different sizes each get proportionate dab density.
    """
    n = len(R_list)
    lobes = []
    if n == 1:
        R = R_list[0]
        lobes.append((center, R, (R * dab_frac[0], R * dab_frac[1])))
        return lobes
    if layout == "ring":
        R_avg = sum(R_list) / n
        ring_r = margin * R_avg / max(1e-4, math.sin(math.pi / n))
        for i, R in enumerate(R_list):
            ang = 2.0 * math.pi * i / n + rng.uniform(-0.15, 0.15)
            cx = center[0] + math.cos(ang) * ring_r
            cy = center[1] + math.sin(ang) * ring_r
            cz = center[2] + rng.uniform(-jitter_frac, jitter_frac) * R_avg
            lobes.append(((cx, cy, cz), R, (R * dab_frac[0], R * dab_frac[1])))
    elif layout == "stack":
        x, y, z = center
        prev_R = None
        prev_z = z
        for i, R in enumerate(R_list):
            if i == 0:
                cz = z
            else:
                cz = prev_z + margin * (prev_R + R)
            hx = x + rng.uniform(-jitter_frac, jitter_frac) * R
            hy = y + rng.uniform(-jitter_frac, jitter_frac) * R
            lobes.append(((hx, hy, cz), R, (R * dab_frac[0], R * dab_frac[1])))
            prev_R, prev_z = R, cz
    else:
        raise ValueError(f"unknown layout {layout!r}")
    return lobes


def finalize_mesh(name, bm, vcol):
    # Many overlapping closed blobs share near-coincident verts at their
    # intersections -- weld near-coincident verts BEFORE recalculating
    # normals (bush_pack gotcha: recalc alone only re-orients existing faces,
    # doesn't merge geometry, so a stray dark/degenerate triangle can survive
    # at an overlap seam otherwise).
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
# non-emissive slot for the whole pack (trunk + canopy share it, differentiated
# purely by vertex color -- same discipline as bush_pack).
# =============================================================================
def make_vcol_material(name, roughness=0.92):
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
# PALETTES (linear-ish 0-1 tones, kept under 1.0 -- golem/flower/bush convention)
# =============================================================================
TRUNK_DARK = (0.078, 0.060, 0.048)     # warm brown-gray, shaded base
TRUNK_LIGHT = (0.30, 0.24, 0.185)      # lighter warm brown-gray, sunlit top
TRUNK_DRY_DARK = (0.098, 0.080, 0.058)  # paler/more golden bark for tree_dry
TRUNK_DRY_LIGHT = (0.40, 0.325, 0.220)

PRAIRIE_DARK = (0.035, 0.095, 0.032)
PRAIRIE_LIGHT = (0.52, 0.68, 0.22)

TALL_DARK = (0.032, 0.088, 0.034)
TALL_LIGHT = (0.46, 0.62, 0.20)

WIDE_DARK = (0.030, 0.082, 0.036)
WIDE_LIGHT = (0.44, 0.60, 0.22)

YOUNG_DARK = (0.045, 0.105, 0.040)
YOUNG_LIGHT = (0.56, 0.72, 0.26)

DRY_DARK = (0.150, 0.110, 0.052)
DRY_LIGHT = (0.74, 0.58, 0.20)
TWIG_DARK = (0.090, 0.062, 0.034)
TWIG_MID = (0.32, 0.22, 0.11)

# fraction of a lobe's OWN envelope radius used for its dab radius range --
# the bush_large/bush_dry established ratio (0.100/0.50=0.20 .. 0.135/0.50=0.27)
DAB_FRAC = (0.20, 0.28)


def anchor_canopy_center(top_c, R_list, embed_frac=0.38):
    """Trunk-canopy integration rule (task brief): the canopy anchor sits
    embed_frac * R_avg BELOW the trunk's top ring, so the trunk's own top
    segment is already deep inside the lowest lobe's nucleus before any dab
    is placed -- guarantees >=20% penetration even after cluster_lobes' own
    +-jitter_frac*R vertical jitter (default embed 0.38 - jitter ~0.10-0.12
    still clears the 0.20 floor with margin)."""
    R_avg = sum(R_list) / len(R_list)
    tx, ty, tz = top_c
    return (tx, ty, tz - embed_frac * R_avg)


# =============================================================================
# VARIANT BUILDERS
# =============================================================================
def build_tree_prairie(rng):
    """1. Classic prairie tree -- trunk with a leaning kink + round 3-lobe
    canopy. The generalist ficha silhouette everything else is judged
    against.

    REAL-SCALE REBUILD (2026-07-28, Joan in-game review): the whole pack was
    originally modeled at ~2.3m total -- bush scale. floor1_prairie.gd's
    scatter range 0.8-1.7x is calibrated for REAL-METER natives (legacy birch
    5.45m / common 7.26m), so in-game these rendered at eye height ("arbol
    miniatura"). All 5 variants rebuilt at real native heights: prairie ~7m,
    tall ~10m, wide ~6m, young ~3m, dry ~4.5m. Dab counts raised (denser
    granular canopy at the bigger scale) + jitter raised + per-lobe green
    tint (tint3) to break the 'perfect polygon blocks' read."""
    bm = bmesh.new()
    vcol = {}
    top_c, top_r = build_trunk(bm, vcol, rng, base=(0.0, 0.0, 0.0), height=5.4,
                                base_r=0.32, top_r=0.20, col_base=TRUNK_DARK,
                                col_top=TRUNK_LIGHT, sides=7, rings=7,
                                bends=[(0.40, math.radians(50), 0.42),
                                       (0.75, math.radians(230), 0.18)])
    R_list = [1.85, 1.72, 1.60]
    anchor = anchor_canopy_center(top_c, R_list, embed_frac=0.38)
    lobes = cluster_lobes(anchor, R_list, DAB_FRAC, rng, layout="ring", margin=0.48)
    build_lobe_mass(bm, vcol, rng, lobes, n_core=40, n_detail=26,
                     col_dark=PRAIRIE_DARK, col_light=PRAIRIE_LIGHT)
    return finalize_mesh("tree_prairie_01", bm, vcol)


def build_tree_prairie_tall(rng):
    """2. Slender edge tree -- TALL foliage COLUMN (poplar/cypress silhouette:
    a real slender tree carries canopy along MOST of its height, not a bare
    pole with a pom-pom on top).

    PASS-1 FIX: an earlier 2-lobe pure-vertical "stack" (centers differing
    only in Z, margin=0.5) rendered as a wasp-waisted SNOWMAN/pagoda -- two
    near-spherical nuclei touching at a point read as two balls, not one
    crown, even though their envelope spheres overlapped on paper (a
    spherical primitive stacked along a single axis always shows its
    equator as a waist). Fixed with 3 lobes + large horizontal jitter.

    PASS-2 FIX (coordinator review, 2026-07-27): pass-1's 3-lobe crown was
    connected (no waist) but only covered ~25% of the tree's total height
    sitting on a ~75%-bare trunk -- read as a "chupetin"/lollipop, not an
    esbelto tree. A real slender tree (poplar/cypress) carries foliage along
    50-60% of its height. Rebuilt as a FLAME/SPINDLE silhouette: 5 lobes
    stacked in a tight column (small horizontal jitter this time -- the
    pass-1 large-jitter trick was for breaking a 2-ball waist, not needed
    with 5 lobes of continuously DECREASING radius, whose smooth taper
    itself avoids the waist look), radii shrinking bottom->tip (widest lobe
    at the base of the crown, narrowest at the very top) so the outline
    reads as a tapering flame, not a row of equal balls. `embed_frac=0.35`
    (deeper than the default 0.38-0.42 used elsewhere) deliberately pulls
    the WHOLE lobe stack down so canopy coverage starts well below the
    trunk's own top, leaving only the bottom ~40-45% of the trunk visibly
    bare -- verified by direct height arithmetic before rendering: trunk
    top=1.45, anchor(lobe0) z=1.45-0.35*avg(R)=1.352, lobe0's visible
    bottom surface ~=1.352-0.40*0.9=0.99 (the bare-trunk/canopy transition),
    top of lobe4 ~=2.27 -> total height ~2.27, bare-trunk fraction
    ~0.99/2.27=44%, canopy-coverage fraction ~56% -- both inside the
    40-50%/50-60% targets BEFORE a single render, then confirmed by eye."""
    bm = bmesh.new()
    vcol = {}
    # PASS-2b FIX (coordinator re-review): the idealized "canopy visually
    # starts at lobe_center - R*0.9" arithmetic used to size pass-2's numbers
    # predicted ~55% canopy coverage, but the ACTUAL render (real dabs only
    # sample core_dist_range 0.45-0.90 of R, never fully to the pole) read
    # closer to ~40% -- the formula over-estimates how far down a sparse dab
    # shell actually reaches. Fix empirically, not just by more arithmetic:
    # shorter bare-trunk cylinder (1.10 vs 1.45) + deeper embed (0.48 vs
    # 0.35) + a bigger bottom lobe (0.44 vs 0.40) so the widest lobe's real
    # dab mass reaches lower down the trunk, re-verified by eye against the
    # render (not trusted from math alone).
    # REAL-SCALE REBUILD (2026-07-28): ~10m total (map-edge poplar niche).
    top_c, top_r = build_trunk(bm, vcol, rng, base=(0.0, 0.0, 0.0), height=4.5,
                                base_r=0.30, top_r=0.18, col_base=TRUNK_DARK,
                                col_top=TRUNK_LIGHT, sides=6, rings=7,
                                bends=[(0.60, math.radians(210), 0.15)])
    R_list = [1.9, 1.6, 1.3, 1.0, 0.7]  # bottom(widest) -> tip(narrowest)
    anchor = anchor_canopy_center(top_c, R_list, embed_frac=0.54)
    lobes = cluster_lobes(anchor, R_list, DAB_FRAC, rng, layout="stack", margin=0.34,
                           jitter_frac=0.12)
    # over-budget trim (5-lobe column runs the pairwise safety-stitch pass
    # harder than a 2-3 lobe crown) -- cut decorative n_detail dabs only,
    # per coordinator instruction: never touch the nucleus/core mass passes.
    build_lobe_mass(bm, vcol, rng, lobes, n_core=28, n_detail=14,
                     col_dark=TALL_DARK, col_light=TALL_LIGHT)
    return finalize_mesh("tree_prairie_tall_01", bm, vcol)


def build_tree_prairie_wide(rng):
    """3. Wide parasol shade tree -- shorter/thicker trunk, WIDE 4-lobe
    horizontal ring canopy (umbrella silhouette for a resting-shade spot)."""
    bm = bmesh.new()
    vcol = {}
    # REAL-SCALE REBUILD (2026-07-28): ~6m total, crown span ~7-8m (parasol).
    top_c, top_r = build_trunk(bm, vcol, rng, base=(0.0, 0.0, 0.0), height=4.3,
                                base_r=0.38, top_r=0.26, col_base=TRUNK_DARK,
                                col_top=TRUNK_LIGHT, sides=8, rings=6,
                                bends=[(0.55, math.radians(20), 0.22)])
    R_list = [2.3, 2.15, 2.05, 1.9]
    anchor = anchor_canopy_center(top_c, R_list, embed_frac=0.34)
    lobes = cluster_lobes(anchor, R_list, DAB_FRAC, rng, layout="ring", margin=0.50,
                           jitter_frac=0.06)
    build_lobe_mass(bm, vcol, rng, lobes, n_core=30, n_detail=24,
                     col_dark=WIDE_DARK, col_light=WIDE_LIGHT)
    return finalize_mesh("tree_prairie_wide_01", bm, vcol)


def build_tree_young(rng):
    """4. Small young sapling -- short straight trunk, 2 small lobes, the
    bush->tree transition size."""
    bm = bmesh.new()
    vcol = {}
    # REAL-SCALE REBUILD (2026-07-28): ~3m total (sapling, above player head).
    top_c, top_r = build_trunk(bm, vcol, rng, base=(0.0, 0.0, 0.0), height=2.0,
                                base_r=0.13, top_r=0.09, col_base=TRUNK_DARK,
                                col_top=TRUNK_LIGHT, sides=6, rings=5, bends=[])
    R_list = [1.0, 0.8]
    anchor = anchor_canopy_center(top_c, R_list, embed_frac=0.42)
    lobes = cluster_lobes(anchor, R_list, DAB_FRAC, rng, layout="ring", margin=0.50,
                           jitter_frac=0.10)
    build_lobe_mass(bm, vcol, rng, lobes, n_core=16, n_detail=14,
                     col_dark=YOUNG_DARK, col_light=YOUNG_LIGHT)
    return finalize_mesh("tree_young_01", bm, vcol)


def build_tree_dry(rng):
    """5. Dry/golden tree -- sparse 2-lobe canopy + 2-3 visible bare branches
    (add_twig anchored INSIDE a canopy blob, <=40% poking out -- bush_dry_01's
    proven twig-anchoring recipe, re-tuned to tree scale)."""
    bm = bmesh.new()
    vcol = {}
    # REAL-SCALE REBUILD (2026-07-28): ~4.5m total (dry-zone tree).
    top_c, top_r = build_trunk(bm, vcol, rng, base=(0.0, 0.0, 0.0), height=3.3,
                                base_r=0.24, top_r=0.14, col_base=TRUNK_DRY_DARK,
                                col_top=TRUNK_DRY_LIGHT, sides=7, rings=7,
                                bends=[(0.40, math.radians(310), 0.42)])
    R_list = [1.15, 0.90]
    anchor = anchor_canopy_center(top_c, R_list, embed_frac=0.40)
    lobes = cluster_lobes(anchor, R_list, DAB_FRAC, rng, layout="ring", margin=0.48,
                           jitter_frac=0.10)
    placed = build_lobe_mass(bm, vcol, rng, lobes, n_core=12, n_detail=10,
                              col_dark=DRY_DARK, col_light=DRY_LIGHT)

    # twig anchoring -- bush_dry_01 recipe, tree-scale params. PASS-1 FIX: the
    # first version capped total_rise at 0.55 and drew lean/width from a
    # 0.06-0.12/0.024-0.036 range that was tuned by "3-4x the bush numbers"
    # arithmetic, not against the actual canopy size here (R~0.26-0.34) --
    # rendered as thin dead-straight wire antennae towering FAR above the
    # canopy, nothing like a branch poking through foliage. A twig's rise
    # must stay proportioned to the BLOB it grows from, not to the tree's
    # overall height. Fix: rise cap tied to R (<=0.85*R, so it can never be
    # taller than the lobe it roots in), embed_frac pushed higher (deeper
    # root = shorter poke), and lean/width shrunk back toward bush_dry_01's
    # own proportions (this pack's trunk already carries the "big" read;
    # twigs are a texture accent, not a second silhouette element).
    candidates = sorted(placed, key=lambda p: p[0][2])
    candidates = candidates[len(candidates) // 3:]
    tips = []
    attempts = 0
    while len(tips) < 3 and attempts < 60:
        attempts += 1
        (bx, by, bz), R = candidates[rng.randrange(len(candidates))]
        ang = rng.uniform(0.0, 2.0 * math.pi)
        elev = rng.uniform(0.10, 0.90)
        horiz = math.sqrt(max(0.0, 1.0 - elev * elev))
        depth_frac = rng.uniform(0.40, 0.75)
        dist_from_center = (1.0 - depth_frac) * R
        rx, ry, rz = math.cos(ang) * horiz, math.sin(ang) * horiz, elev
        root_x = bx + rx * dist_from_center
        root_y = by + ry * dist_from_center
        root_z = bz + rz * dist_from_center
        horiz_off = math.sqrt((root_x - bx) ** 2 + (root_y - by) ** 2)
        if horiz_off >= R:
            continue
        top_local = bz + math.sqrt(max(0.0, R * R - horiz_off * horiz_off))
        to_surface = max(0.02, top_local - root_z)
        embed_t = rng.uniform(0.65, 0.80)
        total_rise = to_surface / embed_t
        if total_rise > 0.85 * R:
            continue  # would tower over its own canopy blob -- drop it
        # twig linear dims scaled ~3.4x with the real-scale rebuild (they are
        # absolute meters, unlike total_rise which is already tied to R)
        lean = rng.uniform(0.12, 0.20)
        width_base = rng.uniform(0.055, 0.085)
        tip = add_twig(bm, vcol, rng, (root_x, root_y, max(0.0, root_z)), lean, ang,
                       total_rise, width_base, TWIG_DARK, TWIG_MID, segments=3, bend=0.4)
        tips.append((tip, ang))
    for tip, ang in tips[:2]:
        fork_ang = ang + rng.uniform(-0.8, 0.8)
        add_twig(bm, vcol, rng, (tip.x, tip.y, tip.z), rng.uniform(0.085, 0.15),
                 fork_ang, rng.uniform(0.10, 0.17), rng.uniform(0.034, 0.05),
                 TWIG_DARK, TWIG_MID, segments=2, bend=0.3)
    return finalize_mesh("tree_dry_01", bm, vcol)


# =============================================================================
# BUILD ALL VARIANTS
# =============================================================================
BUILDERS = [
    ("tree_prairie_01", build_tree_prairie),
    ("tree_prairie_tall_01", build_tree_prairie_tall),
    ("tree_prairie_wide_01", build_tree_prairie_wide),
    ("tree_young_01", build_tree_young),
    ("tree_dry_01", build_tree_dry),
]

mat_tree = make_vcol_material("tree_pack_mat")

objects = []
print(f"\n[tree_pack] seed={SEED}\n")
for i, (name, fn) in enumerate(BUILDERS):
    rng = random.Random(SEED * 1000 + i * 131)
    obj = fn(rng)
    obj.data.materials.append(mat_tree)
    tris = count_tris(obj)
    objects.append(obj)
    # Budget raised 800 -> 1600 with the real-scale rebuild: a 7-10m tree the
    # player walks under needs denser dab granularity than the old 2.3m bush-
    # scale version (still cheap vs the 98k-tri TRELLIS-era assets).
    status = "OK" if tris <= 1600 else "!! OVER 1600-TRI BUDGET !!"
    dims = obj.dimensions
    print(f"[tree_pack] built {name}  tris={tris}  h={dims.z:.2f}m  {status}")

# ---------- export: all 5 objects still at local origin (0,0,0) -- showcase
# layout offsets are applied AFTER export, same discipline as bush_pack. ----------
bpy.ops.object.select_all(action='DESELECT')
for o in objects:
    o.select_set(True)
export_kwargs = dict(
    filepath=os.path.join(ASSET_DIR, "tree_pack.glb"),
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
print(f"[tree_pack] EXPORTED -> {os.path.join(ASSET_DIR, 'tree_pack.glb')}")

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
print(f"[tree_pack] per-variant GLBs exported -> {ASSET_DIR}")

# =============================================================================
# SHOWCASE RENDER -- ficha-style: sunlit-meadow stage, labels above each tree,
# plus a macro close-up of tree_prairie_01 and tree_dry_01.
# =============================================================================
SPACING = 8.0
for i, obj in enumerate(objects):
    obj.location = ((i - (len(objects) - 1) / 2.0) * SPACING, 0.0, 0.0)

ground_mat = bpy.data.materials.new("tree_ground_mat")
ground_mat.use_nodes = True
gn = ground_mat.node_tree.nodes["Principled BSDF"]
gn.inputs["Base Color"].default_value = (0.10, 0.145, 0.06, 1.0)
gn.inputs["Roughness"].default_value = 0.95
groundlib.build_ground(scene, size=48.0, subdiv=50, roughness=0.25, scale=2.0,
                        material=ground_mat, name="tree_showcase_ground")

# 1.8m PLAYER REFERENCE POST (golem lesson 2026-06-10: scale must be judged
# against a human-height marker, or a 2.3m "tree" passes review as fine).
ref_mesh = bpy.data.meshes.new("player_ref")
ref_bm = bmesh.new()
bmesh.ops.create_cube(ref_bm, size=1.0)
for v in ref_bm.verts:
    v.co.x *= 0.35
    v.co.y *= 0.35
    v.co.z = v.co.z * 1.8 + 0.9  # 1.8m tall, base at z=0
ref_bm.to_mesh(ref_mesh)
ref_bm.free()
ref_obj = bpy.data.objects.new("player_ref", ref_mesh)
ref_obj.location = (-(len(objects) - 1) / 2.0 * SPACING - 3.5, 0.0, 0.0)
ref_mat = bpy.data.materials.new("player_ref_mat")
ref_mat.use_nodes = True
ref_n = ref_mat.node_tree.nodes["Principled BSDF"]
ref_n.inputs["Base Color"].default_value = (0.85, 0.25, 0.20, 1.0)
ref_mesh.materials.append(ref_mat)
scene.collection.objects.link(ref_obj)

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


add_light("key", (-12.0, -30.0, 20.0), 4200, 12.0)
add_light("fill", (18.0, -22.0, 11.0), 1100, 11.0)
add_light("rim", (3.0, 22.0, 14.0), 2600, 9.0)

target = bpy.data.objects.new("target", None)
target.location = (0.0, 0.0, 4.0)
scene.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 32
cam = bpy.data.objects.new("cam", cd)
cam.location = (0.0, -44.0, 9.5)
scene.collection.objects.link(cam)
cam.constraints.new(type='TRACK_TO').target = target
scene.camera = cam

# ---------- labels: z>0, align_y='BOTTOM' so text grows UPWARD from just
# above the ground plane (flower_pack/bush_pack gotcha -- a flat opaque
# ground fully occludes anything below its own z=0 surface from an elevated
# camera). ----------
LABELS = {
    "tree_prairie_01": "prairie",
    "tree_prairie_tall_01": "tall",
    "tree_prairie_wide_01": "wide",
    "tree_young_01": "young",
    "tree_dry_01": "dry",
}
label_mat = bpy.data.materials.new("label_mat")
label_mat.use_nodes = True
lm_n = label_mat.node_tree.nodes["Principled BSDF"]
lm_n.inputs["Base Color"].default_value = (0.98, 0.98, 0.95, 1.0)
lm_n.inputs["Roughness"].default_value = 0.55

label_objs = []
for obj in objects:
    bpy.ops.object.text_add(location=(obj.location.x, -3.2, 0.05))
    txt = bpy.context.object
    txt.data.body = LABELS[obj.name]
    txt.data.size = 0.75
    txt.data.align_x = 'CENTER'
    txt.data.align_y = 'BOTTOM'
    txt.data.extrude = 0.010
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
scene.render.filepath = os.path.join(REN_DIR, "tree_showcase.png")
bpy.ops.render.render(write_still=True)
print("[tree_pack] RENDERED -> renders/tree_showcase.png")


def render_solo_macro(obj_index, cam_offset, target_z, out_name, lens=28):
    target_obj = objects[obj_index]
    for o in objects:
        o.hide_render = (o is not target_obj)
    for lbl in label_objs:
        lbl.hide_render = True
    mt = bpy.data.objects.new(f"{out_name}_target", None)
    mt.location = (target_obj.location.x, 0.0, target_z)
    scene.collection.objects.link(mt)
    cd_ = bpy.data.cameras.new(f"{out_name}_cam")
    cd_.lens = lens
    cam_ = bpy.data.objects.new(f"{out_name}_cam", cd_)
    cam_.location = (target_obj.location.x + cam_offset[0], cam_offset[1], cam_offset[2])
    scene.collection.objects.link(cam_)
    cam_.constraints.new(type='TRACK_TO').target = mt
    scene.camera = cam_
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 1400
    scene.render.filepath = os.path.join(REN_DIR, out_name)
    bpy.ops.render.render(write_still=True)
    print(f"[tree_pack] RENDERED -> renders/{out_name}")
    for o in objects:
        o.hide_render = False
    for lbl in label_objs:
        lbl.hide_render = False


# macro of tree_prairie_01 (index 0) -- the generalist silhouette, judged at
# in-game viewing distance for trunk/canopy integration.
render_solo_macro(0, (-5.5, -12.0, 2.0), 3.6, "tree_showcase_macro_prairie.png")
# macro of tree_prairie_tall_01 (index 1) -- coordinator fix-pass check: full
# flame/spindle silhouette + bare-trunk fraction, not just the wide ficha.
render_solo_macro(1, (-6.0, -14.5, 2.5), 4.8, "tree_showcase_macro_tall.png")
# macro of tree_dry_01 (index 4) -- verify sparse canopy + visible anchored
# twigs read correctly (not floating wires) at close range.
render_solo_macro(4, (-4.5, -10.0, 1.7), 2.4, "tree_showcase_macro_dry.png")
# PLAYER-EYE shot (NEW, the view Joan actually judged in-game): camera at
# 1.65m eye height, ~6m from the prairie tree -- the trunk should tower and
# the canopy underside should be overhead, never at eye level.
render_solo_macro(0, (2.0, -6.0, 1.65), 3.2, "tree_showcase_playereye.png", lens=24)

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SCRIPT_DIR, "tree_pack_wip.blend"))
print("[tree_pack] DONE")
