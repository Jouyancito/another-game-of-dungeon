"""
gen_golem_dressing.py - bespoke "of the golem" dressing pieces (P1 Pradera).

Generates the small props the golem wears/sheds, in a cohesive low-poly toon
style (Ghibli / Frieren palette ref from Joan 2026-06-10: soft pastel greens +
pink/white flowers with yellow centers) so they read as belonging to THIS
creature, not as map assets slapped on top.

Exports (all into game/assets/art/piso1_pradera/enemies/big/):
  golem_rock_chip_01.glb    - weathered stone chip (golem fragment). Godot floats 3x.
  golem_moss_patch_01.glb   - soft green moss mound that hugs the stone.
  golem_flower_pink_01.glb   - small 5-lobe pink flower + yellow center.
  golem_flower_white_01.glb  - small white daisy + yellow center.

Style: chamfered/jittered flat-shaded for stone (gen_golem make_rock_block
vocabulary); flat scalloped discs for flowers; low flat-shaded mound for moss.
Colors are BAKED via a Principled BSDF base color so they survive the GLB export
(no Godot material_override needed for the dressing).

AXIS: build Z-up (Blender native); export_yup=True maps Blender-Z -> glTF-Y.

Usage:
  blender.exe --background --python gen_golem_dressing.py
  blender.exe --background --python gen_golem_dressing.py -- --seed 42
"""

import bpy
import bmesh
import math
import random
import sys
import os
from mathutils import Vector, Euler

SEED = 7
argv = sys.argv
if "--" in argv:
    extra = argv[argv.index("--") + 1:]
    for i, arg in enumerate(extra):
        if arg == "--seed" and i + 1 < len(extra):
            SEED = int(extra[i + 1])
        elif arg.startswith("--seed="):
            SEED = int(arg.split("=", 1)[1])

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "..", "assets", "art", "piso1_pradera", "enemies", "big")
)
os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- Palette (Frieren/Ghibli pastel, from Joan's moodboard) ---
STONE_RGBA = (0.42, 0.40, 0.36, 1.0)   # matches golem body golem_stone slot
MOSS_RGBA = (0.34, 0.53, 0.27, 1.0)    # saturated soft green (warm key was washing it yellow)
PINK_RGBA = (0.88, 0.45, 0.63, 1.0)    # saturated soft pink (was washing to white)
WHITE_RGBA = (0.95, 0.95, 0.92, 1.0)   # warm white petal
YELLOW_RGBA = (0.97, 0.83, 0.32, 1.0)  # flower center


def make_material(name, rgba):
    """Node-based material with a baked base color (exports into the GLB)."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = rgba
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = 0.9
    mat.diffuse_color = rgba
    return mat


def make_rock_block(name, location, size, rotation=(0.0, 0.0, 0.0),
                    bevel=0.06, jitter=0.06, block_seed=0, detail=0,
                    displace=0.10, rot_jitter_deg=5.0):
    """Chamfered, jittered, flat-shaded rocky box - gen_golem family signature."""
    lrng = random.Random(SEED * 131 + block_seed)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    sx, sy, sz = size
    for v in bm.verts:
        v.co.x *= sx
        v.co.y *= sy
        v.co.z *= sz
    min_dim = max(0.001, min(sx, sy, sz))
    bevel_off = min(bevel, min_dim * 0.45)
    bmesh.ops.bevel(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
                    offset=bevel_off, offset_type="OFFSET", segments=1,
                    profile=0.5, affect="EDGES", clamp_overlap=True)
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
    obj.rotation_euler = Euler((rotation[0] + lrng.uniform(-rj, rj),
                                rotation[1] + lrng.uniform(-rj, rj),
                                rotation[2] + lrng.uniform(-rj, rj)), "XYZ")
    return obj


def _new_obj(name, bm):
    mesh = bpy.data.meshes.new(name + "_mesh")
    bm.to_mesh(mesh)
    bm.free()
    mesh.validate(verbose=False)
    return bpy.data.objects.new(name, mesh)


def build_rock_chip():
    return make_rock_block("golem_rock_chip", (0, 0, 0), (0.62, 0.50, 0.44),
                           bevel=0.07, jitter=0.14, block_seed=1, detail=1,
                           displace=0.14, rot_jitter_deg=0.0)


def build_moss_patch():
    """Low, soft mound that hugs the stone - subdivided flat box, jittered, green."""
    mrng = random.Random(SEED * 977 + 5)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co.x *= 0.80
        v.co.y *= 0.80
        v.co.z *= 0.12   # very flat = a moss carpet that clings, not a blob
    bmesh.ops.bevel(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
                    offset=0.08, offset_type="OFFSET", segments=1, profile=0.5,
                    affect="EDGES", clamp_overlap=True)
    for _ in range(2):
        bmesh.ops.subdivide_edges(bm, edges=list(bm.edges), cuts=1, use_grid_fill=True)
    # Dome the top into a soft cushion; gentle lumps only (no spiky lichen look).
    for v in bm.verts:
        if v.co.z > 0:
            v.co.z += (0.55 - (v.co.x * v.co.x + v.co.y * v.co.y)) * 0.14
        v.co.x += mrng.uniform(-0.022, 0.022)
        v.co.y += mrng.uniform(-0.022, 0.022)
        v.co.z += mrng.uniform(-0.014, 0.014)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _new_obj("golem_moss_patch", bm)


def build_moss_tuft():
    """Shape VARIANT of the moss: a rounder, lumpier low cushion (icosphere base)
    instead of the flat carpet, so the dressing isn't one repeated stamp."""
    mrng = random.Random(SEED * 977 + 19)
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.40)
    for v in bm.verts:
        v.co.z *= 0.55                      # squash into a cushion
        v.co.x += mrng.uniform(-0.05, 0.05)
        v.co.y += mrng.uniform(-0.05, 0.05)
        v.co.z += mrng.uniform(-0.04, 0.04)
        if v.co.z < 0:
            v.co.z *= 0.35                  # flatten the underside so it sits on rock
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _new_obj("golem_moss_tuft", bm)


def build_grass_clump(seed=11):
    """Low CLINGING grass: a fan of thin blades that hug the stone (lean OUT low,
    not up like a bush). Joan: 'pasto pegado a la piedra, no arbustos'."""
    grng = random.Random(SEED * 61 + seed)
    bm = bmesh.new()
    for _i in range(20):
        ang = grng.uniform(0.0, 2.0 * math.pi)
        ln = grng.uniform(0.22, 0.42)        # blade length (spreads out)
        rise = grng.uniform(0.06, 0.16)      # low rise = clings/hugs the rock
        w = grng.uniform(0.020, 0.034)       # blade width at base
        dx, dy = math.cos(ang), math.sin(ang)
        px, py = -dy, dx                     # perpendicular = blade width dir
        b1 = bm.verts.new((px * w, py * w, 0.0))
        b2 = bm.verts.new((-px * w, -py * w, 0.0))
        # gentle arc: a mid bend so the blade droops back toward the stone
        mid = bm.verts.new((dx * ln * 0.6, dy * ln * 0.6, rise))
        tip = bm.verts.new((dx * ln, dy * ln, rise * 0.55))
        bm.faces.new((b1, b2, mid))
        bm.faces.new((b2, tip, mid))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _new_obj("golem_grass_clump", bm)


def build_flower(name, seed):
    """5 distinct petals (rounded quads) tilted up into a shallow cup + a small
    raised disc center. Reads as a real bloom, not a flat scalloped disc. 2 slots."""
    frng = random.Random(SEED * 53 + seed)
    bm = bmesh.new()
    tilt = math.radians(24.0)
    for k in range(5):
        ang = k * (2.0 * math.pi / 5.0) + frng.uniform(-0.05, 0.05)
        pbm = bmesh.new()
        bmesh.ops.create_cube(pbm, size=1.0)
        for v in pbm.verts:
            v.co.x *= 0.090   # petal width
            v.co.y *= 0.20    # petal length (radial)
            v.co.z *= 0.022   # thin
            v.co.y += 0.17    # push the petal out from the center
        bmesh.ops.bevel(pbm, geom=list(pbm.verts) + list(pbm.edges) + list(pbm.faces),
                        offset=0.035, offset_type="OFFSET", segments=1, profile=0.7,
                        affect="EDGES", clamp_overlap=True)
        for v in pbm.verts:
            # tilt the petal up around X (raise the outer tip into a cup)
            y, z = v.co.y, v.co.z
            v.co.y = y * math.cos(tilt) - z * math.sin(tilt)
            v.co.z = y * math.sin(tilt) + z * math.cos(tilt)
            # rotate the petal around Z into its slot
            x, yy = v.co.x, v.co.y
            v.co.x = x * math.cos(ang) - yy * math.sin(ang)
            v.co.y = x * math.sin(ang) + yy * math.cos(ang)
        bmesh.ops.recalc_face_normals(pbm, faces=pbm.faces)
        tmp = bpy.data.meshes.new("petal_tmp")
        pbm.to_mesh(tmp)
        pbm.free()
        bm.from_mesh(tmp)
        bpy.data.meshes.remove(tmp)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    petals = _new_obj(name + "_petals", bm)

    # Center: small flat disc (octagon cylinder), raised just above the petals.
    cb = bmesh.new()
    bmesh.ops.create_cone(cb, cap_ends=True, cap_tris=False, segments=8,
                          radius1=0.075, radius2=0.075, depth=0.05)
    for v in cb.verts:
        v.co.z += 0.05
    bmesh.ops.recalc_face_normals(cb, faces=cb.faces)
    center = _new_obj(name + "_center", cb)
    return petals, center


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for coll in (bpy.data.meshes, bpy.data.materials):
        for block in list(coll):
            if block.users == 0:
                coll.remove(block)


def finalize_flat_centered(obj):
    me = obj.data
    for poly in me.polygons:
        poly.use_smooth = False
    me.validate(verbose=False)
    n = len(me.vertices)
    cx = sum(v.co.x for v in me.vertices) / n
    cy = sum(v.co.y for v in me.vertices) / n
    for v in me.vertices:
        v.co.x -= cx
        v.co.y -= cy


def join_two(a, b, final_name):
    for o in (a, b):
        bpy.context.collection.objects.link(o)
    bpy.ops.object.select_all(action="DESELECT")
    a.select_set(True)
    b.select_set(True)
    bpy.context.view_layer.objects.active = a
    bpy.ops.object.join()
    a.name = final_name
    return a


def count_tris(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def export_glb(filepath):
    kwargs = dict(filepath=filepath, export_format="GLB", export_apply=True,
                  export_materials="EXPORT", export_normals=True,
                  export_tangents=False, export_texcoords=False,
                  export_cameras=False, export_lights=False)
    try:
        bpy.ops.export_scene.gltf(**kwargs, export_yup=True)
    except TypeError:
        bpy.ops.export_scene.gltf(**kwargs)


def export_single(obj, filename):
    bpy.context.view_layer.objects.active = obj
    finalize_flat_centered(obj)
    out = os.path.join(OUTPUT_DIR, filename)
    export_glb(out)
    print(f"[gen_dressing] EXPORTED -> {filename}  tris={count_tris(obj)}")


def _box(name, loc, size, rot=(0.0, 0.0, 0.0)):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    sx, sy, sz = size
    for v in bm.verts:
        v.co.x *= sx
        v.co.y *= sy
        v.co.z *= sz
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = _new_obj(name, bm)
    o.location = Vector(loc)
    o.rotation_euler = Euler(rot, "XYZ")
    return o


def _join_all(objs, name):
    for o in objs:
        try:
            bpy.context.collection.objects.link(o)
        except RuntimeError:
            pass
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    objs[0].name = name
    return objs[0]


def build_branch_nest():
    """A gnarled branch with leaves + a twig nest with eggs growing out of the
    golem — 'nature made a home on it' (Joan). Multi-material, joined. Z-up."""
    parts = []
    wood = make_material("branch_wood", (0.34, 0.24, 0.15, 1.0))
    leaf = make_material("branch_leaf", (0.37, 0.53, 0.27, 1.0))
    twig = make_material("nest_twig", (0.29, 0.20, 0.12, 1.0))
    egg = make_material("egg_pale", (0.87, 0.88, 0.80, 1.0))
    # branch: 3 thin segments arcing up + out (+X)
    for i, spec in enumerate([
            ((0.00, 0.0, 0.16), (0.05, 0.05, 0.30), (0.0, math.radians(18), 0.0)),
            ((0.12, 0.0, 0.40), (0.045, 0.045, 0.26), (0.0, math.radians(44), 0.0)),
            ((0.30, 0.0, 0.50), (0.04, 0.04, 0.22), (0.0, math.radians(66), 0.0))]):
        b = _box("branch_%d" % i, spec[0], spec[1], spec[2])
        b.data.materials.append(wood)
        parts.append(b)
    # leaves: flat triangles fanning at the branch tip
    lbm = bmesh.new()
    lrng = random.Random(SEED * 71 + 5)
    for _k in range(7):
        ang = lrng.uniform(0.0, 2.0 * math.pi)
        ln = lrng.uniform(0.10, 0.18)
        dx, dy = math.cos(ang), math.sin(ang)
        px, py = -dy, dx
        w = 0.04
        v1 = lbm.verts.new((px * w, py * w, 0.0))
        v2 = lbm.verts.new((-px * w, -py * w, 0.0))
        v3 = lbm.verts.new((dx * ln, dy * ln, lrng.uniform(0.02, 0.09)))
        lbm.faces.new((v1, v2, v3))
    bmesh.ops.recalc_face_normals(lbm, faces=lbm.faces)
    leaves = _new_obj("branch_leaves", lbm)
    leaves.location = Vector((0.44, 0.0, 0.56))
    leaves.data.materials.append(leaf)
    parts.append(leaves)
    # nest: a flattened bowl seated in the fork
    nbm = bmesh.new()
    bmesh.ops.create_cone(nbm, cap_ends=True, cap_tris=False, segments=10,
                          radius1=0.15, radius2=0.11, depth=0.08)
    nest = _new_obj("nest", nbm)
    nest.location = Vector((0.07, 0.0, 0.36))
    nest.data.materials.append(twig)
    parts.append(nest)
    # eggs in the nest
    for j, egg_xy in enumerate([(-0.045, 0.02), (0.045, 0.01), (0.0, -0.045)]):
        ebm = bmesh.new()
        bmesh.ops.create_icosphere(ebm, subdivisions=1, radius=0.033)
        for v in ebm.verts:
            v.co.z *= 1.25   # egg-shaped
        bmesh.ops.recalc_face_normals(ebm, faces=ebm.faces)
        e = _new_obj("egg_%d" % j, ebm)
        e.location = Vector((0.07 + egg_xy[0], egg_xy[1], 0.40))
        e.data.materials.append(egg)
        parts.append(e)
    return _join_all(parts, "golem_branch_nest")


def main():
    print(f"\n[gen_dressing] seed={SEED}  output_dir={OUTPUT_DIR}\n")

    # 1) Rock chip
    clear_scene()
    chip = build_rock_chip()
    bpy.context.collection.objects.link(chip)
    chip.data.materials.append(make_material("golem_stone", STONE_RGBA))
    export_single(chip, "golem_rock_chip_01.glb")

    # 2) Moss patch
    clear_scene()
    moss = build_moss_patch()
    bpy.context.collection.objects.link(moss)
    moss.data.materials.append(make_material("golem_moss", MOSS_RGBA))
    export_single(moss, "golem_moss_patch_01.glb")

    # 2b) Moss tuft (shape variant)
    clear_scene()
    tuft = build_moss_tuft()
    bpy.context.collection.objects.link(tuft)
    tuft.data.materials.append(make_material("golem_moss", MOSS_RGBA))
    export_single(tuft, "golem_moss_tuft_02.glb")

    # 2c) Clinging grass blades (replaces the bush-y patches)
    clear_scene()
    grass = build_grass_clump()
    bpy.context.collection.objects.link(grass)
    grass.data.materials.append(make_material("golem_grass", (0.40, 0.58, 0.27, 1.0)))
    export_single(grass, "golem_grass_clump_01.glb")

    # 2d) Branch + twig nest with eggs (the 'nature made a home' detail)
    clear_scene()
    bn = build_branch_nest()
    bpy.context.view_layer.objects.active = bn
    for p in bn.data.polygons:
        p.use_smooth = False
    export_glb(os.path.join(OUTPUT_DIR, "golem_branch_nest_01.glb"))
    print("[gen_dressing] EXPORTED -> golem_branch_nest_01.glb  tris=%d" % count_tris(bn))

    # 3) Pink flower
    clear_scene()
    p, c = build_flower("flower_pink", seed=2)
    p.data.materials.append(make_material("petal_pink", PINK_RGBA))
    c.data.materials.append(make_material("flower_center", YELLOW_RGBA))
    flower_p = join_two(p, c, "golem_flower_pink")
    export_single(flower_p, "golem_flower_pink_01.glb")

    # 4) White daisy
    clear_scene()
    p2, c2 = build_flower("flower_white", seed=3)
    p2.data.materials.append(make_material("petal_white", WHITE_RGBA))
    c2.data.materials.append(make_material("flower_center", YELLOW_RGBA))
    flower_w = join_two(p2, c2, "golem_flower_white")
    export_single(flower_w, "golem_flower_white_01.glb")

    # 5) Yellow flower (color variant)
    clear_scene()
    p3, c3 = build_flower("flower_yellow", seed=4)
    p3.data.materials.append(make_material("petal_yellow", (0.96, 0.80, 0.30, 1.0)))
    c3.data.materials.append(make_material("flower_center", (0.82, 0.52, 0.18, 1.0)))
    flower_y = join_two(p3, c3, "golem_flower_yellow")
    export_single(flower_y, "golem_flower_yellow_01.glb")

    print("\n[gen_dressing] DONE\n")


main()
