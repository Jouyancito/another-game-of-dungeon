"""
build_river_pack.py - river-channel ROCK + REED pack for Piso 1 Pradera
(DP_ToonGrounded: flat-shaded, FLOAT_COLOR only, no textures, Z-up build,
base at Z=0, export_yup=True).

References (MANDATORY, loaded before writing this - see
game/docs/art/_references/prairie_rivers/_synthesis.md +
game/docs/art/_references/rocks/_synthesis.md):
  - river_boulders_rapids.jpg / frog_on_rocks_stream.jpg: boulders sit
    DIRECTLY IN the channel, water splits/foams around them, and each rock
    shows a wet/dry SPLIT keyed to water contact - dark+mossy where it
    touches the waterline, lighter/drier above. The split line follows the
    rock's own facets (frog_on_rocks_stream.jpg: irregular, not a ruler-cut
    band).
  - heron_riverbank_reeds.jpg: reeds root DIRECTLY IN the water/streambed,
    not set back on dry land - stems break the surface right at the edge.
  - rocks/_synthesis.md: non-uniform per-rock scale, faceted noise-displaced
    surface (not a smooth sphere), warm grey-tan base, embedded (sunk) base.

Structural precedent (read before writing this script, per task brief):
  - rock_pack/build_rock_pack.py: make_rock() noise-displaced-icosphere
    technique (FLOAT_COLOR, per-vertex AO shading, embed_into_ground,
    join_parts) - reused/extended here for the channel rocks.
  - bush_pack/build_bush_pack.py: enforce_overlap adjacency rule (a chunk
    farther from its nearest neighbor than ~0.6x the summed radii reads as
    a disconnected floating island) - reused for the wet-cluster's rock
    spacing, and the add_twig-style tapered-prism technique - adapted here
    into reed stalks (prisms, not flat cards, so they hold up as chunky
    verticals instead of paper-thin cards at reed scale).

WET/DRY SPLIT technique (new here): the boundary is decided PER-FACE (not a
smooth per-vertex gradient) against an ABSOLUTE world-Z waterline shared by
every chunk of a rock (and every rock in the cluster) so multiple chunks/
rocks read as sitting in the SAME body of water. Each face's threshold is
perturbed by low-frequency 3D noise sampled at the face center, so the
boundary wiggles between faces instead of being a laser-straight cut -
combined with genuinely irregular facet boundaries (noise-displaced,
low-subdivision icosphere chunks), this produces the "follows the facets"
read the reference calls for. A LOOP still gets its own vertex-level AO tone
blended into whichever zone (wet/dry) its FACE landed in, so the boundary is
hard at the face level but each zone still has internal AO shading, not a
flat block color.

Triangle budgets (task brief): rock_river_wet_01 <=300, rock_river_wet_
cluster_01 <=450, rock_river_dry_01 <=300, reed_clump_01 <=350, reed_clump_
small_01 <=200.

Run:
  blender.exe --background --python build_river_pack.py
  blender.exe --background --python build_river_pack.py -- --seed 7
"""
import bpy
import bmesh
import math
import os
import random
import sys
from mathutils import Vector, Matrix
from mathutils import noise as mnoise

SEED = 20260727
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
ASSET_DIR = os.path.normpath(os.path.join(
    SCRIPT_DIR, "..", "..", "..", "assets", "art", "piso1_pradera", "props", "water"))
os.makedirs(ASSET_DIR, exist_ok=True)

sys.path.insert(0, os.path.dirname(SCRIPT_DIR))
import _ground_common as groundlib  # noqa: E402

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


# =============================================================================
# SMALL HELPERS (shared vocabulary with rock_pack / bush_pack)
# =============================================================================
def clamp01(x):
    return max(0.0, min(1.0, x))


def lerp3(a, b, t):
    return [a[i] + (b[i] - a[i]) * t for i in range(3)]


def join_parts(objs, name):
    for o in objs:
        o.location = Vector((0.0, 0.0, 0.0))
    if len(objs) == 1:
        joined = objs[0]
        joined.name = name
        joined.location = Vector((0.0, 0.0, 0.0))
        return joined
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    joined = bpy.context.view_layer.objects.active
    joined.name = name
    joined.location = Vector((0.0, 0.0, 0.0))
    return joined


def embed_into_ground(obj, embed_amount):
    """Data-level mesh shift (rock_pack convention) - sinks a slice of the
    base below Z=0 so it reads as embedded in the streambed, not resting on
    top of it, while keeping the object's own pivot at world origin."""
    zs = [v.co.z for v in obj.data.vertices]
    zmin = min(zs)
    shift = -zmin - embed_amount
    obj.data.transform(Matrix.Translation((0.0, 0.0, shift)))
    obj.data.update()


def count_tris(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def make_vcol_material(name, roughness=0.85, specular=0.20):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n = m.node_tree.nodes["Principled BSDF"]
    n.inputs["Roughness"].default_value = roughness
    spec = n.inputs.get("Specular IOR Level")
    if spec is not None:
        spec.default_value = specular
    attr = m.node_tree.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    m.node_tree.links.new(attr.outputs["Color"], n.inputs["Base Color"])
    return m


# =============================================================================
# PALETTES
# =============================================================================
# Wet channel rock: dark/cool/desaturated waterline band + a green moss touch,
# vs a warm-lit dry cap above the waterline (still cooler/darker than the
# fully-dry lecho variant - it's still splashed occasionally).
# pass-2e fix: WET_DARK/WET_LIGHT were both near-black (0.045-0.16) - at
# render exposure that reads almost identically to plain ambient-occlusion
# shadow in ANY crevice (wet or dry rock alike), so the "wet band" was
# indistinguishable from ordinary shading rather than a distinctly colored
# wet material - confirmed by debug face-count print (20-62 wet faces per
# chunk, split logic itself was always correct) plus a side-by-side look at
# rock_river_dry_01 (wet=False) which showed a near-identical dark sliver at
# its own base from plain shadow. Brightened + kept it cool/desaturated so
# it stays visually "wet" rather than "lit", not just less dark.
WET_DARK = (0.070, 0.090, 0.105)
WET_LIGHT = (0.195, 0.215, 0.230)
# pass-3 fix (2026-07-27): round-2's MOSS_TOUCH (0.31,0.56,0.21) is a bright
# mint-green - at the small 1-face blotches the split logic was producing it
# read as a flat painted-on triangle, not moss. Target color is #5a7a4a
# (dark/desaturated olive), sRGB->linear-converted so Blender's Standard view
# transform displays it back near that hex ((0.353,0.478,0.290) sRGB ->
# ~(0.10,0.19,0.07) linear) - see measure_channel_rock_waterline_z()'s
# neighbor fix (moss patch CONTIGUITY, not per-face probability) for the
# other half of this fix.
MOSS_TOUCH = (0.100, 0.190, 0.070)
# coordinator fix (round 2): dry tones were reading as cold bone-white -
# reused verbatim from rock_pack/build_rock_pack.py's documented granite
# palette (STONE_DARK/STONE_LIGHT) instead of a separately-tuned warm, so
# river rocks stay in the SAME granite family as the ground-scatter pack.
CHANNEL_DRY_DARK = (0.20, 0.145, 0.088)   # == rock_pack STONE_DARK
CHANNEL_DRY_LIGHT = (0.66, 0.585, 0.445)  # == rock_pack STONE_LIGHT

# Fully-dry streambed rock: same warm granite family as CHANNEL_DRY (rock_pack
# STONE_DARK/STONE_LIGHT) - never touches water, so no separate cooler variant.
DRY_DARK = (0.20, 0.145, 0.088)
DRY_LIGHT = (0.66, 0.585, 0.445)

# Reeds - cool blue-green gradient stalk, brown-tan spike head.
REED_DARK = (0.032, 0.082, 0.042)
REED_MID = (0.130, 0.300, 0.130)
REED_LIGHT = (0.220, 0.420, 0.200)
REED_HEAD_DARK = (0.190, 0.125, 0.058)
REED_HEAD_LIGHT = (0.440, 0.310, 0.145)


# =============================================================================
# CHANNEL ROCK CHUNK - noise-displaced icosphere (rock_pack's make_rock
# technique), extended with a per-FACE wet/dry split against an ABSOLUTE
# world-Z waterline shared across every chunk/rock of the same build, so
# multiple chunks read as sitting in the same water.
# =============================================================================
def _displace_channel_rock_bm(radius, subdiv, seed, elongate, taper,
                               noise_scale, noise_strength, ridge_weight,
                               flatten_base):
    """Shared noise-displacement core for a channel-rock chunk, LOCAL to its
    own origin (no `center` offset applied yet) - extracted so
    measure_channel_rock_waterline_z() can build the EXACT same deterministic
    geometry make_channel_rock() will, purely to measure its Z extent before
    any face is colored."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radius)
    seed_v = Vector((seed * 17.13, seed * 5.71, seed * 31.9))

    ridge_val = {}
    for v in bm.verts:
        co = v.co.copy()
        n1 = mnoise.noise(co * noise_scale + seed_v)
        n2 = mnoise.noise(co * noise_scale * 2.4 + seed_v + Vector((5.0, 5.0, 5.0)))
        ridged = 1.0 - abs(n1 * 2.0 - 1.0)
        ridge_val[v] = ridged
        d = (n2 * 2.0 - 1.0) * 0.55 + (ridged - 0.5) * ridge_weight
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

    if flatten_base > 0.0:
        # coordinator fix (round 2): rock_river_dry_01 read as "floating,
        # round belly, point contact" - a noise-displaced icosphere's bottom
        # is a single vertex/small facet, so it touches the ground plane at
        # essentially one point. Pull the bottom flatten_base fraction of the
        # mesh toward a near-flat plateau (rock_pack's flatten_top logic,
        # inverted) so the rock SEATS with a broad contact patch instead of
        # balancing on a tip. A little noise jitter keeps the plateau from
        # reading as a laser-flat cut.
        zs = [v.co.z for v in bm.verts]
        zmin, zmax = min(zs), max(zs)
        h = max(1e-5, zmax - zmin)
        # pass-2b fix: plateau_z was zmin + h*0.025 (a small POSITIVE offset)
        # - that pulls the single lowest vertex UP toward that offset
        # (its own w=1 at t=0), raising the mesh's effective lowest point by
        # roughly 1-1.5cm and making embed_into_ground's shift (which reads
        # the NEW, now-higher zmin) sink the whole rock LESS than intended -
        # rendered as MORE floaty, not less. plateau_z must sit AT the
        # original zmin (zero-mean jitter only) so the widening pull brings
        # surrounding verts DOWN to the existing lowest level instead of
        # lifting the lowest point itself.
        plateau_z = zmin
        for v in bm.verts:
            t = (v.co.z - zmin) / h
            if t < flatten_base:
                w = clamp01(1.0 - t / flatten_base)
                jitter = (mnoise.noise(v.co * 8.0 + seed_v + Vector((77.0, 3.0, 19.0))) - 0.5) * 0.24 * h * flatten_base
                target_z = plateau_z + jitter
                v.co.z = v.co.z + (target_z - v.co.z) * w
                # pass-2c fix: clamping Z alone did NOT widen the footprint -
                # an icosphere's bottom pole is already narrow in X/Y by
                # construction, so pulling those same narrow-radius verts
                # down just moved a still-narrow tip lower (still read as a
                # rounded belly balanced on a point). Push the flattened
                # band's verts OUTWARD in X/Y too (relative to chunk-local
                # origin, before `+= center`) so the flattened disc actually
                # has AREA - a real "foot", not a lowered apex.
                xy_scale = 1.0 + 0.85 * w
                v.co.x *= xy_scale
                v.co.y *= xy_scale

    return bm, ridge_val


def measure_channel_rock_waterline_z(radius, subdiv, seed, elongate, taper,
                                      center=None,
                                      noise_scale=2.6, noise_strength=0.24,
                                      ridge_weight=0.38, flatten_base=0.0,
                                      split_noise_scale=3.4, split_irregularity=0.055,
                                      frac=0.30):
    """PASS-3 fix (2026-07-27, macro_cluster defect #1): the cluster's
    central rock ("main") showed NO wet band while its much-smaller satellites
    did. Root cause, confirmed via debug face-count+Z-range print: a single
    fixed absolute waterline_z (0.20) that read fine on the small satellites
    only covered ~11% of the tall main rock's faces (a thin sliver right at
    its base that embed_into_ground then buried entirely).

    TWO earlier attempts, both measured wrong before landing here:
    (1) linear height-fraction (zmin + 0.35*(zmax-zmin)) - a taper-widened,
    noise-displaced icosphere's face-count is NOT uniform across its Z range
    (this mesh's lower band is sparse - a few large faces near the base pole
    vs many small ones near the "equator"), so 35% of *height* measured 0% of
    *faces* wet.
    (2) face-count PERCENTILE ignoring the split's own jitter - picking the
    exact Z at the 30th-percentile face put the threshold IN a densely
    packed cluster of faces, and the per-face `split_irregularity` jitter
    (already part of make_channel_rock's own wet/dry decision, +-0.055) was
    then large enough relative to that cluster's spacing to flip MOST of the
    intended-wet faces back to dry at render time - measured 2/80 wet, not
    ~24/80.

    Fixed by BISECTING directly in the same post-jitter decision space
    make_channel_rock() itself uses (same split_noise_scale/split_irregularity/
    split_seed_v formula) instead of an idealized pre-jitter percentile - this
    finds a waterline_z that reliably lands ~`frac` of the main rock's faces
    on the wet side ONCE JITTER IS APPLIED, matching rock_river_wet_01's
    already-correct main chunk's empirical ~25% wet-face ratio.

    CRITICAL: `mnoise.noise()` samples a 3D position, so the jitter it
    produces for a face is NOT translation-invariant - evaluating it on the
    LOCAL (center=(0,0,0)) face center gives a completely different value
    than make_channel_rock() gets from the same face's REAL (post `+=center`)
    position. A first version of this bisection measured in local space and
    got 2/80 wet in the real build vs. the ~24/80 it computed for itself -
    the fix is to add `center` here too (mirroring make_channel_rock's own
    `for v in bm.verts: v.co += center` step) before touching ANY noise call,
    so every position fed to mnoise.noise here is IDENTICAL to what the real
    build will use. Returns an ABSOLUTE waterline_z ready to use as-is (the
    caller does NOT need to add center.z again)."""
    center = center if center is not None else Vector((0.0, 0.0, 0.0))
    bm, _ridge_val = _displace_channel_rock_bm(
        radius, subdiv, seed, elongate, taper, noise_scale, noise_strength,
        ridge_weight, flatten_base)
    for v in bm.verts:
        v.co += center
    seed_v = Vector((seed * 17.13, seed * 5.71, seed * 31.9))
    split_seed_v = seed_v + Vector((233.0, 71.0, 5.0))
    face_data = []
    for f in bm.faces:
        fc = f.calc_center_median()
        wob = mnoise.noise(fc * split_noise_scale + split_seed_v)
        jitter = (wob * 2.0 - 1.0) * split_irregularity
        face_data.append((fc.z, jitter))
    bm.free()

    zmin = min(z for z, _ in face_data)
    zmax = max(z for z, _ in face_data)
    target_n = max(1, round(frac * len(face_data)))
    lo, hi = zmin - split_irregularity - 0.01, zmax + split_irregularity + 0.01
    for _ in range(40):
        mid = (lo + hi) / 2.0
        n_wet = sum(1 for z, j in face_data if z < mid + j)
        if n_wet < target_n:
            lo = mid
        else:
            hi = mid
    return hi


def make_channel_rock(name, center=None, radius=0.26, subdiv=1, seed=0,
                       elongate=(1.0, 1.0, 1.0), taper=0.0,
                       noise_scale=2.6, noise_strength=0.24, ridge_weight=0.38,
                       wet=True, waterline_z=0.16, split_irregularity=0.055,
                       split_noise_scale=3.4,
                       flatten_base=0.0):
    center = center if center is not None else Vector((0.0, 0.0, 0.0))
    bm, ridge_val = _displace_channel_rock_bm(
        radius, subdiv, seed, elongate, taper, noise_scale, noise_strength,
        ridge_weight, flatten_base)
    seed_v = Vector((seed * 17.13, seed * 5.71, seed * 31.9))
    paint_seed_v = seed_v + Vector((91.0, 47.0, 13.0))
    split_seed_v = seed_v + Vector((233.0, 71.0, 5.0))

    for v in bm.verts:
        v.co += center

    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()

    # base AO tone per vertex (dark in crevices/undersides, light on upward
    # faces) - rock_pack's formula, kept identical for a consistent family.
    base_tone = {}
    for v in bm.verts:
        nrm = v.normal
        paint = mnoise.noise(v.co * 3.5 + paint_seed_v)
        crevice = ridge_val.get(v, 0.0)
        crev_factor = clamp01((crevice - 0.62) / 0.38)
        t_ao = clamp01(0.26 + 0.52 * (nrm.z * 0.5 + 0.5) + 0.30 * paint - 0.30 * crev_factor)
        base_tone[v] = t_ao

    col_layer = bm.loops.layers.float_color.new("Col")

    # PASS 1 - classify every face wet/dry first (unchanged threshold logic),
    # so moss placement (PASS 2) can pick from the real wet-face set instead
    # of rolling independently per-face.
    face_is_wet = {}
    for f in bm.faces:
        if wet:
            fc = f.calc_center_median()
            wob = mnoise.noise(fc * split_noise_scale + split_seed_v)
            thresh_z = waterline_z + (wob * 2.0 - 1.0) * split_irregularity
            face_is_wet[f] = fc.z < thresh_z
        else:
            face_is_wet[f] = False

    # PASS 2 - pass-3 fix (2026-07-27, macro_wet defect #2): moss used to be
    # ONE noise roll per face, independent of its neighbors, which at the
    # sparse wet-face counts this split produces reads as a single flat
    # mint-green triangle (paint blob), not moss. Replace with 2-4
    # deterministic CONTIGUOUS patches (1-3 faces each) grown by BFS across
    # the wet-face adjacency graph, seeded off this chunk's own `seed` param
    # so placement is reproducible per rock but distinct rock-to-rock -
    # spread along the wet band so at least one patch is visible from any
    # camera angle instead of relying on a single lucky face.
    moss_faces = set()
    if wet:
        wet_face_list = [f for f in bm.faces if face_is_wet[f]]
        if wet_face_list:
            patch_rng = random.Random(seed * 7919 + 101)
            n_patches = patch_rng.randint(2, 4)
            for _ in range(n_patches):
                seed_face = patch_rng.choice(wet_face_list)
                patch_size = patch_rng.randint(1, 3)
                patch = {seed_face}
                frontier = [seed_face]
                while len(patch) < patch_size and frontier:
                    cur = frontier.pop()
                    neighbors = [nf for e in cur.edges for nf in e.link_faces
                                 if nf is not cur and face_is_wet.get(nf, False)
                                 and nf not in patch]
                    patch_rng.shuffle(neighbors)
                    for nf in neighbors:
                        if len(patch) >= patch_size:
                            break
                        patch.add(nf)
                        frontier.append(nf)
                moss_faces.update(patch)

    # PASS 3 - bake vertex colors per loop from the wet/dry + moss-patch
    # classification decided above.
    for f in bm.faces:
        is_wet_face = face_is_wet[f]
        moss_here = f in moss_faces
        if wet:
            dark, light = (WET_DARK, WET_LIGHT) if is_wet_face else (CHANNEL_DRY_DARK, CHANNEL_DRY_LIGHT)
        else:
            dark, light = DRY_DARK, DRY_LIGHT
        for l in f.loops:
            t = base_tone[l.vert]
            base = [dark[i] + (light[i] - dark[i]) * t for i in range(3)]
            if moss_here:
                # stronger mix (was 0.50-0.80, now 0.62-0.90) so the moss
                # actually reads as green in the macro instead of a faint
                # tint indistinguishable from the wet-dark AO shading.
                mt = 0.70 + 0.26 * t
                base = [base[i] + (MOSS_TOUCH[i] - base[i]) * mt for i in range(3)]
            l[col_layer] = (base[0], base[1], base[2], 1.0)

    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.validate(verbose=False)
    for p in me.polygons:
        p.use_smooth = False
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    return obj


# =============================================================================
# REED STALK / SEED-HEAD - tapered n-gon PRISMS (not flat cards - a flat card
# reed reads paper-thin at close range), rooted below Z=0 so they plant into
# the streambed instead of floating on top of it.
# =============================================================================
def add_reed_stalk(bm, vcol, rng, base_xy, height, sides, lean_deg, lean_ang,
                    root_depth=0.05, base_r=0.017, tip_r=0.004):
    bx, by = base_xy
    lean = math.radians(lean_deg)
    dx, dy = math.cos(lean_ang), math.sin(lean_ang)
    zs_frac = [0.0, 0.5, 1.0]  # ground(post-root) -> mid -> tip, 2 segments
    rings = []
    for zf in zs_frac:
        z = zf * height
        lean_amount = math.tan(lean) * max(0.0, z)
        cx = bx + dx * lean_amount
        cy = by + dy * lean_amount
        u = clamp01(z / height) if height > 1e-6 else 0.0
        r = base_r + (tip_r - base_r) * u
        ring = []
        for i in range(sides):
            ang = 2.0 * math.pi * i / sides + rng.uniform(-0.06, 0.06)
            rx = cx + math.cos(ang) * r
            ry = cy + math.sin(ang) * r
            ring.append(bm.verts.new((rx, ry, z)))
        rings.append((ring, z))
    # root ring, embedded below ground - same XY as the ground(z=0) ring so
    # the buried segment doesn't lean (only the above-ground part sways).
    root_ring = []
    for i in range(sides):
        ang = 2.0 * math.pi * i / sides
        rx = bx + math.cos(ang) * base_r * 1.05
        ry = by + math.sin(ang) * base_r * 1.05
        root_ring.append(bm.verts.new((rx, ry, -root_depth)))
    rings.insert(0, (root_ring, -root_depth))

    for i in range(len(rings) - 1):
        ring_a, _za = rings[i]
        ring_b, _zb = rings[i + 1]
        for s in range(sides):
            a0, a1 = ring_a[s], ring_a[(s + 1) % sides]
            b0, b1 = ring_b[s], ring_b[(s + 1) % sides]
            bm.faces.new((a0, a1, b1, b0))

    for ring, z in rings:
        u = clamp01(z / height) if height > 1e-6 else 0.0
        if u < 0.65:
            col = lerp3(REED_DARK, REED_MID, clamp01(u / 0.65))
        else:
            col = lerp3(REED_MID, REED_LIGHT, clamp01((u - 0.65) / 0.35))
        for v in ring:
            vcol[v] = col

    tip_ring, tip_z = rings[-1]
    tip_center = sum((v.co for v in tip_ring), Vector()) / len(tip_ring)
    return tip_center, (dx, dy)


def add_seed_head(bm, vcol, rng, center, dir_xy, length, radius, sides=5):
    cx, cy, cz = center
    dx, dy = dir_xy
    top = bm.verts.new((cx + dx * length * 0.18, cy + dy * length * 0.18, cz + length))
    bot = bm.verts.new((cx, cy, cz - length * 0.10))
    ring = []
    for i in range(sides):
        ang = 2.0 * math.pi * i / sides + rng.uniform(-0.15, 0.15)
        r = radius * (0.85 + 0.25 * abs(math.sin(ang * 2.0)))
        rz = cz + length * 0.32
        rx = cx + math.cos(ang) * r + dx * length * 0.06
        ry = cy + math.sin(ang) * r + dy * length * 0.06
        ring.append(bm.verts.new((rx, ry, rz)))
    for i in range(sides):
        a, b = ring[i], ring[(i + 1) % sides]
        bm.faces.new((top, a, b))
        bm.faces.new((bot, b, a))
    vcol[top] = REED_HEAD_LIGHT
    vcol[bot] = REED_HEAD_DARK
    for v in ring:
        vcol[v] = lerp3(REED_HEAD_DARK, REED_HEAD_LIGHT, 0.55)


def finalize_reed_mesh(name, bm, vcol):
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0006)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()
    col_layer = bm.loops.layers.float_color.new("Col")
    for f in bm.faces:
        for loop in f.loops:
            c = vcol.get(loop.vert, (0.2, 0.35, 0.2))
            loop[col_layer] = (c[0], c[1], c[2], 1.0)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.validate(verbose=False)
    for p in me.polygons:
        p.use_smooth = False
    obj = bpy.data.objects.new(name, me)
    scene.collection.objects.link(obj)
    return obj


def build_reed_clump(name, n_stalks, footprint_r, height_range, seed):
    rng = random.Random(seed)
    bm = bmesh.new()
    vcol = {}
    for i in range(n_stalks):
        ang = rng.uniform(0.0, 2.0 * math.pi)
        rad = footprint_r * math.sqrt(rng.uniform(0.0, 1.0))
        bx, by = math.cos(ang) * rad, math.sin(ang) * rad
        height = rng.uniform(*height_range)
        sides = rng.choice([3, 4])
        lean_deg = rng.uniform(2.0, 8.0)
        lean_ang = rng.uniform(0.0, 2.0 * math.pi)
        tip, dirxy = add_reed_stalk(
            bm, vcol, rng, (bx, by), height, sides, lean_deg, lean_ang,
            root_depth=0.05, base_r=rng.uniform(0.014, 0.020), tip_r=rng.uniform(0.003, 0.005))
        head_len = height * rng.uniform(0.14, 0.20)
        head_rad = rng.uniform(0.013, 0.020)
        add_seed_head(bm, vcol, rng, tip, dirxy, head_len, head_rad)
    return finalize_reed_mesh(name, bm, vcol)


# =============================================================================
# VARIANT BUILDERS
# =============================================================================
def build_rock_river_wet_01():
    """1. Medium channel rock, single boulder read (main + 2 fused satellite
    bulges, all sharing ONE absolute waterline_z so the split reads as one
    continuous irregular line across the whole rock, not 3 disagreeing
    bands). subdiv=2 (~80 tris/chunk empirically, NOT the 4x-per-level
    formula the icosphere name suggests - measured via count_tris on pass 1,
    which came in at 60 tris total with subdiv=1 = a bare 20-face
    icosahedron per chunk, far too coarse for the split to have any facet
    granularity to follow) so the waterline has enough facets to read as an
    irregular line instead of vanishing into 2-3 giant triangles. <=300
    tris."""
    wl = 0.155
    main = make_channel_rock("rrw_main", center=Vector((0.0, 0.0, 0.24)), radius=0.24,
                              subdiv=2, seed=10, elongate=(1.05, 0.95, 1.15), taper=0.18,
                              wet=True, waterline_z=wl)
    sat_a = make_channel_rock("rrw_sat_a", center=Vector((0.17, -0.10, 0.14)), radius=0.13,
                               subdiv=2, seed=11, elongate=(1.1, 1.0, 0.9), taper=0.10,
                               wet=True, waterline_z=wl)
    sat_b = make_channel_rock("rrw_sat_b", center=Vector((-0.14, 0.08, 0.10)), radius=0.10,
                               subdiv=2, seed=12, elongate=(0.95, 1.05, 0.85), taper=0.08,
                               wet=True, waterline_z=wl)
    obj = join_parts([main, sat_a, sat_b], "rock_river_wet_01")
    obj.data.materials.append(MAT_ROCK)
    embed_into_ground(obj, 0.05)
    return obj


def build_rock_river_wet_cluster_01():
    """2. 3-4 channel rocks packed HUB-AND-SPOKE around one main rock (each
    satellite center placed at ~0.60x the summed radii from the MAIN rock,
    not from its neighbors) - pass-1 fix: the original square/ring layout
    used ~0.86-0.90x separation (rock_pack's outcrop_hollow "near-touching
    with a deliberate gap" convention, wrong precedent to copy here) and
    rendered with visible gaps between rocks even though bounding spheres
    nominally overlapped - the golem_guardian lesson that noise-carved
    surfaces need real overlap (~0.55-0.65x, bush_pack's fused-core number),
    not just bbox-touch. All 4 rocks share the SAME waterline_z as the
    single-rock variant so the cluster reads as sitting in the same water.
    subdiv=2 per chunk (same facet-granularity fix as wet_01). <=450 tris.

    pass-2 fix: with wl=0.155 (wet_01's value) the smaller/lower satellite
    chunks mostly occlude the main chunk's own wet band from the showcase
    camera angle, and their own bands sit low/shadowed near the embedded
    base - a dedicated macro read as almost all-dry. Bumped to 0.20 (this
    cluster's chunks are smaller on average than wet_01's, so the same
    absolute height covers a bigger fraction of each one) so the split
    stays legible despite the occlusion.

    pass-3 fix (2026-07-27): that flat wl=0.20 broke the CENTRAL/main rock -
    debug face-count print showed only 9/80 (11%) of its faces qualified as
    wet (a thin sliver right at its base that embed_into_ground then buried),
    while the smaller satellites read 41-77% wet, because 0.20 sits at ~54%
    of the tall main rock's own height but only ~30-50% of the satellites'
    much shorter height. Derive the ONE shared absolute waterline from the
    MAIN rock's own measured geometry instead of a flat guess - see
    measure_channel_rock_waterline_z()."""
    a_radius, a_subdiv, a_seed = 0.20, 2, 20
    a_elongate, a_taper = (1.0, 0.92, 1.05), 0.15
    a_center_z = 0.20
    wl = measure_channel_rock_waterline_z(
        radius=a_radius, subdiv=a_subdiv, seed=a_seed,
        elongate=a_elongate, taper=a_taper,
        center=Vector((0.0, 0.0, a_center_z)), frac=0.42)
    a = make_channel_rock("rrwc_a", center=Vector((0.0, 0.0, a_center_z)), radius=a_radius,
                           subdiv=a_subdiv, seed=a_seed, elongate=a_elongate, taper=a_taper,
                           wet=True, waterline_z=wl)
    # b: dist=0.204 from a, sum(a,b)=0.34 -> 0.60x
    b = make_channel_rock("rrwc_b", center=Vector((0.156, 0.131, 0.13)), radius=0.14,
                           subdiv=2, seed=21, elongate=(1.05, 1.0, 0.95), taper=0.12,
                           wet=True, waterline_z=wl)
    # c: dist=0.192 from a, sum(a,c)=0.32 -> 0.60x
    c = make_channel_rock("rrwc_c", center=Vector((-0.180, 0.0657, 0.11)), radius=0.12,
                           subdiv=2, seed=22, elongate=(0.95, 1.0, 0.90), taper=0.10,
                           wet=True, waterline_z=wl)
    # d: dist=0.186 from a, sum(a,d)=0.31 -> 0.60x
    d = make_channel_rock("rrwc_d", center=Vector((-0.0323, -0.1832, 0.10)), radius=0.11,
                           subdiv=2, seed=23, elongate=(1.0, 1.0, 0.85), taper=0.08,
                           wet=True, waterline_z=wl)
    obj = join_parts([a, b, c, d], "rock_river_wet_cluster_01")
    obj.data.materials.append(MAT_ROCK)
    embed_into_ground(obj, 0.05)
    return obj


def build_rock_river_dry_01():
    """3. Dry streambed rock - warm light tones, no wet band at all
    (wet=False short-circuits the split logic entirely). subdiv=2 for facet
    consistency with the wet variants. <=300 tris.

    coordinator fix (round 2): FAILED as "floating, round belly, point
    contact". Two changes: (1) flatten_base=0.14 on BOTH chunks so each one
    seats on a broad flattened plateau instead of a single bottom vertex/
    facet tip - rock_pack's flatten_top logic, inverted, new param on
    make_channel_rock(). (2) the satellite's center.z was lowered from 0.11
    to 0.065 so ITS OWN flattened plateau lands close to the same absolute
    height as main's, before the joined object gets a single global
    embed_into_ground() shift - the earlier version only pulled the
    LOWEST point of the joined mesh down to the embed line, so the higher-
    sitting satellite would have floated ~2.5cm above ground once main's
    base was flattened (exactly the 'hanging fragment' risk flagged) -
    lowering the satellite's own resting height keeps both chunks' bases
    landing together. embed_into_ground amount reduced 0.04 -> 0.025 (2-3cm
    per spec, was sinking deeper than asked)."""
    # pass-2d fix: flatten_base=0.14 on a subdiv=2 icosphere (coarse vertex
    # rings) only caught the single bottom-pole vertex - the render showed
    # ZERO visible change because there was nothing else in that thin a
    # band to pull. Bumped to 0.34 so it reliably catches 2+ full vertex
    # rings, and the XY widen factor bumped too (0.55 -> 0.85) for a
    # decisively wider foot, not a subtle one.
    main = make_channel_rock("rrd_main", center=Vector((0.0, 0.0, 0.22)), radius=0.23,
                              subdiv=2, seed=30, elongate=(1.05, 0.90, 1.10), taper=0.20,
                              wet=False, flatten_base=0.34)
    sat = make_channel_rock("rrd_sat", center=Vector((0.20, 0.14, 0.07)), radius=0.11,
                             subdiv=2, seed=31, elongate=(1.0, 1.05, 0.85), taper=0.10,
                             wet=False, flatten_base=0.36)
    obj = join_parts([main, sat], "rock_river_dry_01")
    obj.data.materials.append(MAT_ROCK)
    embed_into_ground(obj, 0.025)
    return obj


def build_reed_clump_01():
    """4. Dense mata: 8-12 stalks, heights 0.6-1.2m, rooted -5cm. <=350 tris."""
    return build_reed_clump("reed_clump_01", n_stalks=10, footprint_r=0.16,
                             height_range=(0.6, 1.2), seed=40)


def build_reed_clump_small_01():
    """5. Sparse edge version: 4-6 stalks. <=200 tris."""
    return build_reed_clump("reed_clump_small_01", n_stalks=5, footprint_r=0.11,
                             height_range=(0.55, 1.0), seed=50)


# =============================================================================
# BUILD ALL
# =============================================================================
MAT_ROCK = make_vcol_material("river_rock_mat", roughness=0.86, specular=0.18)
MAT_REED = make_vcol_material("river_reed_mat", roughness=0.75, specular=0.10)

BUILDERS = [
    ("rock_river_wet_01", build_rock_river_wet_01, 300),
    ("rock_river_wet_cluster_01", build_rock_river_wet_cluster_01, 450),
    ("rock_river_dry_01", build_rock_river_dry_01, 300),
    ("reed_clump_01", build_reed_clump_01, 350),
    ("reed_clump_small_01", build_reed_clump_small_01, 200),
]

objects = []
print(f"\n[river_pack] seed={SEED}\n")
for name, fn, budget in BUILDERS:
    obj = fn()
    if name.startswith("reed_"):
        obj.data.materials.append(MAT_REED)
    tris = count_tris(obj)
    objects.append(obj)
    status = "OK" if tris <= budget else f"!! OVER {budget}-TRI BUDGET !!"
    print(f"[river_pack] built {name}  tris={tris}/{budget}  {status}")

# =============================================================================
# EXPORT - combined + per-variant, straight into props/water/, GLBs still at
# local origin (0,0,0); showcase layout offsets applied AFTER export.
# =============================================================================
bpy.ops.object.select_all(action='DESELECT')
for o in objects:
    o.select_set(True)
export_kwargs = dict(
    filepath=os.path.join(ASSET_DIR, "river_pack.glb"),
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
print(f"[river_pack] EXPORTED -> {os.path.join(ASSET_DIR, 'river_pack.glb')}")

for o in objects:
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    variant_kwargs = dict(
        filepath=os.path.join(ASSET_DIR, f"env_river_{o.name}.glb"),
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
print(f"[river_pack] per-variant GLBs exported -> {ASSET_DIR}")

# =============================================================================
# SHOWCASE RENDER - 5 fichas labeled (z>0), + 2 macros (wet split legibility,
# reed clump read).
# =============================================================================
SPACING = 1.5
GROUND_SIZE, GROUND_ROUGH, GROUND_SCALE = 5.5, 0.08, 0.5
# pass-2d fix: the showcase ground is NOT flat (_ground_common's noise
# undulation, same as every other pack's showcase) - placing every object
# at a flat z=0 while the actual terrain surface dips/rises under its
# specific (x,y) reads as floating/sinking independent of the asset's OWN
# base geometry, and was very likely compounding (or entirely causing) the
# 'floating' read on rock_river_dry_01 in the previous 2 passes. Snap each
# object's placement Z to the REAL local ground height, same pattern
# _ground_common.py documents for mob builds.
for i, obj in enumerate(objects):
    x = (i - (len(objects) - 1) / 2.0) * SPACING
    gz = groundlib.ground_height(x, 0.0, size=GROUND_SIZE, roughness=GROUND_ROUGH, scale=GROUND_SCALE)
    obj.location = (x, 0.0, gz)

ground_mat = bpy.data.materials.new("river_ground_mat")
ground_mat.use_nodes = True
gn = ground_mat.node_tree.nodes["Principled BSDF"]
gn.inputs["Base Color"].default_value = (0.10, 0.11, 0.13, 1.0)
gn.inputs["Roughness"].default_value = 0.55
groundlib.build_ground(scene, size=GROUND_SIZE, subdiv=40, roughness=GROUND_ROUGH, scale=GROUND_SCALE,
                        material=ground_mat, name="river_showcase_ground")

world = bpy.data.worlds.new("ficha")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.38, 0.50, 0.62, 1.0)


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


add_light("key", (-2.0, -5.6, 4.0), 230, 3.0)
add_light("fill", (3.4, -3.8, 2.0), 55, 2.8)
add_light("rim", (0.5, 4.0, 2.6), 150, 2.4)

target = bpy.data.objects.new("target", None)
target.location = (0.0, 0.0, 0.28)
scene.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 42
cam = bpy.data.objects.new("cam", cd)
cam.location = (0.0, -7.6, 2.0)
scene.collection.objects.link(cam)
cam.constraints.new(type='TRACK_TO').target = target
scene.camera = cam

LABELS = {
    "rock_river_wet_01": "wet channel",
    "rock_river_wet_cluster_01": "wet cluster",
    "rock_river_dry_01": "dry bed",
    "reed_clump_01": "reeds",
    "reed_clump_small_01": "reeds small",
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
    txt.data.size = 0.10
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
scene.render.filepath = os.path.join(REN_DIR, "river_showcase.png")
bpy.ops.render.render(write_still=True)
print("[river_pack] RENDERED -> renders/river_showcase.png")


def render_solo_macro(obj_index, cam_offset, out_name, lens=32, target_z=0.28):
    target_obj = objects[obj_index]
    for o in objects:
        o.hide_render = (o is not target_obj)
    for lbl in label_objs:
        lbl.hide_render = True
    # target/cam Z now offset by the object's own ground-snapped location.z
    # (see the GROUND_SIZE/ROUGH/SCALE fix above) so the macro camera aims
    # at the object's REAL resting height, not an assumed flat z=0.
    base_z = target_obj.location.z
    mt = bpy.data.objects.new(f"{out_name}_target", None)
    mt.location = (target_obj.location.x, 0.0, target_z + base_z)
    scene.collection.objects.link(mt)
    cd_ = bpy.data.cameras.new(f"{out_name}_cam")
    cd_.lens = lens
    cam_ = bpy.data.objects.new(f"{out_name}_cam", cd_)
    cam_.location = (target_obj.location.x + cam_offset[0], cam_offset[1], cam_offset[2] + base_z)
    scene.collection.objects.link(cam_)
    cam_.constraints.new(type='TRACK_TO').target = mt
    scene.camera = cam_
    scene.render.filepath = os.path.join(REN_DIR, out_name)
    bpy.ops.render.render(write_still=True)
    print(f"[river_pack] RENDERED -> renders/{out_name}")
    for o in objects:
        o.hide_render = False
    for lbl in label_objs:
        lbl.hide_render = False


# macro of rock_river_wet_01 (index 0) - judge the split's legibility.
# pass-2f fix: debug face-count print showed the wet zone is real (20-62
# wet faces per chunk) but the ORIGINAL camera (elevated, target_z=0.28,
# looking down at the object) mostly sees the UPPER hemisphere - the wet
# band sits by definition near the BASE (waterline_z=0.155), i.e. on the
# lower hemisphere, which faces mostly down/away from an elevated
# look-down camera. Lowered + aimed the camera near the waterline itself
# (target_z=0.13) with a flatter, closer angle so the lower band is
# actually in view instead of grazed at the very edge of frame.
render_solo_macro(0, (-0.42, -0.68, 0.30), "river_showcase_macro_wet.png", target_z=0.13)
# macro of rock_river_wet_cluster_01 (index 1) - judge cohesion (no islands)
# + split legibility across the 4 fused chunks (verification-loop check,
# not in the original brief's minimum deliverable list, added because
# 'clusters sin islas' is an explicit pass/fail criterion).
render_solo_macro(1, (-0.42, -0.68, 0.28), "river_showcase_macro_cluster.png", target_z=0.14)
# macro of rock_river_dry_01 (index 2) - coordinator round-2 request: judge
# the flatten_base seating fix (broad contact, no floating point-balance)
# and the re-aligned warm granite palette.
render_solo_macro(2, (-0.55, -0.95, 0.55), "river_showcase_macro_dry.png", target_z=0.20)
# macro of reed_clump_01 (index 3) - judge vertical read / anchoring / heads.
# pass-1 fix: the bush-style target_z=0.28 + close offset only framed the
# stalks' lower third and cut off the seed heads entirely (reeds run up to
# ~1.2m + a head, nearly 4x a bush's height) - pull back and aim at
# mid-height so the full plant (root -> head) fits in frame.
render_solo_macro(3, (-0.55, -1.55, 0.95), "river_showcase_macro_reed.png", target_z=0.55)

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(SCRIPT_DIR, "river_pack_wip.blend"))
print("[river_pack] DONE")
