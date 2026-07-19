# build_golem.py — Floating-Stone Golem, STRUCTURAL REWRITE 2026-07-19.
#
# Joan rejected the previous build (commit dd2cc63: a torso-cluster core +
# 7 independently-orbiting stones) as reading like a scattered rock pile,
# not a creature. Root cause per
# game/docs/art/_references/golem_floating/_synthesis.md: no anatomical
# structure (stones just floated near where a body part *might* be) and no
# shared rhythm (each stone group had its own phase/orbit -> looked like
# debris, not a puppet held together by magic).
#
# THE FIX (see _synthesis.md refs 02/05/09):
#   - The figure is built from ANATOMICAL GROUPS (head, torso, upper_arm,
#     forearm, fist x2, leg x2) — each group itself a small CLUSTER of 2-3
#     overlapping rock chunks (reads as one packed stone mass, ref 02),
#     positioned in its correct anatomical slot with a SMALL gap to its
#     neighbor group (ref 05 — "the magic lives in the gap, not in far
#     orbits").
#   - ALL groups share the SAME timing curve (idle bob / move plod / hit
#     flinch) with only a small per-group LAG + amplitude gain proportional
#     to how many "joints" the group sits from the torso (puppet weight,
#     not independent phases). attack is the one clip with a distinct
#     curve (arm whip), but both arms run it on the SAME timeline, so the
#     slam still reads synchronized.
#   - Energy is baked as EMISSIVE CRACKS carried by the same ridge-noise
#     that carves each chunk's surface (a second per-vertex "Crack" color
#     attribute, concentrated on the torso and faint on the head) instead
#     of a separate glowing sphere glued to the body.
#   - Moss is concentrated at the joint-facing side of each cluster and at
#     the leg/foot base, not scattered uniformly.
#   - death is the ONE clip where every chunk gets independent physics
#     (falls apart) — that's the correct place for it, everywhere else the
#     figure must read as ONE thing.
#
# Reuses the existing per-chunk rock generator (noise-displaced icosphere,
# flat-shaded, painterly vertex color) and the NLA export pipeline from the
# rejected build; only the COMPOSITION and ANIMATION drivers change.
# Run: blender -b --python build_golem.py
import bpy
import bmesh
import math
import os
import random
import sys
from mathutils import Vector
from mathutils import noise as mnoise

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
ANIM_DIR = os.path.join(REN_DIR, "anim")
os.makedirs(ANIM_DIR, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
FPS = 24
scene.render.fps = FPS

SEED = 20260719
SCALE = 1.15  # iteration 4b (2026-07-19b, self-corrected mid-session — see the
              # JOINT_TOUCH/EFF_R notes below) keeps the PROVEN overlap-ratio
              # cohesion (~0.6-0.85, same regime golem_guardian validated) but
              # applies it to genuinely bigger limb-segment radii (bumped
              # Z-elongate on leg/arm main chunks), so the same trusted touch
              # ratio now spans real anatomical reach instead of collapsing.
              # Nominal (pre-scale) skeleton is ~2.4m tall at SCALE=1.0; SCALE
              # is retuned up so the final standing figure lands in the
              # ~2.5-3m contract (~2.8m here). SCALE is applied uniformly to
              # every anchor AND every radius, so it preserves every
              # gap/overlap ratio below exactly.

# Iteration 1 FAILED the silhouette test (read as a scattered debris cloud,
# same failure Joan rejected the old build for). Root cause found by
# inspecting actual object transforms after build: gaps between chained
# limb chunks (e.g. upper_arm -> forearm) measured ~0.148 world units when
# the design intent was ~0.06 — noise displacement (noise_strength=0.34)
# shrinks a chunk's effective reach toward any GIVEN neighbor unpredictably
# (up to ~30%), so anchors placed via "nominal half-height + small gap"
# arithmetic silently drift into wide, inconsistent gaps once carved. Fix:
# (1) every inter-cluster anchor below is now DERIVED from the actual
#     radius/elongate of both neighbors via JOINT_OVERLAP (a fraction of
#     the summed effective radii — 0.92 = nominal near-touch, small
#     overlap for safety margin against the carving above), not eyeballed;
# (2) noise_strength is LOWERED (0.20-0.26) on every chunk that carries a
#     joint connection (main chunks in the leg/arm chain + torso + head) to
#     shrink that variance; satellites (which only need to fuse into their
#     OWN cluster, not bridge a visible joint) keep the default 0.34 for
#     texture richness.
# Iteration 2 STILL failed: chain anchors computed with JOINT_OVERLAP=0.92
# (near-touch) measured only 3-6cm gaps by bounding-box math, yet the
# render still showed each limb segment as a visibly separate floating
# rock. Cause: dimensions.z/2 measures a chunk's FARTHEST reach in that
# axis, not its actual local silhouette AT the specific point facing its
# neighbor — noise carving can (and did) carve a crevice right on the
# contact axis, so the true local gap is bigger than the bounding-box
# estimate even at low noise_strength. Fix: stop aiming for "near touch"
# on inter-cluster joints — aim for GENUINE overlap (same regime as the
# intra-cluster satellites), so the chunks' cores interpenetrate and stay
# visually connected regardless of which way the crevices fall. The seams
# between segments still read as distinct rocks because of the jagged
# silhouette itself (see ref_02) — they don't need an open-air gap to read
# as separate anatomical pieces. NOTE (iteration 3): 0.60 alone made the
# figure read as one blob but swallowed the neck and pushed the shoulder
# bumps up level with (or above) the head, so "head clearly on top" failed.
#
# ITERATION 4 (2026-07-19b, orchestrator-diagnosed regression): iteration 3's
# fix was STILL WRONG, just less obviously — JOINT_OVERLAP/HEAD_OVERLAP/
# SHOULDER_OVERLAP all compute the gap as `RATIO * (r1 + r2)` with ratio < 1,
# i.e. a FRACTION of the summed radii. For two EQUAL radii that means the
# anchor-to-anchor distance is *less than one radius*, so the far surface of
# the parent chunk still reaches deep past the child's own center — genuine,
# heavy interpenetration, not a "small touch". Applied once (e.g. torso <->
# head) that reads as acceptable cohesion; CHAINED three times in a row down
# an arm (torso->shoulder->elbow->fist) each additional 40-60% overlap
# compounds, so upper_arm/forearm/fist end up almost concentric — exactly
# the "stubby bump instead of an articulated limb" failure the orchestrator's
# render review caught (self-reported PASS was wrong). Root confusion: this
# whole file conflated two DIFFERENT distance regimes under one lever.
#   - INTRA-cluster (the 2-3 chunks that make up ONE anatomical part, e.g.
#     torso main+chestL+chestR, or fist main+knuA+knuB): tight/overlapping is
#     CORRECT there — and that packing was never driven by JOINT_OVERLAP at
#     all, it's the hardcoded `local=Vector(...)` offsets in PART_DEFS below,
#     which stay untouched by this fix (those clusters already read fine).
#   - INTER-part (shoulder->elbow->fist, hip->knee->ankle, torso->head): this
#     needs REAL anatomical reach — each joint's gap is now an EXPLICIT flat
#     "GAP_*" constant (a few cm of "small magic gap", not a fraction of the
#     combined mass), added to BOTH neighbors' own radius toward each other
#     (`anchor2 = anchor1 + self_radius_of(1) + GAP + self_radius_of(2)`).
#     This can't collapse when chained, because each joint only ever adds a
#     flat constant, never multiplies away the parts' own size. The resulting
#     pre-scale skeleton is taller (~3.26m at SCALE=1.0) purely because real
#     anatomy needs more room than deep overlap did — SCALE above is retuned
#     to compensate and land the final figure back at ~2.8m.
# ITERATION 4b (same session, self-corrected after the first render): flat
# near-zero gaps on top of full radius sums (surface-to-surface "just
# touching") STILL read as disconnected floating rocks, even smaller than
# iteration 4's. Root cause: two ROUND blobs meeting at a tangent point touch
# at a SINGLE point of zero area — at low subdiv that point may not even land
# on a vertex, and even where it does, noise carving unpredictably eats into
# whichever side faces the joint, so a "zero gap" surface calc routinely
# renders as a visible notch. This is exactly the golem_guardian 2026-07-19
# lesson (blob-center spacing needs to be ~0.55-0.65x the summed radii —
# genuine INTERPENETRATION, not tangency — to survive noise carving and read
# as connected). That means iteration 3's RATIO-based approach (`distance =
# RATIO * (r1+r2)`) was never wrong in its ratio value (~0.6 IS the correct
# cohesion regime) — the bug was that it was the ONLY lever being pulled: it
# was applied to the ORIGINAL small chunk radii, so a correctly-cohesive
# chain simply couldn't span real anatomical distance no matter what ratio
# was chosen (three 0.6-ratio joints in a row on ~0.3-radius parts adds up to
# barely more than one radius total). ITERATION 4b's real fix is pulling BOTH
# levers together: keep the proven ~0.6-0.85 overlap RATIO for genuine
# cohesion at every joint (below), AND make each limb-chain chunk's own
# ELONGATION bigger along the joint axis (the bumped Z-elongate values on
# leg_upper/leg_lower/upper_arm/forearm main chunks above) so the ratio has
# real size to work with — the same two-part solution golem_guardian's own
# 5-blob tapered arm chain uses (each blob genuinely overlaps the next AND
# there's real absolute size/count along the path).
JOINT_TOUCH = 0.62        # leg_lower<->leg_upper<->torso spine chain, and each arm-chain
                           # joint (shoulder->elbow->fist): genuine overlap for cohesion
HEAD_TOUCH = 0.75          # torso->head: a bit less overlap so the head pokes up clearly
                           # above the torso with a visible neck notch
SHOULDER_TOUCH = 0.58     # torso side->upper_arm: matches JOINT_TOUCH now — orchestrator fix,
                           # must read apart from the torso's own silhouette from the start
ARM_BEND_X = 0.16          # extra outward drift added per arm segment (elbow, then wrist)
                           # on TOP of the JOINT_TOUCH-derived Z chain below — a silhouette
                           # bend (natural elbow angle) layered on the touch, not replacing it

UP = Vector((0.0, 0.0, 1.0))
DOWN = Vector((0.0, 0.0, -1.0))
LEFTWARD = Vector((-1.0, 0.0, 0.0))
RIGHTWARD = Vector((1.0, 0.0, 0.0))


def clamp(x, lo, hi):
    return max(lo, min(hi, x))


def lerp(a, b, t):
    return a + (b - a) * max(0.0, min(1.0, t))


def ease_in_cubic(t):
    t = max(0.0, min(1.0, t))
    return t * t * t


def ease_out_cubic(t):
    t = max(0.0, min(1.0, t))
    return 1.0 - (1.0 - t) ** 3


def ease_in_expo(t):
    t = max(0.0, min(1.0, t))
    return 0.0 if t <= 0.0 else 2.0 ** (10.0 * (t - 1.0))


def ease_out_expo(t):
    t = max(0.0, min(1.0, t))
    return 1.0 if t >= 1.0 else 1.0 - 2.0 ** (-10.0 * t)


# =============================================================================
# ROCK CHUNK GENERATOR — icosphere + Perlin displacement for a jagged
# silhouette + painterly vertex-color stone. Two color attributes per chunk:
#   "Col"   — RGB albedo (dark/light noise-mix + directional moss tint)
#   "Crack" — R=G=B mask, nonzero ONLY on chunks built with crack=True,
#             reusing the SAME ridge value that carved the chunk's surface
#             crevices — so the glow-crack pattern is geometrically tied to
#             real crevices, not painted independently ("light escaping
#             through fractures", not a decal).
# =============================================================================
def make_rock(name, radius=0.5, subdiv=2, seed=0, elongate=(1.0, 1.0, 1.0),
              taper=0.0, noise_scale=2.6, noise_strength=0.34,
              moss_dirs=None, crack=False, crack_threshold=0.78,
              crack_sharp=2.0, crack_gain=1.0, flat=True,
              dark=(0.22, 0.235, 0.26), light=(0.62, 0.64, 0.68),
              moss_col=(0.28, 0.48, 0.15)):
    if moss_dirs is None:
        moss_dirs = [(UP, 0.30)]

    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radius)
    seed_v = Vector((seed * 17.13, seed * 5.71, seed * 31.9))
    paint_seed_v = seed_v + Vector((91.0, 47.0, 13.0))

    ridge_val = {}
    crack_ridge_val = {}
    for v in bm.verts:
        co = v.co.copy()
        n1 = mnoise.noise(co * noise_scale + seed_v)
        n2 = mnoise.noise(co * noise_scale * 2.4 + seed_v + Vector((5.0, 5.0, 5.0)))
        ridged = 1.0 - abs(n1 * 2.0 - 1.0)          # ridge-ish: crevices between bumps
        ridge_val[v.index] = ridged
        # a SEPARATE, higher-frequency ridge sample (different noise offset,
        # ~4x the shape frequency) drives the crack mask — reusing the
        # shape's own low-frequency ridge produced only 1-2 big blobby
        # patches instead of a network of hairline fractures
        n3 = mnoise.noise(co * noise_scale * 4.2 + seed_v + Vector((23.0, 71.0, -17.0)))
        crack_ridge_val[v.index] = 1.0 - abs(n3 * 2.0 - 1.0)
        d = (n2 * 2.0 - 1.0) * 0.55 + (ridged - 0.5) * 0.9
        v.co += v.normal * (d * noise_strength * radius)
        v.co.x *= elongate[0]
        v.co.y *= elongate[1]
        v.co.z *= elongate[2]
    if taper:
        zs = [v.co.z for v in bm.verts]
        zmin, zmax = min(zs), max(zs)
        h = max(1e-5, zmax - zmin)
        for v in bm.verts:
            t = (v.co.z - zmin) / h
            s = 1.0 + taper * (1.0 - t)
            v.co.x *= s
            v.co.y *= s
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()

    col_layer = bm.loops.layers.color.new("Col")
    crack_layer = bm.loops.layers.color.new("Crack")
    bm.verts.ensure_lookup_table()
    vcol = {}
    vcrack = {}
    for v in bm.verts:
        nrm = v.normal
        paint = mnoise.noise(v.co * 3.5 + paint_seed_v)  # ~[0,1] painterly variation
        t_ao = clamp(0.20 + 0.55 * (nrm.z * 0.5 + 0.5) + 0.35 * paint, 0.0, 1.0)
        base = [dark[i] + (light[i] - dark[i]) * t_ao for i in range(3)]
        mt = 0.0
        for mdir, bias in moss_dirs:
            dp = nrm.dot(mdir)
            if dp > bias:
                local_mt = min(1.0, (dp - bias) / max(1e-4, 1.0 - bias))
                local_mt *= 0.55 + 0.45 * paint  # patchy, not a uniform cap
                mt = max(mt, local_mt)
        if mt > 0.0:
            base = [base[i] + (moss_col[i] - base[i]) * mt for i in range(3)]
        vcol[v.index] = (base[0], base[1], base[2], 1.0)
        cm = 0.0
        if crack:
            rv = crack_ridge_val[v.index]
            m = max(0.0, (rv - crack_threshold) / max(1e-4, 1.0 - crack_threshold))
            m = m ** crack_sharp
            cm = min(1.0, m * crack_gain)
        vcrack[v.index] = (cm, cm, cm, 1.0)
    for f in bm.faces:
        for loop in f.loops:
            vi = loop.vert.index
            loop[col_layer] = vcol[vi]
            loop[crack_layer] = vcrack[vi]

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = not flat
    try:
        me.color_attributes.render_color_index = me.color_attributes.find("Col")
        me.color_attributes.active_color_index = me.color_attributes.render_color_index
    except Exception:
        pass
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return obj


CRACK_BASE_STRENGTH = 3.4
CRACK_COLOR = (0.28, 0.88, 0.98, 1.0)  # cyan, PO canon 2026-07-19


def mat_stone():
    m = bpy.data.materials.new("golem_stone")
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Roughness"].default_value = 0.88
    n.inputs["Specular IOR Level"].default_value = 0.25
    n.inputs["Emission Color"].default_value = CRACK_COLOR

    attr_col = nt.nodes.new("ShaderNodeAttribute")
    attr_col.attribute_name = "Col"
    nt.links.new(attr_col.outputs["Color"], n.inputs["Base Color"])

    attr_crack = nt.nodes.new("ShaderNodeAttribute")
    attr_crack.attribute_name = "Crack"

    boost = nt.nodes.new("ShaderNodeValue")
    boost.label = "crack_boost"
    boost.outputs[0].default_value = CRACK_BASE_STRENGTH

    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = 'MULTIPLY'
    nt.links.new(attr_crack.outputs["Fac"], mul.inputs[0])
    nt.links.new(boost.outputs[0], mul.inputs[1])
    nt.links.new(mul.outputs[0], n.inputs["Emission Strength"])

    return m, boost


STONE_MAT, CRACK_BOOST = mat_stone()

# =============================================================================
# ANATOMICAL PART TABLE — every part is a small CLUSTER of 2-3 chunks
# (main mass + 1-2 satellites overlapping it, per the 2026-07-03 golem
# lesson: "one rock per limb" reads cheap — a packed multi-chunk cluster
# reads as real stone). `anchor` values are for the +X (R) side; mirrored
# parts flip both anchor.x and every chunk's local.x for L. `depth` = how
# many joints the part sits from the torso — drives lag/amplitude so
# extremities carry proportionally more "weight" while staying on the SAME
# shared timing curve (puppet, not independent orbits).
# =============================================================================
# EFF_R — effective radius (radius * elongate along the relevant axis) of
# each part's MAIN chunk, used to derive the anchors below. Keep in sync with
# the "main" chunk radius/elongate in PART_DEFS if you retune a chunk's size.
# The leg/arm Z-elongate values were bumped up in iteration 4b (was 1.05-1.3,
# now 1.3-1.6) specifically so each limb SEGMENT itself is longer along its
# own joint axis — that's where real limb length comes from now, not from
# widening the gap between segments (see the GAP_* note above).
EFF_R = dict(
    torso_up=0.58 * 1.15, torso_down=0.58 * 1.15, torso_side=0.58 * 1.05,
    head=0.20 * 1.05,
    leg_upper_up=0.30 * 1.30, leg_upper_down=0.30 * 1.30,
    leg_lower_up=0.28 * 1.30,
    upper_arm_up=0.26 * 1.60, upper_arm_down=0.26 * 1.60,
    forearm_up=0.24 * 1.50, forearm_down=0.24 * 1.50,
    fist_up=0.30 * 1.0,
)

# Bottom-up chain: feet on the ground -> hips -> torso -> head/shoulders ->
# down each arm. Each step is `TOUCH_RATIO * (parent_eff_r + self_eff_r)` —
# same shape as the ORIGINAL formula, deliberately: the ratio was never the
# bug (0.6-0.85 is the proven cohesion regime, confirmed by golem_guardian).
# What changed is EFF_R itself is now bigger (bumped Z-elongate above), so
# the same trusted ratio yields real anatomical reach instead of collapsing
# — three ~0.6-ratio joints on ~0.4-radius parts (now) span meaningfully
# more than three ~0.6-ratio joints on ~0.3-radius parts (before).
_LEG_LOWER_Z = EFF_R["leg_lower_up"]                                              # foot rests near z=0
_LEG_UPPER_Z = _LEG_LOWER_Z + JOINT_TOUCH * (EFF_R["leg_lower_up"] + EFF_R["leg_upper_down"])
_TORSO_Z = _LEG_UPPER_Z + JOINT_TOUCH * (EFF_R["leg_upper_up"] + EFF_R["torso_down"])
_HEAD_Z = _TORSO_Z + HEAD_TOUCH * (EFF_R["torso_up"] + EFF_R["head"])
_SHOULDER_X = SHOULDER_TOUCH * (EFF_R["torso_side"] + EFF_R["upper_arm_up"])
_UPPER_ARM_Z = _TORSO_Z + 0.40   # shoulder sits within the torso's upper band (a real
                                  # shoulder attaches INTO the torso mass), clearly below
                                  # the head (_HEAD_Z), with the arm reading apart from the
                                  # torso via _SHOULDER_X (lateral) instead of height alone
# forearm/fist continue the SAME touch-ratio pattern as the spine chain (Z =
# the primary reach direction downward from the shoulder), with an extra
# outward X drift layered on top for a natural elbow bend.
_FOREARM_X = _SHOULDER_X + ARM_BEND_X
_FOREARM_Z = _UPPER_ARM_Z - JOINT_TOUCH * (EFF_R["upper_arm_down"] + EFF_R["forearm_up"])
_FIST_X = _FOREARM_X + ARM_BEND_X
_FIST_Z = _FOREARM_Z - JOINT_TOUCH * (EFF_R["forearm_down"] + EFF_R["fist_up"])

PART_DEFS = {
    "torso": dict(
        anchor=Vector((0.0, 0.02, _TORSO_Z)), depth=0, mirror=False,
        moss_dirs=[(DOWN, 0.30), (LEFTWARD, 0.55), (RIGHTWARD, 0.55)],
        crack=True, crack_gain=1.0,
        chunks=[
            dict(suffix="main", local=Vector((0.0, 0.0, 0.0)), radius=0.58,
                 elongate=(1.05, 0.95, 1.15), taper=0.22, subdiv=4, noise_strength=0.26),
            dict(suffix="chestL", local=Vector((-0.30, -0.18, 0.18)), radius=0.30, subdiv=3),
            dict(suffix="chestR", local=Vector((0.30, -0.16, 0.14)), radius=0.28, subdiv=3),
        ]),
    "head": dict(
        anchor=Vector((0.0, 0.04, _HEAD_Z)), depth=1, mirror=False,
        moss_dirs=[(UP, 0.45), (DOWN, 0.55)],
        crack=True, crack_gain=0.4,
        chunks=[
            dict(suffix="main", local=Vector((0.0, 0.0, 0.0)), radius=0.20,
                 elongate=(1.0, 1.0, 1.05), subdiv=2, noise_strength=0.22),
            dict(suffix="jaw", local=Vector((0.0, -0.10, -0.10)), radius=0.12, subdiv=2),
        ]),
    "leg_upper": dict(
        anchor=Vector((0.28, 0.0, _LEG_UPPER_Z)), depth=1, mirror=True,
        moss_dirs=[(UP, 0.35), (DOWN, 0.35)], crack=False,
        chunks=[
            dict(suffix="main", local=Vector((0.0, 0.0, 0.0)), radius=0.30,
                 elongate=(1.0, 1.0, 1.30), taper=0.05, subdiv=2, noise_strength=0.22),
            dict(suffix="side", local=Vector((0.16, -0.05, -0.05)), radius=0.16, subdiv=2),
        ]),
    "leg_lower": dict(
        anchor=Vector((0.28, 0.02, _LEG_LOWER_Z)), depth=2, mirror=True,
        moss_dirs=[(DOWN, -0.30), (UP, 0.35)], crack=False,
        chunks=[
            dict(suffix="main", local=Vector((0.0, 0.0, 0.05)), radius=0.28,
                 elongate=(0.95, 1.0, 1.30), taper=0.30, subdiv=2, noise_strength=0.22),
            dict(suffix="toe", local=Vector((0.10, -0.14, -0.14)), radius=0.15, subdiv=2),
        ]),
    "upper_arm": dict(
        anchor=Vector((_SHOULDER_X, -0.05, _UPPER_ARM_Z)), depth=1, mirror=True,
        moss_dirs=[(UP, 0.35), (DOWN, 0.35)], crack=False,
        chunks=[
            dict(suffix="main", local=Vector((0.0, 0.0, 0.0)), radius=0.26,
                 elongate=(1.0, 1.0, 1.60), subdiv=2, noise_strength=0.20),
            dict(suffix="bump", local=Vector((0.10, 0.06, 0.10)), radius=0.14, subdiv=2),
        ]),
    "forearm": dict(
        anchor=Vector((_FOREARM_X, -0.08, _FOREARM_Z)), depth=2, mirror=True,
        moss_dirs=[(UP, 0.35), (DOWN, 0.35)], crack=False,
        chunks=[
            dict(suffix="main", local=Vector((0.0, 0.0, 0.0)), radius=0.24,
                 elongate=(1.0, 1.0, 1.50), subdiv=2, noise_strength=0.20),
            dict(suffix="bump", local=Vector((0.08, -0.04, -0.08)), radius=0.13, subdiv=2),
        ]),
    "fist": dict(
        anchor=Vector((_FIST_X, -0.15, _FIST_Z)), depth=3, mirror=True,
        moss_dirs=[(UP, 0.40)], crack=False,
        chunks=[
            dict(suffix="main", local=Vector((0.0, 0.0, 0.0)), radius=0.30,
                 elongate=(1.05, 1.0, 1.0), subdiv=2, noise_strength=0.20),
            dict(suffix="knuA", local=Vector((0.16, -0.10, 0.08)), radius=0.16, subdiv=2),
            dict(suffix="knuB", local=Vector((0.08, -0.16, -0.10)), radius=0.14, subdiv=2),
        ]),
}

seed_counter = 1
ALL_CHUNKS = []   # dict(name, obj, base, radius, depth, part, side)

for part_key, pdef in PART_DEFS.items():
    sides = [(None, 1)] if not pdef["mirror"] else [("L", -1), ("R", 1)]
    for side_label, sign in sides:
        anchor = pdef["anchor"].copy()
        anchor.x *= sign
        group_key = part_key if side_label is None else f"{part_key}_{side_label}"
        for cd in pdef["chunks"]:
            local = cd["local"].copy()
            local.x *= sign
            base = (anchor + local) * SCALE
            radius = cd["radius"] * SCALE
            name = f"{group_key}_{cd['suffix']}"
            obj = make_rock(
                name, radius=radius, subdiv=cd.get("subdiv", 2), seed=seed_counter,
                elongate=cd.get("elongate", (1.0, 1.0, 1.0)), taper=cd.get("taper", 0.0),
                noise_strength=cd.get("noise_strength", 0.34),
                moss_dirs=pdef["moss_dirs"], crack=pdef.get("crack", False),
                crack_gain=pdef.get("crack_gain", 1.0))
            seed_counter += 1
            obj.location = base
            obj.data.materials.append(STONE_MAT)
            ALL_CHUNKS.append(dict(name=name, obj=obj, base=base, radius=radius,
                                    depth=pdef["depth"], part=group_key, side=sign))

rng = random.Random(SEED)
for info in ALL_CHUNKS:
    base = info["base"]
    fdir = Vector((base.x, base.y, 0.0))
    fdir = fdir.normalized() if fdir.length > 1e-4 else Vector(
        (rng.uniform(-1, 1), rng.uniform(-1, 1), 0.0)).normalized()
    info["fall_dir"] = fdir
    info["fall_dist"] = rng.uniform(0.35, 1.10) * SCALE
    info["death_stagger"] = rng.uniform(0.0, 0.25)
    info["fall_rot_axis"] = Vector((rng.uniform(-1, 1), rng.uniform(-1, 1),
                                     rng.uniform(-1, 1))).normalized()
    info["fall_rot_amount"] = rng.uniform(0.8, 2.6)

MOB_XMIN = min(c["base"].x - c["radius"] for c in ALL_CHUNKS)
MOB_XMAX = max(c["base"].x + c["radius"] for c in ALL_CHUNKS)
MOB_YMIN = min(c["base"].y - c["radius"] for c in ALL_CHUNKS)
MOB_YMAX = max(c["base"].y + c["radius"] for c in ALL_CHUNKS)
MOB_ZMAX = max(c["base"].z + c["radius"] for c in ALL_CHUNKS)
MOB_HX = max(abs(MOB_XMIN), abs(MOB_XMAX))
MOB_HY = max(abs(MOB_YMIN), abs(MOB_YMAX))

# =============================================================================
# ANIMATION — every part shares ONE timing curve per clip (CORE_FN), only
# lagged/amplified by `depth` (synced_offset) so the whole figure reads as
# ONE puppet moving in sync, weight increasing toward the extremities.
# attack is the exception: the arm chain (upper_arm/forearm/fist) runs a
# purpose-built whip curve instead — but BOTH arms run it on the identical
# timeline `t`, so the slam still reads synchronized, not alternating.
# death is the only clip with independent per-chunk physics (collapse).
# =============================================================================
def core_idle(t):
    z = 0.045 * math.sin(2 * math.pi * t) * SCALE
    x = 0.02 * math.sin(2 * math.pi * t * 0.5 + 0.3) * SCALE
    return Vector((x, 0.0, z))


def core_move(t):
    ph = (t * 2.0) % 1.0
    if ph < 0.22:
        z = -0.16 * ease_in_expo(ph / 0.22)
    else:
        u = (ph - 0.22) / 0.78
        z = -0.16 * (1.0 - ease_out_cubic(u))
    x = 0.06 * math.sin(2 * math.pi * t) * SCALE
    return Vector((x, 0.0, z * SCALE))


def core_attack(t):
    if t < 0.30:
        u = t / 0.30
        y = 0.03 * ease_in_cubic(u)
        z = 0.02 * ease_in_cubic(u)
    elif t < 0.46:
        u = (t - 0.30) / 0.16
        y = lerp(0.03, -0.07, ease_in_expo(u))
        z = lerp(0.02, -0.05, ease_in_expo(u))
    elif t < 0.55:
        y, z = -0.07, -0.05
    else:
        u = (t - 0.55) / 0.45
        y = lerp(-0.07, 0.0, ease_out_cubic(u))
        z = lerp(-0.05, 0.0, ease_out_cubic(u))
    return Vector((0.0, y * SCALE, z * SCALE))


def core_hit(t):
    y = 0.12 * math.sin(math.pi * min(1.0, t * 1.6))
    z = -0.07 * math.sin(math.pi * t)
    return Vector((0.0, y * SCALE, z * SCALE))


CORE_FN = {"idle-loop": core_idle, "move-loop": core_move, "attack": core_attack, "hit": core_hit}
LAG_PER_DEPTH = {"idle-loop": 0.020, "move-loop": 0.035, "attack": 0.012, "hit": 0.015}
AMP_GAIN_PER_DEPTH = {"idle-loop": 0.05, "move-loop": 0.09, "attack": 0.04, "hit": 0.06}


def synced_offset(clip, t, depth):
    lag = depth * LAG_PER_DEPTH.get(clip, 0.02)
    t_l = max(0.0, t - lag)
    off = CORE_FN[clip](t_l)
    amp = 1.0 + depth * AMP_GAIN_PER_DEPTH.get(clip, 0.05)
    return off * amp


def torso_breathe_scale(clip, t):
    if clip == "idle-loop":
        return 1.0 + 0.03 * math.sin(2 * math.pi * t)
    return 1.0


def arm_whip_offset(t, side, depth):
    # side: -1 (L) / +1 (R). depth 1=upper_arm, 2=forearm, 3=fist — amplitude
    # grows with depth so the chain reads as a WHIP (shoulder moves a
    # little, fist moves a lot) while every joint runs the identical
    # anticipation -> explosive-release -> overshoot/settle timeline `t`,
    # so both arms (and every link in each arm) stay in lockstep.
    amp = 0.45 + 0.35 * (depth - 1)
    if t < 0.28:
        u = ease_in_cubic(t / 0.28)
        x = lerp(0.0, side * 0.22, u) * amp
        y = lerp(0.0, 0.16, u) * amp
        z = lerp(0.0, 0.42, u) * amp
    elif t < 0.42:
        u = ease_in_expo((t - 0.28) / 0.14)
        x = lerp(side * 0.22, -side * 0.16, u) * amp
        y = lerp(0.16, -0.46, u) * amp
        z = lerp(0.42, -0.12, u) * amp
    elif t < 0.50:
        x, y, z = -side * 0.16 * amp, -0.46 * amp, -0.12 * amp
    else:
        u = ease_out_cubic((t - 0.50) / 0.50)
        ov = 0.04 * amp * math.sin(2 * math.pi * ((t - 0.50) / 0.50) * 2.2) * (1.0 - u)
        x = lerp(-side * 0.16 * amp, 0.0, u)
        y = lerp(-0.46 * amp, 0.0, u) + ov
        z = lerp(-0.12 * amp, 0.0, u)
    return Vector((x * SCALE, y * SCALE, z * SCALE))


ARM_PARTS_PREFIX = ("upper_arm_", "forearm_", "fist_")


def death_fall(info, t):
    stagger = info["death_stagger"]
    local_t = max(0.0, min(1.0, (t - stagger) / max(1e-4, 1.0 - stagger)))
    height = info["base"].z
    ground = info["radius"] * 0.75
    target_xy = Vector((info["base"].x, info["base"].y)) + Vector(
        (info["fall_dir"].x, info["fall_dir"].y)) * info["fall_dist"]
    if local_t < 0.55:
        u = local_t / 0.55
        z = lerp(height, ground, ease_in_expo(u))
        xy = Vector((info["base"].x, info["base"].y)).lerp(target_xy, ease_in_expo(u) * 0.9)
        rot_t = ease_in_expo(u)
    elif local_t < 0.68:
        u = (local_t - 0.55) / 0.13
        bounce_amt = min(0.16 * SCALE, max(0.02, (height - ground)) * 0.28)
        z = ground + bounce_amt * math.sin(math.pi * u)
        xy = target_xy
        rot_t = 1.0
    else:
        u = (local_t - 0.68) / 0.32
        decay = 1.0 - u
        wob = 0.025 * SCALE * decay * math.sin(2 * math.pi * u * 3.0)
        z = ground + wob
        xy = target_xy
        rot_t = 1.0
    pos = Vector((xy.x, xy.y, z))
    rot = info["fall_rot_axis"] * (info["fall_rot_amount"] * rot_t) if local_t > 0.0 else Vector((0, 0, 0))
    return pos, rot


ANIMS = {"idle-loop": 96, "move-loop": 48, "attack": 36, "hit": 16, "death": 72}

mat_ad = STONE_MAT.node_tree.animation_data_create()

clip_actions = {}
for clip_name, frames in ANIMS.items():
    obj_actions = {}
    for info in ALL_CHUNKS:
        obj = info["obj"]
        ad = obj.animation_data_create()
        act = bpy.data.actions.new(f"{clip_name}_{info['name']}")
        ad.action = act
        obj_actions[info["name"]] = (ad, act)

    boost_act = bpy.data.actions.new(f"{clip_name}_crack_boost")
    mat_ad.action = boost_act

    for f in range(1, frames + 1, 2):
        t = (f - 1) / max(1, frames - 1)

        if clip_name == "death":
            for info in ALL_CHUNKS:
                pos, rot = death_fall(info, t)
                obj = info["obj"]
                obj.location = pos
                obj.keyframe_insert("location", frame=f)
                obj.rotation_euler = rot
                obj.keyframe_insert("rotation_euler", frame=f)
            # cracks die fast (fully dark by t=0.30) — well before the pile
            # finishes settling, so "the golem's magic dies" reads before
            # the last bounce
            gt = min(1.0, t / 0.30)
            CRACK_BOOST.outputs[0].default_value = CRACK_BASE_STRENGTH * (1.0 - gt)
            CRACK_BOOST.outputs[0].keyframe_insert("default_value", frame=f)
            continue

        if clip_name == "attack":
            for info in ALL_CHUNKS:
                obj = info["obj"]
                if info["part"].startswith(ARM_PARTS_PREFIX):
                    off = arm_whip_offset(t, info["side"], info["depth"])
                else:
                    off = synced_offset("attack", t, info["depth"])
                obj.location = info["base"] + off
                obj.keyframe_insert("location", frame=f)
                if info["part"] == "torso":
                    obj.scale = Vector((1.0, 1.0, torso_breathe_scale("attack", t)))
                    obj.keyframe_insert("scale", frame=f)
            pulse = 1.0 + 0.6 * math.exp(-((t - 0.46) ** 2) / (2 * 0.025 ** 2))
        else:
            for info in ALL_CHUNKS:
                obj = info["obj"]
                off = synced_offset(clip_name, t, info["depth"])
                obj.location = info["base"] + off
                obj.keyframe_insert("location", frame=f)
                if info["part"] == "torso":
                    obj.scale = Vector((1.0, 1.0, torso_breathe_scale(clip_name, t)))
                    obj.keyframe_insert("scale", frame=f)
            if clip_name == "idle-loop":
                pulse = 1.0 + 0.15 * math.sin(2 * math.pi * t * 2.0)
            elif clip_name == "hit":
                pulse = 1.0 + 0.4 * math.exp(-((t - 0.15) ** 2) / (2 * 0.03 ** 2))
            else:
                pulse = 1.0

        CRACK_BOOST.outputs[0].default_value = CRACK_BASE_STRENGTH * pulse
        CRACK_BOOST.outputs[0].keyframe_insert("default_value", frame=f)

    clip_actions[clip_name] = (frames, obj_actions, boost_act)

for info in ALL_CHUNKS:
    info["obj"].animation_data.action = None
    info["obj"].location = info["base"]
    info["obj"].scale = Vector((1.0, 1.0, 1.0))
    info["obj"].rotation_euler = (0.0, 0.0, 0.0)
mat_ad.action = None
CRACK_BOOST.outputs[0].default_value = CRACK_BASE_STRENGTH

# =============================================================================
# FICHA SHOWCASE SCENE — contract rig (§4).
# =============================================================================
world = bpy.data.worlds.new("ficha")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.30, 0.22, 0.48, 1.0)


def add_light(name, loc, energy, size):
    ld = bpy.data.lights.new(name, type='AREA')
    ld.energy = energy
    ld.size = size
    lo = bpy.data.objects.new(name, ld)
    lo.location = loc
    bpy.context.collection.objects.link(lo)
    lo.rotation_mode = 'QUATERNION'
    lo.rotation_quaternion = lo.location.to_track_quat('Z', 'Y')


add_light("key", (-3.6, -2.3, 3.1), 530, 3.6)
add_light("fill", (3.2, -2.1, 1.2), 145, 3.4)
add_light("rim", (0.7, 3.7, 2.7), 630, 3.4)

target = bpy.data.objects.new("target", None)
target.location = (0.0, 0.0, 1.45)
bpy.context.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 50
cam = bpy.data.objects.new("cam", cd)
cam.location = (-2.6, -5.8, 2.0)
bpy.context.collection.objects.link(cam)
cam.constraints.new(type='TRACK_TO').target = target
scene.camera = cam

try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.eevee.taa_render_samples = 64
scene.view_settings.view_transform = 'Standard'

# =============================================================================
# RENDER — anim frames per clip (mob only, original framing), then reset,
# then the hero still (mob + player-scale silhouette).
# =============================================================================
scene.render.resolution_x = 512
scene.render.resolution_y = 640
for clip_name, (frames, obj_actions, boost_act) in clip_actions.items():
    for info in ALL_CHUNKS:
        ad, act = obj_actions[info["name"]]
        ad.action = act
    mat_ad.action = boost_act
    for f in range(1, frames + 1, 2):
        scene.frame_set(f)
        scene.render.filepath = os.path.join(ANIM_DIR, f"{clip_name.replace('-loop', '')}_{f:03d}.png")
        bpy.ops.render.render(write_still=True)
    print("[golem] frames", clip_name)
for info in ALL_CHUNKS:
    info["obj"].animation_data.action = None
    info["obj"].location = info["base"]
    info["obj"].scale = Vector((1.0, 1.0, 1.0))
    info["obj"].rotation_euler = (0.0, 0.0, 0.0)
mat_ad.action = None
CRACK_BOOST.outputs[0].default_value = CRACK_BASE_STRENGTH

# ---------- hero still: scale silhouette (mob style contract §4, Pokedex rule) ----------
sys.path.insert(0, os.path.dirname(OUT_DIR))
import _ficha_common as ficha

SIL_DIST = math.sqrt(MOB_HX ** 2 + MOB_HY ** 2) + 0.4 + 0.254
right_dir = ficha.camera_right_vector(cam, target)
sil_loc = (right_dir * SIL_DIST)
sil_loc.z = 0.0
sil = ficha.add_scale_silhouette(location=tuple(sil_loc))
sil_xmin, sil_xmax, sil_ymin, sil_ymax, sil_zmin, sil_zmax = ficha.silhouette_bbox(location=tuple(sil_loc))
old_target_loc, old_cam_loc = ficha.frame_hero_camera(
    cam, target,
    x_min=min(MOB_XMIN, sil_xmin), x_max=max(MOB_XMAX, sil_xmax),
    y_min=min(MOB_YMIN, sil_ymin), y_max=max(MOB_YMAX, sil_ymax),
    z_min=0.0, z_max=max(MOB_ZMAX, sil_zmax))

scene.frame_set(1)
scene.render.resolution_x = 1024
scene.render.resolution_y = 1280
scene.render.filepath = os.path.join(REN_DIR, "golem_hero.png")
bpy.ops.render.render(write_still=True)

ficha.restore_hero_camera(cam, target, old_target_loc, old_cam_loc)
ficha.remove_scale_silhouette(sil)

# =============================================================================
# NLA PUSH + EXPORT
# =============================================================================
for clip_name, (frames, obj_actions, boost_act) in clip_actions.items():
    for info in ALL_CHUNKS:
        ad, act = obj_actions[info["name"]]
        tr = ad.nla_tracks.new()
        tr.name = clip_name
        tr.strips.new(clip_name, 1, act)
    trm = STONE_MAT.node_tree.animation_data.nla_tracks.new()
    trm.name = clip_name
    trm.strips.new(clip_name, 1, boost_act)

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "golem_wip.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "golem.glb"),
    use_selection=False,
    export_animations=True,
    export_morph=False,
    export_animation_mode='NLA_TRACKS',
)
print("[golem] DONE")
