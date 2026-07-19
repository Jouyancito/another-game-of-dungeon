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
# Parts (12 objects, no parenting — every sampler computes WORLD transforms
# directly, staggering per Appendix A of the motion spec to avoid lockstep):
#   torso, head, glow_chest, glow_head, arm_L, arm_R, fist_L, fist_R, tree,
#   stone_1, stone_2, stone_3
#
# Clips (standard 5 + the awaken deliverable):
#   idle-loop (36f)  DORMANT breathing loop — mound rises/falls, tree sways.
#   awaken    (168f) DORMANT -> STANDING, 6 PO-approved beats (see AWAKEN_BEATS).
#   move-loop (48f)  STANDING knuckle-drag gait, 2-beat arm swing.
#   attack    (30f)  STANDING fist-raise-and-slam (placeholder full moveset).
#   hit       (16f)  STANDING flinch — torso recoil + tree shudder.
#   death     (48f)  STANDING -> forward collapse, ends mound-like (Move 8:
#                    NOT a reverse-awaken — a real crumble-forward, poetic
#                    callback to the dormant silhouette).
#
# Run: blender.exe --background --python build_golem_guardian.py
import bpy
import bmesh
import math
import os
from mathutils import Vector, Euler
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
MOSS_COL = (0.32, 0.38, 0.29)        # desaturated moss (not the saturated green of golem_floating)


def make_rock(name, center=None, radius=0.5, subdiv=2, seed=0, elongate=(1.0, 1.0, 1.0),
              taper=0.0, noise_scale=2.6, noise_strength=0.32,
              moss=True, moss_bias=0.24, flat=True,
              dark=STONE_DARK, light=STONE_LIGHT, moss_col=MOSS_COL):
    center = center if center is not None else Vector((0.0, 0.0, 0.0))
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radius)
    seed_v = Vector((seed * 17.13, seed * 5.71, seed * 31.9))
    paint_seed_v = seed_v + Vector((91.0, 47.0, 13.0))
    for v in bm.verts:
        co = v.co.copy()
        n1 = mnoise.noise(co * noise_scale + seed_v)
        n2 = mnoise.noise(co * noise_scale * 2.4 + seed_v + Vector((5.0, 5.0, 5.0)))
        ridged = 1.0 - abs(n1 * 2.0 - 1.0)
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
    for v in bm.verts:
        v.co += center
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()

    col_layer = bm.loops.layers.color.new("Col")
    bm.verts.ensure_lookup_table()
    vcol = {}
    for v in bm.verts:
        nrm = v.normal
        paint = mnoise.noise(v.co * 3.5 + paint_seed_v)
        t_ao = max(0.0, min(1.0, 0.20 + 0.55 * (nrm.z * 0.5 + 0.5) + 0.35 * paint))
        base = [dark[i] + (light[i] - dark[i]) * t_ao for i in range(3)]
        if moss and nrm.z > moss_bias:
            mt = min(1.0, (nrm.z - moss_bias) / (1.0 - moss_bias))
            mt *= 0.55 + 0.45 * paint
            base = [base[i] + (moss_col[i] - base[i]) * mt * 0.80 for i in range(3)]
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
    return obj


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
    attr = m.node_tree.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
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
GLOW_CHEST_MAT, GLOW_CHEST_BSDF = mat_glow("glow_chest_mat")
GLOW_HEAD_MAT, GLOW_HEAD_BSDF = mat_glow("glow_head_mat")
GLOW_BASE_STRENGTH = 2.0

# =============================================================================
# BUILD — STANDING pose is the authored rest shape. Front = -Y (matches
# golem_floating's camera convention: cam sits at negative Y, looks toward
# +Y, so the -Y-facing surface is what the camera/player sees).
# =============================================================================
TORSO_PIVOT = Vector((0.0, 0.0, 1.70))
torso_blobs = [
    make_rock("torso_b0", center=Vector((0.0, 0.05, 0.20)), radius=1.05, subdiv=3, seed=1,
              elongate=(1.05, 0.95, 1.0), taper=0.15),
    make_rock("torso_b1", center=Vector((0.0, -0.22, 1.15)), radius=0.85, subdiv=3, seed=2,
              elongate=(1.05, 0.9, 0.95)),
    make_rock("torso_b2", center=Vector((0.05, 0.40, 1.35)), radius=0.65, subdiv=3, seed=3,
              elongate=(1.0, 1.05, 0.95)),
]
for o in torso_blobs:
    o.data.materials.append(STONE_MAT)
torso = join_parts(torso_blobs, "torso", TORSO_PIVOT)

HEAD_PIVOT = Vector((0.0, -0.20, 3.42))  # forward of the tree's trunk (Y=0.55) so a near-
# front camera reads them as separate silhouette elements, not the head sitting "on" the trunk
head_blobs = [make_rock("head_b0", center=Vector((0.0, 0.0, 0.30)), radius=0.42, subdiv=3, seed=4,
                         elongate=(0.95, 0.95, 1.0), moss=False)]
head_blobs[0].data.materials.append(STONE_MAT)
head = join_parts(head_blobs, "head", HEAD_PIVOT)

GLOW_CHEST_OFFSET = Vector((0.0, -1.02, 1.35))  # torso_b1 front surface, world-space @ STANDING
GLOW_HEAD_OFFSET = HEAD_PIVOT + Vector((0.0, -0.42, 0.30))  # head front, eye band

glow_chest = make_rock("glow_chest", center=Vector((0.0, 0.0, 0.0)), radius=0.20, subdiv=2, seed=0,
                        elongate=(1.0, 0.55, 1.0), noise_strength=0.05, moss=False, flat=False)
glow_chest.data.materials.append(GLOW_CHEST_MAT)
glow_chest.location = GLOW_CHEST_OFFSET.copy()

glow_head = make_rock("glow_head", center=Vector((0.0, 0.0, 0.0)), radius=0.10, subdiv=2, seed=0,
                       elongate=(1.4, 0.45, 0.7), noise_strength=0.04, moss=False, flat=False)
glow_head.data.materials.append(GLOW_HEAD_MAT)
glow_head.location = GLOW_HEAD_OFFSET.copy()


ARM_END_LOCAL = Vector((0.95, -0.50, -1.92))  # unsigned template (side multiplies X)


def make_arm(side):
    """side: -1.0 (left) or +1.0 (right). 5 blobs strung along the shoulder-
    to-wrist path with GENEROUS radius overlap (spacing kept well under the
    sum of consecutive radii) — first pass used 3 widely-spaced blobs whose
    NOMINAL bounding spheres technically touched but read as disconnected
    floating rocks once noise-displacement carved into them (caught via
    render: satellite rocks with visible background gaps, not a limb).
    Tapers thick-shoulder -> thin-wrist, swept outside the torso's own
    silhouette (torso belly reaches X~=1.10 at the shoulder height — must
    clear that or the limb fuses into the torso blob with no read at all).
    Standing rest rotation is (0,0,0) — the "hang down, knuckle on ground"
    shape is baked directly into the blob offsets, per the brief's approach."""
    stops = [(0.06, 0.58), (0.27, 0.52), (0.48, 0.46), (0.69, 0.40), (0.90, 0.34)]
    blobs = []
    for i, (t, r) in enumerate(stops):
        c = Vector((side * ARM_END_LOCAL.x * t, ARM_END_LOCAL.y * t, ARM_END_LOCAL.z * t))
        b = make_rock(f"arm_b{i}_{side}", center=c, radius=r, subdiv=2, seed=10 + side + i,
                       elongate=(1.0, 1.0, 1.08), moss=(i < 2))
        blobs.append(b)
    for o in blobs:
        o.data.materials.append(STONE_MAT)
    return blobs


SHOULDER_L = Vector((-1.38, -0.10, 2.55))
SHOULDER_R = Vector((1.38, -0.10, 2.55))
arm_L = join_parts(list(make_arm(-1.0)), "arm_L", SHOULDER_L)
arm_R = join_parts(list(make_arm(1.0)), "arm_R", SHOULDER_R)


def make_fist(side):
    """Terminal boulder-knuckle — the BIGGEST single mass on the limb (per
    brief: "fist-boulders that rest on the ground"), bigger than the wrist
    blob it attaches to so the arm visibly THICKENS toward its business end."""
    main = make_rock(f"fist_main_{side}", center=Vector((0.0, 0.0, 0.0)), radius=0.62, subdiv=3,
                      seed=20 + side, elongate=(1.12, 1.05, 0.85), moss=False)
    knuckle = make_rock(f"fist_kn_{side}", center=Vector((side * 0.24, -0.10, 0.30)), radius=0.30,
                         subdiv=2, seed=21 + side, moss=False)
    for o in (main, knuckle):
        o.data.materials.append(STONE_MAT)
    return main, knuckle


FIST_L_STANDING = Vector((-2.33, -0.58, 0.55))
FIST_R_STANDING = Vector((2.33, -0.58, 0.55))
fist_L = join_parts(list(make_fist(-1.0)), "fist_L", FIST_L_STANDING)
fist_R = join_parts(list(make_fist(1.0)), "fist_R", FIST_R_STANDING)

# ---- tree: trunk (cone frustum) + 3 foliage blobs, joined ----
TREE_PIVOT = Vector((0.05, 0.55, 3.35))
bpy.ops.mesh.primitive_cone_add(radius1=0.20, radius2=0.11, depth=1.65, vertices=10,
                                 location=(0.0, 0.0, 0.825))
trunk = bpy.context.object
trunk.name = "tree_trunk"
# BAKE the primitive's location into mesh data + zero object.location — join_parts
# below force-sets every blob's object.location to the shared pivot, which would
# otherwise SILENTLY DISCARD trunk's (0,0,0.825) placement (that offset only
# exists as object.location right now, not as mesh-local coordinates like the
# bmesh-built foliage blobs already have via their `center` param). Caught this
# the hard way: first render had the trunk vertically CENTERED on the pivot
# instead of BASED there, leaving foliage floating disconnected far above it.
bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
trunk.data.materials.append(BARK_MAT)
foliage_a = make_foliage_blob("foliage_a", center=Vector((0.0, 0.05, 2.00)), radius=0.58, seed=1)
foliage_b = make_foliage_blob("foliage_b", center=Vector((-0.36, 0.10, 1.80)), radius=0.42, seed=2)
foliage_c = make_foliage_blob("foliage_c", center=Vector((0.33, 0.02, 1.86)), radius=0.40, seed=3)
for o in (foliage_a, foliage_b, foliage_c):
    o.data.materials.append(FOLIAGE_MAT)
tree = join_parts([trunk, foliage_a, foliage_b, foliage_c], "tree", TREE_PIVOT)

# ---- moss stones (2-3 small stones around the base, per brief) ----
STONE_STANDING = {
    "stone_1": Vector((1.55, 0.85, 0.27)),
    "stone_2": Vector((-1.25, 1.05, 0.24)),
    "stone_3": Vector((0.30, -1.55, 0.31)),
}
stone_objs = {}
for i, (nm, pos) in enumerate(STONE_STANDING.items()):
    r = [0.30, 0.26, 0.34][i]
    blob = make_rock(nm, center=Vector((0, 0, 0)), radius=r, subdiv=2, seed=30 + i,
                      moss=True, moss_bias=0.05)
    blob.data.materials.append(STONE_MAT)
    blob.location = pos
    stone_objs[nm] = blob

PARTS = {
    "torso": torso, "head": head, "arm_L": arm_L, "arm_R": arm_R,
    "fist_L": fist_L, "fist_R": fist_R, "tree": tree,
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
    "torso": dict(loc=TORSO_PIVOT.copy(), rot=Vector((math.radians(7), 0, 0)), scale=Vector((1, 1, 1))),
    "head": dict(loc=HEAD_PIVOT.copy(), rot=Vector((math.radians(5), 0, 0)), scale=Vector((1, 1, 1))),
    "arm_L": dict(loc=SHOULDER_L.copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "arm_R": dict(loc=SHOULDER_R.copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "fist_L": dict(loc=FIST_L_STANDING.copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "fist_R": dict(loc=FIST_R_STANDING.copy(), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
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
    "arm_L": dict(loc=Vector((-0.50, 0.20, 1.00)), rot=Vector((math.radians(-65), 0, math.radians(-30))), scale=Vector((0.42, 0.42, 0.42))),
    "arm_R": dict(loc=Vector((0.50, 0.20, 1.00)), rot=Vector((math.radians(-65), 0, math.radians(30))), scale=Vector((0.42, 0.42, 0.42))),
    "fist_L": dict(loc=Vector((-0.62, 0.12, 0.40)), rot=Vector((0, 0, 0)), scale=Vector((0.62, 0.62, 0.62))),
    "fist_R": dict(loc=Vector((0.62, 0.12, 0.40)), rot=Vector((0, 0, 0)), scale=Vector((0.62, 0.62, 0.62))),
    "tree": dict(loc=Vector((0.05, 0.35, 2.00)), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "stone_1": dict(loc=Vector((1.10, 0.60, 0.27)), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "stone_2": dict(loc=Vector((-0.90, 0.75, 0.24)), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
    "stone_3": dict(loc=Vector((0.15, -0.80, 0.31)), rot=Vector((0, 0, 0)), scale=Vector((1, 1, 1))),
}

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


def sample_idle(f, frames=36):
    """DORMANT breathing loop — mound rises/falls ~2%, tree sways gently."""
    t = (f - 1) / frames
    phase = t * 2 * math.pi
    out = {k: (v["loc"].copy(), v["rot"].copy(), v["scale"].copy()) for k, v in DORMANT.items()}
    breath = 0.020 * math.sin(phase)  # ~2% of mound height (~2.1m -> ~0.04m peak-peak)
    torso_loc, torso_rot, torso_scale = out["torso"]
    out["torso"] = (torso_loc + Vector((0, 0, breath * 2.0)), torso_rot, torso_scale)
    head_loc, head_rot, head_scale = out["head"]
    out["head"] = (head_loc + Vector((0, 0, breath * 1.6)), head_rot, head_scale)
    tree_loc, tree_rot, tree_scale = out["tree"]
    sway = math.radians(3.0) * math.sin(phase * 0.85 + 0.4)
    out["tree"] = (tree_loc + Vector((0, 0, breath * 1.6)), tree_rot + Vector((sway, 0, sway * 0.4)), tree_scale)
    return out, dict(chest=0.0, head=0.0)


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


def tree_tilt_deg(f):
    """Tree sways with the emergence + rise, overshoots on the settle-back."""
    if f <= 31:
        return 0.0
    if f <= 67:
        u = (f - 31) / (67 - 31)
        return 20.0 * ease_in_cubic(u)
    if f <= 115:
        u = (f - 67) / (115 - 67)
        return lerp(20.0, 27.0, smoothstep(u))
    if f <= 144:
        u = (f - 115) / (144 - 115)
        # swings back through 0 with an overshoot (~8% of peak) then rests
        overshoot = -27.0 * 0.08
        if u < 0.65:
            return lerp(27.0, overshoot, ease_out_cubic(u / 0.65))
        return lerp(overshoot, 0.0, ease_out_cubic((u - 0.65) / 0.35))
    return 0.0


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


def glow_head_strength(f):
    if f < 124:
        return 0.0
    u = clamp01((f - 124) / (142 - 124))
    return lerp(0.0, GLOW_BASE_STRENGTH, ease_out_cubic(u))


def head_look_rot(f, entering_rot):
    """Beat 6 (144-168f): head settles/turns toward camera and holds."""
    if f < 144:
        return entering_rot
    u = clamp01((f - 144) / (166 - 144))
    final_rx = math.radians(9)
    rx = lerp(entering_rot.x, final_rx, ease_out_cubic(u))
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

    # head — delayed a few frames behind torso, then looks at camera (beat 6)
    hu = rise_progress(max(0, f - 4))
    h_loc = lerp_v(DORMANT["head"]["loc"], STANDING["head"]["loc"], hu)
    h_rot = lerp_v(DORMANT["head"]["rot"], STANDING["head"]["rot"], hu)
    h_rot = head_look_rot(f, h_rot)
    h_scale = lerp_v(DORMANT["head"]["scale"], STANDING["head"]["scale"], hu)
    out["head"] = (h_loc + Vector((0, 0, trem * 0.6)), h_rot, h_scale)

    # arms — delayed further (shoulders emerge in beat 3), separate outward
    # slightly extra at the peak of beat 3 (frame ~55) for a clear "the hump
    # splits" silhouette beat before folding into the smooth rise.
    au = rise_progress(max(0, f - 7))
    a_pop = 0.14 * math.exp(-((f - 55) ** 2) / (2 * 9.0 ** 2)) if 40 <= f <= 70 else 0.0
    for side, arm_name, fist_name, sign in (("L", "arm_L", "fist_L", -1.0), ("R", "arm_R", "fist_R", 1.0)):
        a_loc = lerp_v(DORMANT[arm_name]["loc"], STANDING[arm_name]["loc"], au)
        a_loc = a_loc + Vector((sign * a_pop, 0, 0))
        a_rot = lerp_v(DORMANT[arm_name]["rot"], STANDING[arm_name]["rot"], au)
        a_scale = lerp_v(DORMANT[arm_name]["scale"], STANDING[arm_name]["scale"], au)
        out[arm_name] = (a_loc, a_rot, a_scale)
        fu = rise_progress(max(0, f - 11))
        f_loc = lerp_v(DORMANT[fist_name]["loc"], STANDING[fist_name]["loc"], fu)
        f_scale = lerp_v(DORMANT[fist_name]["scale"], STANDING[fist_name]["scale"], fu)
        out[fist_name] = (f_loc, Vector((0, 0, 0)), f_scale)

    # tree — base tracks torso's rise, plus its own tilt/overshoot sway
    tree_u = rise_progress(max(0, f - 3))
    tr_loc = lerp_v(DORMANT["tree"]["loc"], STANDING["tree"]["loc"], tree_u)
    tilt = math.radians(tree_tilt_deg(f))
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
def sample_move(f, frames=48):
    t = (f - 1) / frames
    phase = t * 2 * math.pi
    swing = math.radians(38) * math.sin(phase)  # boosted from 22 deg — too subtle vs the
    # multi-blob arm's own bulk to read at showcase-camera distance (render-verified)
    out = {}
    bob = -0.16 * abs(math.sin(phase))
    out["torso"] = (STANDING["torso"]["loc"] + Vector((0, 0, bob)),
                     STANDING["torso"]["rot"] + Vector((0, 0, math.radians(3.5) * math.sin(phase))),
                     Vector((1, 1, 1)))
    out["head"] = (STANDING["head"]["loc"] + Vector((0, 0, bob * 0.6)), STANDING["head"]["rot"], Vector((1, 1, 1)))
    rotL, fistL = arm_end("L", swing)
    rotR, fistR = arm_end("R", -swing)
    out["arm_L"] = (SHOULDER_L, rotL, Vector((1, 1, 1)))
    out["arm_R"] = (SHOULDER_R, rotR, Vector((1, 1, 1)))
    out["fist_L"] = (fistL, Vector((0, 0, 0)), Vector((1, 1, 1)))
    out["fist_R"] = (fistR, Vector((0, 0, 0)), Vector((1, 1, 1)))
    out["tree"] = (STANDING["tree"]["loc"], Vector((math.radians(4) * math.sin(phase), 0, 0)), Vector((1, 1, 1)))
    for s in ("stone_1", "stone_2", "stone_3"):
        out[s] = (STANDING[s]["loc"], Vector((0, 0, 0)), Vector((1, 1, 1)))
    return out, dict(chest=GLOW_BASE_STRENGTH, head=GLOW_BASE_STRENGTH)


# ---- ATTACK (30f) — raise both fists overhead, slam down, hold ----
def sample_attack(f, frames=30):
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
    out = {}
    out["torso"] = (STANDING["torso"]["loc"] + Vector((0, 0, tz)), STANDING["torso"]["rot"], Vector((1, 1, 1)))
    out["head"] = (STANDING["head"]["loc"] + Vector((0, 0, tz * 0.6)), STANDING["head"]["rot"], Vector((1, 1, 1)))
    rotL, fistL = arm_end("L", rx)
    rotR, fistR = arm_end("R", rx)
    out["arm_L"] = (SHOULDER_L, rotL, Vector((1, 1, 1)))
    out["arm_R"] = (SHOULDER_R, rotR, Vector((1, 1, 1)))
    out["fist_L"] = (fistL, Vector((0, 0, 0)), Vector((1, 1, 1)))
    out["fist_R"] = (fistR, Vector((0, 0, 0)), Vector((1, 1, 1)))
    out["tree"] = (STANDING["tree"]["loc"], Vector((rx * 0.35, 0, 0)), Vector((1, 1, 1)))
    for s in ("stone_1", "stone_2", "stone_3"):
        out[s] = (STANDING[s]["loc"], Vector((0, 0, 0)), Vector((1, 1, 1)))
    return out, dict(chest=GLOW_BASE_STRENGTH, head=GLOW_BASE_STRENGTH)


# ---- HIT (16f) — flinch: torso recoils, tree shudders ----
def sample_hit(f, frames=16):
    t = (f - 1) / (frames - 1)
    env = math.sin(math.pi * min(1.0, t * 1.5))
    out = {}
    out["torso"] = (STANDING["torso"]["loc"] + Vector((0, 0.22 * env, -0.16 * env)),
                     STANDING["torso"]["rot"] + Vector((-math.radians(11) * env, 0, 0)), Vector((1, 1, 1)))
    out["head"] = (STANDING["head"]["loc"] + Vector((0, 0.14 * env, -0.07 * env)), STANDING["head"]["rot"], Vector((1, 1, 1)))
    rx = -math.radians(26) * env
    rotL, fistL = arm_end("L", rx)
    rotR, fistR = arm_end("R", rx)
    out["arm_L"] = (SHOULDER_L, rotL, Vector((1, 1, 1)))
    out["arm_R"] = (SHOULDER_R, rotR, Vector((1, 1, 1)))
    out["fist_L"] = (fistL, Vector((0, 0, 0)), Vector((1, 1, 1)))
    out["fist_R"] = (fistR, Vector((0, 0, 0)), Vector((1, 1, 1)))
    shudder = math.radians(9) * math.sin(2 * math.pi * 4.0 * t) * (1.0 - t)
    out["tree"] = (STANDING["tree"]["loc"], Vector((shudder, 0, shudder * 0.5)), Vector((1, 1, 1)))
    for s in ("stone_1", "stone_2", "stone_3"):
        out[s] = (STANDING[s]["loc"], Vector((0, 0, 0)), Vector((1, 1, 1)))
    return out, dict(chest=GLOW_BASE_STRENGTH, head=GLOW_BASE_STRENGTH)


# ---- DEATH (48f) — forward collapse, ends mound-like (Move 8, NOT reverse-awaken) ----
def sample_death(f, frames=48):
    t = (f - 1) / (frames - 1)
    out = {}
    if t < 0.12:  # recognition delay
        lean = 0.0
        drop_u = 0.0
    elif t < 0.40:  # the lean — slow start (tree_fall Stage-A)
        u = (t - 0.12) / 0.28
        lean = 60.0 * ease_in_cubic(u)
        drop_u = 0.0
    elif t < 0.63:  # the fall — accelerating
        u = (t - 0.40) / 0.23
        lean = lerp(60.0, 92.0, ease_in_expo(u))
        drop_u = ease_in_expo(u)
    elif t < 0.71:  # impact hold
        lean = 92.0
        drop_u = 1.0
    else:  # settle
        u = (t - 0.71) / 0.29
        wob = 4.0 * (1.0 - u) * math.sin(2 * math.pi * 2.5 * u)
        lean = 92.0 + wob
        drop_u = 1.0

    torso_rot = math.radians(lean)
    torso_loc = lerp_v(STANDING["torso"]["loc"], DORMANT["torso"]["loc"] + Vector((0, -0.15, 0)), drop_u)
    out["torso"] = (torso_loc, Vector((torso_rot, 0, 0)), Vector((1, 1, 1)))
    head_loc = lerp_v(STANDING["head"]["loc"], DORMANT["head"]["loc"] + Vector((0, -0.20, 0)), drop_u)
    out["head"] = (head_loc, Vector((torso_rot * 0.9, 0, 0)), Vector((1, 1, 1)))

    fly = lerp(0.0, 55.0, drop_u)
    for side, arm_name, fist_name, sign in (("L", "arm_L", "fist_L", -1.0), ("R", "arm_R", "fist_R", 1.0)):
        rx = math.radians(-fly)
        rz = math.radians(sign * fly * 0.4)
        rot, fistpos = arm_end(side, rx, 0.0, rz)
        a_loc = lerp_v(STANDING[arm_name]["loc"], DORMANT[arm_name]["loc"], drop_u * 0.5)
        out[arm_name] = (a_loc, rot, Vector((1, 1, 1)))
        f_loc = fistpos + (torso_loc - STANDING["torso"]["loc"])
        out[fist_name] = (f_loc, Vector((0, 0, 0)), Vector((1, 1, 1)))

    out["tree"] = (lerp_v(STANDING["tree"]["loc"], DORMANT["tree"]["loc"] + Vector((0, -0.3, -0.3)), drop_u),
                    Vector((torso_rot * 0.8, 0, 0)), Vector((1, 1, 1)))

    for nm in ("stone_1", "stone_2", "stone_3"):
        p, r = tumble(f, 10, 42, STANDING[nm]["loc"], STANDING[nm]["loc"] + (STANDING[nm]["loc"].normalized() * 0.9 if STANDING[nm]["loc"].length > 0 else Vector((0.5, 0, 0))),
                      bounce_h=0.12)
        out[nm] = (p, r, Vector((1, 1, 1)))

    chest = lerp(GLOW_BASE_STRENGTH, 0.0, clamp01((t - 0.63) / 0.25))
    head_g = lerp(GLOW_BASE_STRENGTH, 0.0, clamp01((t - 0.63) / 0.25))
    return out, dict(chest=chest, head=head_g)


CLIPS = {
    "idle-loop": (36, sample_idle, 2),
    "awaken": (AWAKEN_FRAMES, sample_awaken, 3),
    "move-loop": (48, sample_move, 2),
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

TARGET_Z = 2.75
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

for name in PARTS:
    anim_data[name].action = None
glow_chest_ad.action = None
glow_head_ad.action = None
glow_chest_mat_ad.action = None
glow_head_mat_ad.action = None
reset_to_standing()

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

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "golem_guardian_wip.blend"))
bpy.ops.export_scene.gltf(
    filepath=os.path.join(OUT_DIR, "golem_guardian.glb"),
    use_selection=False,
    export_animations=True,
    export_morph=False,
    export_animation_mode='NLA_TRACKS',
)
print("[golem_guardian] DONE")
