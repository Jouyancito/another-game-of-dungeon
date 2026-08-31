# build_rock_pack.py — floor-1 prairie ground-scatter ROCK pack (6 variants).
#
# Built FROM game/docs/art/_references/rocks/_synthesis.md (3 granite-boulder
# photos, 2026-07-18): non-uniform per-rock scale, faceted noise-displaced
# surface (not smooth, not spiky), warm grey-tan base with pale-sage lichen +
# dark base moss, rocks embedded (base sunk) in the ground, not floating.
#
# REUSES the noise-displaced-icosphere rock-chunk generator technique from
# game/tools/blender/golem_floating/build_golem.py (make_rock) and the
# FLOAT_COLOR fix + directional moss + cave-carving-for-a-hollow technique
# from game/tools/blender/golem_guardian/build_golem_guardian.py — see the
# per-function docstring below for what was reused vs. added.
#
# Ground-scatter scale (existing 3 rocks in
# game/assets/art/piso1_pradera/props/rocks/ are plain, near-identical ico
# stamps — this pack aims for genuinely distinct silhouette FAMILIES per the
# reference synthesis's #1 finding: "real rock fields are a MIX of silhouette
# families, not one shape repeated at different sizes").
#
# Run: blender --background --python build_rock_pack.py
import bpy
import bmesh
import math
import os
import random
from mathutils import Vector, Matrix
from mathutils import noise as mnoise

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")
os.makedirs(REN_DIR, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

SEED = 20260720

# =============================================================================
# PALETTE — warm grey-tan granite (rocks reference), explicitly NOT the cool
# blue-grey STONE_DARK/STONE_LIGHT golem_guardian uses for its construct body.
# Sampled from the reference synthesis: base body ~(0.52,0.51,0.46), lichen
# ~(0.58,0.60,0.48). Values below are that sample biased for shadow/highlight
# contrast range, kept WARM (R>=G>=B family) throughout.
# =============================================================================
STONE_DARK = (0.20, 0.145, 0.088)     # warm dark brown-grey shadow/crevice
STONE_LIGHT = (0.66, 0.585, 0.445)    # warm light grey-tan highlight
LICHEN_COL = (0.63, 0.67, 0.50)       # pale sage-green lichen patch (upward faces)
LICHEN_COL_RICH = (0.52, 0.64, 0.36)  # saturated moss-green, for the flagship "mossy" variant
BASE_MOSS_COL = (0.15, 0.27, 0.115)   # dark moss where rock meets soil
CAVE_COL = (0.045, 0.040, 0.035)      # near-black warm shadow, hollow interior


def clamp(x, lo=0.0, hi=1.0):
    return max(lo, min(hi, x))


# =============================================================================
# ROCK CHUNK GENERATOR — noise-displaced icosphere, flat-shaded, painterly
# FLOAT_COLOR vertex paint. Core displacement/cave-carving loop is the same
# technique as build_golem.py's make_rock + golem_guardian's cave carving;
# NEW here: warm palette, a two-tier moss system (pale lichen on upward faces
# + dark base-moss banded near ground_z + a touch in deep shaded crevices),
# and flatten_top (for the slab variant).
# =============================================================================
def make_rock(name, center=None, radius=0.5, subdiv=2, seed=0, elongate=(1.0, 1.0, 1.0),
              taper=0.0, flatten_top=0.0, noise_scale=2.6, noise_strength=0.26,
              ridge_weight=0.40, lichen=True, lichen_bias=0.32,
              base_moss=True, moss_band=0.28, ground_z=0.0, crevice_shade=0.35,
              flat=True, dark=STONE_DARK, light=STONE_LIGHT,
              lichen_col=LICHEN_COL, moss_col=BASE_MOSS_COL,
              cave_dir=None, cave_angle=0.55, cave_depth=0.0, cave_color=CAVE_COL, caves=None):
    center = center if center is not None else Vector((0.0, 0.0, 0.0))
    all_caves = list(caves) if caves else []
    if cave_dir is not None and cave_depth > 0.0:
        all_caves.append(dict(dir=cave_dir, angle=cave_angle, depth=cave_depth, color=cave_color))

    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radius)
    seed_v = Vector((seed * 17.13, seed * 5.71, seed * 31.9))
    paint_seed_v = seed_v + Vector((91.0, 47.0, 13.0))

    ridge_val = {}
    for v in bm.verts:
        co = v.co.copy()
        n1 = mnoise.noise(co * noise_scale + seed_v)
        n2 = mnoise.noise(co * noise_scale * 2.4 + seed_v + Vector((5.0, 5.0, 5.0)))
        ridged = 1.0 - abs(n1 * 2.0 - 1.0)  # ridge-ish: crevices between bumps
        ridge_val[v.index] = ridged
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

    if flatten_top > 0.0:
        zs = [v.co.z for v in bm.verts]
        zmin, zmax = min(zs), max(zs)
        h = max(1e-5, zmax - zmin)
        plateau_z = zmin + h * 0.86
        for v in bm.verts:
            t = (v.co.z - zmin) / h
            if t > 0.55:
                w = clamp((t - 0.55) / 0.45 * flatten_top)
                v.co.z = v.co.z + (plateau_z - v.co.z) * w

    for v in bm.verts:
        v.co += center

    def cave_t_single(co, spec):
        rel = co - center
        d = rel.length
        if d < 1e-6:
            return 0.0
        cos_a = clamp(rel.normalized().dot(spec["dir"]), -1.0, 1.0)
        ang = math.acos(cos_a)
        if ang >= spec["angle"]:
            return 0.0
        t = 1.0 - ang / spec["angle"]
        return t * t * (3.0 - 2.0 * t)

    def cave_max(co):
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
                    new_d = max(0.03, d - spec["depth"] * t_s)
                    v.co = center + rel.normalized() * new_d

    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()

    # FLOAT_COLOR, NOT byte_color — BYTE_COLOR corner attributes silently
    # sRGB-decode on readback with no matching encode on bmesh write, crushing
    # hand-authored tones toward black (golem_guardian 2026-07-20 gotcha).
    col_layer = bm.loops.layers.float_color.new("Col")
    bm.verts.ensure_lookup_table()
    vcol = {}
    for v in bm.verts:
        nrm = v.normal
        paint = mnoise.noise(v.co * 3.5 + paint_seed_v)
        crevice = ridge_val.get(v.index, 0.0)
        crev_factor = clamp((crevice - 0.62) / 0.38)  # only genuinely sharp creases count
        t_ao = clamp(0.22 + 0.55 * (nrm.z * 0.5 + 0.5) + 0.32 * paint - crevice_shade * crev_factor)
        base = [dark[i] + (light[i] - dark[i]) * t_ao for i in range(3)]

        if lichen and nrm.z > lichen_bias:
            lt = min(1.0, (nrm.z - lichen_bias) / max(0.001, (1.0 - lichen_bias) * 0.55))
            lt *= 0.65 + 0.35 * paint
            base = [base[i] + (lichen_col[i] - base[i]) * lt * 0.78 for i in range(3)]

        if base_moss:
            h_above = v.co.z - ground_z
            if h_above < moss_band:
                mt = clamp(1.0 - h_above / max(0.001, moss_band))
                mt = (mt ** 2.0) * (0.55 + 0.45 * paint)  # steeper falloff = thin band, not half the rock
                base = [base[i] + (moss_col[i] - base[i]) * mt * 0.85 for i in range(3)]
            crev_mt = (crev_factor ** 2) * 0.18  # shaded-crevice moss, even up higher (subtle accent)
            if crev_mt > 0.0:
                base = [base[i] + (moss_col[i] - base[i]) * crev_mt for i in range(3)]

        ct, cspec = cave_max(v.co)
        if ct > 0.0:
            ccol = cspec["color"]
            base = [base[i] + (ccol[i] - base[i]) * ct for i in range(3)]

        vcol[v.index] = (base[0], base[1], base[2], 1.0)

    for f in bm.faces:
        for loop in f.loops:
            loop[col_layer] = vcol[loop.vert.index]

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


def join_parts(objs, name):
    for o in objs:
        o.location = Vector((0.0, 0.0, 0.0))
    if len(objs) == 1:
        # bpy.ops.object.join() on a single-object selection warns "No mesh
        # data to join" and leaves the object/name untouched — rename directly.
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
    """Data-level mesh shift (NOT object.location) so the object's own pivot
    stays at world origin (Godot ground-placement convention) while a slice
    of its base sits below Z=0 — the reference synthesis's #5 takeaway
    ("sink the rock slightly... reads as embedded, not resting on top")."""
    zs = [v.co.z for v in obj.data.vertices]
    zmin = min(zs)
    shift = -zmin - embed_amount
    obj.data.transform(Matrix.Translation((0.0, 0.0, shift)))
    obj.data.update()


def obj_bbox(obj):
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    return min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)


def make_material(name, roughness=0.85, specular=0.20):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n = m.node_tree.nodes["Principled BSDF"]
    n.inputs["Roughness"].default_value = roughness
    n.inputs["Specular IOR Level"].default_value = specular
    attr = m.node_tree.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    m.node_tree.links.new(attr.outputs["Color"], n.inputs["Base Color"])
    return m


MAT_ROUGH = make_material("rock_pack_rough", roughness=0.88, specular=0.16)
MAT_SMOOTH = make_material("rock_pack_smooth", roughness=0.64, specular=0.34)


# =============================================================================
# VARIANT 1 — small rounded pebble cluster (scatter density filler)
# =============================================================================
def build_pebble_cluster():
    rng = random.Random(SEED + 1)
    specs = [
        (Vector((-0.12, 0.03)), 0.14),
        (Vector((0.10, -0.05)), 0.11),
        (Vector((0.02, 0.14)), 0.09),
        (Vector((0.19, 0.10)), 0.07),
    ]
    chunks = []
    for i, (xy, r) in enumerate(specs):
        elong = (1.0 + rng.uniform(-0.12, 0.15), 1.0 + rng.uniform(-0.12, 0.15),
                 0.72 + rng.uniform(-0.08, 0.10))
        c = make_rock(f"pebble_{i}", center=Vector((xy.x, xy.y, r * elong[2] * 0.60)),
                       radius=r, subdiv=2, seed=100 + i, elongate=elong,
                       noise_scale=3.4, noise_strength=0.15, ridge_weight=0.18,
                       lichen=(i % 3 == 0), lichen_bias=0.50,
                       base_moss=True, moss_band=r * 1.2, ground_z=0.0, crevice_shade=0.15)
        chunks.append(c)
    obj = join_parts(chunks, "prop_rock_scatter_pebbles_01")
    obj.data.materials.append(MAT_SMOOTH)
    embed_into_ground(obj, 0.012)
    return obj


# =============================================================================
# VARIANT 2 — medium weathered boulder, mossy top
# =============================================================================
def build_boulder_mossy():
    main = make_rock("boulder_mossy_main", center=Vector((0.0, 0.0, 0.34)), radius=0.36,
                      subdiv=3, seed=200, elongate=(1.05, 0.95, 1.15), taper=0.22,
                      noise_scale=2.4, noise_strength=0.24, ridge_weight=0.38,
                      lichen=True, lichen_bias=0.18, lichen_col=LICHEN_COL_RICH,
                      base_moss=True, moss_band=0.20, ground_z=0.0, crevice_shade=0.35)
    base_chunk = make_rock("boulder_mossy_base", center=Vector((0.22, -0.12, 0.10)), radius=0.20,
                            subdiv=2, seed=201, elongate=(1.1, 1.0, 0.85), taper=0.15,
                            noise_scale=2.8, noise_strength=0.20, ridge_weight=0.32,
                            lichen=False, base_moss=True, moss_band=0.20, ground_z=0.0)
    obj = join_parts([main, base_chunk], "prop_rock_boulder_mossy_01")
    obj.data.materials.append(MAT_ROUGH)
    embed_into_ground(obj, 0.06)
    return obj


# =============================================================================
# VARIANT 3 — flat wide slab (low profile, sittable/steppable)
# =============================================================================
def build_slab_flat():
    main = make_rock("slab_main", center=Vector((0.0, 0.0, 0.11)), radius=0.55,
                      subdiv=3, seed=300, elongate=(1.0, 0.68, 0.20), taper=0.10,
                      flatten_top=0.75, noise_scale=2.2, noise_strength=0.14,
                      ridge_weight=0.28, lichen=True, lichen_bias=0.48, base_moss=True,
                      moss_band=0.12, ground_z=0.0, crevice_shade=0.25)
    obj = join_parts([main], "prop_rock_slab_flat_01")
    obj.data.materials.append(MAT_ROUGH)
    embed_into_ground(obj, 0.02)
    return obj


# =============================================================================
# VARIANT 4 — jagged broken rock cluster (2-3 angular fragments)
# =============================================================================
def build_broken_cluster():
    a = make_rock("broken_a", center=Vector((-0.17, 0.0, 0.24)), radius=0.26, subdiv=2, seed=400,
                   elongate=(0.95, 0.85, 1.35), taper=-0.22, noise_scale=2.4, noise_strength=0.28,
                   ridge_weight=0.72, lichen=True, lichen_bias=0.52, base_moss=True, moss_band=0.10)
    b = make_rock("broken_b", center=Vector((0.19, 0.08, 0.17)), radius=0.20, subdiv=2, seed=401,
                   elongate=(0.85, 1.0, 1.30), taper=-0.18, noise_scale=2.7, noise_strength=0.30,
                   ridge_weight=0.72, lichen=True, lichen_bias=0.55, base_moss=True, moss_band=0.09)
    c = make_rock("broken_c", center=Vector((0.04, -0.24, 0.11)), radius=0.15, subdiv=2, seed=402,
                   elongate=(1.05, 0.80, 1.15), taper=-0.15, noise_scale=3.0, noise_strength=0.30,
                   ridge_weight=0.72, lichen=False, base_moss=True, moss_band=0.08)
    obj = join_parts([a, b, c], "prop_rock_cluster_broken_01")
    obj.data.materials.append(MAT_ROUGH)
    embed_into_ground(obj, 0.04)
    return obj


# =============================================================================
# VARIANT 5 — large single boulder, deep-embedded "been here forever" read
# =============================================================================
def build_boulder_large():
    main = make_rock("boulder_large_main", center=Vector((0.0, 0.0, 0.62)), radius=0.62,
                      subdiv=3, seed=500, elongate=(1.0, 0.85, 1.35), taper=0.30,
                      noise_scale=2.0, noise_strength=0.17, ridge_weight=0.26,
                      lichen=True, lichen_bias=0.58, base_moss=True, moss_band=0.14,
                      ground_z=0.0, crevice_shade=0.30)
    obj = join_parts([main], "prop_rock_boulder_large_01")
    obj.data.materials.append(MAT_ROUGH)
    embed_into_ground(obj, 0.16)
    return obj


# =============================================================================
# VARIANT 6 — rocky outcrop with a small shadowed hollow/den (mini version of
# golem_guardian's dormant-cave trick: two masses carve concave faces toward
# each other so the negative space between them reads as a shelter gap).
# =============================================================================
def build_outcrop_hollow():
    # Baseline touching distance (sum of radii) is 0.60; centers below are
    # placed at ~0.60 apart (near-touching) and BOTH facing surfaces are
    # carved away from each other (cave_dir points FROM each rock TOWARD the
    # other's center) so the carving opens a genuine physical gap instead of
    # fighting a large pre-existing overlap (2026-07-20 lesson from this
    # build: with less separation the render showed NO visible gap at all —
    # carving alone couldn't out-recede a baseline overlap of 0.15+).
    gap_dir_a = Vector((1.0, 0.0, -0.15)).normalized()
    gap_dir_b = Vector((-1.0, 0.0, -0.15)).normalized()
    a = make_rock("outcrop_a", center=Vector((-0.28, 0.0, 0.30)), radius=0.34, subdiv=3, seed=600,
                   elongate=(1.0, 0.95, 1.15), taper=0.20, noise_scale=2.4, noise_strength=0.19,
                   ridge_weight=0.34, lichen=True, lichen_bias=0.42, base_moss=True, moss_band=0.16,
                   crevice_shade=0.30, cave_dir=gap_dir_a, cave_angle=0.62, cave_depth=0.17,
                   cave_color=CAVE_COL)
    b = make_rock("outcrop_b", center=Vector((0.32, 0.02, 0.24)), radius=0.26, subdiv=3, seed=601,
                   elongate=(1.0, 0.95, 1.05), taper=0.20, noise_scale=2.6, noise_strength=0.19,
                   ridge_weight=0.34, lichen=True, lichen_bias=0.42, base_moss=True, moss_band=0.15,
                   crevice_shade=0.30, cave_dir=gap_dir_b, cave_angle=0.58, cave_depth=0.14,
                   cave_color=CAVE_COL)
    obj = join_parts([a, b], "prop_rock_outcrop_hollow_01")
    obj.data.materials.append(MAT_ROUGH)
    embed_into_ground(obj, 0.05)
    return obj


VARIANTS = [
    ("prop_rock_scatter_pebbles_01", build_pebble_cluster),
    ("prop_rock_boulder_mossy_01", build_boulder_mossy),
    ("prop_rock_slab_flat_01", build_slab_flat),
    ("prop_rock_cluster_broken_01", build_broken_cluster),
    ("prop_rock_boulder_large_01", build_boulder_large),
    ("prop_rock_outcrop_hollow_01", build_outcrop_hollow),
]

built = []
for name, fn in VARIANTS:
    obj = fn()
    built.append((name, obj))
    print(f"[rock_pack] built {name}")

# =============================================================================
# SHOWCASE LAYOUT — lay all 6 out in a row on a ground plane for the render;
# reset to world origin (each variant's own placement pivot) before export.
# =============================================================================
GAP = 0.35
prev_half = 0.0
cursor_x = 0.0
first = True
layout = []
for name, obj in built:
    xmin, xmax, ymin, ymax, zmin, zmax = obj_bbox(obj)
    half_w = max(abs(xmin), abs(xmax), 0.05)
    if first:
        cursor_x = 0.0
        first = False
    else:
        cursor_x += prev_half + GAP + half_w
    obj.location.x = cursor_x
    prev_half = half_w
    layout.append((name, obj, cursor_x, ymin, ymax, zmax))

row_end_x = cursor_x + prev_half


def make_ground(xmin, xmax, ymin, ymax, z=0.0):
    verts = [(xmin, ymin, z), (xmax, ymin, z), (xmax, ymax, z), (xmin, ymax, z)]
    faces = [(0, 1, 2, 3)]
    me = bpy.data.meshes.new("ground")
    me.from_pydata(verts, [], faces)
    me.update()
    obj = bpy.data.objects.new("ground", me)
    bpy.context.collection.objects.link(obj)
    mat = bpy.data.materials.new("ground_mat")
    mat.use_nodes = True
    n = mat.node_tree.nodes["Principled BSDF"]
    n.inputs["Base Color"].default_value = (0.23, 0.21, 0.14, 1.0)
    n.inputs["Roughness"].default_value = 0.95
    obj.data.materials.append(mat)
    return obj


ground = make_ground(-0.35, row_end_x + 0.35, -0.75, 0.70)

# =============================================================================
# WORLD / LIGHTS / CAMERA (warm key + cool fill, per _art_canon D2 Act-1)
# =============================================================================
world = bpy.data.worlds.new("rockpack_world")
scene.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.42, 0.42, 0.44, 1.0)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6

row_center_x = row_end_x / 2.0
target = bpy.data.objects.new("target", None)
target.location = (row_center_x, 0.0, 0.28)
bpy.context.collection.objects.link(target)


def add_light(name, loc, energy, size, target_loc, color=(1.0, 1.0, 1.0)):
    ld = bpy.data.lights.new(name, type='AREA')
    ld.energy = energy
    ld.size = size
    ld.color = color
    lo = bpy.data.objects.new(name, ld)
    lo.location = loc
    bpy.context.collection.objects.link(lo)
    lo.rotation_mode = 'QUATERNION'
    direction = Vector(target_loc) - Vector(loc)
    lo.rotation_quaternion = direction.to_track_quat('-Z', 'Y')
    return lo


key_loc = (row_center_x - 1.4, -3.0, 2.3)
fill_loc = (row_center_x + 2.6, -2.2, 1.1)
rim_loc = (row_center_x + 0.4, 2.6, 2.0)
add_light("key", key_loc, 65, 2.0, target.location, color=(1.0, 0.90, 0.76))   # warm key
add_light("fill", fill_loc, 18, 2.0, target.location, color=(0.78, 0.87, 1.0))  # cool fill
add_light("rim", rim_loc, 50, 1.8, target.location, color=(1.0, 0.95, 0.85))

row_span = max(1.0, row_end_x)
cam_dist = row_span * 0.95 + 1.6
cd = bpy.data.cameras.new("cam")
cd.lens = 38
cam = bpy.data.objects.new("cam", cd)
cam.location = (row_center_x, -cam_dist, cam_dist * 0.42 + 0.5)
bpy.context.collection.objects.link(cam)
cam.constraints.new(type='TRACK_TO').target = target
scene.camera = cam

# =============================================================================
# LABELS — "if easy": FONT curve objects, camera-facing via TRACK_TO.
# =============================================================================
LABELS = {
    "prop_rock_scatter_pebbles_01": "pebbles",
    "prop_rock_boulder_mossy_01": "mossy boulder",
    "prop_rock_slab_flat_01": "slab",
    "prop_rock_cluster_broken_01": "broken cluster",
    "prop_rock_boulder_large_01": "large boulder",
    "prop_rock_outcrop_hollow_01": "outcrop hollow",
}
for name, obj in built:
    curve = bpy.data.curves.new(f"label_{name}", type='FONT')
    curve.body = LABELS.get(name, name)
    curve.size = 0.10
    curve.extrude = 0.004
    curve.align_x = 'CENTER'
    lobj = bpy.data.objects.new(f"label_{name}", curve)
    bpy.context.collection.objects.link(lobj)
    lobj.location = (obj.location.x, -0.62, 0.02)
    lmat = bpy.data.materials.new(f"label_mat_{name}")
    lmat.use_nodes = True
    lb = lmat.node_tree.nodes["Principled BSDF"]
    lb.inputs["Base Color"].default_value = (0.05, 0.05, 0.05, 1.0)
    lb.inputs["Emission Color"].default_value = (0.95, 0.95, 0.90, 1.0)
    lb.inputs["Emission Strength"].default_value = 1.4
    lobj.data.materials.append(lmat)
    con = lobj.constraints.new(type='TRACK_TO')
    con.target = cam
    con.track_axis = 'TRACK_Z'
    con.up_axis = 'UP_Y'

# =============================================================================
# RENDER
# =============================================================================
try:
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
except TypeError:
    scene.render.engine = 'BLENDER_EEVEE'
if hasattr(scene.eevee, "use_raytracing"):
    scene.eevee.use_raytracing = True
scene.eevee.taa_render_samples = 96
scene.view_settings.view_transform = 'Standard'

scene.render.resolution_x = max(1600, int(700 + row_span * 550))
scene.render.resolution_y = 900
scene.render.filepath = os.path.join(REN_DIR, "rock_showcase.png")
bpy.ops.render.render(write_still=True)
print("[rock_pack] showcase rendered")

# =============================================================================
# RESET + EXPORT — pivot each rock back to its own world origin (reset
# transforms before export), select ONLY the 6 rock objects, save .blend,
# export GLB.
# =============================================================================
for name, obj in built:
    obj.location = Vector((0.0, 0.0, 0.0))
    obj.rotation_euler = (0.0, 0.0, 0.0)
    obj.scale = Vector((1.0, 1.0, 1.0))

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "rock_pack_wip.blend"))

bpy.ops.object.select_all(action="DESELECT")
for name, obj in built:
    obj.select_set(True)
bpy.context.view_layer.objects.active = built[0][1]

bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "rock_pack.glb"),
    use_selection=True,
    export_animations=False,
    export_apply=True,
    export_yup=True,
)
print("[rock_pack] combined GLB exported")

# per-variant GLBs — object names already follow the props/rocks folder's
# prop_rock_<name>_01 convention (see VARIANTS above), so the object name
# doubles as the filename. Mirrors grass_pack's per-variant export pattern
# so floor1_prairie.gd's POOL_ROCKS can preload individual scenes.
for name, obj in built:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    fname = f"{name}.glb"
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUT_DIR, fname),
        use_selection=True,
        export_animations=False,
        export_apply=True,
        export_yup=True,
    )
print("[rock_pack] per-variant GLBs exported")
print("[rock_pack] DONE")
