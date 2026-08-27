# build_golem_guardian.py — Golem Guardian (mound-with-tree miniboss). PO Joan
# approved 6-beat AWAKEN design (2026-07-19), core glow = CYAN. Built FROM
# game/docs/art/_references/golem/ (ref01 tree-on-back + ref02 mossy-mound-
# as-terrain + ref04/07 knuckle-drag rise) and the motion spec's weight
# principles (game/docs/art/_references/golem/motion/_motion_spec.md —
# rock_movement low-bounce tumble physics, tree_fall Stage-A slow-start).
# Different entity from golem_floating/build_golem.py (that one is a floating-
# stone cluster; THIS one is a solid standing/mound construct) but reuses its
# noise-displaced-icosphere rock generator + flat-shade + NLA-per-clip export.
#
# APPROACH (per brief): STANDING pose is the authored rest pose (all part
# meshes built with local vertex data relative to a chosen PIVOT point, object
# .location = pivot in world space at rx=ry=rz=0). DORMANT = a different
# world pivot + rotation + scale per part (mound tuck). No shape keys, no
# armature — pure per-object transform keyframes, matching the brief's
# suggested approach and avoiding the shape-key contamination gotcha (contract
# §5) entirely.
#
# Parts (14 objects, no parenting — every sampler computes WORLD transforms
# directly, staggering per Appendix A of the motion spec to avoid lockstep):
#   torso, head, glow_chest, glow_head, arm_L, arm_R, fist_L, fist_R,
#   leg_L, leg_R, tree, stone_1, stone_2, stone_3
#
# Clips (standard 5 + the awaken deliverable):
#   idle-loop (36f)  DORMANT breathing loop — mound rises/falls, tree sways.
#   awaken    (168f) DORMANT -> STANDING, 6 PO-approved beats (see AWAKEN_BEATS).
#   move-loop (48f)  STANDING plodding gait, 2-beat arm swing + leg weight-shift.
#   attack    (30f)  STANDING fist-raise-and-slam (placeholder full moveset).
#   hit       (16f)  STANDING flinch — torso recoil + tree shudder.
#   death     (48f)  STANDING -> forward collapse, ends mound-like (Move 8:
#                    NOT a reverse-awaken — a real crumble-forward, poetic
#                    callback to the dormant silhouette).
#
# Run: blender.exe --background --python build_golem_guardian.py
#
# UPDATE (2026-07-19/20, PO Joan) — 3 additions to the awaken sequence per the
# new "Boss encounter structure" section in
# game/docs/art/_references/golem/motion/_motion_spec.md:
#   1. Dormant mound gets a small cave-like hollow (torso_b0 carve, see
#      CAVE_CENTER/CAVE_RADIUS/CAVE_DEPTH + make_rock's cave_* params).
#   2. Eyes (glow_head) now open on an explicit EARLY beat (a quick pop
#      inside beat 2, ~frame 18-24) instead of only lighting at the very end;
#      head-look-at-player also now starts partway through the rise (beat 4)
#      and holds, instead of snapping only in the final beat.
#   3. Arms are no longer a shared/simultaneous "shoulders split" motion —
#      each arm has its OWN buried-mass rise window (see
#      ARM_RISE_WINDOW/arm_rise_progress/arm_dirt_pop/arm_settle_bounce): the
#      RIGHT arm rises+settles fully, THEN the LEFT arm starts its own rise.
#
# UPDATE (2026-07-20+, PASS 4 — PO Joan, refs 10-15) — 6 corrective fixes,
# 2 of them (crystal + eye embedding) previously raised and NEVER actually
# fixed across earlier passes:
#   1. Distinct stones, not a fused pillar — arm/fist blob spacing was an
#      effective ~0.42 overlap ratio (over-fused); rebuilt via a generic
#      chain_positions() helper (ports golem_floating's JOINT_TOUCH lesson)
#      at ratio 0.65. Torso b0<->b1 loosened from ~0.52 to ~0.62 too.
#   2. Legs added (leg_L/leg_R, NEW parts) — arms shortened (ARM_DIR_LOCAL)
#      and freed from ground-support duty; each leg is a thigh/shin/foot
#      chain built with the same chain_positions technique.
#   3. Tree rigid-follow — tree_rigid_tilt_deg() reads the torso's own actual
#      per-frame rotation (awaken clip; idle/move already did this in a
#      prior pass) instead of an independent authored curve; the old curve
#      (tree_tilt_deg) is kept as a smaller secondary whip layer on top.
#   4. Crystal (glow_chest) re-nested INSIDE the torso_b0/b1/torso_lip seam
#      (was floating ~1.2-1.7 units from any blob surface), shrunk+flattened
#      into a shard, given a grime vertex-mask material (make_gem +
#      mat_glow_grimy) and a rock "lip" chunk partially occluding it.
#   5. Eyes recessed into actual carved sockets on head_b0 (make_rock's new
#      `caves` list param — 2 sockets on one blob) instead of sitting flush/
#      proud on the surface; glow_eye_L/R pulled back to nest at socket floor.
#   6. Reveal choreography — legs now assemble (dirt-pop/settle) alongside
#      the existing per-arm sequential rise; eyes-open + head-look timing
#      reviewed and left as-is (already deliberate per the prior pass).
#
# UPDATE (2026-07-20+, PASS 6 — PO Joan, live Blender inspection) — 3 fixes,
# one of them (ground plane) new SHARED infrastructure the whole
# motor-blender pipeline needs, not just this mob:
#   1. Irregular limb stones — arm/leg chains still read as uniform-size
#      "stacked beads on an antenna" despite PASS 4's spacing fix (spacing
#      alone doesn't fix SIZE uniformity). jitter_radii() breaks the smooth
#      ARM_RADII/LEG_RADII taper into genuinely mixed big/small stones per
#      chain; each blob also gets its own elongate/seed/noise_scale jitter
#      so silhouettes differ stone-to-stone. Added ONE thin arcane glow seam
#      (make_seam_glow, reuses the core/eye cyan) per arm/leg at the
#      shoulder/hip-side joint — a hint of magical binding, not a light show.
#   2. True cascading FK lag — TREE_LAG/MOVE_LAG were single fixed-phase
#      delays on ONE object, not a chain. New CHAIN_DEPTH + cascade_frame()
#      generalize this: torso (root, depth0) leads on its own true motion
#      curve; arm/leg/head (depth1) and fist (depth2) replay the SAME
#      per-clip driver function delayed by depth*DELAY_PER_JOINT frames
#      (chunk_i_pose(f) = root_motion(f - i*DELAY_PER_JOINT)) instead of
#      computing their own motion at the current frame in lockstep. Applied
#      to idle/move/attack/hit/death; awaken's already-approved sequential
#      per-arm rise (addition #3) is left untouched, only its fist-trails-arm
#      offset is re-expressed via the same DELAY_PER_JOINT constant.
#   3. Ground plane + floating debris — NEW shared `_ground_common.py`
#      (sibling to `_ficha_common.py`) provides build_ground()/ground_height()
#      (same noise formula for the visible mesh and the query function, so
#      they can't drift apart). This build now: (a) samples ground_height()
#      once at the golem's own footprint origin as a uniform Z offset for
#      every rigid-body pivot (TORSO_PIVOT, HEAD_PIVOT, SHOULDER_*, HIP_*,
#      TREE_PIVOT, GLOW_CHEST_OFFSET, TARGET_Z) so the rig plants on the
#      real (irregular) terrain instead of an implicit Z=0; (b) the 3 loose
#      moss stones get their OWN per-XY ground_height() query, both at rest
#      (STANDING/DORMANT) and at their DEATH-clip tumble destination (fixes
#      the literal "a stone falls, ends up floating" bug — a stone that
#      rolls to a new XY on uneven terrain used to keep the Z it had before
#      it moved); (c) build_ground() adds a large visible ground mesh to the
#      scene so floating errors are self-evident in every future render.
import bpy
import bmesh
import math
import os
import sys
import random as pyrandom
from mathutils import Vector, Euler
from mathutils import noise as mnoise

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
ANIM_DIR = os.path.join(REN_DIR, "anim")
os.makedirs(ANIM_DIR, exist_ok=True)

sys.path.insert(0, os.path.dirname(OUT_DIR))
import _ground_common as groundlib  # noqa: E402 — PASS 6 fix 3, shared ground utility

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
FPS = 24
scene.render.fps = FPS
SEED = 20260719

# PASS 6 fix 3 (2026-07-20+, PO Joan — "generating floating models... generate
# a ground/floor reference"): sample the real (irregular, not flat) terrain
# height once at the golem's own footprint origin and use it as a uniform Z
# offset for every rigid-body pivot below (TORSO_PIVOT, HEAD_PIVOT,
# SHOULDER_*, HIP_*, TREE_PIVOT, GLOW_CHEST_OFFSET) — this is an
# APPROXIMATION (a single sample under the whole rig, not per-foot IK) but is
# enough to genuinely plant the golem on its local terrain instead of the
# old implicit Z=0 assumption, and is cheap/safe: it doesn't touch any
# part-to-part relationship, only where the whole rig sits vertically. The
# 3 loose moss stones get their OWN per-XY ground_height() query below
# instead (they're independent falling/resting objects, not part of the
# rigid body — see STONE_STANDING/STONE_DORMANT).
GROUND_OFFSET_Z = groundlib.ground_height(0.0, 0.0)


# =============================================================================
# EASING HELPERS
# =============================================================================
def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


def clamp01(t):
    return max(0.0, min(1.0, t))


def smoothstep(t):
    t = clamp01(t)
    return t * t * (3.0 - 2.0 * t)


def ease_in_cubic(t):
    t = clamp01(t)
    return t * t * t


def ease_out_cubic(t):
    t = clamp01(t)
    return 1.0 - (1.0 - t) ** 3


def ease_in_expo(t):
    t = clamp01(t)
    return 0.0 if t <= 0.0 else 2.0 ** (10.0 * (t - 1.0))


def ease_out_expo(t):
    t = clamp01(t)
    return 1.0 if t >= 1.0 else 1.0 - 2.0 ** (-10.0 * t)


def lerp_v(a, b, t):
    return a.lerp(b, clamp01(t))


# =============================================================================
# ROCK GENERATOR — noise-displaced icosphere, flat-shaded, per-vertex painterly
# stone color (§1.1: dense-but-stylized, not cheap-facet low-poly). `center`
# offsets the blob in LOCAL space so callers control the object's pivot
# (object.location is left at world PIVOT by the caller — mesh data encodes
# the offset from that pivot, so rotating the object rotates around the pivot,
# not the blob's own centroid). Mirrors golem_floating/build_golem.py's
# make_rock, generalized with the `center` param for multi-blob rigid parts.
# =============================================================================
STONE_DARK = (0.075, 0.088, 0.108)   # grey-blue desaturated, cool
STONE_LIGHT = (0.44, 0.49, 0.56)
MOSS_COL = (0.19, 0.36, 0.115)       # desaturated moss (not the saturated green of golem_floating)
# 2026-08-25 form pass: previous (0.26, 0.35, 0.185) gave a mean G-R
# separation of only ~0.04 on moss-eligible vertices once blended against the
# blue-grey stone — present in the data (GLB probe confirmed COLOR_0 ships)
# but perceptually near-invisible in the truth render. Wider G-vs-R/B spread
# keeps the same desaturated family while actually reading as colonization.
# ^ fix 2: lowered blue / raised green-vs-blue separation vs the original
# (0.32,0.38,0.29) — that version was nearly indistinguishable in hue from
# the cool blue-grey stone once blended (see make_rock's moss comment).


def make_rock(name, center=None, radius=0.5, subdiv=2, seed=0, elongate=(1.0, 1.0, 1.0),
              taper=0.0, noise_scale=2.6, noise_strength=0.32, ridge_weight=0.9,
              moss=True, moss_bias=0.24, flat=True,
              dark=STONE_DARK, light=STONE_LIGHT, moss_col=MOSS_COL,
              cave_dir=None, cave_angle=0.55, cave_depth=0.0,
              cave_color=(0.015, 0.017, 0.022), caves=None, chipped=False,
              align_dir=None):
    """cave_dir (unit Vector, direction FROM the blob's own sphere-origin
    `center`) + cave_angle (half-angle, radians) + cave_depth: pulls verts
    inside the angular cone around cave_dir RADIALLY INWARD toward `center`
    (smoothstep falloff on angle) to carve a physical concave hollow — no
    separate interior geometry needed, the dent + a dark vertex-color blend
    (cave_color) is enough to read as a shadowed opening (2026-07-19/20
    dormant-cave add). Deliberately ANGULAR, not a fixed-point Euclidean
    radius: a first attempt targeted a single fixed 3D point on the NOMINAL
    (un-noised) sphere surface and a Euclidean cave_radius around it — caught
    via an isolated debug render (instrumented vert count) that this touched
    only 9 of 642 verts, because noise_strength displaces the ACTUAL surface
    up to +-0.34 units off the nominal radius, so a fixed point mostly floats
    in empty space or deep inside solid rock instead of sitting where the
    bumpy surface actually is. Measuring by ANGLE from the blob's own center
    is immune to that — it always finds and carves the real surface in that
    direction, regardless of local noise/taper variance.
    cave_t() is recomputed from v.co (not cached by index) in both the
    displacement pass and the color pass, deliberately — bmesh remove_doubles
    between the two passes can renumber vertex indices, so an index-keyed
    mask dict would silently mismatch after that call.
    `caves` (fix 5, 2026-07-20+): optional LIST of extra cave specs
    (dict(dir=Vector, angle=rad, depth=float, color=(r,g,b))) carved in
    ADDITION to the single cave_dir/cave_angle/cave_depth/cave_color quad —
    lets one blob carve MULTIPLE independent hollows (e.g. two eye sockets on
    the same head_b0 blob) instead of only one. Single-cave params stay for
    backward compat (torso's dormant-mound cave keeps using them); `caves`
    is for the new multi-socket case."""
    center = center if center is not None else Vector((0.0, 0.0, 0.0))
    all_caves = list(caves) if caves else []
    if cave_dir is not None and cave_depth > 0.0:
        all_caves.append(dict(dir=cave_dir, angle=cave_angle, depth=cave_depth, color=cave_color))
    # BLOCK VOCABULARY (2026-08-26, PO Joan): the noise-displaced icosphere
    # read as "piedras redondas / asteriscos" next to the in-game golem's
    # stacked chamfered blocks (golem_A_vs_B.png verdict). The body now
    # speaks gen_golem.py's make_rock_block language — chamfered, jittered,
    # flat-shaded boxes — while keeping this function's signature, caves,
    # taper, moss and vertex-color pipeline untouched so every call site,
    # pose table and animation beat keeps working unchanged.
    # v11 (PO 2026-08-26, con refs de esculturas de piedra): "sigues agregando
    # las irregularidades al cubo, así que queda el cubo sí o sí relleno".
    # Noise ON a cube keeps the cube underneath. A real stone is an ANGULAR
    # FACETED CHUNK: random planar cuts, wedges, tapers. So the base form is
    # now a CONVEX HULL of a corner-biased point cloud — the corner bias
    # keeps the stacked-block DNA of golem A, the hull's random facets give
    # every stone its own irregular cut. No subdivide+displace pass at all.
    bm = bmesh.new()
    lrng = pyrandom.Random(9173 + seed * 131)
    seed_v = Vector((seed * 17.13, seed * 5.71, seed * 31.9))
    paint_seed_v = seed_v + Vector((91.0, 47.0, 13.0))
    sx = radius * 1.02 * elongate[0]
    sy = radius * 1.02 * elongate[1]
    sz = radius * 1.02 * elongate[2]
    pts = []
    # 8 battered corners (strong independent jitter = each corner its own cut)
    for cx in (-1, 1):
        for cy in (-1, 1):
            for cz in (-1, 1):
                pts.append(Vector((cx * lrng.uniform(0.50, 1.0),
                                   cy * lrng.uniform(0.50, 1.0),
                                   cz * lrng.uniform(0.50, 1.0))))
    # a few face/edge bulges so silhouettes break asymmetrically
    for _ in range(6):
        d = Vector((lrng.uniform(-1, 1), lrng.uniform(-1, 1), lrng.uniform(-1, 1)))
        if d.length < 1e-3:
            continue
        pts.append(d.normalized() * lrng.uniform(0.78, 1.10))
    hull_in = [bm.verts.new(Vector((p.x * sx, p.y * sy, p.z * sz))) for p in pts]
    res = bmesh.ops.convex_hull(bm, input=hull_in)
    _drop = list({g for g in (res["geom_interior"] + res["geom_unused"])
                  if isinstance(g, bmesh.types.BMVert)})
    if _drop:
        bmesh.ops.delete(bm, geom=_drop, context="VERTS")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    # ONE light chamfer so facet edges catch the toon light (family signature)
    min_dim = max(0.001, min(sx, sy, sz))
    bmesh.ops.bevel(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
                    offset=min(0.07 * radius, min_dim * 0.30), offset_type="OFFSET",
                    segments=1, profile=0.5, affect="EDGES", clamp_overlap=True)
    # v13 (PO refs 20-26: "ni una es muy pulida") — organic EROSION over the
    # angular hull: one subdivide + per-normal noise displacement kills the
    # perfect-polyhedron read (flat facets, long straight edges) while the
    # hull keeps the stone's angular cuts underneath. Strength rides the
    # caller's existing noise_strength knob.
    bmesh.ops.subdivide_edges(bm, edges=list(bm.edges), cuts=1, use_grid_fill=False)
    bm.normal_update()
    _ero = noise_strength * 0.50 * radius
    for v in bm.verts:
        n = mnoise.noise(v.co * (2.6 / max(radius, 0.05)) + seed_v)
        v.co += v.normal * ((n * 2.0 - 1.0) * _ero)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    # Small whole-block rotation jitter (big blocks tilt less: their top
    # carries rooted vegetation).
    rj = math.radians(7.0) * max(0.4, min(1.0, 0.5 / max(radius, 0.001)))
    rot = Euler((lrng.uniform(-rj, rj), lrng.uniform(-rj, rj),
                 lrng.uniform(-rj * 2.0, rj * 2.0))).to_matrix()
    for v in bm.verts:
        v.co = rot @ v.co
    # "Piedra picada" (PO 2026-08-26): shear one oblique corner off and leave
    # the cut face jagged — the fracture that keeps the body from reading as
    # all-perfect-cubes. Callers opt in per stone via chipped=True.
    if chipped:
        cdir = Vector((lrng.uniform(-1, 1), lrng.uniform(-1, 1), lrng.uniform(0.2, 1.0)))
        cdir.normalize()
        bmesh.ops.bisect_plane(
            bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
            plane_co=cdir * (0.52 * max(sx, sy, sz)), plane_no=cdir,
            clear_outer=True)
        boundary = [e for e in bm.edges if e.is_boundary]
        if boundary:
            bmesh.ops.holes_fill(bm, edges=boundary, sides=12)
        # jag the fresh cut: displace its verts along the cut plane
        for v in bm.verts:
            if abs((v.co.normalized().dot(cdir)) - 1.0) < 0.35 and v.co.length > 0.3 * min_dim:
                v.co += cdir * lrng.uniform(-0.10, 0.02) * radius
                v.co.x += lrng.uniform(-0.05, 0.05) * sx
                v.co.y += lrng.uniform(-0.05, 0.05) * sy
    if taper:
        zs = [v.co.z for v in bm.verts]
        zmin, zmax = min(zs), max(zs)
        h = max(1e-5, zmax - zmin)
        for v in bm.verts:
            t = (v.co.z - zmin) / h
            s = 1.0 + taper * (1.0 - t)
            v.co.x *= s
            v.co.y *= s
    # Chain alignment (v7 fix): a box's elongated axis must FOLLOW the limb
    # chain direction or consecutive blocks read as scattered loose cubes
    # instead of a segmented stone arm/leg. Rotates local +Z onto align_dir.
    if align_dir is not None and align_dir.length > 1e-6:
        q = Vector((0, 0, 1)).rotation_difference(align_dir.normalized())
        rot_m = q.to_matrix()
        for v in bm.verts:
            v.co = rot_m @ v.co
    for v in bm.verts:
        v.co += center

    def cave_t_single(co, spec):
        rel = co - center
        d = rel.length
        if d < 1e-6:
            return 0.0
        cos_a = max(-1.0, min(1.0, rel.normalized().dot(spec["dir"])))
        ang = math.acos(cos_a)
        if ang >= spec["angle"]:
            return 0.0
        t = 1.0 - ang / spec["angle"]
        return t * t * (3.0 - 2.0 * t)  # smoothstep falloff, 1 at cone axis, 0 at cone edge

    def cave_max(co):
        """Strongest single cave affecting this vertex (specs don't overlap
        in practice — e.g. two eye sockets pointed at different local
        directions — so max() picks whichever cone the vertex sits in)."""
        best_t, best_spec = 0.0, None
        for spec in all_caves:
            t = cave_t_single(co, spec)
            if t > best_t:
                best_t, best_spec = t, spec
        return best_t, best_spec

    if all_caves:
        for v in bm.verts:
            t_s, spec = cave_max(v.co)
            if t_s > 0.0:
                rel = v.co - center
                d = rel.length
                if d > 1e-6:
                    new_d = max(0.05, d - spec["depth"] * t_s)
                    v.co = center + rel.normalized() * new_d

    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()

    # FLOAT_COLOR, not BYTE_COLOR (fix 2 root cause, 2026-07-20): BYTE_COLOR
    # corner attributes silently apply an sRGB DECODE when read back (by
    # Python's color_attributes API and by the Attribute shader node) even
    # though bmesh's loop-color WRITE does no corresponding encode — so a
    # hand-authored "linear" tone like STONE_DARK=(0.075,0.088,0.108) came
    # back as (0.0065,0.0080,0.0116) once rendered, and a fully-blended
    # MOSS_COL patch (t_ao=1) came back barely distinguishable from plain
    # dark stone. This is why moss read as invisible EVERYWHERE (not just on
    # limbs) even though moss=True was already set on the torso from the
    # start — confirmed empirically: a (0.075,0.088,0.108)/(0.32,0.38,0.29)
    # round-trip through BYTE_COLOR crushes both toward black; the identical
    # round-trip through FLOAT_COLOR returns the exact values written.
    col_layer = bm.loops.layers.float_color.new("Col")
    bm.verts.ensure_lookup_table()
    # Per-BLOCK tonal variation (gen_golem 2026-06-10 lesson: value jitter +
    # slight hue drift per stone is THE cheap win that makes a pile of blocks
    # read as distinct real stones instead of one flat mass).
    # v7 fix: one shared VALUE factor + tiny per-channel drift — the previous
    # fully-independent per-channel jitter tinted adjacent stones lilac/green
    # and the pile read as patchwork, not stone.
    _val = 1.0 + lrng.uniform(-0.11, 0.11)
    block_tone = [_val * (1.0 + lrng.uniform(-0.025, 0.025)) for _ in range(3)]
    vcol = {}
    for v in bm.verts:
        nrm = v.normal
        paint = mnoise.noise(v.co * 3.5 + paint_seed_v)
        t_ao = max(0.0, min(1.0, 0.20 + 0.55 * (nrm.z * 0.5 + 0.5) + 0.35 * paint))
        base = [(dark[i] + (light[i] - dark[i]) * t_ao) * block_tone[i] for i in range(3)]
        if moss and nrm.z > moss_bias:
            # Fix 2 cont. (2026-07-20): even with the color-space bug fixed,
            # this blend was mathematically too weak to ever read as green —
            # worked the numbers by hand: the OLD ramp (divide by the full
            # 1.0-moss_bias span, cap blend at *0.80) only reaches ~60% blend
            # at the single MOST upward-facing vertex on the whole mesh,
            # giving a best-case green-vs-blue separation of ~0.03 — clamped
            # by float rounding to invisible against the stone's own natural
            # blue-grey tint. Steeper ramp (saturates well before the most
            # extreme normals, so more of the "roughly upward" surface gets
            # real coverage, not just the mathematical apex) + higher blend
            # ceiling (0.95) now gives ~0.10+ separation at typical
            # moss-eligible vertices — confirmed by hand-computing both old
            # and new formulas against the same sample vertex before/after.
            mt = min(1.0, (nrm.z - moss_bias) / max(0.001, (1.0 - moss_bias) * 0.42))
            mt *= 0.7 + 0.3 * paint
            base = [base[i] + (moss_col[i] - base[i]) * mt * 0.95 for i in range(3)]
        ct, cspec = cave_max(v.co)
        if ct > 0.0:
            ccol = cspec["color"]
            base = [base[i] + (ccol[i] - base[i]) * ct for i in range(3)]
        vcol[v.index] = base
    for f in bm.faces:
        for loop in f.loops:
            c = vcol[loop.vert.index]
            loop[col_layer] = (c[0], c[1], c[2], 1.0)

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = not flat
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return obj


def make_foliage_blob(name, center, radius, seed=0, noise_strength=0.20):
    """Smooth (non-flat) canopy blob — organic soft foliage, not stone."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=radius)
    seed_v = Vector((seed * 13.7, seed * 29.3, seed * 5.1))
    for v in bm.verts:
        n = mnoise.noise(v.co * 3.0 + seed_v)
        v.co += v.normal * ((n * 2.0 - 1.0) * noise_strength * radius)
        v.co += center
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return paint_col_white(obj)


def paint_col_white(obj):
    """Fill a FLOAT_COLOR 'Col' layer with WHITE on a vegetation mesh.
    MANDATORY before joining veg into a rock body (found 2026-08-26, black
    spikes in Godot): the joined mesh carries the rocks' 'Col' attribute, and
    vertices that never wrote it get the layer DEFAULT — BLACK. glTF then
    multiplies COLOR_0 over the whole mesh, so every tuft/bush/flower
    rendered pitch black in Godot while Blender's EEVEE (whose flat materials
    ignore the attribute) kept showing them green. White = neutral multiply."""
    ca = obj.data.color_attributes.new(name="Col", type="FLOAT_COLOR", domain="CORNER")
    n = len(ca.data)
    ca.data.foreach_set("color", [1.0] * (n * 4))
    return obj


def make_grass_tuft(name, center, radius=0.16, seed=0, blades=7, height=0.26):
    """Fan of thin tetrahedral grass blades leaning outward from `center`.
    Tetrahedra (not single-sided cards) so Godot's backface culling can never
    make a blade vanish. ~4 tris per blade. Body vegetation for the guardian:
    joined into torso/head so it rides every pose — dormant mound reads as a
    grassy hillock and the SAME growth stands up with the golem (ref 10:
    nothing 'appears new' on waking)."""
    rng = pyrandom.Random(seed)
    bm = bmesh.new()
    for i in range(blades):
        ang = rng.uniform(0, math.tau)
        lean = rng.uniform(0.15, 0.55)
        r0 = rng.uniform(0.15, 0.85) * radius
        bx, by = math.cos(ang) * r0, math.sin(ang) * r0
        h = height * rng.uniform(0.6, 1.15)
        w = 0.030 * rng.uniform(0.7, 1.2)
        tip = Vector((bx + math.cos(ang) * lean * h, by + math.sin(ang) * lean * h, h))
        # base triangle (tiny footprint) + apex = tetrahedron
        pax, pay = -math.sin(ang) * w, math.cos(ang) * w
        v0 = bm.verts.new(center + Vector((bx + pax, by + pay, 0.0)))
        v1 = bm.verts.new(center + Vector((bx - pax, by - pay, 0.0)))
        v2 = bm.verts.new(center + Vector((bx - math.cos(ang) * w, by - math.sin(ang) * w, 0.0)))
        v3 = bm.verts.new(center + tip)
        for tri in ((v0, v1, v3), (v1, v2, v3), (v2, v0, v3), (v0, v2, v1)):
            bm.faces.new(tri)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return paint_col_white(obj)


def make_flower(name, center, seed=0, petal_len=0.062, tilt_deg=38.0):
    """Tiny 5-petal cup flower (golem v5 rule: delicate florcitas, never
    plates). Petals are thin quads fanned around a small center knob, tilted
    up into a cup. ~12 tris. Material slots: [0]=petals, [1]=center."""
    rng = pyrandom.Random(seed)
    bm = bmesh.new()
    tilt = math.radians(tilt_deg + rng.uniform(-8, 8))
    for i in range(5):
        a = i * math.tau / 5.0 + rng.uniform(-0.12, 0.12)
        dir2 = Vector((math.cos(a), math.sin(a), 0.0))
        up = Vector((0, 0, 1))
        out = (dir2 * math.cos(tilt) + up * math.sin(tilt)).normalized()
        side = dir2.cross(up).normalized() * petal_len * 0.32
        base = center + dir2 * 0.012 + Vector((0, 0, 0.008))
        tip = base + out * petal_len
        v0 = bm.verts.new(base + side)
        v1 = bm.verts.new(base - side)
        v2 = bm.verts.new(tip - side * 0.55)
        v3 = bm.verts.new(tip + side * 0.55)
        f = bm.faces.new((v0, v1, v2, v3))
        f.material_index = 0
    res = bmesh.ops.create_cube(bm, size=0.026)
    for v in res["verts"]:
        v.co += center + Vector((0, 0, 0.016))
    for f in bm.faces:
        if len(f.verts) == 4 and all(v in res["verts"] for v in f.verts):
            f.material_index = 1
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return paint_col_white(obj)


def pack_satellites(prefix, center, halfext, count=6, seed=0, r_range=(0.18, 0.34),
                    embed=0.40, reject=None):
    """Smaller stones PRESSED into a core stone's surface (PO refs 20-26,
    2026-08-27: every body mass is a packed AGGLOMERATE — one big core with
    varied medium/small stones compressed around it, never one clean
    polygon). Distinct from make_rubble_cluster (free-floating piles): these
    sink ~40% of their radius into the core so the cluster reads compressed.
    halfext: the core's half-extents (box support). reject(d): optional
    direction veto (keep satellites off the cave mouth / head seat)."""
    rng = pyrandom.Random(seed)
    sats = []
    tries = 0
    while len(sats) < count and tries < count * 25:
        tries += 1
        d = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-1, 1)))
        if d.length < 0.2:
            continue
        d.normalize()
        if reject is not None and reject(d):
            continue
        t = 1.0 / max(abs(d.x) / halfext.x, abs(d.y) / halfext.y, abs(d.z) / halfext.z)
        r = rng.uniform(*r_range)
        c = center + d * (t + r * (1.0 - embed))
        i = len(sats)
        sats.append(make_rock(f"{prefix}_{i}", center=c, radius=r, subdiv=1,
                              seed=seed * 47 + i,
                              noise_scale=3.6, noise_strength=0.16,
                              ridge_weight=0.1, moss=(i % 3 != 2), moss_bias=0.12))
    return sats


def make_rubble_cluster(prefix, center, count=4, base_r=0.16, seed=0, spread=0.45):
    """Un monton de piedras chicas (PO 2026-08-26: 'algunas en monton y otras
    mas grandes en menor cantidad') — a handful of small weathered blocks
    scattered around `center`, meant to orbit joints and rest at the bust's
    base. Returns a list of objects (caller appends materials + joins)."""
    rng = pyrandom.Random(seed)
    rocks = []
    for i in range(count):
        off = Vector((rng.uniform(-1, 1) * spread, rng.uniform(-1, 1) * spread,
                      rng.uniform(-0.4, 0.5) * spread))
        r = base_r * rng.uniform(0.65, 1.35)
        rocks.append(make_rock(f"{prefix}_{i}", center=center + off, radius=r,
                               subdiv=1, seed=seed * 31 + i,
                               noise_scale=3.6, noise_strength=0.16,
                               ridge_weight=0.1, moss=(i % 2 == 0), moss_bias=0.1))
    return rocks


def make_leaf_clump(name, center, radius, n_cards, seed, card=0.30):
    """A cloud of alpha-cutout leaf-sprite CARDS (prairie tree_pack read):
    each card is one quad mapped to the full leaf-cluster atlas, oriented
    outward+up with jitter. This is what makes foliage read as LEAVES
    instead of a smooth blob."""
    rng = pyrandom.Random(seed)
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")
    for _ in range(n_cards):
        d = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-0.5, 1)))
        if d.length < 1e-3:
            d = Vector((0, 0, 1))
        d.normalize()
        pos = center + Vector((d.x * radius * rng.uniform(0.1, 1.0),
                               d.y * radius * rng.uniform(0.1, 1.0),
                               d.z * radius * 0.72 * rng.uniform(0.1, 1.0)))
        nrm = (d + Vector((0, 0, rng.uniform(0.25, 0.8)))).normalized()
        t1 = nrm.cross(Vector((0.31, 0.71, 0.63))).normalized()
        t2 = nrm.cross(t1).normalized()
        s = card * rng.uniform(0.7, 1.3) * 0.5
        corners = ((-1, -1), (1, -1), (1, 1), (-1, 1))
        uvs = ((0, 0), (1, 0), (1, 1), (0, 1))
        vs = [bm.verts.new(pos + t1 * (a * s) + t2 * (b * s)) for a, b in corners]
        f = bm.faces.new(vs)
        for loop, uv in zip(f.loops, uvs):
            loop[uv_layer].uv = uv
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return paint_col_white(obj)


def join_parts(objs, name, pivot):
    """Join blobs that ALL share the same object.location=pivot (identity
    rotation/scale at build time) — mesh-local coordinates already encode the
    offset from pivot, so NO transform_apply here (that would bake pivot into
    the mesh and reset location to 0, destroying the custom pivot)."""
    for o in objs:
        o.location = pivot
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    joined = bpy.context.view_layer.objects.active
    joined.name = name
    joined.location = pivot
    return joined


# =============================================================================
# MATERIALS
# =============================================================================
def mat_stone(name):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n = m.node_tree.nodes["Principled BSDF"]
    n.inputs["Roughness"].default_value = 0.86
    n.inputs["Specular IOR Level"].default_value = 0.22
    # ShaderNodeVertexColor ("Color Attribute"), NOT the generic
    # ShaderNodeAttribute: the glTF exporter only recognizes the former as
    # vertex-color usage. With the generic Attribute node the export silently
    # drops COLOR_0 entirely (verified 2026-08-25: wip.blend carried full
    # per-vertex moss/AO data while the exported GLB had none).
    attr = m.node_tree.nodes.new("ShaderNodeVertexColor")
    attr.layer_name = "Col"
    m.node_tree.links.new(attr.outputs["Color"], n.inputs["Base Color"])
    return m


def mat_glow(name, color=(0.14, 0.82, 0.92), strength=2.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n = m.node_tree.nodes["Principled BSDF"]
    n.inputs["Base Color"].default_value = (*color, 1.0)
    n.inputs["Emission Color"].default_value = (*color, 1.0)
    n.inputs["Emission Strength"].default_value = strength
    n.inputs["Roughness"].default_value = 0.2
    return m, n


def mat_glow_grimy(name, color=(0.14, 0.82, 0.92), grime_color=(0.085, 0.075, 0.065),
                    strength=2.0):
    """Fix 4 (2026-07-20+, embed the crystal): a per-vertex 'Grime' FLOAT_COLOR
    attribute (built by make_gem, below) mixes the glow's Base/Emission Color
    toward a dark desaturated patina wherever the mask is high — dirty regions
    read darker/duller even at full Emission Strength, clean crack-lines still
    shine through. Emission STRENGTH itself stays a single uniform BSDF input
    (still keyframed per-frame by the existing awaken reveal curve,
    glow_chest_strength/glow_head_strength) — only the COLOR fed into that
    strength is grime-mixed, so the reveal animation is untouched."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Roughness"].default_value = 0.28

    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Grime"

    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = 'RGBA'
    for s in mix.inputs:
        if s.name == "Factor" and s.type == 'VALUE':
            nt.links.new(attr.outputs["Fac"], s)
        elif s.name == "A" and s.type == 'RGBA':
            s.default_value = (*color, 1.0)
        elif s.name == "B" and s.type == 'RGBA':
            s.default_value = (*grime_color, 1.0)
    mix_out = None
    for s in mix.outputs:
        if s.type == 'RGBA':
            mix_out = s
            break
    nt.links.new(mix_out, n.inputs["Base Color"])
    nt.links.new(mix_out, n.inputs["Emission Color"])
    n.inputs["Emission Strength"].default_value = strength
    return m, n


def make_gem(name, center, radius, subdiv=2, seed=0, elongate=(1.0, 1.0, 1.0),
             noise_strength=0.05, grime_bias=0.15, grime_amount=0.55):
    """Small emissive gem/eye blob with a baked 'Grime' FLOAT_COLOR mask
    (patchy noise, biased toward outward/upward-facing normals — dust settles
    from above/outside, same directional logic as make_rock's moss) driving
    mat_glow_grimy's Base/Emission-Color mix. Mirrors make_rock's FLOAT_COLOR
    convention (NOT BYTE_COLOR — see the 2026-07-20 sRGB round-trip gotcha in
    make_rock's own docstring, same bug would silently crush this mask too)."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radius)
    seed_v = Vector((seed * 11.3, seed * 41.7, seed * 3.2))
    for v in bm.verts:
        n = mnoise.noise(v.co * 4.0 + seed_v)
        v.co += v.normal * ((n * 2.0 - 1.0) * noise_strength * radius)
        v.co.x *= elongate[0]
        v.co.y *= elongate[1]
        v.co.z *= elongate[2]
        v.co += center
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()

    grime_layer = bm.loops.layers.float_color.new("Grime")
    bm.verts.ensure_lookup_table()
    gmask = {}
    for v in bm.verts:
        nrm = v.normal
        paint = mnoise.noise(v.co * 5.0 + seed_v + Vector((61.0, 7.0, 29.0)))
        dirf = max(0.0, nrm.z * 0.4 + nrm.y * 0.4 + 0.2)  # up + outward-back bias
        g = 0.0
        if dirf > grime_bias:
            g = min(1.0, (dirf - grime_bias) / max(0.001, 1.0 - grime_bias))
            g *= (0.5 + 0.5 * paint) * grime_amount
        gmask[v.index] = g
    for f in bm.faces:
        for loop in f.loops:
            g = gmask[loop.vert.index]
            loop[grime_layer] = (g, g, g, 1.0)

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return paint_col_white(obj)


def mat_flat(name, color, rough=0.75):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n = m.node_tree.nodes["Principled BSDF"]
    n.inputs["Base Color"].default_value = (*color, 1.0)
    n.inputs["Roughness"].default_value = rough
    return m


STONE_MAT = mat_stone("guardian_stone")
BARK_MAT = mat_flat("tree_bark", (0.115, 0.085, 0.065), rough=0.9)
FOLIAGE_MAT = mat_flat("tree_foliage", (0.145, 0.40, 0.36), rough=0.6)
# Canopy tint drift (tree_pack 2026-07-28 lesson: uniform lobes read as one
# candy blob) — second, warmer-green foliage tone for the off lobes.
FOLIAGE_MAT_B = mat_flat("tree_foliage_b", (0.165, 0.42, 0.27), rough=0.6)
FOLIAGE_MAT_C = mat_flat("tree_foliage_c", (0.115, 0.33, 0.20), rough=0.6)  # v17: third, deeper tone

# v18 (PO: "las hojas... mas parecidos a los de pradera"): the prairie trees
# read as trees because their canopy is LEAF-SPRITE CARDS (alpha-cutout
# atlas), not smooth blobs. Reuse tree_pack's existing green atlas + bark
# diffuse instead of regenerating them.
_TREE_TEX_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tree_pack", "_tex")


def mat_leaf_cards(name, atlas_png="leaf_green_512.png"):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n = m.node_tree.nodes["Principled BSDF"]
    n.inputs["Roughness"].default_value = 0.72
    n.inputs["Specular IOR Level"].default_value = 0.1
    tex = m.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.join(_TREE_TEX_DIR, atlas_png))
    m.node_tree.links.new(tex.outputs["Color"], n.inputs["Base Color"])
    m.node_tree.links.new(tex.outputs["Alpha"], n.inputs["Alpha"])
    try:
        m.blend_method = "CLIP"
        m.alpha_threshold = 0.45
    except AttributeError:
        pass  # renamed across Blender versions; the alpha link alone exports alphaMode
    m.use_backface_culling = False
    return m


def mat_bark_tex(name):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n = m.node_tree.nodes["Principled BSDF"]
    n.inputs["Roughness"].default_value = 0.9
    tex = m.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.join(_TREE_TEX_DIR, "bark_brown_01_diff_512.jpg"))
    m.node_tree.links.new(tex.outputs["Color"], n.inputs["Base Color"])
    return m


LEAF_MAT = mat_leaf_cards("tree_leaf_cards")
BARK_TEX_MAT = mat_bark_tex("tree_bark_tex")
# Body vegetation (2026-08-25 form pass, Joan: dormant must read as a grassy
# mini-mount, ref image #36 style): desaturated greens tied to MOSS_COL's
# family, darker so the toon rig's light multiply doesn't wash them out.
VEG_GRASS_MAT = mat_flat("veg_grass", (0.14, 0.27, 0.09), rough=0.85)
VEG_BUSH_MAT = mat_flat("veg_bush", (0.115, 0.30, 0.155), rough=0.7)
FLOWER_PINK_MAT = mat_flat("flower_pink", (0.58, 0.24, 0.38), rough=0.65)
FLOWER_WHITE_MAT = mat_flat("flower_white", (0.62, 0.62, 0.55), rough=0.65)
FLOWER_CENTER_MAT = mat_flat("flower_center", (0.55, 0.44, 0.12), rough=0.7)
GLOW_CHEST_MAT, GLOW_CHEST_BSDF = mat_glow_grimy("glow_chest_mat")
GLOW_HEAD_MAT, GLOW_HEAD_BSDF = mat_glow_grimy("glow_head_mat", grime_color=(0.06, 0.055, 0.05))
# v18: 2.0 blew out to WHITE under the preview's bloom (the documented
# "white cloud" gotcha) — at 1.2 the cyan survives and the bloom halos it.
GLOW_BASE_STRENGTH = 1.2

# =============================================================================
# BUILD — STANDING pose is the authored rest shape. Front = -Y (matches
# golem_floating's camera convention: cam sits at negative Y, looks toward
# +Y, so the -Y-facing surface is what the camera/player sees).
# =============================================================================
# v10: whole standing skeleton raised +0.80 — the air-gapped leg chains got
# ~0.8m longer and the feet must still plant on the ground. (Un-compresses
# the "chato" v9 silhouette at the same time.)
# v15 (PO: "muy alto y delgado — en las refs se sienten mas heavys"):
# whole skeleton drops 0.35 and widens; the mass reads squat again.
TORSO_PIVOT = Vector((0.0, 0.0, 2.15 + GROUND_OFFSET_Z))
# Dormant-mound cave (addition #1, 2026-07-19/20): a shadowed hollow carved
# into torso_b0's own front-lower surface (-Y = camera/player-facing side,
# per the file's front-direction convention; low Z-ish = the taper-widened
# base). Angular cone (not a fixed 3D point — see make_rock's cave_dir
# docstring for why) centered on the (0,-0.989,-0.148) direction from
# torso_b0's own sphere-origin, i.e. mostly straight front with a slight
# downward tilt. Subtle per ref_02 ("indistinguishable from terrain until it
# wakes") — angle/depth kept moderate, not a gaping hole.
CAVE_DIR = Vector((0.0, -1.0, 0.0))
# Tightened for the flat block face (2026-08-26): 42deg/0.55 carved on a box
# front read as a smooth satellite dish, not a shadowed hollow.
CAVE_ANGLE = math.radians(28)
CAVE_DEPTH = 0.34
# Torso keeps somewhat more ruggedness than the limbs (it's the "ancient
# core") but is still rounded down from the original ridge_weight=0.9 default
# — the unmodified torso next to smoothed-out arms/fists looked like a
# mismatched thorny core bolted onto smooth limbs (fix 1 quality pass).
# Fix 1 (2026-07-20+, distinct stones not a fused pillar): torso_b0<->b1 used
# to sit at a center-to-center distance of ~0.99 vs a combined radius of 1.90
# (ratio ~0.52) — tighter than the golem_floating-validated 0.58-0.75
# cohesion regime, so the two biggest torso masses fused into one smooth dome
# with no visible waist/seam between them (this IS most of the "reads like a
# pillar" complaint — the torso is the biggest visual mass on the body).
# Pushed b1 out along the SAME b0->b1 direction to land at ratio ~0.62 (still
# genuinely overlapping/cohesive, just enough less than before for a real
# facet-shadow seam to survive between them). b2 was already at ratio ~0.71
# (b0->b2), left alone.
TORSO_ROUND = dict(noise_scale=3.0, noise_strength=0.28, ridge_weight=0.55)
# PO 2026-08-26 (Clash Royale stone golem): ONE dominant torso/bust block
# (b0, taller and wider) with only SMALL accent stones around it — the old
# three-similar-masses stack competed with itself.
torso_blobs = [
    # The dominant bust slab: wide and deep-chested but capped LOW enough
    # (top ~z1.65 local / ~3.35 world) that the head still crests above it
    # (2026-07-03 rule: la cabeza debe CRESTAR) — v6's 1.22-tall monolith
    # swallowed the head entirely.
    make_rock("torso_b0", center=Vector((0.0, 0.10, 0.70)), radius=1.0, subdiv=3, seed=1,
              elongate=(1.38, 0.88, 0.82), taper=0.15,
              cave_dir=CAVE_DIR, cave_angle=CAVE_ANGLE, cave_depth=CAVE_DEPTH,
              cave_color=(0.006, 0.007, 0.010), **TORSO_ROUND),
    # v10: accents REST on b0's top face (b0 top ~z1.65 local, sunk 0.04 for
    # a seated read) instead of half-merging into the bust.
    # v14 (Joan, Godot preview): at y-0.45 the 28-deg lean carried this stone
    # to world (-1.35, 4.07) — exactly the head's seat, they collided. Moved
    # to top-center-right, clear of the head's forward overhang.
    make_rock("torso_b1", center=Vector((0.38, 0.12, 2.00)), radius=0.40, subdiv=3, seed=2,
              elongate=(1.05, 0.9, 0.90), **TORSO_ROUND),
    make_rock("torso_b2", center=Vector((0.12, 0.45, 2.08)), radius=0.50, subdiv=3, seed=3,
              elongate=(1.0, 1.05, 0.92), **TORSO_ROUND),
]
# v13 (refs 20-26): the bust is a packed AGGLOMERATE — satellites pressed
# into b0's surface. Vetoes: the cave mouth (front, d.y < -0.75) and the
# head seat (top-center, d.z > 0.85).
torso_blobs += pack_satellites(
    "torso_sat", Vector((0.0, 0.10, 0.70)),
    Vector((1.02 * 1.13, 1.02 * 0.78, 1.02 * 0.93)),
    count=9, seed=71, r_range=(0.20, 0.44), embed=0.42,
    reject=lambda d: d.y < -0.75 or d.z > 0.85)
_torso_blobs_tail = [
    # Fix 4 (embed the crystal): a thin rock LIP near the mouth of torso_b0's
    # own dormant-mound CAVE (below), grazing the crystal from the camera
    # side so it's partially OCCLUDED instead of sitting in open air. Distance
    # to the crystal center (see GLOW_CHEST_OFFSET below) is ~0.37, just under
    # the two radii's sum (~0.39) — a grazing overlap, not a full envelope
    # (a first attempt nested the crystal at the CAVE's own centerline, deep
    # enough to sit BEHIND the cave's carved floor surface -- fully occluded,
    # confirmed invisible by a dedicated close-up render -- fixed by moving
    # it to a distance greater than the carved-floor depth, see below).
    # Orchestrator fix (2026-07-20c): the 0.26-radius lip only grazed the
    # crystal (~0.02 units of overlap past the two radii's sum) -- confirmed
    # by closeup_crystal.png still showing the gem's FULL round silhouette,
    # fully exposed. Doubling the radius so it genuinely overlaps and covers
    # a real portion of the gem from camera, not just brushes its edge.
    make_rock("torso_lip", center=Vector((-0.30, -0.50, 0.35)), radius=0.50, subdiv=2, seed=44,
              elongate=(1.1, 0.7, 0.85), noise_scale=3.2, noise_strength=0.22,
              ridge_weight=0.35, moss=True, moss_bias=0.10),
]
torso_blobs += _torso_blobs_tail
for o in torso_blobs:
    o.data.materials.append(STONE_MAT)
# Body vegetation (2026-08-25): bushes + grass tufts EMBEDDED into the torso's
# upper masses (overlap past the surface per the 0.55-0.65x cohesion rule so
# they fuse, not hover). Joined into the torso object so every pose/clip
# carries them for free — the dormant mound reads as a grassy hillock and the
# standing golem keeps the SAME growth (ref 10 continuity). Torso only tilts
# 20 deg X in dormant, so "up" stays up in both poses.
# v17 (PO: "el pasto esta FLOTANDO, deberia estar pegado a la piedra... mas
# repartido, y ponerle unas flores pequeñas"): vegetation ROOTS by sampling
# the bust's REAL upward-facing vertices — contact guaranteed by
# construction, spread across the whole top instead of hand-guessed points
# that drift every time the torso reshapes.
def surface_spots(src_obj, count, seed, min_up=0.55, min_z=0.60, sink=0.05):
    rng = pyrandom.Random(seed)
    cands = [v.co.copy() for v in src_obj.data.vertices
             if v.normal.z > min_up and v.co.z > min_z]
    rng.shuffle(cands)
    spots = []
    for co in cands:
        if all((co - s).length > 0.40 for s in spots):
            spots.append(co)
        if len(spots) >= count:
            break
    return [s - Vector((0, 0, sink)) for s in spots]


_veg_spots = surface_spots(torso_blobs[0], 10, seed=91)
torso_veg = []
_n_bush = 2
for _i, _s in enumerate(_veg_spots[:_n_bush]):
    # v18: bushes speak the same leaf-card language as the tree
    torso_veg.append(make_leaf_clump(f"torso_bush_{_i}", _s + Vector((0, 0, 0.08)),
                                     0.20 + 0.05 * (_i % 2), n_cards=8,
                                     seed=21 + _i, card=0.26))
for _i, _s in enumerate(_veg_spots[_n_bush:]):
    torso_veg.append(make_grass_tuft(f"torso_grass_{_i}", _s, radius=0.16,
                                     seed=31 + _i, blades=13, height=0.24))
for o in torso_veg[:_n_bush]:
    o.data.materials.append(LEAF_MAT)
for o in torso_veg[_n_bush:]:
    o.data.materials.append(VEG_GRASS_MAT)
# Flowers (PO 2026-08-26): a sparse handful on the sunniest tops, near but
# not inside the grass — ecological placement, never random scatter.
# v17: more, smaller, and ROOTED like the grass (surface-sampled).
_flower_spots = surface_spots(torso_blobs[0], 6, seed=95, sink=0.02)
torso_flowers = [make_flower(f"torso_flower_{i}", s, seed=51 + i, petal_len=0.052)
                 for i, s in enumerate(_flower_spots)]
for i, fl in enumerate(torso_flowers):
    fl.data.materials.append(FLOWER_PINK_MAT if i % 3 != 1 else FLOWER_WHITE_MAT)
    fl.data.materials.append(FLOWER_CENTER_MAT)
# v11 (PO: "algunas en monton y otras mas grandes en menor cantidad"): small
# rubble piles orbiting the bust's base — size contrast against the few big
# hero stones.
torso_rubble = (make_rubble_cluster("torso_rub_a", Vector((-1.05, -0.45, -0.10)), count=4,
                                    base_r=0.16, seed=61, spread=0.35)
                + make_rubble_cluster("torso_rub_b", Vector((1.10, 0.30, 0.05)), count=3,
                                      base_r=0.14, seed=62, spread=0.30))
for o in torso_rubble:
    o.data.materials.append(STONE_MAT)
torso = join_parts(torso_blobs + torso_veg + torso_flowers + torso_rubble, "torso", TORSO_PIVOT)

# Hunch follow (2026-08-26): with the torso leaning 18 deg the upper-back
# surface swings ~0.32 forward / ~0.07 down at head height — the head tracks
# it and juts a touch further forward+down (sunk-in-shoulders Clash read).
# v10: rests ON the bust's top face instead of intersecting it — stones
# stack, they don't merge. v11: follows the 28-deg gorilla lean (further
# forward, a touch lower — head juts ahead of the braced bust).
# z: at the head's y (-1.28) the 28-deg-leaned bust surface sits at ~3.68
# world; jaw bottom is pivot-0.25 -> 3.95 rests the head with a 0.02 kiss
# (4.30 left it hovering 0.37 in the air, caught on the v11 board).
HEAD_PIVOT = Vector((0.0, -1.24, 3.52 + GROUND_OFFSET_Z))  # forward of the tree's trunk so a near-
# front camera reads them as separate silhouette elements, not the head sitting "on" the trunk
# Fix 3 (2026-07-20, PO refs 12/13): the head used to be a single blank rock
# blob with 2 floating glow dots — no readable face. Add carved facial
# FEATURES built the same way the body is (chunk/displacement geometry,
# joined into the same "head" object) instead of a decal: a brow ridge
# (overhang that shadows the eyes), a jaw mass (squares off the lower face),
# and a nose bridge between the eyes. Positions are tuned so brow/jaw
# protrude slightly FORWARD of head_b0's own sphere surface at their height
# (verified by hand against the sphere-radius math, then confirmed by
# render) — a flush blob wouldn't read as an overhang, it'd just look like
# more rock. Eyes (glow_head, below) sit in the gap between brow and jaw.
# Fix 5 (2026-07-20+, embed the eyes): two SOCKET cavities carved into
# head_b0 itself (reusing make_rock's cave mechanism via the new `caves`
# list — see its docstring) instead of the eyes sitting flush on the
# nominal sphere surface. Directions point from head_b0's own sphere-origin
# toward where the (now-recessed) glow_eye_L/R blobs sit, below — narrow
# cone (22deg) sized to just fit an eye + a socket rim, moderate depth
# (0.12) so the recess reads as a real hollow without punching through the
# ~0.42-radius head.
EYE_SOCKET_ANGLE = math.radians(22)
EYE_SOCKET_DEPTH = 0.12
EYE_SOCKET_DIR_L = Vector((-0.2956, -0.9552, 0.0))
EYE_SOCKET_DIR_R = Vector((0.2956, -0.9552, 0.0))
head_blobs = [
    make_rock("head_b0", center=Vector((0.0, 0.0, 0.30)), radius=0.42, subdiv=3, seed=4,
              elongate=(0.95, 0.95, 1.0),
              noise_scale=3.2, noise_strength=0.20, ridge_weight=0.35, moss=True,
              caves=[
                  dict(dir=EYE_SOCKET_DIR_L, angle=EYE_SOCKET_ANGLE, depth=EYE_SOCKET_DEPTH,
                       color=(0.010, 0.011, 0.014)),
                  dict(dir=EYE_SOCKET_DIR_R, angle=EYE_SOCKET_ANGLE, depth=EYE_SOCKET_DEPTH,
                       color=(0.010, 0.011, 0.014)),
              ]),
    # Tuned down from an earlier pass that used x-elongate=1.35 at z=0.56 —
    # rendered as a disconnected wide "hat brim" sitting ABOVE the skull
    # rather than a furrowed brow merged into it (confirmed by render: a
    # visible neck/gap read between the cap and the eyes). Narrower (closer
    # to head_b0's own width so it doesn't wing out sideways) and lower/
    # closer to the eye band so it overhangs the eyes directly.
    # v9 relief push: on the old SPHERE these centers put each feature proud
    # of the curved surface; the block's flat front face sits at y~-0.43, so
    # the same centers left brow/jaw/nose poking out barely 0.04-0.10 — the
    # face read as a faint engraving. Pushed forward so the features protrude
    # like real stacked stone slabs (ref 13 stoic carved face).
    make_rock("head_brow", center=Vector((0.0, -0.38, 0.46)), radius=0.26, subdiv=2, seed=40,
              elongate=(1.05, 0.70, 0.55),
              noise_scale=3.4, noise_strength=0.16, ridge_weight=0.25,
              moss=True, moss_bias=0.15),
    make_rock("head_jaw", center=Vector((0.0, -0.28, -0.02)), radius=0.34, subdiv=2, seed=41,
              elongate=(1.15, 0.70, 0.65),
              noise_scale=3.4, noise_strength=0.16, ridge_weight=0.25, moss=False),
    make_rock("head_nose", center=Vector((0.0, -0.46, 0.30)), radius=0.11, subdiv=2, seed=42,
              elongate=(0.55, 1.2, 1.5),
              noise_scale=3.6, noise_strength=0.12, ridge_weight=0.2, moss=False),
]
for _hb in head_blobs:
    _hb.data.materials.append(STONE_MAT)
# One small crown tuft (2026-08-25). Biased toward the head's BACK (+Y): the
# head pitches 78 deg forward in the dormant tuck, so a back-top tuft still
# points roughly up on the mound instead of stabbing into the ground.
_head_tuft = make_grass_tuft("head_grass", Vector((0.06, 0.16, 0.64)), radius=0.11,
                             seed=35, blades=5, height=0.16)
_head_tuft.data.materials.append(VEG_GRASS_MAT)
head = join_parts(head_blobs + [_head_tuft], "head", HEAD_PIVOT)

# Fix 4 (2026-07-20+, embed the crystal): nested INSIDE torso_b0's own
# dormant-mound CAVE hollow (CAVE_DIR/CAVE_ANGLE/CAVE_DEPTH above), not
# floating in open air below the torso (the OLD offset (0,-1.02,1.35)
# measured ~1.2-1.7 units from the nearest torso blob center — clearly
# outside every blob's surface, confirmed by render: a clean ball floating
# under the mound). ITERATION 2 of this fix nested it at distance 0.35
# along CAVE_DIR from torso_b0's center — confirmed INVISIBLE by a
# dedicated close-up render, because the cave's carved FLOOR sits at
# ~radius(1.05) - CAVE_DEPTH(0.55) =~0.50 from center, so a point at 0.35
# is BEHIND that floor (inside solid rock, occluded by the floor itself),
# not in the hollow's open air. The hollow's visible empty space is between
# the carved floor (~0.50) and the original convex surface (~1.05) — this
# position (distance 0.70 along CAVE_DIR) sits inside that range, so the
# gem is visible peeking out of the cave mouth instead of buried behind it.
# v10: +0.80 with the raised torso pivot — this constant is ABSOLUTE, and
# left at 1.90 the crystal floated at crotch height below the risen bust.
GLOW_CHEST_OFFSET = Vector((0.0, -0.86, 2.12 + GROUND_OFFSET_Z))  # v15: follows the squat torso's cave mouth
# v9: the block head's front face sits at y~-0.43 (flat), further out than
# the old sphere surface at this height — at the old -0.2866 the emissive
# eyes were BURIED 0.14 inside solid stone and the golem rendered eyeless.
# -0.47 puts them flush at the face, shadowed under the brow ledge (v5 rule:
# flush in the face, nothing in front).
GLOW_HEAD_OFFSET = HEAD_PIVOT + Vector((0.0, -0.47, 0.30))  # head front, at the eye sockets

glow_chest = make_gem("glow_chest", center=Vector((0.0, 0.0, 0.0)), radius=0.13, subdiv=2, seed=0,
                       elongate=(1.0, 0.65, 1.2), noise_strength=0.08, grime_bias=-0.10, grime_amount=0.8)
glow_chest.data.materials.append(GLOW_CHEST_MAT)
glow_chest.location = GLOW_CHEST_OFFSET.copy()

# Fix 5 cont.: eyes are now RECESSED (offset magnitude from head_b0's center
# pulled in from ~0.44 -- outside the nominal 0.42-radius sphere, i.e.
# sitting proud on the surface -- to ~0.30, i.e. nested at the floor of the
# EYE_SOCKET_* cavities carved into head_b0 above) and smaller (0.085->0.065
# radius) so they read as a small glow deep in a dark socket, not a sticker
# disc on the surface. 2 separate eye lobes joined into the SAME "glow_head"
# object/pivot as before, so downstream animation lines need zero changes.
glow_eye_L = make_gem("glow_eye_L", center=Vector((-0.0887, 0.0, 0.0)), radius=0.065, subdiv=2, seed=0,
                       elongate=(1.0, 0.6, 0.85), noise_strength=0.04, grime_bias=0.2, grime_amount=0.4)
glow_eye_R = make_gem("glow_eye_R", center=Vector((0.0887, 0.0, 0.0)), radius=0.065, subdiv=2, seed=0,
                       elongate=(1.0, 0.6, 0.85), noise_strength=0.04, grime_bias=0.2, grime_amount=0.4)
for _eo in (glow_eye_L, glow_eye_R):
    _eo.data.materials.append(GLOW_HEAD_MAT)
glow_head = join_parts([glow_eye_L, glow_eye_R], "glow_head", GLOW_HEAD_OFFSET)


def chain_positions(direction, radii, ratio=0.65, start=None):
    """Places len(radii) blob centers along `direction` (only its direction
    matters, any length) so each consecutive PAIR sits at
    ratio*(r_i+r_{i+1}) apart — genuine interpenetration derived from BOTH
    chunks' own size, not a fixed gap and not a fraction of a hand-picked
    fixed end-vector. Ports golem_floating's iteration-4b lesson (its big
    comment block documents 4 failed iterations before landing on this
    exact formula): the OLD golem_guardian arm hand-picked 5 t-fractions of
    a fixed ARM_END_LOCAL, which worked out to an effective overlap ratio of
    ~0.42 — tighter than the validated 0.58-0.75 cohesion-but-distinguishable
    regime, which is why the limb fused into one smooth pillar with almost
    no visible seam (fix 1). Returns a list of Vector centers, `start`-
    relative (`start` defaults to the origin, i.e. the first blob sits AT
    the chain's own object pivot, same convention as the old arm's first
    stop)."""
    start = start if start is not None else Vector((0.0, 0.0, 0.0))
    d = direction.normalized()
    centers = [start.copy()]
    cursor = 0.0
    for i in range(1, len(radii)):
        cursor += ratio * (radii[i - 1] + radii[i])
        centers.append(start + d * cursor)
    return centers


# =============================================================================
# PASS 6 fix 1 (2026-07-20+, PO Joan — "practically a stone antenna made of
# overlapping circular stones... IRREGULAR stones, overlapping, fused in an
# arcane way"). Two helpers:
#   jitter_radii() — breaks chain_positions' smooth taper into genuinely
#   mixed big/small stones (a real assembled pile, not a size gradient).
#   make_seam_glow() — a thin cyan crack at ONE joint per limb, reusing the
#   existing core/eye glow color/material language, suggesting the stones
#   are held together by magic rather than mechanically stacked. Deliberately
#   subtle (low emission strength, small radius) — "a hint, not another
#   light show" per the brief.
# =============================================================================
def jitter_radii(base_radii, jitter=0.38, seed=0):
    """Real assembled rock piles mix big and small stones, not a smooth
    taper. Applies an independent +-jitter fraction to EACH radius in a
    chain (seeded/deterministic) instead of the untouched smooth-taper list
    chain_positions used to receive verbatim."""
    rng = pyrandom.Random(seed)
    return [max(0.06, r * (1.0 + rng.uniform(-jitter, jitter))) for r in base_radii]


SEAM_GLOW_COLOR = (0.14, 0.82, 0.92)  # same cyan as the core/eyes — "arcane binding" language


def seam_joint_geometry(c0, r0, c1, r1, pad=1.12):
    """Analytic two-sphere intersection circle — the ACTUAL visible crease
    between two overlapping chain blobs. First attempt placed the seam at
    the pair's volumetric midpoint ((c0+c1)*0.5) — confirmed by render to
    be INVISIBLE, because once two blobs genuinely interpenetrate (as
    intended, per chain_positions' whole cohesion mechanism) that midpoint
    sits buried deep inside solid fused rock, not on any visible surface —
    same class of bug as the crystal/eye-socket 'floating vs buried' fixes
    documented earlier in this file. The two-sphere intersection circle is
    where the surfaces ACTUALLY cross, so a ring built there sits exactly on
    the real crease. `pad` (>1) slightly oversizes the ring so it pokes past
    the blobs' own noise displacement instead of being swallowed by it.
    Returns (point, radius, direction) for make_seam_glow."""
    d_vec = c1 - c0
    dist = d_vec.length
    if dist < 1e-6:
        return (c0 + c1) * 0.5, min(r0, r1) * 0.5, Vector((0, 0, 1))
    d = d_vec / dist
    x = (dist * dist + r0 * r0 - r1 * r1) / (2.0 * dist)
    circle_r = math.sqrt(max(0.02, r0 * r0 - x * x))
    return c0 + d * x, circle_r * pad, d


def make_seam_glow(name, center, direction, radius=0.075, thickness=0.020, strength=0.38):
    """A thin flattened glowing ring at a limb joint — reads as a magical
    seam binding two separately-assembled stones together, instead of
    mechanical stacking. Oriented perpendicular to the chain direction (so
    it wraps the joint like a crack, not a floating coin) and joined into
    the same limb object as everything else, so it inherits that limb's
    per-frame transform for free. Static (not part of the awaken glow
    reveal) — an always-present ancient binding, not a power-up cue."""
    # v18 (PO: "un poligono azul no se lee como nada"): a small emissive ORB
    # instead of the flat ring disc — with the preview's bloom it reads as an
    # energy mote floating in the joint gap. Real particle VFX comes with the
    # Godot wiring.
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=radius * 0.62)
    for v in bm.verts:
        v.co += center
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    m, _ = mat_glow(f"{name}_mat", color=SEAM_GLOW_COLOR, strength=strength)
    obj.data.materials.append(m)
    return obj


# Fix 2 (add legs): arms are now SHORTER — they hang free at the sides
# (brief: "freeing the arms to hang/gesture at the sides instead of
# touching the ground") now that real legs (below) bear the golem's weight.
# Direction is unsigned (side multiplies X): mostly down, slightly forward
# (-Y) and outward (+X).
ARM_DIR_LOCAL = Vector((0.24, -0.46, -0.85))  # v16: less sideways flare, more forward (simio)
# v9 (Clash read): 2 LARGE stones per arm, not 4 similar cubes — many
# same-size blocks read as a scattered pile, few big ones read as a limb.
# v14 (Joan): "mas piedras con menos espacio" — 3 links, tighter gaps.
# v15: thicker (heavy read) and slightly shorter chain.
ARM_RADII = [0.50, 0.42, 0.34]
# v10 (PO: "se sobreponen las piedras... se siente raro" + "brazos/piernas
# mas separadas"): 0.65 was a SPHERE-overlap cohesion ratio — on aligned
# blocks it buried each stone deep inside its neighbor. At 1.30 the faces
# separate into a visible AIR GAP (~0.15m at arm scale): the stones float
# apart, held by magic (canon PO 2026-07-17, gaps=magia), and the seam glow
# ring now sits in real air instead of inside rock. Also lengthens the limb
# chains, stretching the "chato/comprimido" v9 silhouette.
ARM_TOUCH = 1.05  # v15: casi contacto (Joan: aun "muy alejada una de otra" en v14)


def make_arm(side):
    """side: -1.0 (left) or +1.0 (right). Blob centers come from
    chain_positions (ARM_TOUCH ratio) instead of hand-picked t-fractions —
    see that function's docstring for why. Standing rest rotation is
    (0,0,0) — the "hang at the side" shape is baked directly into the blob
    offsets. Returns (blobs, last_blob_center, last_blob_radius) — the
    wrist-end center/radius are needed by the caller to continue the SAME
    chain into the fist.
    PASS 6 fix 1: radii come through jitter_radii() (genuinely mixed
    big/small stones, not a smooth taper) and each blob gets its OWN
    elongate/seed/noise_scale/noise_strength jitter so silhouettes differ
    stone-to-stone — the "identical sphere / stacked-bead antenna" fix. One
    arcane glow seam is added at the shoulder-side joint (blob0<->blob1)."""
    d = Vector((side * ARM_DIR_LOCAL.x, ARM_DIR_LOCAL.y, ARM_DIR_LOCAL.z))
    radii = jitter_radii(ARM_RADII, jitter=0.38, seed=100 + int(side))
    centers = chain_positions(d, radii, ratio=ARM_TOUCH)
    blobs = []
    for i, (c, r) in enumerate(zip(centers, radii)):
        # Fix 1 (round the limbs — river-stone, never a point, refs 10/11/13/
        # 15): low ridge_weight + lower strength + higher scale vs the torso's
        # TORSO_ROUND preset — UNCHANGED from the prior pass (still correct,
        # do not reopen sharp facets). Fix 2 (moss continuity): moss=True on
        # EVERY blob — UNCHANGED, still correct.
        rng = pyrandom.Random(700 + int(side) * 10 + i)
        elong = (1.0 + rng.uniform(-0.18, 0.18), 1.0 + rng.uniform(-0.18, 0.18),
                 1.08 + rng.uniform(-0.15, 0.20))
        # One "piedra picada" per arm (PO 2026-08-26), at a DIFFERENT link on
        # each side (left: mid, right: lower) so the fractures read organic,
        # not mirrored.
        chip = i == 1  # the forearm stone; per-side seeds vary the fracture
        b = make_rock(f"arm_b{i}_{side}", center=c, radius=r, subdiv=2,
                       seed=10 + side + i * 3 + rng.randint(0, 9),
                       elongate=elong,
                       noise_scale=3.8 + rng.uniform(-0.6, 0.6),
                       noise_strength=0.15 + rng.uniform(-0.03, 0.05), ridge_weight=0.15,
                       moss=True, chipped=chip, align_dir=d)
        blobs.append(b)
        # v14: NO satellites on the air-gapped arm links — pressed pebbles on
        # top of floating chain stones read as orbiting debris, not a packed
        # limb (v13 board verdict). Agglomerate packing lives on the big
        # grounded masses only: bust, thigh, fist.
    for o in blobs:
        o.data.materials.append(STONE_MAT)
    seam_pt, seam_r, seam_dir = seam_joint_geometry(centers[0], radii[0], centers[1], radii[1])
    seam = make_seam_glow(f"arm_seam_{side}", seam_pt, seam_dir, radius=seam_r)
    blobs.append(seam)
    return blobs, centers[-1], radii[-1]


# Shoulders ride the 18-deg lean (forward+slightly down) — also sells the
# knuckle-drag hunch on its own.
# x +-1.64: air gap vs the torso side face (half-x ~1.15 + stone half ~0.43
# + ~0.06 of air) — v9's 1.38 buried the shoulder stone in the bust.
# v11 gorilla brace: shoulders drop and come forward so the heavier arm
# chains can plant their fists near the ground ahead of the body.
# v16 (Joan): "brazos muy hacia los costados — un 20% mas angosto, postura
# de simio" — 1.78 -> 1.45 and the chain aims more forward.
SHOULDER_L = Vector((-1.45, -0.60, 2.58 + GROUND_OFFSET_Z))
SHOULDER_R = Vector((1.45, -0.60, 2.58 + GROUND_OFFSET_Z))
_arm_blobs_L, _wrist_L, _wrist_r_L = make_arm(-1.0)
_arm_blobs_R, _wrist_R, _wrist_r_R = make_arm(1.0)
arm_L = join_parts(list(_arm_blobs_L), "arm_L", SHOULDER_L)
arm_R = join_parts(list(_arm_blobs_R), "arm_R", SHOULDER_R)


def make_fist(side):
    """Terminal boulder-knuckle — the BIGGEST single mass on the limb (per
    brief: "fist-boulders"), bigger than the wrist blob it attaches to so
    the arm visibly THICKENS toward its business end. Knuckle offset is now
    derived the same JOINT_TOUCH way as the arm chain (fix 1 — the old
    offset ratio was ~0.43, over-fused) instead of a hand-picked vector."""
    FIST_MAIN_R = 0.55
    main = make_rock(f"fist_main_{side}", center=Vector((0.0, 0.0, 0.0)), radius=FIST_MAIN_R, subdiv=3,
                      seed=20 + side, elongate=(1.18, 1.08, 0.78),
                      noise_scale=4.0, noise_strength=0.14, ridge_weight=0.12, moss=True)
    KNU_R = 0.20
    knu_dir = Vector((side * 0.60, -0.25, 0.75))
    # Knuckle keeps a KISS gap (1.12), not the full limb air gap — a pebble
    # drifting far off the fist reads as debris, not anatomy.
    knu_offset = knu_dir.normalized() * (1.12 * (FIST_MAIN_R + KNU_R))
    knuckle = make_rock(f"fist_kn_{side}", center=knu_offset, radius=KNU_R,
                         subdiv=2, seed=21 + side,
                         noise_scale=4.0, noise_strength=0.14, ridge_weight=0.12, moss=True)
    # v11: a small pebble pile drifting around each planted fist ("monton")
    pebbles = make_rubble_cluster(f"fist_rub_{side}", Vector((side * 0.45, -0.30, -0.25)),
                                  count=2, base_r=0.12, seed=63 + int(side), spread=0.20)
    # v13: packed satellites pressed into the fist boulder itself
    fist_sats = pack_satellites(f"fist_sat_{side}", Vector((0.0, 0.0, 0.0)),
                                Vector((FIST_MAIN_R * 1.20, FIST_MAIN_R * 1.10,
                                        FIST_MAIN_R * 0.80)),
                                count=3, seed=150 + int(side) * 11,
                                r_range=(FIST_MAIN_R * 0.28, FIST_MAIN_R * 0.42),
                                embed=0.45)
    parts = [main, knuckle] + pebbles + fist_sats
    for o in parts:
        if not o.data.materials:
            o.data.materials.append(STONE_MAT)
    return parts, FIST_MAIN_R


FIST_MAIN_R = 0.55
_arm_dir_L = Vector((-ARM_DIR_LOCAL.x, ARM_DIR_LOCAL.y, ARM_DIR_LOCAL.z)).normalized()
_arm_dir_R = Vector((ARM_DIR_LOCAL.x, ARM_DIR_LOCAL.y, ARM_DIR_LOCAL.z)).normalized()
# PASS 6 fix 1: gap sized off the ACTUAL (jittered) wrist-blob radius per
# side, not the nominal ARM_RADII[-1] — the two can now differ by up to 38%
# since make_arm jitters its radii, and using the stale nominal value would
# silently under/over-size the wrist<->fist gap relative to the real blob.
_fist_gap_L = ARM_TOUCH * (_wrist_r_L + FIST_MAIN_R)
_fist_gap_R = ARM_TOUCH * (_wrist_r_R + FIST_MAIN_R)
FIST_L_STANDING = SHOULDER_L + _wrist_L + _arm_dir_L * _fist_gap_L
FIST_R_STANDING = SHOULDER_R + _wrist_R + _arm_dir_R * _fist_gap_R
_fL = make_fist(-1.0)
_fR = make_fist(1.0)
fist_L = join_parts(list(_fL[0]), "fist_L", FIST_L_STANDING)
fist_R = join_parts(list(_fR[0]), "fist_R", FIST_R_STANDING)


def clamp_above_ground(loc, obj, pad=0.03):
    """v17 hard rule (PO 2026-08-27: "el piso es el limite del modelado, asi
    no traspasa el suelo"): raise a part's STANDING pivot until its lowest
    vertex clears the local terrain height. Threshold derived from the LIVE
    mesh + live ground function (LECCIONES.md #8: never a copied constant)."""
    min_local_z = min(v.co.z for v in obj.data.vertices)
    floor_z = groundlib.ground_height(loc.x, loc.y) + pad
    if loc.z + min_local_z < floor_z:
        loc = loc.copy()
        loc.z = floor_z - min_local_z
    return loc


FIST_L_STANDING = clamp_above_ground(FIST_L_STANDING, fist_L)
FIST_R_STANDING = clamp_above_ground(FIST_R_STANDING, fist_R)


# =============================================================================
# LEGS (fix 2 — mandatory, previously NONE existed; arms doubled as ground
# support). Same chain_positions technique as the arm, thicker/sturdier
# radii (weight-bearing), hip pivot set so the standing silhouette reads as
# torso-above-2-legs with arms free at the sides (see ARM_DIR_LOCAL above).
# Each leg is ONE joined object (thigh+shin+foot chunks) — no separate
# fist-style split needed since nothing needs independent wrist rotation.
# =============================================================================
LEG_DIR_LOCAL = Vector((0.28, -0.08, -0.95))  # unsigned (side multiplies X): outward flare +
# slight forward lean + mostly straight down — the outward flare is what
# makes the leg read APART from the torso's own belly silhouette as it
# descends (same clearance logic as the shoulder note on the old arm).
LEG_RADII = [0.48, 0.40]  # v15: thicker stumps (heavy read)
LEG_TOUCH = 1.04  # v15: casi contacto
FOOT_R = 0.34


def make_leg(side):
    """side: -1.0 (left) or +1.0 (right). thigh/shin chain via
    chain_positions, then a flattened/elongated FOOT chunk continuing the
    same chain (forward = -Y, matches the body's own front convention) so
    the leg visibly plants on the ground instead of ending in a round
    stump. Standing rest rotation is (0,0,0) — pose is baked into offsets,
    same convention as arm/torso/head.
    PASS 6 fix 1: same jitter_radii() + per-blob shape variety + one arcane
    glow seam treatment as make_arm — see that function's docstring."""
    d = Vector((side * LEG_DIR_LOCAL.x, LEG_DIR_LOCAL.y, LEG_DIR_LOCAL.z))
    radii = jitter_radii(LEG_RADII, jitter=0.32, seed=300 + int(side))
    centers = chain_positions(d, radii, ratio=LEG_TOUCH)
    blobs = []
    for i, (c, r) in enumerate(zip(centers, radii)):
        rng = pyrandom.Random(800 + int(side) * 10 + i)
        elong = (1.0 + rng.uniform(-0.15, 0.15), 1.0 + rng.uniform(-0.15, 0.15),
                 1.10 + rng.uniform(-0.12, 0.18))
        b = make_rock(f"leg_b{i}_{side}", center=c, radius=r, subdiv=2,
                       seed=50 + side + i * 3 + rng.randint(0, 9),
                       elongate=elong,
                       noise_scale=3.6 + rng.uniform(-0.5, 0.5),
                       noise_strength=0.16 + rng.uniform(-0.03, 0.05), ridge_weight=0.18,
                       moss=True, align_dir=d)
        blobs.append(b)
        if i == 0:  # v13: packed satellites on the thigh stone
            blobs.extend(pack_satellites(
                f"leg_sat_{side}", c, Vector((r * 1.05, r * 1.05, r * 1.16)),
                count=2, seed=180 + int(side) * 9,
                r_range=(r * 0.32, r * 0.46), embed=0.45))
    foot_gap = LEG_TOUCH * (radii[-1] + FOOT_R)
    foot_c = centers[-1] + d.normalized() * foot_gap
    foot_r_j = FOOT_R * (1.0 + pyrandom.Random(899 + int(side)).uniform(-0.15, 0.15))
    foot = make_rock(f"leg_foot_{side}", center=foot_c, radius=foot_r_j, subdiv=2, seed=53 + side,
                      elongate=(1.10, 1.40, 0.55), taper=-0.08,
                      noise_scale=3.4, noise_strength=0.14, ridge_weight=0.15, moss=True)
    blobs.append(foot)
    for o in blobs:
        o.data.materials.append(STONE_MAT)
    seam_pt, seam_r, seam_dir = seam_joint_geometry(centers[0], radii[0], centers[1], radii[1])
    seam = make_seam_glow(f"leg_seam_{side}", seam_pt, seam_dir, radius=seam_r)
    blobs.append(seam)
    return blobs, centers[-1], d.normalized()


HIP_L = Vector((-0.80, 0.22, 1.66 + GROUND_OFFSET_Z))  # v15: wider stance, lower
HIP_R = Vector((0.80, 0.22, 1.66 + GROUND_OFFSET_Z))
_leg_blobs_L, _shin_L, _leg_dir_L = make_leg(-1.0)
_leg_blobs_R, _shin_R, _leg_dir_R = make_leg(1.0)
leg_L = join_parts(list(_leg_blobs_L), "leg_L", HIP_L)
leg_R = join_parts(list(_leg_blobs_R), "leg_R", HIP_R)
# v17: same floor rule as the fists — feet plant ON the terrain, never through.
HIP_L = clamp_above_ground(HIP_L, leg_L)
HIP_R = clamp_above_ground(HIP_R, leg_R)

# ---- tree: trunk (cone frustum) + 3 foliage blobs, joined ----
# Tracks the 18-deg torso lean: the upper-back anchor point moved ~0.30
# forward / slightly up vs the old 7-deg posture.
# v19 (PO: "queda flotando"): the anchor SAMPLES the torso's real surface
# under the tree's footprint — transform local verts by the 28-deg STANDING
# lean, take the highest one near the tree's x/y, sink the pivot 0.18 into
# it. Same guarantee-by-construction as the rooted vegetation.
_lean = math.radians(28)
_c28, _s28 = math.cos(_lean), math.sin(_lean)
_anchor_z = []
for _v in torso.data.vertices:
    _wy = _v.co.y * _c28 - _v.co.z * _s28
    _wz = _v.co.y * _s28 + _v.co.z * _c28 + TORSO_PIVOT.z
    if abs(_v.co.x - 0.05) < 0.40 and -0.30 < _wy < 0.40:
        _anchor_z.append(_wz)
TREE_PIVOT = Vector((0.05, 0.02, max(_anchor_z) - 0.18))
# Torso-LOCAL anchor (v20): un-lean the sampled world seat so every clip can
# re-derive the tree's position from the torso's live transform — the
# authoring loop overrides pose["tree"] location with this each frame.
TREE_ANCHOR_REL = Euler((-_lean, 0, 0)).to_matrix() @ (TREE_PIVOT - TORSO_PIVOT)
# v17 tree realism (PO: "un arbol muy low poly... como los de la pradera,
# sin ramas simetricas que apuntan a todos lados — mas al azar"): CURVED
# tapered trunk tube (no more straight cone-pole), 3 SHORT branches at
# random heights/azimuths reaching INTO the canopy, and a crown of ~18
# small multi-tone dabs in asymmetric clumps instead of 5 big lollipop
# lobes. tree_pack vocabulary at guardian scale; full leaf-atlas port stays
# a future polish pass.
_tree_rng = pyrandom.Random(777)




def make_trunk_tube(name, path_pts, radii, sides=9):
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")
    rings = []
    for c, r in zip(path_pts, radii):
        ring = []
        for k in range(sides):
            a = k / sides * math.tau
            ring.append(bm.verts.new(c + Vector((math.cos(a) * r, math.sin(a) * r, 0.0))))
        rings.append(ring)
    for i in range(len(rings) - 1):
        for k in range(sides):
            v0, v1 = rings[i][k], rings[i][(k + 1) % sides]
            v2, v3 = rings[i + 1][(k + 1) % sides], rings[i + 1][k]
            f = bm.faces.new((v0, v1, v2, v3))
            u0, u1 = k / sides * 2.0, (k + 1) / sides * 2.0
            vv0, vv1 = i * 0.55, (i + 1) * 0.55
            for loop, uv in zip(f.loops, ((u0, vv0), (u1, vv0), (u1, vv1), (u0, vv1))):
                loop[uv_layer].uv = uv
    bm.faces.new(rings[0])
    bm.faces.new(tuple(reversed(rings[-1])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return paint_col_white(obj)


# gently S-curved trunk, 1.7m tall, tapering 0.19 -> 0.07
_trunk_path = [Vector((0.0, 0.0, 0.0)), Vector((0.05, -0.04, 0.45)),
               Vector((0.14, 0.02, 0.95)), Vector((0.08, 0.09, 1.40)),
               Vector((0.0, 0.05, 1.70))]
trunk = make_trunk_tube("tree_trunk", _trunk_path, [0.19, 0.16, 0.125, 0.095, 0.07])
trunk.data.materials.append(BARK_TEX_MAT)

_tree_parts = [trunk]
# 3 short random branches, each feeding a leaf-card clump (v18: cards with
# the prairie leaf atlas replace the smooth blobs)
for _bi in range(3):
    u = _tree_rng.uniform(0.55, 0.9)
    base = _trunk_path[int(u * (len(_trunk_path) - 1))].copy()
    az = _tree_rng.uniform(0, math.tau)
    up = _tree_rng.uniform(0.5, 0.9)
    d = Vector((math.cos(az), math.sin(az), up)).normalized()
    blen = _tree_rng.uniform(0.35, 0.55)
    br = make_trunk_tube(f"tree_branch_{_bi}",
                         [base, base + d * blen * 0.6, base + d * blen],
                         [0.055, 0.038, 0.022], sides=6)
    br.data.materials.append(BARK_TEX_MAT)
    _tree_parts.append(br)
    clump = make_leaf_clump(f"tree_leaves_b{_bi}", base + d * (blen + 0.10), 0.34,
                            n_cards=9, seed=90 + _bi * 7, card=0.58)
    clump.data.materials.append(LEAF_MAT)
    _tree_parts.append(clump)
# main crown: 3 asymmetric leaf-card clumps around the trunk top
_crown_top = _trunk_path[-1]
# v19 (PO: "las hojas deberian ser mas grandes — mira las proporciones"):
# cards ~doubled, clump radii up — the canopy must read against a 10m body.
for _ci, (_cx, _cy, _cz, _cr, _n) in enumerate(
        ((0.05, 0.02, 0.34, 0.55, 18), (-0.34, 0.12, 0.14, 0.42, 12), (0.30, -0.16, 0.08, 0.38, 11))):
    clump = make_leaf_clump(f"tree_leaves_c{_ci}", _crown_top + Vector((_cx, _cy, _cz)),
                            _cr, n_cards=_n, seed=120 + _ci * 11, card=0.62)
    clump.data.materials.append(LEAF_MAT)
    _tree_parts.append(clump)
tree = join_parts(_tree_parts, "tree", TREE_PIVOT)

# ---- moss stones (2-3 small stones around the base, per brief) ----
# PASS 6 fix 3: these are independent loose rocks (exactly the "if a stone
# falls, it ends up floating" case Joan flagged) — each gets its OWN
# ground_height() query at its own (x, y), not a hand-picked Z literal or
# the rig's single origin-sampled GROUND_OFFSET_Z. STONE_SETTLE_Z preserves
# the ORIGINAL hand-tuned settle depth (how far each stone's center sits
# above its own contact point, e.g. partially embedded) — previously added
# to an implicit flat Z=0, now added to the real local terrain height.
STONE_SETTLE_Z = {"stone_1": 0.27, "stone_2": 0.24, "stone_3": 0.31}
STONE_XY_STANDING = {
    "stone_1": (1.55, 0.85), "stone_2": (-1.25, 1.05), "stone_3": (0.30, -1.55),
}
STONE_STANDING = {
    nm: Vector((x, y, groundlib.ground_height(x, y) + STONE_SETTLE_Z[nm]))
    for nm, (x, y) in STONE_XY_STANDING.items()
}
stone_objs = {}
for i, (nm, pos) in enumerate(STONE_STANDING.items()):
    r = [0.30, 0.26, 0.34][i]
    blob = make_rock(nm, center=Vector((0, 0, 0)), radius=r, subdiv=2, seed=30 + i,
                      noise_scale=3.2, noise_strength=0.22, ridge_weight=0.4,
                      moss=True, moss_bias=0.05)
    blob.data.materials.append(STONE_MAT)
    blob.location = pos
    stone_objs[nm] = blob

PARTS = {
    "torso": torso, "head": head, "arm_L": arm_L, "arm_R": arm_R,
    "fist_L": fist_L, "fist_R": fist_R, "leg_L": leg_L, "leg_R": leg_R, "tree": tree,
    "stone_1": stone_objs["stone_1"], "stone_2": stone_objs["stone_2"], "stone_3": stone_objs["stone_3"],
}
TRIS = 0
for _o in list(PARTS.values()) + [glow_chest, glow_head]:
    TRIS += sum(len(p.vertices) - 2 for p in _o.data.polygons)
print(f"[golem_guardian] tris={TRIS}")

# =============================================================================
# REST-POSE TABLES — STANDING (authored rest, rot=0 baseline for rigid parts
# whose shape already encodes the pose) and DORMANT (mound tuck delta).
# =============================================================================
STANDING = {
    # v11: 28 deg (PO: "muy posicion anatomica" at 18 — the golem must read
    # BRACED on its big heavy arms, gorilla weight-forward, not standing).
    "torso": dict(loc=TORSO_PIVOT.copy(), rot=Vector((math.radians(28), 0, 0)), scale=Vector((1, 1, 1))),
    "head": dict(loc=HEAD_PIVOT.copy(), rot=Vector((math.radians(5), 0, 0)), scale=Vector((1, 1, 1))),
    "arm_L": dict(loc=SHOULDER_L.copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "arm_R": dict(loc=SHOULDER_R.copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "fist_L": dict(loc=FIST_L_STANDING.copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "fist_R": dict(loc=FIST_R_STANDING.copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "leg_L": dict(loc=HIP_L.copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "leg_R": dict(loc=HIP_R.copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "tree": dict(loc=TREE_PIVOT.copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "stone_1": dict(loc=STONE_STANDING["stone_1"].copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "stone_2": dict(loc=STONE_STANDING["stone_2"].copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "stone_3": dict(loc=STONE_STANDING["stone_3"].copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
}

DORMANT = {
    "torso": dict(loc=Vector((0.0, 0.12, 0.55)), rot=Vector((math.radians(20), 0, 0)), scale=Vector((1.05, 1.05, 0.70))),
    "head": dict(loc=Vector((0.0, 0.30, 0.95)), rot=Vector((math.radians(78), 0, 0)), scale=Vector((0.88, 0.88, 0.88))),
    # arms are a ~2.2m lever from the shoulder pivot — folding that into a
    # 2.2m-tall mound needs SCALE, not rotation alone (a pure-rotation fold
    # of a limb this long swings its end ~1.7m away from the pivot, well
    # outside the mound). Shrink + tuck close + fold up against the torso.
    # Z lowered 1.00->0.40ish (addition #3, 2026-07-19/20): each arm must
    # read as a SEPARATE mass buried IN THE EARTH at the mound's base, not
    # folded mid-torso — this is what a sequential ground-rise needs to sell.
    # Fix 2 retune: the arm chain is now ~1.33m shoulder->fist (was ~2.27m
    # before it was shortened to hang free at the sides — see ARM_DIR_LOCAL)
    # so the dormant tuck no longer needs as aggressive a shrink to fit
    # inside the mound (0.42 -> 0.52).
    "arm_L": dict(loc=Vector((-0.42, 0.14, 0.38)), rot=Vector((math.radians(-60), 0, math.radians(-30))), scale=Vector((0.52, 0.52, 0.52))),
    "arm_R": dict(loc=Vector((0.42, 0.14, 0.38)), rot=Vector((math.radians(-60), 0, math.radians(30))), scale=Vector((0.52, 0.52, 0.52))),
    "fist_L": dict(loc=Vector((-0.52, 0.08, 0.20)), rot=Vector((0, 0, 0)), scale=Vector((0.62, 0.62, 0.62))),
    "fist_R": dict(loc=Vector((0.52, 0.08, 0.20)), rot=Vector((0, 0, 0)), scale=Vector((0.62, 0.62, 0.62))),
    # Legs (fix 2, new): tucked/buried near the mound's base, folded flat-ish
    # (large X rotation) so the "standing vertical leg" shape lies low and
    # close to the ground under the mound instead of poking straight up.
    "leg_L": dict(loc=Vector((-0.34, 0.16, 0.16)), rot=Vector((math.radians(75), 0, math.radians(-18))), scale=Vector((0.42, 0.42, 0.42))),
    "leg_R": dict(loc=Vector((0.34, 0.16, 0.16)), rot=Vector((math.radians(75), 0, math.radians(18))), scale=Vector((0.42, 0.42, 0.42))),
    "tree": dict(loc=Vector((0.05, 0.35, 2.00)), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "stone_1": dict(loc=None, rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "stone_2": dict(loc=None, rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "stone_3": dict(loc=None, rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
}
# PASS 6 fix 3: dormant stone XY (unchanged from the original hand-tuned
# tuck positions) resolved to a REAL ground_height() Z, same treatment as
# STONE_STANDING above — these are still independent loose rocks, not part
# of the rigid body's uniform GROUND_OFFSET_Z shift below.
_STONE_XY_DORMANT = {
    "stone_1": (1.10, 0.60), "stone_2": (-0.90, 0.75), "stone_3": (0.15, -0.80),
}
for _nm, (_x, _y) in _STONE_XY_DORMANT.items():
    DORMANT[_nm]["loc"] = Vector((_x, _y, groundlib.ground_height(_x, _y) + STONE_SETTLE_Z[_nm]))

# PASS 6 fix 3: every OTHER dormant part (rigid body — torso/head/arms/
# fists/legs/tree) shifts by the same single-sample GROUND_OFFSET_Z used for
# the STANDING pivots above, so the dormant mound sits on the real local
# terrain too, not an implicit Z=0. Stones are excluded (already resolved
# per-XY, immediately above) — applying both would double-shift them.
for _nm, _d in DORMANT.items():
    if _nm in _STONE_XY_DORMANT:
        continue
    _d["loc"] = _d["loc"] + Vector((0, 0, GROUND_OFFSET_Z))

PART_NAMES = list(STANDING.keys())
FIST_REL = {"L": FIST_L_STANDING - SHOULDER_L, "R": FIST_R_STANDING - SHOULDER_R}


def arm_end(side, rx, ry=0.0, rz=0.0):
    """Rotate the arm about its shoulder pivot (world axes) and return the
    matching fist end-effector world position — same rotation matrix drives
    both the arm mesh's rotation_euler and the fist's tracked position, so
    they stay visually attached without a real IK chain."""
    shoulder = SHOULDER_L if side == "L" else SHOULDER_R
    eul = Euler((rx, ry, rz), 'XYZ')
    mat = eul.to_matrix()
    fist_pos = shoulder + mat @ FIST_REL[side]
    return Vector((rx, ry, rz)), fist_pos


# =============================================================================
# TUMBLE — simplified rock_movement physics (low-bounce fall + settle) for
# the moss stones (pebbles rolling down the flank / shed-and-fall beats).
# =============================================================================
def tumble(f, start_f, end_f, start_pos, end_pos, bounce_h=0.10):
    if f <= start_f:
        return start_pos.copy(), Vector((0, 0, 0))
    if f >= end_f:
        return end_pos.copy(), Vector((0, 0, 6.0 * math.radians(1)))
    t = (f - start_f) / (end_f - start_f)
    if t < 0.55:
        u = t / 0.55
        pos = lerp_v(start_pos, end_pos, ease_in_expo(u))
        bounce = 0.0
    elif t < 0.72:
        u = (t - 0.55) / 0.17
        pos = end_pos.copy()
        bounce = bounce_h * math.sin(math.pi * u)
    else:
        u = (t - 0.72) / 0.28
        pos = end_pos.copy()
        bounce = bounce_h * 0.30 * (1.0 - u) * math.sin(2 * math.pi * u * 3.0)
    pos = Vector((pos.x, pos.y, pos.z + max(0.0, bounce)))
    rot = Vector((0.0, 0.0, math.radians(140) * ease_out_cubic(t)))
    return pos, rot


# =============================================================================
# PASS 6 fix 2 (2026-07-20+, PO Joan — "move as if there's an invisible
# skeleton/rig underneath, and the stones follow that rig with a delay that
# increases from the center out toward the tips of the limbs"). Generalizes
# the file's existing single-fixed-phase-delay patterns (TREE_LAG in
# sample_idle, MOVE_LAG in sample_move — kept as-is, they're already correct
# "prior art for lag" per the brief, just not a CHAIN) into an actual
# cascading chain for the two real multi-link chains this rig has: torso
# (root, depth0) -> arm (depth1) -> fist (depth2), and torso -> leg (depth1,
# no separate depth2 object). head is included at depth1 too (light touch —
# "head should telegraph... torso follows" per the motion spec's own
# Appendix A #8, applied in reverse here since torso IS the root).
#
# chunk_i_pose(f) = root_motion(f - i * DELAY_PER_JOINT), literally: wherever
# a part's motion is driven by evaluating some f-dependent function (a phase,
# an angle, a lerp factor), a non-root part evaluates that SAME function at a
# frame delayed by its own chain depth instead of at the current frame — see
# cascade_frame() below.
# =============================================================================
DELAY_PER_JOINT = 3  # frames at 24fps — tuned by eye: a few frames per joint
# step reads as believable heavy drag without becoming either a chaotic
# jumble (too large) or an imperceptible non-effect (too small).
CHAIN_DEPTH = {
    "torso": 0,
    "head": 1, "arm_L": 1, "arm_R": 1, "leg_L": 1, "leg_R": 1,
    "fist_L": 2, "fist_R": 2,
}


def cascade_frame(f, part_name, frames, loop=False):
    """Frame at which to SAMPLE the shared motion driver for `part_name`,
    delayed by its chain depth (0=root/torso, 1=first joint out, 2=tip).
    `loop` wraps into the clip's own [1, frames] range (for -loop clips, so
    there's no pop at the seam); one-shot clips clamp to frame 1 instead
    (holds the rest pose — correct, since a one-shot's frame 1 IS its rest
    pose by construction)."""
    depth = CHAIN_DEPTH.get(part_name, 0)
    raw = f - depth * DELAY_PER_JOINT
    if loop:
        return ((raw - 1) % frames) + 1
    return max(1, raw)


# =============================================================================
# CLIP SAMPLERS — each returns (dict part_name -> (loc, rot, scale),
# dict glow -> strength). No parenting: every part's world transform is
# computed directly per frame.
# =============================================================================
def sample_dormant_static():
    out = {k: (v["loc"].copy(), v["rot"].copy(), v["scale"].copy()) for k, v in DORMANT.items()}
    return out, dict(chest=0.0, head=0.0)


def sample_standing_static():
    out = {k: (v["loc"].copy(), v["rot"].copy(), v["scale"].copy()) for k, v in STANDING.items()}
    return out, dict(chest=GLOW_BASE_STRENGTH, head=GLOW_BASE_STRENGTH)


def breath_curve(f, frames=36):
    t = (f - 1) / frames
    phase = t * 2 * math.pi
    return 0.020 * math.sin(phase)  # ~2% of mound height (~2.1m -> ~0.04m peak-peak)


def sample_dormant(f, frames=8):
    """DORMANT static hold (v10, PO 2026-08-26: "antes de eso es piedra, sin
    moverse"). The old breathing loop broke the core illusion — a rock that
    breathes is not a rock. Perfectly still, glow off. The wind/tree sway is
    deliberately absent too: at 10m-hill scale the tree will get ambient
    sway from Godot-side wind later, not from the mob's own clip."""
    out = {k: (v["loc"].copy(), v["rot"].copy(), v["scale"].copy()) for k, v in DORMANT.items()}
    return out, dict(chest=0.0, head=0.0)


def sample_idle(f, frames=48):
    """STANDING idle (v10) — the awake golem's subtle weight shift. Slow
    torso bob + pitch, arms/fists lag the torso a beat (their air-gapped
    stones drift on the shared magic, not in lockstep), tree keeps its own
    inertia lag + slow wind cycle on top (motion spec identity line: 'the
    tree...has its own inertia and lags behind the body')."""
    out = {k: (v["loc"].copy(), v["rot"].copy(), v["scale"].copy()) for k, v in STANDING.items()}
    phase = (f - 1) / frames * 2 * math.pi
    sway = math.sin(phase)

    torso_loc, torso_rot, torso_scale = out["torso"]
    out["torso"] = (torso_loc + Vector((0, 0, 0.020 * sway)),
                    torso_rot + Vector((math.radians(0.7) * sway, 0, 0)), torso_scale)

    head_b = math.sin(phase - 0.55)
    head_loc, head_rot, head_scale = out["head"]
    out["head"] = (head_loc + Vector((0, 0, 0.026 * head_b)),
                   head_rot + Vector((math.radians(1.0) * head_b, 0, 0)), head_scale)

    for name, amp, lag in (("arm_L", 0.030, 0.9), ("arm_R", 0.030, 1.1),
                           ("fist_L", 0.038, 1.5), ("fist_R", 0.038, 1.7),
                           ("leg_L", 0.010, 0.4), ("leg_R", 0.010, 0.5)):
        b = math.sin(phase - lag)
        loc, rot, sc = out[name]
        out[name] = (loc + Vector((0, 0, amp * b)), rot, sc)

    tree_loc, tree_rot, tree_scale = out["tree"]
    lag_b = math.sin(phase - 1.3)
    wind = math.radians(2.0) * math.sin(phase * 0.4 + 1.2)
    tree_sway = math.radians(1.6) * lag_b + wind
    out["tree"] = (tree_loc + Vector((0, 0, 0.020 * lag_b)),
                    tree_rot + Vector((tree_sway, 0, tree_sway * 0.4)), tree_scale)
    return out, dict(chest=GLOW_BASE_STRENGTH, head=GLOW_BASE_STRENGTH)


# ---- AWAKEN (168f, 24fps = 7s) — the deliverable. Beats per PO brief. ----
AWAKEN_FRAMES = 168


def rise_progress(f):
    """Body-rise progress u in [0,1] across beats 3-5 (frames 31-144).
    Beats 1-2 (0-31): u=0, body hasn't risen (tremor only).
    Beat 3 (31-67): 0 -> 0.42 (the hump splits, ~40% rise), smoothstep.
    Beat 4 (67-115): 0.42 -> 1.0 with a mid-rise dip/catch (fall-and-catch).
    Beat 5-6 (115-168): holds at 1.0 (settle wobble layered separately)."""
    if f <= 31:
        return 0.0
    if f <= 67:
        u = (f - 31) / (67 - 31)
        return 0.42 * smoothstep(u)
    if f <= 115:
        u = (f - 67) / (115 - 67)
        base = lerp(0.42, 1.0, ease_out_cubic(u))
        dip = 0.10 * math.exp(-((u - 0.60) ** 2) / (2 * 0.085 ** 2))
        return max(0.34, base - dip)
    return 1.0


def tremor(f):
    """Beat 2 (12-31f): one breath heave + micro-tremor on the torso."""
    if f < 12 or f > 31:
        return 0.0
    u = (f - 12) / (31 - 12)
    return 0.045 * math.sin(2 * math.pi * 2.6 * u) * math.sin(math.pi * u)


def settle_wobble(f, start=115, end=144, cycles=2.2, amp=1.0):
    if f < start or f > end:
        return 0.0
    u = (f - start) / (end - start)
    decay = (1.0 - u)
    return amp * decay * math.sin(2 * math.pi * cycles * u)


ARM_RISE_WINDOW = {"R": (34, 74), "L": (80, 120)}  # RIGHT completes fully
# (74) before LEFT even starts (80) — sequential, not simultaneous.


def arm_rise_progress(f, side):
    """Addition #3 (2026-07-19/20): each arm gets its OWN buried-mass rise
    curve instead of sharing one 'shoulders split from the mass' progress
    with the other arm. RIGHT (34-74f, inside/around beat 3) rises and fully
    settles first; LEFT (80-120f, beat 4) only starts once RIGHT is done.
    Joan: 'right arm finishes assembling, THEN left arm begins' — two
    separate golem-pieces climbing out of the earth to join the body, not
    one shoulder-split motion happening to both sides at once."""
    start, end = ARM_RISE_WINDOW[side]
    if f <= start:
        return 0.0
    if f >= end:
        return 1.0
    return ease_out_cubic((f - start) / (end - start))


def arm_dirt_pop(f, side):
    """Brief outward 'breaks free from the ground' jolt right as THIS arm's
    own rise begins — rock_movement Move 1's Displacement phase (near-zero
    then an immediate jump, not a smooth ramp-up)."""
    start, _ = ARM_RISE_WINDOW[side]
    peak = start + 6
    if abs(f - peak) > 9:
        return 0.0
    return 0.16 * math.exp(-((f - peak) ** 2) / (2 * 4.5 ** 2))


def arm_settle_bounce(f, side):
    """Small settle micro-oscillation right after THIS arm finishes its own
    rise (rock_movement's low-bounce settle phase, applied per-arm)."""
    _, end = ARM_RISE_WINDOW[side]
    tail = end + 14
    if f < end or f > tail:
        return 0.0
    u = (f - end) / (tail - end)
    return 0.05 * (1.0 - u) * math.sin(2 * math.pi * 1.6 * u)


# Fix 2 (legs, new): both legs rise TOGETHER (unlike the sequential arms —
# the ground splitting open at the base is the FOUNDATION event the rest of
# the rise stands on, not a per-limb spotlight beat) starting right as the
# tremor (beat 2) ends, finishing partway through beat 3.
LEG_RISE_WINDOW = (10, 50)


def leg_rise_progress(f):
    start, end = LEG_RISE_WINDOW
    if f <= start:
        return 0.0
    if f >= end:
        return 1.0
    return ease_out_cubic((f - start) / (end - start))


def leg_dirt_pop(f):
    peak = LEG_RISE_WINDOW[0] + 5
    if abs(f - peak) > 8:
        return 0.0
    return 0.12 * math.exp(-((f - peak) ** 2) / (2 * 4.0 ** 2))


def leg_settle_bounce(f):
    _, end = LEG_RISE_WINDOW
    tail = end + 12
    if f < end or f > tail:
        return 0.0
    u = (f - end) / (tail - end)
    return 0.04 * (1.0 - u) * math.sin(2 * math.pi * 1.5 * u)


# Fix 3 (2026-07-20+, tree rigidly follows its anchor): idle-loop and
# move-loop ALREADY tie the tree's sway to the torso's own breath/sway
# (TREE_LAG / torso_sway_lagged above, a prior pass) — awaken was the one
# clip still running tree_tilt_deg as a fully independent authored curve
# (20->27deg ramp with its own overshoot, never reading the torso's actual
# rotation). torso_rot_awaken() factors out the SAME per-frame torso
# rotation sample_awaken's own torso block computes, so the tree can read
# it; tree_tilt_deg is kept as the WHIP/overshoot layer (secondary energy,
# the tree's own inertia/lag/character) added ON TOP of that rigid base,
# instead of being the tree's only source of motion.
TREE_FOLLOW_GAIN = 1.9  # same gain sample_move already uses for its own torso-follow


def torso_rot_awaken(f):
    u = rise_progress(f)
    return lerp_v(DORMANT["torso"]["rot"], STANDING["torso"]["rot"], u)


def tree_tilt_deg(f):
    """WHIP layer only (fix 3): the tree's own secondary sway/overshoot
    character, ADDED to the rigid torso-follow base in sample_awaken —
    reduced from the old full-authorship amplitude since the rigid term now
    supplies part of the visible lean."""
    if f <= 31:
        return 0.0
    if f <= 67:
        u = (f - 31) / (67 - 31)
        return 11.0 * ease_in_cubic(u)
    if f <= 115:
        u = (f - 67) / (115 - 67)
        return lerp(11.0, 15.0, smoothstep(u))
    if f <= 144:
        u = (f - 115) / (144 - 115)
        # swings back through 0 with an overshoot (~8% of peak) then rests
        overshoot = -15.0 * 0.08
        if u < 0.65:
            return lerp(15.0, overshoot, ease_out_cubic(u / 0.65))
        return lerp(overshoot, 0.0, ease_out_cubic((u - 0.65) / 0.35))
    return 0.0


def tree_rigid_tilt_deg(f, lag_frames=4):
    """The RIGID component (fix 3, mandatory): reads the torso's own actual
    per-frame rotation (lagged a few frames for inertia — 'the tree...has
    its own inertia and lags behind the body', same identity line the
    idle/move fixes already use), relative to the torso's STANDING baseline
    lean, amplified by TREE_FOLLOW_GAIN since the tree is a lever riding on
    top of the torso (its swing reads bigger than the torso's own tilt)."""
    lagged = torso_rot_awaken(max(0, f - lag_frames))
    delta_x = lagged.x - STANDING["torso"]["rot"].x
    return math.degrees(delta_x) * TREE_FOLLOW_GAIN


def glow_chest_strength(f):
    peek = 0.0
    if 12 <= f <= 31:
        u = (f - 12) / (31 - 12)
        peek = 0.55 * math.sin(math.pi * u)
    if f < 31:
        return peek
    if f < 116:
        return 0.12  # dim residual crack-light, holding through beats 3-4
    u = clamp01((f - 116) / (134 - 116))
    return lerp(0.12, GLOW_BASE_STRENGTH, ease_out_cubic(u))


def head_rise_progress(f):
    """The head un-buries FASTER than the rest of the body — motion-spec
    Appendix A #8 ('head should telegraph intent... head turns first, body
    follows') taken further per addition #2. Necessary, not just stylistic:
    the head/eye object is spatially NESTED inside the torso's dormant mass,
    so no amount of rotating it or raising its emission strength makes it
    visible until its LOCATION has risen far enough to clear the torso's
    silhouette — confirmed by render (a lit eye at f=25, using the original
    hu=rise_progress(f-4) curve, was completely invisible; it only became
    visible once that curve's progress crossed roughly ~0.75-0.85, around
    f=85-88). This curve front-loads that same exposure level to f=50 (deep
    in beat 3, 31-67f) instead of f=88, holds there, then rejoins the
    original late curve once IT catches up — so the final standing timing
    (full by ~115) is unchanged, only the early approach is faster."""
    if f <= 14:
        return 0.0
    if f <= 50:
        u = (f - 14) / (50 - 14)
        return 0.85 * smoothstep(u)
    return max(0.85, rise_progress(max(0, f - 4)))


EYES_OPEN_START, EYES_OPEN_END = 44, 52  # beat 3 (31-67f) — timed to land
# right as head_rise_progress crosses its exposure threshold (see above), so
# the eyes visibly snap on right as the head becomes visible, not before.
EYES_OPEN_LEVEL = 1.15  # "eyes open" plateau — clearly lit but short of full power


def glow_head_strength(f):
    """Addition #2 (2026-07-19/20): an explicit EARLY eyes-open beat inside
    beat 2, not just the final-beat ramp. A HARD/QUICK pop (6 frames,
    ease_out_expo) from 0 -> EYES_OPEN_LEVEL — Joan: 'a hard or quick-eased
    transition reads better than a slow fade... like a creature waking up,
    not a light dimmer'. Holds at that plateau through beats 3-4 (visibly
    lit the whole time), THEN brightens further to full GLOW_BASE_STRENGTH
    near the climax (unchanged from the original final-beat ramp) — so the
    eyes are lit long before the end, and gain intensity rather than
    appearing from nothing at the very end."""
    if f < EYES_OPEN_START:
        return 0.0
    if f < EYES_OPEN_END:
        u = (f - EYES_OPEN_START) / (EYES_OPEN_END - EYES_OPEN_START)
        return EYES_OPEN_LEVEL * ease_out_expo(u)
    if f < 124:
        return EYES_OPEN_LEVEL
    u = clamp01((f - 124) / (142 - 124))
    return lerp(EYES_OPEN_LEVEL, GLOW_BASE_STRENGTH, ease_out_cubic(u))


LOOK_START, LOOK_END = 54, 78  # right after the eyes-open beat (44-52) — now
# that head_rise_progress exposes the head by ~f50 (beat 3), the look-turn
# can follow immediately after: eyes snap open, THEN the head tilts to hold
# on the player, well before frame 144 and holding through the rest of the
# rise + settle, per Joan's brief.


def head_look_rot(f, entering_rot):
    """Addition #2 (2026-07-19/20): head starts tracking/holding toward the
    player during beat 4 (LOOK_START=82), not only in the final beat — holds
    the look through the rest of the rise + settle, instead of snapping at
    frame 144. `entering_rot` is the head's natural un-bury rotation (from
    the DORMANT->STANDING rot blend); this layers the extra 'look at camera'
    tilt on top of it and locks it in once LOOK_END is reached."""
    p = 0.0 if f < LOOK_START else (1.0 if f > LOOK_END else ease_out_cubic((f - LOOK_START) / (LOOK_END - LOOK_START)))
    final_rx = math.radians(9)
    rx = lerp(entering_rot.x, final_rx, p)
    return Vector((rx, entering_rot.y, entering_rot.z))


def sample_awaken(f):
    u = rise_progress(f)
    trem = tremor(f)
    wob = settle_wobble(f)
    out = {}

    # torso — leads the rise (per Appendix A stagger: torso first)
    t_loc = lerp_v(DORMANT["torso"]["loc"], STANDING["torso"]["loc"], u)
    t_rot = lerp_v(DORMANT["torso"]["rot"], STANDING["torso"]["rot"], u)
    t_scale = lerp_v(DORMANT["torso"]["scale"], STANDING["torso"]["scale"], u)
    t_loc = t_loc + Vector((0, 0, trem + wob * 0.05))
    out["torso"] = (t_loc, t_rot, t_scale)

    # head — LEADS the torso's own rise (addition #2: head_rise_progress is
    # ahead of the body so it's exposed early enough for the beat-3 eyes-open
    # + head-look beats to actually be visible), then looks at camera.
    hu = head_rise_progress(f)
    h_loc = lerp_v(DORMANT["head"]["loc"], STANDING["head"]["loc"], hu)
    h_rot = lerp_v(DORMANT["head"]["rot"], STANDING["head"]["rot"], hu)
    h_rot = head_look_rot(f, h_rot)
    h_scale = lerp_v(DORMANT["head"]["scale"], STANDING["head"]["scale"], hu)
    out["head"] = (h_loc + Vector((0, 0, trem * 0.6)), h_rot, h_scale)

    # arms — SEQUENTIAL per addition #3: RIGHT rises+settles as its own
    # buried mass, fully done, THEN LEFT starts its own separate rise (see
    # ARM_RISE_WINDOW). Each side has its own dirt-fall pop + settle bounce.
    for side, arm_name, fist_name, sign in (("L", "arm_L", "fist_L", -1.0), ("R", "arm_R", "fist_R", 1.0)):
        au = arm_rise_progress(f, side)
        pop = arm_dirt_pop(f, side)
        bounce = arm_settle_bounce(f, side)
        a_loc = lerp_v(DORMANT[arm_name]["loc"], STANDING[arm_name]["loc"], au)
        a_loc = a_loc + Vector((sign * pop, 0, bounce))
        a_rot = lerp_v(DORMANT[arm_name]["rot"], STANDING[arm_name]["rot"], au)
        a_scale = lerp_v(DORMANT[arm_name]["scale"], STANDING[arm_name]["scale"], au)
        out[arm_name] = (a_loc, a_rot, a_scale)
        fu = arm_rise_progress(max(0, f - DELAY_PER_JOINT), side)  # fist trails its own arm
        # PASS 6 fix 2: reuses the shared DELAY_PER_JOINT constant instead of a
        # separately hand-picked "3" — same cascading-chain idea, depth1->depth2,
        # layered on top of the already-approved sequential per-arm rise design,
        # which stays untouched here since it's PO-approved (addition #3).
        f_loc = lerp_v(DORMANT[fist_name]["loc"], STANDING[fist_name]["loc"], fu)
        f_scale = lerp_v(DORMANT[fist_name]["scale"], STANDING[fist_name]["scale"], fu)
        out[fist_name] = (f_loc, Vector((0, 0, 0)), f_scale)

    # legs — fix 2: rise TOGETHER (LEG_RISE_WINDOW), unlike the sequential
    # arms — see LEG_RISE_WINDOW's own comment for why.
    for side, leg_name, sign in (("L", "leg_L", -1.0), ("R", "leg_R", 1.0)):
        lu = leg_rise_progress(f)
        pop = leg_dirt_pop(f)
        bounce = leg_settle_bounce(f)
        l_loc = lerp_v(DORMANT[leg_name]["loc"], STANDING[leg_name]["loc"], lu)
        l_loc = l_loc + Vector((sign * pop, 0, bounce))
        l_rot = lerp_v(DORMANT[leg_name]["rot"], STANDING[leg_name]["rot"], lu)
        l_scale = lerp_v(DORMANT[leg_name]["scale"], STANDING[leg_name]["scale"], lu)
        out[leg_name] = (l_loc, l_rot, l_scale)

    # tree — fix 3: base tracks torso's rise (position) AND a RIGID tilt
    # derived from the torso's own actual per-frame rotation
    # (tree_rigid_tilt_deg), with tree_tilt_deg now only the secondary
    # whip/overshoot layered on top — see tree_rigid_tilt_deg's docstring.
    tree_u = rise_progress(max(0, f - 3))
    tr_loc = lerp_v(DORMANT["tree"]["loc"], STANDING["tree"]["loc"], tree_u)
    tilt = math.radians(tree_rigid_tilt_deg(f) + tree_tilt_deg(f))
    out["tree"] = (tr_loc, Vector((tilt, 0, tilt * 0.25)), Vector((1, 1, 1)))

    # stones — stone_1/2 tumble a short hop during the tremor (beat 2), then
    # continue further out during the rise (beat 4). stone_3 stays put until
    # the rise dislodges it with one bigger tumble (shed-and-fall).
    mid1 = lerp_v(DORMANT["stone_1"]["loc"], STANDING["stone_1"]["loc"], 0.55)
    p1a, r1a = tumble(f, 13, 28, DORMANT["stone_1"]["loc"], mid1, bounce_h=0.07)
    if f <= 28:
        out["stone_1"] = (p1a, r1a, Vector((1, 1, 1)))
    else:
        p1b, r1b = tumble(f, 70, 106, mid1, STANDING["stone_1"]["loc"], bounce_h=0.10)
        out["stone_1"] = (p1b, r1b, Vector((1, 1, 1)))

    mid2 = lerp_v(DORMANT["stone_2"]["loc"], STANDING["stone_2"]["loc"], 0.50)
    p2a, r2a = tumble(f, 15, 30, DORMANT["stone_2"]["loc"], mid2, bounce_h=0.06)
    if f <= 30:
        out["stone_2"] = (p2a, r2a, Vector((1, 1, 1)))
    else:
        p2b, r2b = tumble(f, 74, 110, mid2, STANDING["stone_2"]["loc"], bounce_h=0.09)
        out["stone_2"] = (p2b, r2b, Vector((1, 1, 1)))

    p3, r3 = tumble(f, 68, 112, DORMANT["stone_3"]["loc"], STANDING["stone_3"]["loc"], bounce_h=0.14)
    out["stone_3"] = (p3, r3, Vector((1, 1, 1)))

    glow = dict(chest=glow_chest_strength(f), head=glow_head_strength(f))
    return out, glow


# ---- MOVE-LOOP (48f) — heavy knuckle-drag gait, 2-beat arm swing ----
def move_phase(f, frames=48):
    t = (f - 1) / frames
    return t * 2 * math.pi


def move_swing_angle(f, frames=48):
    """The shared driver for the arm-swing chain (fix 2) — root motion the
    arm/fist links replay at increasing delay. Sign (L vs R) is applied by
    the caller."""
    return math.radians(38) * math.sin(move_phase(f, frames))  # boosted from 22 deg — too
    # subtle vs the multi-blob arm's own bulk to read at showcase-camera distance (render-verified)


def move_bob(f, frames=48):
    return -0.16 * abs(math.sin(move_phase(f, frames)))


def sample_move(f, frames=64):
    """v14 HEAVY knuckle-walk (Joan: "un brazo primero y el otro despues,
    lento y que golpee el suelo al cambiar de brazo, que no se sienta tan
    liviano"). Each half-cycle ONE fist lifts, heaves forward SLOWLY and
    SLAMS down — the final 15% of the step accelerates into the drop, the
    torso dips with a damped jolt on every slam, the head nods a beat late
    and the tree whips later still. In-place loop: the planted fist's swing
    angle drifts back while the stepping one arcs forward, so the cycle
    closes without net translation (Godot moves the body)."""
    u = ((f - 1) % frames) / frames
    out = {}
    SWING = math.radians(9.0)

    def step_s(w):
        # Non-linear step progress: 70% of the time covers only 80% of the
        # path (the heavy heave), then an ACCELERATING drop — the slam.
        if w < 0.70:
            return 0.80 * smoothstep(w / 0.70)
        if w < 0.86:
            t = (w - 0.70) / 0.16
            return 0.80 + 0.20 * (t * t)
        return 1.0

    def slam_pulse(uu):
        # Damped bounce that starts at each slam instant (one per half
        # cycle, at step-phase w=0.86 -> cycle u 0.43 and 0.93).
        p = 0.0
        for ti in (0.43, 0.93):
            d = (uu - ti) % 1.0
            if d < 0.30:
                p += math.exp(-d * 16.0) * math.cos(2.0 * math.pi * 3.2 * d)
        return p

    arm_states = {}
    for arm_name, offset in (("arm_L", 0.0), ("arm_R", 0.5)):
        w = (u - offset) % 1.0
        if w < 0.5:
            ws = w / 0.5
            s = step_s(ws)
            theta = -SWING + 2.0 * SWING * s
            lift = 0.42 * math.sin(math.pi * s)
        else:
            wp = (w - 0.5) / 0.5
            theta = SWING - 2.0 * SWING * wp
            lift = 0.0
        arm_states[arm_name] = (theta, lift)

    pulse = slam_pulse(u)
    jolt = -0.06 * pulse
    yaw = math.radians(4.0) * math.sin(2.0 * math.pi * u)
    out["torso"] = (STANDING["torso"]["loc"] + Vector((0, 0, jolt)),
                     STANDING["torso"]["rot"] + Vector((math.radians(1.2) * pulse, 0, yaw)),
                     Vector((1, 1, 1)))

    head_pulse = slam_pulse(u - 0.04)
    out["head"] = (STANDING["head"]["loc"] + Vector((0, 0, -0.05 * head_pulse)),
                    STANDING["head"]["rot"] + Vector((math.radians(2.2) * head_pulse, 0, yaw * 0.6)),
                    Vector((1, 1, 1)))

    for side, arm_name, fist_name in (("L", "arm_L", "fist_L"), ("R", "arm_R", "fist_R")):
        theta, lift = arm_states[arm_name]
        rot, fist_pos = arm_end(side, theta)
        out[arm_name] = (SHOULDER_L if side == "L" else SHOULDER_R, rot, Vector((1, 1, 1)))
        out[fist_name] = (fist_pos + Vector((0, 0, lift)), Vector((0, 0, 0)), Vector((1, 1, 1)))

    # Legs shuffle opposite the arms, small and grounded — the arms carry
    # the gait, the legs just keep up.
    for side, leg_name, sign, off in (("L", "leg_L", -1.0, 0.5), ("R", "leg_R", 1.0, 0.0)):
        lphase = 2.0 * math.pi * ((u - off) % 1.0)
        lift_leg = 0.04 * max(0.0, math.sin(lphase))
        knee = math.radians(5.0) * max(0.0, math.sin(lphase))
        out[leg_name] = (STANDING[leg_name]["loc"] + Vector((0, 0, lift_leg)),
                          STANDING[leg_name]["rot"] + Vector((-knee, 0, sign * knee * 0.3)),
                          Vector((1, 1, 1)))

    # Tree: whips AFTER each slam (biggest lag on the chain) + slow wind.
    tree_pulse = slam_pulse(u - 0.08)
    wind = math.radians(1.6) * math.sin(2.0 * math.pi * u * 0.55 + 0.6)
    tree_sway = math.radians(3.2) * tree_pulse + wind
    out["tree"] = (STANDING["tree"]["loc"] + Vector((0, 0, -0.04 * tree_pulse)),
                    Vector((tree_sway, 0, tree_sway * 0.3)), Vector((1, 1, 1)))
    for s in ("stone_1", "stone_2", "stone_3"):
        out[s] = (STANDING[s]["loc"], Vector((0, 0, 0)), Vector((1, 1, 1)))
    return out, dict(chest=GLOW_BASE_STRENGTH, head=GLOW_BASE_STRENGTH)


# ---- ATTACK (30f) — raise both fists overhead, slam down, hold ----
def attack_state(f, frames=30):
    """(rx, tz) driver as a function of frame — extracted so the cascading
    chain (fix 2) can sample it at delayed frames for arm/fist instead of
    every part sharing the exact same rx (the old code's #4 Appendix-A
    'lockstep parts' red flag: arm rotation AND fist position were both
    derived from the SAME rx at the SAME frame, so the fist never lagged the
    arm's own swing at all)."""
    t = (f - 1) / (frames - 1)
    if t < 0.40:
        u = t / 0.40
        rx = lerp(0.0, math.radians(-110), ease_in_cubic(u))
        tz = 0.0
    elif t < 0.46:
        rx = math.radians(-110)
        tz = 0.0
    elif t < 0.62:
        u = (t - 0.46) / 0.16
        rx = lerp(math.radians(-110), math.radians(8), ease_in_expo(u))
        tz = -0.18 * ease_in_expo(u) if u > 0.7 else 0.0
    elif t < 0.68:
        rx = math.radians(8)
        tz = -0.18
    else:
        u = (t - 0.68) / 0.32
        rx = lerp(math.radians(8), 0.0, ease_out_cubic(u))
        tz = lerp(-0.18, 0.0, ease_out_cubic(u))
    return rx, tz


def sample_attack(f, frames=30):
    rx, tz = attack_state(f, frames)
    out = {}
    out["torso"] = (STANDING["torso"]["loc"] + Vector((0, 0, tz)), STANDING["torso"]["rot"], Vector((1, 1, 1)))
    head_f = cascade_frame(f, "head", frames)
    _, tz_h = attack_state(head_f, frames)
    out["head"] = (STANDING["head"]["loc"] + Vector((0, 0, tz_h * 0.6)), STANDING["head"]["rot"], Vector((1, 1, 1)))
    for side, arm_name, fist_name in (("L", "arm_L", "fist_L"), ("R", "arm_R", "fist_R")):
        arm_f = cascade_frame(f, arm_name, frames)
        fist_f = cascade_frame(f, fist_name, frames)
        rx_arm, _ = attack_state(arm_f, frames)
        rx_fist, _ = attack_state(fist_f, frames)
        rot, _ = arm_end(side, rx_arm)
        _, fist_pos = arm_end(side, rx_fist)
        out[arm_name] = (SHOULDER_L if side == "L" else SHOULDER_R, rot, Vector((1, 1, 1)))
        out[fist_name] = (fist_pos, Vector((0, 0, 0)), Vector((1, 1, 1)))
    out["tree"] = (STANDING["tree"]["loc"], Vector((rx * 0.35, 0, 0)), Vector((1, 1, 1)))
    for leg_name in ("leg_L", "leg_R"):
        leg_f = cascade_frame(f, leg_name, frames)
        _, tz_l = attack_state(leg_f, frames)
        out[leg_name] = (STANDING[leg_name]["loc"] + Vector((0, 0, tz_l * 0.3)), STANDING[leg_name]["rot"], Vector((1, 1, 1)))
    for s in ("stone_1", "stone_2", "stone_3"):
        out[s] = (STANDING[s]["loc"], Vector((0, 0, 0)), Vector((1, 1, 1)))
    return out, dict(chest=GLOW_BASE_STRENGTH, head=GLOW_BASE_STRENGTH)


# ---- HIT (16f) — flinch: torso recoils, tree shudders ----
def hit_env(f, frames=16):
    t = (f - 1) / (frames - 1)
    return math.sin(math.pi * min(1.0, t * 1.5))


def sample_hit(f, frames=16):
    env = hit_env(f, frames)
    t = (f - 1) / (frames - 1)
    out = {}
    out["torso"] = (STANDING["torso"]["loc"] + Vector((0, 0.22 * env, -0.16 * env)),
                     STANDING["torso"]["rot"] + Vector((-math.radians(11) * env, 0, 0)), Vector((1, 1, 1)))
    head_f = cascade_frame(f, "head", frames)
    env_h = hit_env(head_f, frames)
    out["head"] = (STANDING["head"]["loc"] + Vector((0, 0.14 * env_h, -0.07 * env_h)), STANDING["head"]["rot"], Vector((1, 1, 1)))
    for side, arm_name, fist_name in (("L", "arm_L", "fist_L"), ("R", "arm_R", "fist_R")):
        arm_f = cascade_frame(f, arm_name, frames)
        fist_f = cascade_frame(f, fist_name, frames)
        rx_arm = -math.radians(26) * hit_env(arm_f, frames)
        rx_fist = -math.radians(26) * hit_env(fist_f, frames)
        rot, _ = arm_end(side, rx_arm)
        _, fist_pos = arm_end(side, rx_fist)
        out[arm_name] = (SHOULDER_L if side == "L" else SHOULDER_R, rot, Vector((1, 1, 1)))
        out[fist_name] = (fist_pos, Vector((0, 0, 0)), Vector((1, 1, 1)))
    shudder = math.radians(9) * math.sin(2 * math.pi * 4.0 * t) * (1.0 - t)
    out["tree"] = (STANDING["tree"]["loc"], Vector((shudder, 0, shudder * 0.5)), Vector((1, 1, 1)))
    for leg_name in ("leg_L", "leg_R"):
        leg_f = cascade_frame(f, leg_name, frames)
        env_l = hit_env(leg_f, frames)
        out[leg_name] = (STANDING[leg_name]["loc"] + Vector((0, 0.05 * env_l, -0.03 * env_l)), STANDING[leg_name]["rot"], Vector((1, 1, 1)))
    for s in ("stone_1", "stone_2", "stone_3"):
        out[s] = (STANDING[s]["loc"], Vector((0, 0, 0)), Vector((1, 1, 1)))
    return out, dict(chest=GLOW_BASE_STRENGTH, head=GLOW_BASE_STRENGTH)


# ---- DEATH (48f) — forward collapse, ends mound-like (Move 8, NOT reverse-awaken) ----
def death_state(f, frames=48):
    """(lean_deg, drop_u) driver as a function of frame — extracted so the
    cascading chain (fix 2) can sample it at delayed frames: the torso
    (root) leads on the TRUE curve, arms (depth1) replay it slightly
    delayed, fists (depth2) replay it delayed further still — a topple
    where the fingertip-equivalent visibly hasn't caught up to where the
    shoulder-equivalent already is, instead of the whole rig collapsing in
    rigid lockstep."""
    t = (f - 1) / (frames - 1)
    if t < 0.12:  # recognition delay
        return 0.0, 0.0
    if t < 0.40:  # the lean — slow start (tree_fall Stage-A)
        u = (t - 0.12) / 0.28
        return 60.0 * ease_in_cubic(u), 0.0
    if t < 0.63:  # the fall — accelerating
        u = (t - 0.40) / 0.23
        return lerp(60.0, 92.0, ease_in_expo(u)), ease_in_expo(u)
    if t < 0.71:  # impact hold
        return 92.0, 1.0
    # settle
    u = (t - 0.71) / 0.29
    wob = 4.0 * (1.0 - u) * math.sin(2 * math.pi * 2.5 * u)
    return 92.0 + wob, 1.0


def sample_death(f, frames=48):
    """v20 (PO 2026-08-27: "deberia volverse un monticulo... el arbol
    deberia quedar en pie"): death is the awaken in reverse — the guardian
    COLLAPSES INWARD and ends EXACTLY at the DORMANT mound pose (canon
    2026-06-14: "muerte = derrumbe, callback to the dormant silhouette").
    Body parts converge fully to their dormant tuck (loc+rot+SCALE — the
    shrink reads as the pieces burying themselves), each at its own cascade
    delay; loose stones still roll OUTWARD as debris flavor. The tree's
    position rides the torso via the global anchor override; here we only
    give its rotation a decaying wobble that settles UPRIGHT."""
    out = {}
    lean, drop_u = death_state(f, frames)

    def to_dormant(name, u):
        loc = lerp_v(STANDING[name]["loc"], DORMANT[name]["loc"], u)
        rot = lerp_v(STANDING[name]["rot"], DORMANT[name]["rot"], u)
        scl = lerp_v(STANDING[name]["scale"], DORMANT[name]["scale"], u)
        return loc, rot, scl

    t_loc, t_rot, t_scl = to_dormant("torso", drop_u)
    t_rot = t_rot + Vector((math.radians(lean) * (1.0 - drop_u), 0, 0))
    out["torso"] = (t_loc, t_rot, t_scl)

    head_f = cascade_frame(f, "head", frames)
    h_lean, h_drop_u = death_state(head_f, frames)
    h_loc, h_rot, h_scl = to_dormant("head", h_drop_u)
    h_rot = h_rot + Vector((math.radians(h_lean) * 0.6 * (1.0 - h_drop_u), 0, 0))
    out["head"] = (h_loc, h_rot, h_scl)

    for name in ("arm_L", "arm_R", "fist_L", "fist_R", "leg_L", "leg_R"):
        p_f = cascade_frame(f, name, frames)
        _, p_drop_u = death_state(p_f, frames)
        loc, rot, scl = to_dormant(name, p_drop_u)
        wobble = math.radians(9.0) * math.sin(p_drop_u * math.pi * 2.2) * (1.0 - p_drop_u)
        out[name] = (loc, rot + Vector((wobble, 0, wobble * 0.4)), scl)

    tree_wobble = (math.radians(lean) * 0.25 * (1.0 - drop_u)
                   + math.radians(4.0) * math.sin(drop_u * math.pi * 3.0) * (1.0 - drop_u))
    out["tree"] = (STANDING["tree"]["loc"], Vector((tree_wobble, 0, tree_wobble * 0.3)),
                    Vector((1, 1, 1)))

    for nm in ("stone_1", "stone_2", "stone_3"):
        start = STANDING[nm]["loc"]
        start_xy = Vector((start.x, start.y, 0.0))
        dir_xy = start_xy.normalized() if start_xy.length > 0 else Vector((0.5, 0, 0))
        end_xy = start_xy + dir_xy * 0.9
        end_z = groundlib.ground_height(end_xy.x, end_xy.y) + STONE_SETTLE_Z[nm]
        end = Vector((end_xy.x, end_xy.y, end_z))
        p, r = tumble(f, 10, 42, start, end, bounce_h=0.12)
        out[nm] = (p, r, Vector((1, 1, 1)))

    t = (f - 1) / (frames - 1)
    chest = lerp(GLOW_BASE_STRENGTH, 0.0, clamp01((t - 0.63) / 0.25))
    head_g = lerp(GLOW_BASE_STRENGTH, 0.0, clamp01((t - 0.63) / 0.25))
    return out, dict(chest=chest, head=head_g)


CLIPS = {
    "dormant-loop": (8, sample_dormant, 4),
    "idle-loop": (48, sample_idle, 2),
    "awaken": (AWAKEN_FRAMES, sample_awaken, 3),
    "move-loop": (64, sample_move, 2),
    "attack": (30, sample_attack, 2),
    "hit": (16, sample_hit, 2),
    "death": (48, sample_death, 2),
}

ALL_OBJS = dict(PARTS)
ALL_OBJS["glow_chest"] = glow_chest
ALL_OBJS["glow_head"] = glow_head

# =============================================================================
# KEYFRAME AUTHORING — one Action per object per clip, sampled every 2 frames
# (dense enough for smooth hand-authored easing; matches golem_floating's
# sampling convention). Glow strength keyframed on the BSDF emission input.
# =============================================================================
anim_data = {}
for name, obj in PARTS.items():
    anim_data[name] = obj.animation_data_create()
glow_chest_ad = glow_chest.animation_data_create()
glow_head_ad = glow_head.animation_data_create()
glow_chest_mat_ad = GLOW_CHEST_MAT.node_tree.animation_data_create()
glow_head_mat_ad = GLOW_HEAD_MAT.node_tree.animation_data_create()

clip_actions = {}
for clip_name, (frames, sampler, render_step) in CLIPS.items():
    part_actions = {}
    for name in PARTS:
        act = bpy.data.actions.new(f"{clip_name}_{name}")
        anim_data[name].action = act
        part_actions[name] = act
    gc_act = bpy.data.actions.new(f"{clip_name}_glow_chest_obj")
    gh_act = bpy.data.actions.new(f"{clip_name}_glow_head_obj")
    gcm_act = bpy.data.actions.new(f"{clip_name}_glow_chest_mat")
    ghm_act = bpy.data.actions.new(f"{clip_name}_glow_head_mat")
    glow_chest_ad.action = gc_act
    glow_head_ad.action = gh_act
    glow_chest_mat_ad.action = gcm_act
    glow_head_mat_ad.action = ghm_act

    for f in range(1, frames + 1, 2):
        pose, glow = sampler(f)
        # v20 TREE ANCHOR OVERRIDE (PO: "sigue flotando, anclalo a la piedra
        # mas grande"): in EVERY clip the tree's position is derived from the
        # torso's live loc/rot/scale carrying the build-time anchor point —
        # hand-keyed tree positions can drift off the bust, this cannot. The
        # sampler keeps authoring only the tree's ROTATION (sway/wobble).
        _to_loc, _to_rot, _to_scl = pose["torso"]
        _rel = Vector((TREE_ANCHOR_REL.x * _to_scl.x, TREE_ANCHOR_REL.y * _to_scl.y,
                       TREE_ANCHOR_REL.z * _to_scl.z))
        _t_loc = _to_loc + Euler(_to_rot).to_matrix() @ _rel
        pose["tree"] = (_t_loc, pose["tree"][1], pose["tree"][2])
        for name, obj in PARTS.items():
            loc, rot, sc = pose[name]
            obj.location = loc
            obj.keyframe_insert("location", frame=f)
            obj.rotation_euler = rot
            obj.keyframe_insert("rotation_euler", frame=f)
            obj.scale = sc
            obj.keyframe_insert("scale", frame=f)
        glow_chest.location = GLOW_CHEST_OFFSET + (pose["torso"][0] - STANDING["torso"]["loc"])
        glow_chest.keyframe_insert("location", frame=f)
        glow_head.location = GLOW_HEAD_OFFSET + (pose["head"][0] - STANDING["head"]["loc"])
        glow_head.keyframe_insert("location", frame=f)
        GLOW_CHEST_BSDF.inputs["Emission Strength"].default_value = glow["chest"]
        GLOW_CHEST_BSDF.inputs["Emission Strength"].keyframe_insert("default_value", frame=f)
        GLOW_HEAD_BSDF.inputs["Emission Strength"].default_value = glow["head"]
        GLOW_HEAD_BSDF.inputs["Emission Strength"].keyframe_insert("default_value", frame=f)

    clip_actions[clip_name] = dict(frames=frames, render_step=render_step, parts=part_actions,
                                    glow_chest=gc_act, glow_head=gh_act,
                                    glow_chest_mat=gcm_act, glow_head_mat=ghm_act)

for name in PARTS:
    anim_data[name].action = None
glow_chest_ad.action = None
glow_head_ad.action = None
glow_chest_mat_ad.action = None
glow_head_mat_ad.action = None


def reset_to_standing():
    for name, obj in PARTS.items():
        obj.location = STANDING[name]["loc"].copy()
        obj.rotation_euler = STANDING[name]["rot"].copy()
        obj.scale = STANDING[name]["scale"].copy()
    glow_chest.location = GLOW_CHEST_OFFSET.copy()
    glow_head.location = GLOW_HEAD_OFFSET.copy()
    GLOW_CHEST_BSDF.inputs["Emission Strength"].default_value = GLOW_BASE_STRENGTH
    GLOW_HEAD_BSDF.inputs["Emission Strength"].default_value = GLOW_BASE_STRENGTH


def set_to_dormant():
    for name, obj in PARTS.items():
        obj.location = DORMANT[name]["loc"].copy()
        obj.rotation_euler = DORMANT[name]["rot"].copy()
        obj.scale = DORMANT[name]["scale"].copy()
    glow_chest.location = GLOW_CHEST_OFFSET + (DORMANT["torso"]["loc"] - STANDING["torso"]["loc"])
    glow_head.location = GLOW_HEAD_OFFSET + (DORMANT["head"]["loc"] - STANDING["head"]["loc"])
    GLOW_CHEST_BSDF.inputs["Emission Strength"].default_value = 0.0
    GLOW_HEAD_BSDF.inputs["Emission Strength"].default_value = 0.0


reset_to_standing()

# =============================================================================
# SCENE — showcase-ficha rig (contract §4), scaled for a ~4.5-5m subject +
# ~2.5m tree on top (king_slime energies x ~1.8; camera pulled back for the
# taller/wider subject; framed for STANDING height throughout, per brief).
# =============================================================================
world = bpy.data.worlds.new("ficha")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.30, 0.22, 0.48, 1.0)


def add_light(name, loc, energy, size, target_z=2.4):
    ld = bpy.data.lights.new(name, type='AREA')
    ld.energy = energy
    ld.size = size
    lo = bpy.data.objects.new(name, ld)
    lo.location = loc
    bpy.context.collection.objects.link(lo)
    lo.rotation_mode = 'QUATERNION'
    lo.rotation_quaternion = (Vector(loc) - Vector((0, 0, target_z))).to_track_quat('Z', 'Y')


add_light("key", (-6.3, -9.5, 5.5), 950, 6.0)
add_light("fill", (5.8, -8.5, 2.6), 260, 5.8)
add_light("rim", (1.2, 9.0, 5.0), 1130, 5.8)

TARGET_Z = 2.75 + GROUND_OFFSET_Z
target = bpy.data.objects.new("target", None)
target.location = (0.0, 0.0, TARGET_Z)
bpy.context.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 36
cam = bpy.data.objects.new("cam", cd)
BASE_CAM_LOC = Vector((-3.5, -10.8, 3.5))
cam.location = BASE_CAM_LOC
bpy.context.collection.objects.link(cam)
cam.constraints.new(type='TRACK_TO').target = target
scene.camera = cam

# PASS 6 fix 3: visible ground plane under the golem in EVERY render (hero,
# dormant, every clip) — irregular terrain (build_ground/ground_height share
# the exact same noise formula, see _ground_common.py), not a flat slab.
# Static object, never keyframed, so it's free background geometry for every
# render call below without touching the animation system.
GROUND_OBJ = groundlib.build_ground(scene, size=9.0)

try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.eevee.taa_render_samples = 64
scene.view_settings.view_transform = 'Standard'


# =============================================================================
# SCALE SILHOUETTE — 1.75m black matte humanoid, hero-still only (contract
# §4 Pokedex rule). NOT part of the exported GLB.
# =============================================================================
def build_silhouette(x_offset=-3.55):
    parts = []
    for side in (-1, 1):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.095, depth=0.80, vertices=10,
                                             location=(x_offset + side * 0.10, 0, 0.40))
        parts.append(bpy.context.object)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.21, depth=0.60, vertices=10,
                                         location=(x_offset, 0, 1.10))
    parts.append(bpy.context.object)
    for side in (-1, 1):
        bpy.ops.mesh.primitive_cylinder_add(radius=0.058, depth=0.58, vertices=8,
                                             location=(x_offset + side * 0.27, 0, 0.97))
        parts.append(bpy.context.object)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.175, location=(x_offset, 0, 1.575), segments=12, ring_count=8)
    parts.append(bpy.context.object)
    sil_mat = bpy.data.materials.new("sil_black")
    sil_mat.use_nodes = True
    n = sil_mat.node_tree.nodes["Principled BSDF"]
    n.inputs["Base Color"].default_value = (0.008, 0.008, 0.010, 1.0)
    n.inputs["Roughness"].default_value = 0.95
    for p in parts:
        p.data.materials.append(sil_mat)
        for poly in p.data.polygons:
            poly.use_smooth = True
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    joined = bpy.context.view_layer.objects.active
    joined.name = "player_silhouette"
    return joined


# =============================================================================
# RENDERS
# =============================================================================
scene.render.resolution_x = 1024
scene.render.resolution_y = 1280

reset_to_standing()
scene.frame_set(1)
sil = build_silhouette()
scene.render.filepath = os.path.join(REN_DIR, "guardian_hero.png")
bpy.ops.render.render(write_still=True)
bpy.data.objects.remove(sil, do_unlink=True)

set_to_dormant()
scene.frame_set(1)
scene.render.filepath = os.path.join(REN_DIR, "guardian_dormant.png")
bpy.ops.render.render(write_still=True)
reset_to_standing()

scene.render.resolution_x = 512
scene.render.resolution_y = 640
for clip_name, data in clip_actions.items():
    for name in PARTS:
        anim_data[name].action = data["parts"][name]
    glow_chest_ad.action = data["glow_chest"]
    glow_head_ad.action = data["glow_head"]
    glow_chest_mat_ad.action = data["glow_chest_mat"]
    glow_head_mat_ad.action = data["glow_head_mat"]
    step = data["render_step"]
    frames = data["frames"]
    for f in range(1, frames + 1, step):
        scene.frame_set(f)
        scene.render.filepath = os.path.join(ANIM_DIR, f"{clip_name.replace('-loop', '')}_{f:03d}.png")
        bpy.ops.render.render(write_still=True)
    print("[golem_guardian] frames", clip_name)

# =============================================================================
# PASS 6 fix 2 VERIFICATION RENDER — a dedicated side-on close-up on one arm
# across 4 move-loop frames, applied by directly calling sample_move() and
# setting object transforms (NOT via NLA — avoids ambiguity about which
# stacked NLA track is "active" at a given frame; this is the same data the
# NLA strips are built from moments later). The main showcase camera looks
# from roughly -Y (near-frontal), and the walk-cycle arm swing rotates
# mostly in the Y-Z (fore-aft) plane — foreshortened almost to nothing from
# that angle even though the underlying angle DOES change ~50 degrees across
# the cycle (confirmed numerically). A side camera (looking down -X) shows
# the fore-aft swing edge-on, where the cascade is actually legible.
# =============================================================================
scene.render.resolution_x = 700
scene.render.resolution_y = 700
# The walk swing is fore-aft (world Y, per this rig's "front=-Y" convention)
# — a camera framed anywhere near "looking at the golem's front" (including
# closeups.py's own arm shot, and the first attempt at THIS camera) puts Y
# largely ALONG the view axis, foreshortening the exact motion we need to
# show (confirmed: fist_L.y swings -0.77 to +0.10, a real 0.87-unit change,
# invisible in 2 earlier framing attempts because Y was depth, not screen
# lateral). True side-on: camera separated from the target ONLY along world
# X, so Y maps to screen-horizontal and Z to screen-vertical.
side_target = Vector((-1.7, -0.34, 1.39 + GROUND_OFFSET_Z))
side_cam_loc = side_target + Vector((-3.5, 0.0, 0.35))
side_target_obj = bpy.data.objects.new("side_target", None)
side_target_obj.location = side_target
bpy.context.collection.objects.link(side_target_obj)
side_cam_d = bpy.data.cameras.new("side_cam")
side_cam_d.lens = 60
side_cam = bpy.data.objects.new("side_cam", side_cam_d)
side_cam.location = side_cam_loc
bpy.context.collection.objects.link(side_cam)
side_cam.constraints.new(type='TRACK_TO').target = side_target_obj
scene.camera = side_cam

# GOTCHA (caught via pixel-diff — 4 "different" frames rendered byte-
# identical): every PARTS object still has the LAST main-loop clip's Action
# ("death") actively assigned at this point — the depsgraph evaluates that
# Action's keyframes at the current (stale, left at frame 47) scene frame on
# every render, SILENTLY OVERRIDING the manual obj.location/rotation_euler/
# scale sets below (a Python property set only sticks until the next
# depsgraph evaluation; an active Action wins that evaluation every time).
# Clear actions here (redundant with the later full cleanup, which still
# needs to run for glow objects/materials) so the manual pose actually reads.
for _name in PARTS:
    anim_data[_name].action = None

CASCADE_FRAMES = [1, 13, 25, 37]
for cf in CASCADE_FRAMES:
    pose, glow = sample_move(cf)
    for name, obj in PARTS.items():
        loc, rot, sc = pose[name]
        obj.location = loc
        obj.rotation_euler = rot
        obj.scale = sc
    glow_chest.location = GLOW_CHEST_OFFSET + (pose["torso"][0] - STANDING["torso"]["loc"])
    glow_head.location = GLOW_HEAD_OFFSET + (pose["head"][0] - STANDING["head"]["loc"])
    GLOW_CHEST_BSDF.inputs["Emission Strength"].default_value = glow["chest"]
    GLOW_HEAD_BSDF.inputs["Emission Strength"].default_value = glow["head"]
    scene.render.filepath = os.path.join(REN_DIR, f"cascade_move_{cf:03d}.png")
    bpy.ops.render.render(write_still=True)
print("[golem_guardian] cascade verification frames done")

bpy.data.objects.remove(side_cam, do_unlink=True)
bpy.data.objects.remove(side_target_obj, do_unlink=True)
scene.camera = cam
scene.render.resolution_x = 512
scene.render.resolution_y = 640
reset_to_standing()

for name in PARTS:
    anim_data[name].action = None
glow_chest_ad.action = None
glow_head_ad.action = None
glow_chest_mat_ad.action = None
glow_head_mat_ad.action = None
reset_to_standing()

# PASS 6 fix 3: the ground plane is a RENDER AID (so floating errors are
# visible in every still/GIF above) — it must NOT ship in the mob's GLB
# (style contract: a mob's asset is the mob, not its showcase stage; the
# ground is scene-only, same reasoning as the hero-still scale silhouette in
# _ficha_common.py). Remove it from the scene now, after the last render,
# before export (which uses use_selection=False / whole-scene export).
bpy.data.objects.remove(GROUND_OBJ, do_unlink=True)

# =============================================================================
# NLA PUSH + EXPORT
# =============================================================================
for clip_name, data in clip_actions.items():
    for name in PARTS:
        tr = anim_data[name].nla_tracks.new()
        tr.name = clip_name
        tr.strips.new(clip_name, 1, data["parts"][name])
    tgc = glow_chest_ad.nla_tracks.new()
    tgc.name = clip_name
    tgc.strips.new(clip_name, 1, data["glow_chest"])
    tgh = glow_head_ad.nla_tracks.new()
    tgh.name = clip_name
    tgh.strips.new(clip_name, 1, data["glow_head"])
    tgcm = glow_chest_mat_ad.nla_tracks.new()
    tgcm.name = clip_name
    tgcm.strips.new(clip_name, 1, data["glow_chest_mat"])
    tghm = glow_head_mat_ad.nla_tracks.new()
    tghm.name = clip_name
    tghm.strips.new(clip_name, 1, data["glow_head_mat"])

# Gotcha: creating NLA strips (all starting at frame 1) makes them ACTIVE
# evaluators immediately once action=None — the scene frame was left at the
# last-rendered death frame (~47), so depsgraph evaluation right after the
# strips are built silently overwrites the manual reset_to_standing() values
# with whatever the (now top-stacked) "death" track evaluates to at frame 47.
# Re-assert the rest pose + park the frame outside every strip's range so the
# saved .blend / exported GLB bind pose is STANDING, not a leftover death lean.
reset_to_standing()
scene.frame_set(1)
reset_to_standing()

# v17 FLOOR GATE (PO: "el piso es el limite del modelado"): every ground-
# contact part's lowest vertex, at its STANDING pose, must clear the local
# terrain. Thresholds derive from live geometry + live ground function; a
# violation KILLS the build instead of shipping a buried fist.
for _gate_name in ("fist_L", "fist_R", "leg_L", "leg_R", "stone_1", "stone_2", "stone_3"):
    _obj = PARTS[_gate_name]
    _loc = STANDING[_gate_name]["loc"]
    _min_world = _loc.z + min(v.co.z for v in _obj.data.vertices)
    _floor = groundlib.ground_height(_loc.x, _loc.y)
    if _min_world < _floor - 0.05:
        raise SystemExit(
            f"[floor-gate] {_gate_name} pierces the ground: min z {_min_world:.3f} "
            f"< terrain {_floor:.3f} at ({_loc.x:.2f},{_loc.y:.2f})")
print("[golem_guardian] floor gate OK — no part pierces the terrain")

# v15 REALISM PASS (PO 2026-08-27, Art Canon §17 Valheim model): bake a
# procedural realistic albedo (cracks/moss/lichen/grime at texel resolution)
# per stone part and swap STONE_MAT for per-part textured materials. Runs
# LAST, after all geometry and animation exist — it only touches materials,
# UVs and the (already neutralized-to-white) Col attribute.
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))
import texture_bake
TEX_SIZES = {"torso": 2048, "head": 1024, "arm_L": 1024, "arm_R": 1024,
             "fist_L": 1024, "fist_R": 1024, "leg_L": 1024, "leg_R": 1024,
             "stone_1": 512, "stone_2": 512, "stone_3": 512}
texture_bake.bake_all(
    {k: v for k, v in PARTS.items() if k != "tree"},
    STONE_MAT, TEX_SIZES)

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "golem_guardian_wip.blend"))
_export_kwargs = dict(
    filepath=os.path.join(OUT_DIR, "golem_guardian.glb"),
    use_selection=False,
    export_animations=True,
    export_morph=False,
    export_animation_mode='NLA_TRACKS',
)
try:
    # Belt-and-suspenders with the ShaderNodeVertexColor fix in mat_stone:
    # force COLOR_0 export regardless of material detection. Kwarg name
    # varies across exporter versions, hence the fallback.
    bpy.ops.export_scene.gltf(**_export_kwargs, export_vertex_color='ACTIVE')
except TypeError:
    bpy.ops.export_scene.gltf(**_export_kwargs)
print("[golem_guardian] DONE")
