"""
build_flower_pack.py - ground-detail WILDFLOWER cluster pack (P1 Pradera).

Reference (MANDATORY, loaded before writing this): foliage_painterly ref_01.png +
_synthesis.md (game/docs/art/_references/foliage_painterly/). The ref shows painted
flower clusters as DENSE VIOLET/PURPLE DOT-MASSES over a green leafy base, wide
gouache value range (dark shadow green -> lime-lit edge), flower color as a
saturated ACCENT DAB layered on top of the mass -- not individual photoreal
petals modeled one by one, not a flat evenly-spaced pattern.

What NOT to repeat (checked game/assets/art/piso1_pradera/vegetation/flowers/,
the 3 existing env_flower_clump_*.gltf, currently excluded from scatter): those
are big single-blossom TEXTURE-CARD cutouts (one photoreal-shaded 5/6-petal
flower baked into a UV atlas, alpha-blend quad). This pack is the opposite
approach on purpose: small CLUMPS built from cheap procedural geometry, colored
entirely via FLOAT_COLOR vertex attributes (no baked texture, no UVs needed) so
the "flower" reads as a dense dab-mass, matching the painterly reference.

Geometry vocabulary (all built directly into a shared bmesh per clump, no
bpy.ops.object.join round-trip -- cheaper and simpler for props this small):
  - leaf blade: bent 2-tri card (same recipe as gen_golem_dressing's
    build_grass_clump), colored dark-shadow -> lime-edge per vertex.
  - blob dab: tiny 4-sided bipyramid (6 verts / 8 tris) = a cheap volumetric
    "poof" with a bright core-color apex fading to a saturated edge-color ring
    -- this is the painterly "dot with a highlight" translated into geometry
    instead of a flat texture blob.
  - star dab: tiny 4-point bipyramid star (10 verts / 16 tris) -- same core/edge
    gradient idea, spiky silhouette for the white/cream variant so it reads
    distinct from the round blob dabs used everywhere else.

Vertex color GOTCHA (see blender-asset-smith skill, 2026-07-20 golem_guardian
entry): BYTE_COLOR corner attributes silently sRGB-decode on readback while
bmesh's loop-color WRITE does not encode -> colors crush toward black. This
script uses bm.loops.layers.float_color.new(...) EXCLUSIVELY, never
.layers.color (BYTE_COLOR).

6 variants (mob_style_contract-style: max 3 colors per prop -- here leaf-base +
flower-edge + flower-core accent):
  1. flower_violet_cluster  - dense violet/purple mass, direct ref_01 match.
  2. flower_yellow_clover   - bright yellow, low/round, close to the ground.
  3. flower_white_star      - white/cream star dabs, taller sparser stems.
  4. flower_bicolor_mix     - violet + yellow dabs woven in one clump.
  5. flower_tall_stalk      - few flowers, TALL thin stalks (grass punctuation).
  6. flower_pale_glow       - pale blue-white, subtle emission (optional
     cave-coherent variant; ecological placement is a SEPARATE follow-up task,
     not resolved here -- this is just the asset).

Run:
  blender.exe --background --python build_flower_pack.py
  blender.exe --background --python build_flower_pack.py -- --seed 7
"""
import bpy
import bmesh
import math
import os
import random
import sys
from mathutils import Vector

SEED = 5
argv = sys.argv
if "--" in argv:
    extra = argv[argv.index("--") + 1:]
    for i, arg in enumerate(extra):
        if arg == "--seed" and i + 1 < len(extra):
            SEED = int(extra[i + 1])
        elif arg.startswith("--seed="):
            SEED = int(arg.split("=", 1)[1])

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = SCRIPT_DIR
REN_DIR = os.path.join(OUT_DIR, "renders")
os.makedirs(REN_DIR, exist_ok=True)

sys.path.insert(0, os.path.dirname(OUT_DIR))
import _ground_common as groundlib  # noqa: E402

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


# =============================================================================
# GEOMETRY HELPERS -- append directly into a shared bmesh + a vert-index -> RGB
# color dict (applied to the FLOAT_COLOR loop layer once at finalize time).
# =============================================================================
def lerp3(a, b, t):
    return [a[i] + (b[i] - a[i]) * t for i in range(3)]


def add_blade(bm, vcol, rng, origin, ang, length, rise, width, col_base, col_tip,
              bend=0.55):
    """Bent 2-tri leaf card (build_grass_clump recipe). origin=(x,y,z)."""
    dx, dy = math.cos(ang), math.sin(ang)
    px, py = -dy, dx
    ox, oy, oz = origin
    b1 = bm.verts.new((ox + px * width, oy + py * width, oz))
    b2 = bm.verts.new((ox - px * width, oy - py * width, oz))
    mid = bm.verts.new((ox + dx * length * bend, oy + dy * length * bend,
                         oz + rise * bend))
    tip = bm.verts.new((ox + dx * length, oy + dy * length, oz + rise))
    bm.faces.new((b1, b2, mid))
    bm.faces.new((b2, tip, mid))
    for v, t in ((b1, 0.0), (b2, 0.0), (mid, 0.55), (tip, 1.0)):
        vcol[v] = lerp3(col_base, col_tip, t)


def add_blob_dab(bm, vcol, rng, center, radius, col_edge, col_core, squash=0.62,
                  sides=4, jitter=0.16):
    """Tiny bipyramid 'poof' dab -- bright core apex, saturated edge ring.
    sides=4 => 6 verts/8 tris (round-clump variants); sides is exposed so the
    star dab below can reuse the same skeleton with more points."""
    cx, cy, cz = center
    top = bm.verts.new((cx, cy, cz + radius * squash))
    bot = bm.verts.new((cx, cy, cz - radius * squash * 0.28))
    ring = []
    for i in range(sides):
        ang = 2.0 * math.pi * i / sides + rng.uniform(-0.18, 0.18)
        r = radius * rng.uniform(1.0 - jitter, 1.0 + jitter)
        rx = cx + math.cos(ang) * r
        ry = cy + math.sin(ang) * r
        rz = cz + radius * 0.12
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
    """Spiky bipyramid star -- alternating long point / short notch ring, so
    the silhouette reads as distinctly pointed vs. the round blob_dab."""
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


def sample_disk(rng, radius, center_bias=0.35):
    """Uniform-ish disk sample biased slightly toward center (sqrt draw
    pulled toward center_bias) -- clump mass denser in the middle, thinning
    at the edge, instead of a hard-edged uniform disk."""
    ang = rng.uniform(0.0, 2.0 * math.pi)
    u = rng.uniform(0.0, 1.0) ** (1.0 / (1.0 + center_bias))
    r = radius * u
    return math.cos(ang) * r, math.sin(ang) * r


def finalize_mesh(name, bm, vcol, double_sided=True):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()
    col_layer = bm.loops.layers.float_color.new("Col")
    for f in bm.faces:
        for loop in f.loops:
            c = vcol.get(loop.vert, (0.5, 0.5, 0.5))
            loop[col_layer] = (c[0], c[1], c[2], 1.0)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.validate(verbose=False)
    # FLAT shading (pass 2 fix, 2026-07-20): smooth shading on the dab
    # bipyramids produced one long glossy specular sweep across each facet --
    # read as a flat plastic "kite" card in close review, the opposite of the
    # reference's brush-dab feel. Flat shading breaks the highlight into
    # discrete facets (same trick the DP_ToonGrounded stone family uses) and
    # reads as a painted chunk of color instead of a glossy chip.
    for p in me.polygons:
        p.use_smooth = False
    obj = bpy.data.objects.new(name, me)
    scene.collection.objects.link(obj)
    return obj


def count_tris(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


# =============================================================================
# MATERIALS -- Attribute("Col") drives Base Color; the color comes entirely
# from per-vertex FLOAT_COLOR data, no texture/UV needed.
# =============================================================================
def make_vcol_material(name, roughness=0.96, double_sided=True):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Roughness"].default_value = roughness
    spec = n.inputs.get("Specular IOR Level")
    if spec is not None:
        spec.default_value = 0.04
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    nt.links.new(attr.outputs["Color"], n.inputs["Base Color"])
    m.use_backface_culling = not double_sided
    return m


def make_vcol_glow_material(name, emission_color, strength=0.45, roughness=0.7,
                             double_sided=True):
    """Base Color still driven per-vertex (Attribute -> COLOR_0, spec-guaranteed
    multiply). Emission is a FIXED uniform color/strength, NOT attribute-linked
    -- glTF's emissiveFactor is one constant per material, it does not get
    multiplied by COLOR_0 the way baseColorFactor does, so an Attribute-driven
    Emission Color renders correctly inside Blender but silently flattens to
    one averaged constant on export (see build_pale_glow docstring)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    n = nt.nodes["Principled BSDF"]
    n.inputs["Roughness"].default_value = roughness
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    nt.links.new(attr.outputs["Color"], n.inputs["Base Color"])
    n.inputs["Emission Color"].default_value = (*emission_color, 1.0)
    n.inputs["Emission Strength"].default_value = strength
    m.use_backface_culling = not double_sided
    return m


# =============================================================================
# PALETTES (linear-ish 0-1 tones, keep under 1.0 -- golem convention)
# =============================================================================
LEAF_DARK = (0.045, 0.115, 0.050)     # shadow inside the mass
LEAF_LIGHT = (0.34, 0.52, 0.16)       # lime-lit edge (ref: "casi amarillo-lima")
LEAF_DARK_COOL = (0.050, 0.095, 0.095)   # pale-glow variant: cooler/desaturated
LEAF_LIGHT_COOL = (0.26, 0.38, 0.32)

VIOLET_EDGE = (0.14, 0.055, 0.26)
VIOLET_CORE = (0.44, 0.28, 0.68)

YELLOW_EDGE = (0.62, 0.48, 0.06)
YELLOW_CORE = (0.97, 0.86, 0.28)

CREAM_EDGE = (0.55, 0.52, 0.42)
CREAM_CORE = (0.97, 0.95, 0.87)

MAGENTA_EDGE = (0.45, 0.10, 0.28)
MAGENTA_CORE = (0.87, 0.40, 0.58)

PALE_EDGE = (0.42, 0.55, 0.62)
PALE_CORE = (0.80, 0.91, 0.98)


# =============================================================================
# CLUMP BUILDERS
# =============================================================================
def build_leaf_mass(bm, vcol, rng, footprint_r, n_tufts, blades_per_tuft,
                     length_range, rise_range, width_range,
                     col_dark=LEAF_DARK, col_light=LEAF_LIGHT,
                     n_canopy=3, canopy_radius_range=(0.045, 0.075),
                     canopy_squash=0.46):
    """Rounded canopy MASS (reuses add_blob_dab as cheap volumetric filler,
    dark-edge -> lime-lit-core gradient -- ref_01's "silueta de nube") plus
    blade cards poking out of it for edge texture. The canopy is what makes
    this read as a leafy clump instead of a bare fan of grass blades; the
    blades alone (2026-07-20 pass 1) looked spiky/sparse, not a painted mass."""
    for _ in range(n_canopy):
        bx, by = sample_disk(rng, footprint_r * 0.7, center_bias=0.2)
        r = rng.uniform(*canopy_radius_range)
        add_blob_dab(bm, vcol, rng, (bx, by, r * canopy_squash * 0.35), r,
                     col_dark, col_light, squash=canopy_squash, sides=6,
                     jitter=0.22)
    for _ in range(n_tufts):
        tx, ty = sample_disk(rng, footprint_r, center_bias=0.25)
        n_here = rng.randint(max(1, blades_per_tuft - 1), blades_per_tuft + 1)
        for _b in range(n_here):
            ang = rng.uniform(0.0, 2.0 * math.pi)
            length = rng.uniform(*length_range)
            rise = rng.uniform(*rise_range)
            width = rng.uniform(*width_range)
            add_blade(bm, vcol, rng, (tx, ty, 0.0), ang, length, rise, width,
                      col_dark, col_light)


def build_dab_scatter(bm, vcol, rng, footprint_r, count, radius_range,
                       height_range, col_edge, col_core, star=False,
                       points=4, height_bias=0.55):
    """Scatter dabs across the footprint, height-biased toward the upper
    portion of the leaf mass (ref: flower dabs sit mostly in the upper/mid
    mass, not evenly through the whole volume down to the ground)."""
    for i in range(count):
        dx, dy = sample_disk(rng, footprint_r, center_bias=0.30)
        t = rng.uniform(0.0, 1.0) ** (1.0 / (1.0 + height_bias))
        z = height_range[0] + (height_range[1] - height_range[0]) * t
        r = rng.uniform(*radius_range)
        if star:
            add_star_dab(bm, vcol, rng, (dx, dy, z), r, col_edge, col_core,
                         points=points)
        else:
            add_blob_dab(bm, vcol, rng, (dx, dy, z), r, col_edge, col_core)


def build_violet_cluster(rng):
    """1. Dense violet/purple mass -- direct match to ref_01.png."""
    bm = bmesh.new()
    vcol = {}
    build_leaf_mass(bm, vcol, rng, footprint_r=0.15, n_tufts=7, blades_per_tuft=3,
                     length_range=(0.09, 0.16), rise_range=(0.10, 0.19),
                     width_range=(0.008, 0.014))
    build_dab_scatter(bm, vcol, rng, footprint_r=0.14, count=32,
                       radius_range=(0.012, 0.021), height_range=(0.06, 0.23),
                       col_edge=VIOLET_EDGE, col_core=VIOLET_CORE)
    return finalize_mesh("flower_violet_cluster", bm, vcol)


def build_yellow_clover(rng):
    """2. Bright yellow, low/round, close to the ground."""
    bm = bmesh.new()
    vcol = {}
    build_leaf_mass(bm, vcol, rng, footprint_r=0.12, n_tufts=6, blades_per_tuft=3,
                     length_range=(0.05, 0.08), rise_range=(0.03, 0.06),
                     width_range=(0.009, 0.015))
    build_dab_scatter(bm, vcol, rng, footprint_r=0.115, count=24,
                       radius_range=(0.011, 0.018), height_range=(0.02, 0.10),
                       col_edge=YELLOW_EDGE, col_core=YELLOW_CORE, height_bias=0.9)
    return finalize_mesh("flower_yellow_clover", bm, vcol)


def build_white_star(rng):
    """3. White/cream star-shaped dabs, taller sparser stems."""
    bm = bmesh.new()
    vcol = {}
    build_leaf_mass(bm, vcol, rng, footprint_r=0.13, n_tufts=5, blades_per_tuft=2,
                     length_range=(0.14, 0.22), rise_range=(0.18, 0.30),
                     width_range=(0.007, 0.011))
    build_dab_scatter(bm, vcol, rng, footprint_r=0.12, count=14,
                       radius_range=(0.016, 0.024), height_range=(0.18, 0.34),
                       col_edge=CREAM_EDGE, col_core=CREAM_CORE, star=True,
                       points=4, height_bias=0.35)
    return finalize_mesh("flower_white_star", bm, vcol)


def build_bicolor_mix(rng):
    """4. Violet + yellow dabs woven together in one clump (wildflower
    meadow patch, not a single-color cluster)."""
    bm = bmesh.new()
    vcol = {}
    build_leaf_mass(bm, vcol, rng, footprint_r=0.14, n_tufts=6, blades_per_tuft=3,
                     length_range=(0.08, 0.14), rise_range=(0.09, 0.16),
                     width_range=(0.008, 0.013))
    build_dab_scatter(bm, vcol, rng, footprint_r=0.13, count=14,
                       radius_range=(0.012, 0.020), height_range=(0.06, 0.20),
                       col_edge=VIOLET_EDGE, col_core=VIOLET_CORE)
    build_dab_scatter(bm, vcol, rng, footprint_r=0.13, count=14,
                       radius_range=(0.011, 0.018), height_range=(0.05, 0.17),
                       col_edge=YELLOW_EDGE, col_core=YELLOW_CORE)
    return finalize_mesh("flower_bicolor_mix", bm, vcol)


def build_tall_stalk(rng):
    """5. Single tall accent stalk -- few flowers, punctuates grass rather
    than carpeting it. A handful of low base leaves + 3 tall thin stems each
    topped with a tiny dab cluster (lupine/foxglove-spike read)."""
    bm = bmesh.new()
    vcol = {}
    build_leaf_mass(bm, vcol, rng, footprint_r=0.07, n_tufts=3, blades_per_tuft=2,
                     length_range=(0.05, 0.08), rise_range=(0.03, 0.06),
                     width_range=(0.008, 0.012))
    n_stems = 3
    for i in range(n_stems):
        sx, sy = sample_disk(rng, 0.05, center_bias=0.1)
        stem_h = rng.uniform(0.34, 0.48)
        ang = rng.uniform(0.0, 2.0 * math.pi)
        lean = 0.02
        # slightly tapered: a wider short base card under the full-height one
        # so the stem doesn't render as a hairline (2026-07-20 pass 1 bug).
        add_blade(bm, vcol, rng, (sx, sy, 0.0), ang, lean * 0.5, stem_h * 0.30,
                   0.020, LEAF_DARK, LEAF_LIGHT, bend=0.9)
        add_blade(bm, vcol, rng, (sx, sy, 0.0), ang, lean, stem_h, 0.013,
                   LEAF_DARK, LEAF_LIGHT, bend=0.85)
        tip = (sx + math.cos(ang) * lean, sy + math.sin(ang) * lean, stem_h)
        for _ in range(3):
            jx = tip[0] + rng.uniform(-0.02, 0.02)
            jy = tip[1] + rng.uniform(-0.02, 0.02)
            jz = tip[2] + rng.uniform(-0.02, 0.03)
            add_blob_dab(bm, vcol, rng, (jx, jy, jz), rng.uniform(0.014, 0.021),
                         MAGENTA_EDGE, MAGENTA_CORE)
    return finalize_mesh("flower_tall_stalk", bm, vcol)


def build_pale_glow(rng):
    """6. Pale blue-white, subtle emission -- optional cave-coherent variant.
    Placement/niche wiring is a SEPARATE follow-up (humidity+shade system),
    NOT decided here; this just ships the asset with its own glow material.

    GOTCHA (2026-07-20): glTF emissiveFactor is ONE constant per MATERIAL --
    it does NOT get multiplied by COLOR_0 the way baseColorFactor does (that
    multiply is spec-guaranteed only for base color). Driving Emission Color
    from the same per-vertex "Col" attribute in Blender renders correctly
    inside Blender but exports as a single flat average color/strength that
    would incorrectly glow the GREEN LEAVES too. Fix: two material slots --
    slot 0 (leaf, no emission) for the canopy+blade faces, slot 1 (glow) for
    the dab faces only, split by face-count boundary at build time."""
    bm = bmesh.new()
    vcol = {}
    build_leaf_mass(bm, vcol, rng, footprint_r=0.14, n_tufts=6, blades_per_tuft=3,
                     length_range=(0.08, 0.15), rise_range=(0.10, 0.18),
                     width_range=(0.008, 0.013),
                     col_dark=LEAF_DARK_COOL, col_light=LEAF_LIGHT_COOL)
    dab_face_start = len(bm.faces)
    build_dab_scatter(bm, vcol, rng, footprint_r=0.13, count=27,
                       radius_range=(0.012, 0.020), height_range=(0.06, 0.22),
                       col_edge=PALE_EDGE, col_core=PALE_CORE)
    obj = finalize_mesh("flower_pale_glow", bm, vcol)
    obj["dab_face_start"] = dab_face_start
    return obj


# =============================================================================
# BUILD ALL VARIANTS
# =============================================================================
BUILDERS = [
    ("flower_violet_cluster", build_violet_cluster, "vcol"),
    ("flower_yellow_clover", build_yellow_clover, "vcol"),
    ("flower_white_star", build_white_star, "vcol"),
    ("flower_bicolor_mix", build_bicolor_mix, "vcol"),
    ("flower_tall_stalk", build_tall_stalk, "vcol"),
    ("flower_pale_glow", build_pale_glow, "glow"),
]

mat_leaf = make_vcol_material("flower_pack_mat")
mat_glow = make_vcol_glow_material("flower_pack_mat_glow",
                                    emission_color=lerp3(PALE_EDGE, PALE_CORE, 0.7),
                                    strength=0.6)

objects = []
print(f"\n[flower_pack] seed={SEED}\n")
for i, (name, fn, mat_kind) in enumerate(BUILDERS):
    rng = random.Random(SEED * 1000 + i * 97)
    obj = fn(rng)
    if mat_kind == "glow":
        obj.data.materials.append(mat_leaf)   # slot 0: canopy + blades, no emission
        obj.data.materials.append(mat_glow)   # slot 1: flower dabs only
        dab_start = obj.get("dab_face_start", 0)
        for pi, p in enumerate(obj.data.polygons):
            p.material_index = 1 if pi >= dab_start else 0
        if "dab_face_start" in obj:
            del obj["dab_face_start"]
    else:
        obj.data.materials.append(mat_leaf)
    objects.append(obj)
    print(f"[flower_pack] built {name}  tris={count_tris(obj)}")

# ---------- export: all 6 objects still at local origin (0,0,0) -- "reset
# transforms before export" is trivially satisfied since arrangement offsets
# are only applied AFTER this export, for the showcase render. ----------
bpy.ops.object.select_all(action='DESELECT')
for o in objects:
    o.select_set(True)
export_kwargs = dict(
    filepath=os.path.join(OUT_DIR, "flower_pack.glb"),
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
print("[flower_pack] EXPORTED -> flower_pack.glb")

# per-variant GLBs, named env_<obj.name>_01 to match the vegetation folder's
# env_<cat>_<name>_01 convention (obj.name is already "flower_<variant>", e.g.
# "flower_pale_glow" -> "env_flower_pale_glow_01.glb"). Mirrors grass_pack's
# per-variant export pattern so individual variants (e.g. the cave-coherent
# pale_glow) can be preloaded on their own without pulling in the other 5.
for o in objects:
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    variant_kwargs = dict(
        filepath=os.path.join(OUT_DIR, f"env_{o.name}_01.glb"),
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
print("[flower_pack] per-variant GLBs exported")

# =============================================================================
# SHOWCASE RENDER -- ficha-style (mob_style_contract §4): flat purple stage,
# 50mm cam, key/fill/rim 110/30/130, Standard view transform. Ground plane
# reused from _ground_common (green-tinted) so the clumps read "planted".
# =============================================================================
SPACING = 0.55
for i, obj in enumerate(objects):
    obj.location = ((i - (len(objects) - 1) / 2.0) * SPACING, 0.0, 0.0)

ground_mat = bpy.data.materials.new("flower_ground_mat")
ground_mat.use_nodes = True
gn = ground_mat.node_tree.nodes["Principled BSDF"]
gn.inputs["Base Color"].default_value = (0.075, 0.11, 0.055, 1.0)
gn.inputs["Roughness"].default_value = 0.95
groundlib.build_ground(scene, size=2.2, subdiv=24, roughness=0.0, scale=0.6,
                        material=ground_mat, name="flower_showcase_ground")

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
    scene.collection.objects.link(lo)
    lo.rotation_mode = 'QUATERNION'
    lo.rotation_quaternion = lo.location.to_track_quat('Z', 'Y')


add_light("key", (-1.2, -3.4, 2.4), 110, 2.2)
add_light("fill", (2.2, -2.6, 1.2), 28, 2.0)
add_light("rim", (0.3, 2.4, 1.6), 95, 1.8)

target = bpy.data.objects.new("target", None)
target.location = (0.0, 0.0, 0.16)
scene.collection.objects.link(target)

cd = bpy.data.cameras.new("cam")
cd.lens = 45
cam = bpy.data.objects.new("cam", cd)
cam.location = (0.0, -5.0, 1.35)
scene.collection.objects.link(cam)
cam.constraints.new(type='TRACK_TO').target = target
scene.camera = cam

# ---------- labels: default-font text, upright, facing the -Y camera ----------
LABELS = {
    "flower_violet_cluster": "violet cluster",
    "flower_yellow_clover": "yellow clover",
    "flower_white_star": "white star",
    "flower_bicolor_mix": "bicolor mix",
    "flower_tall_stalk": "tall stalk",
    "flower_pale_glow": "pale glow",
}
label_mat = bpy.data.materials.new("label_mat")
label_mat.use_nodes = True
lm_n = label_mat.node_tree.nodes["Principled BSDF"]
lm_n.inputs["Base Color"].default_value = (0.97, 0.97, 0.95, 1.0)
lm_n.inputs["Roughness"].default_value = 0.6

# GOTCHA (pass 1, 2026-07-20): labels placed BELOW the ground plane's z=0
# (align_y='TOP' hangs text downward from its origin) were fully occluded --
# a horizontal opaque ground plane blocks any camera ray to a point sitting
# under it, regardless of terrain noise. Fix: origin sits just ABOVE ground
# (z=0.006), align_y='BOTTOM' so the text rises UPWARD from there, and pulled
# forward (more negative Y, toward camera) so it sits in front of the clump
# instead of getting hidden behind its own blades.
for obj in objects:
    bpy.ops.object.text_add(location=(obj.location.x, -0.34, 0.006))
    txt = bpy.context.object
    txt.data.body = LABELS[obj.name]
    txt.data.size = 0.052
    txt.data.align_x = 'CENTER'
    txt.data.align_y = 'BOTTOM'
    txt.data.extrude = 0.003
    txt.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    txt.data.materials.append(label_mat)

try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.eevee.taa_render_samples = 64
scene.view_settings.view_transform = 'Standard'
scene.render.resolution_x = 1600
scene.render.resolution_y = 1000
scene.render.filepath = os.path.join(REN_DIR, "flower_showcase.png")
bpy.ops.render.render(write_still=True)
print("[flower_pack] RENDERED -> renders/flower_showcase.png")

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "flower_pack_wip.blend"))
print("[flower_pack] DONE")
