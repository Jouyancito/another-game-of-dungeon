"""
gen_golem.py — Dungeon Party bespoke stone-golem BODY generator (P1 Pradera).

Generates one GLB:
  golem_dp_body_01.glb  — hunched stone construct body, target <= 1000 tris

This is the ONE enemy that is bespoke-bpy instead of pack-reskin, because a stone
golem is geometrically a pile of beveled rocks — the SAME hard-surface vocabulary as
gen_crystal / (planned) gen_rock / gen_pillar. Decision logged in the Bestiary Visual
Bible §6.5 (game/docs/art/_bestiary_visual_bible.md, v0.2) with Joan's 3 references.

AXIS CONVENTION (IMPORTANT — learned 2026-06-09):
  Build with **Z = up** (Blender native). export_yup=True then maps Blender-Z → glTF-Y,
  so the model stands up in Godot, matching pack enemies (enemy_orc.gltf imports with its
  tall axis on Blender-Z). Building height on Blender-Y (as gen_crystal does) bakes the
  figure LYING DOWN in Godot — fine for a radially-symmetric crystal, broken for a biped.

Style contract (DP_ToonGrounded, _art_canon §9):
  - FLAT-SHADED + one hard chamfer pass per block (the family signature).
  - Bottom-weighted, hunched juggernaut silhouette (wide short legs, long hanging arms,
    head low between high shoulders). One asymmetric break: the LEFT shoulder is the
    "overgrown" side (bigger mass — Godot scatters more vegetation there).
  - Carved flat face plane with two recessed eye sockets (Godot drives cyan emissive eyes).
  - Rock blocks jittered slightly so they read as a pile of stone, not a clean robot.
  - OPAQUE neutral-gray material slot — Godot applies material_override (stone + moss).
  - Z-up in Blender, feet at Z=0.

What this script does NOT do (lives in Godot, per the bible):
  - Moss/grass/mushroom/flower scatter (reuse prairie gltf as child nodes / MultiMesh).
  - Cyan emissive eyes + crack/core glow (material_override).
  - 2-3 small floating rocks with a slow hover tween.

Usage:
  blender.exe --background --python gen_golem.py
  blender.exe --background --python gen_golem.py -- --seed 42

Export destination: game/assets/art/piso1_pradera/enemies/big/
"""

import bpy
import bmesh
import math
import random
import sys
import os
from mathutils import Vector, Euler

# ---------------------------------------------------------------------------
# Parse optional --seed argument passed after '--' in the blender CLI
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

# ---------------------------------------------------------------------------
# Output directory — game/assets/art/piso1_pradera/enemies/big
# ---------------------------------------------------------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "..", "assets", "art", "piso1_pradera", "enemies", "big")
)
os.makedirs(OUTPUT_DIR, exist_ok=True)


# ---------------------------------------------------------------------------
# Rock-block builder: a chamfered, jittered, flat-shaded box.
# All coordinates are Blender Z-up: location/size = (x=side, y=depth, z=height).
# ---------------------------------------------------------------------------
def make_rock_block(
    name: str,
    location: tuple[float, float, float],
    size: tuple[float, float, float],
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
    bevel: float = 0.06,
    jitter: float = 0.06,
    block_seed: int = 0,
    detail: int = 0,
    displace: float = 0.10,
    rot_jitter_deg: float = 5.0,
) -> bpy.types.Object:
    """
    A chamfered, jittered, flat-shaded rocky box.

    detail=0 → clean chamfered box (corners jittered). Cheap. Use for small rubble.
    detail>=1 → subdivide `detail` times then displace every vert by faceted noise →
      believable weathered-stone surface (silhouette notches, not texture). More tris.
    rot_jitter_deg → small random whole-block rotation so blocks aren't grid-aligned
      (kills the clean-cube 'Minecraft' read).
    """
    lrng = random.Random(SEED * 131 + block_seed)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)

    sx, sy, sz = size
    for v in bm.verts:
        v.co.x *= sx
        v.co.y *= sy
        v.co.z *= sz

    # One hard chamfer pass (family signature). offset relative to smallest dim.
    min_dim = max(0.001, min(sx, sy, sz))
    bevel_off = min(bevel, min_dim * 0.45)
    bmesh.ops.bevel(
        bm,
        geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
        offset=bevel_off,
        offset_type="OFFSET",
        segments=2,   # a couple support loops so the Subdivision Surface rounds cleanly
        profile=0.5,
        affect="EDGES",
        clamp_overlap=True,
    )

    # Corner jitter (moves the silhouette — proportional, stays readable).
    for v in bm.verts:
        v.co.x += lrng.uniform(-jitter, jitter) * sx
        v.co.y += lrng.uniform(-jitter, jitter) * sy
        v.co.z += lrng.uniform(-jitter, jitter) * sz

    # Surface detail: subdivide + faceted displacement → weathered rock relief.
    if detail >= 1:
        for _ in range(detail):
            bmesh.ops.subdivide_edges(
                bm, edges=list(bm.edges), cuts=1, use_grid_fill=True
            )
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
    # Add a small random whole-block rotation so masses read as irregular stone.
    rj = math.radians(rot_jitter_deg)
    obj.rotation_euler = Euler((
        rotation[0] + lrng.uniform(-rj, rj),
        rotation[1] + lrng.uniform(-rj, rj),
        rotation[2] + lrng.uniform(-rj, rj),
    ), "XYZ")
    return obj


def scatter_detail_rocks() -> list[bpy.types.Object]:
    """Small rubble/weathering rocks nestled at joints, base and shoulders.
    Break the clean silhouette and sell 'pile of stone'. detail=0 (cheap)."""
    srng = random.Random(SEED * 977 + 3)
    # (x, y, z, base_size) anchor points around the body.
    anchors = [
        (-0.55, 0.20, 0.10, 0.30), (0.58, 0.18, 0.12, 0.28),   # feet rubble
        (-0.70, 0.10, 1.70, 0.26), (0.66, 0.08, 1.66, 0.20),   # shoulder edges
        (-0.78, -0.10, 2.02, 0.20), (-0.30, -0.30, 1.86, 0.22),# overgrown-side back
        (0.0, -0.34, 1.62, 0.22),                               # spine
        (-1.02, 0.18, 0.50, 0.20),                              # left elbow/forearm
    ]
    rocks = []
    for i, (x, y, z, bs) in enumerate(anchors):
        s = bs * srng.uniform(0.7, 1.25)
        rocks.append(make_rock_block(
            f"rubble_{i:02d}",
            (x + srng.uniform(-0.05, 0.05), y + srng.uniform(-0.05, 0.05), z),
            (s, s * srng.uniform(0.7, 1.1), s * srng.uniform(0.6, 1.0)),
            bevel=0.04, jitter=0.12, block_seed=600 + i,
            detail=0, rot_jitter_deg=22.0,
        ))
    return rocks


def make_face_plate(
    name: str,
    location: tuple[float, float, float],  # (x, y=depth, z=height) of face center
    width: float,
    height: float,   # vertical (Z) extent of the face
    depth: float,    # forward (Y) extent
    tilt_deg: float,
) -> list[bpy.types.Object]:
    """
    Carved face: brow ridge + two recessed eye sockets + jaw slab. Z-up.
    Eyes are emissive in Godot; the sockets give them a seat and make the preview read.
    """
    parts = []
    cx, cy, cz = location
    tilt = math.radians(tilt_deg)

    # Brow ridge (thin slab across the top of the face).
    parts.append(make_rock_block(
        name + "_brow",
        (cx, cy + depth * 0.55, cz + height * 0.32),
        (width * 0.92, depth * 0.5, height * 0.16),
        rotation=(tilt, 0.0, 0.0),
        bevel=0.04, jitter=0.04, block_seed=901,
    ))

    # NOTE: no solid eye-socket blocks here. They used to sit IN FRONT of the
    # glowing eye cores and split each eye's glow in two (Joan 2026-06-10). The
    # emissive eye cores (build_golem) now sit flush in the brow/cheek gap as
    # clean single slits, with nothing covering them.

    # Jaw / chin slab (the carved-stone-face read of ref img 3).
    parts.append(make_rock_block(
        name + "_jaw",
        (cx, cy + depth * 0.45, cz - height * 0.30),
        (width * 0.78, depth * 0.42, height * 0.28),
        rotation=(tilt, 0.0, 0.0),
        bevel=0.04, jitter=0.05, block_seed=904,
    ))
    return parts


# ---------------------------------------------------------------------------
# Assemble the golem from rock blocks (Z-up, feet at Z=0).
# Posture: hunched forward (+Y), wide short legs, long knuckle-drag arms,
# head low and forward between high shoulders. Left shoulder = overgrown (bigger).
# Block coords: (x=side, y=depth/forward, z=height).
# ---------------------------------------------------------------------------
def build_golem() -> list[bpy.types.Object]:
    parts: list[bpy.types.Object] = []
    j = 0.07  # base jitter

    # --- LEGS: wide, short, planted (bottom-weighted). ---
    for sgn, sd in ((-1, 1), (1, 2)):
        parts.append(make_rock_block(  # thigh
            f"leg_up_{sd}",
            (sgn * 0.40, -0.02, 0.55),
            (0.46, 0.50, 0.62),
            bevel=0.07, jitter=0.09, block_seed=sd,
        ))
        parts.append(make_rock_block(  # foot (extra wide, grounded)
            f"foot_{sd}",
            (sgn * 0.42, 0.06, 0.18),
            (0.56, 0.66, 0.36),
            bevel=0.07, jitter=j, block_seed=sd + 10, detail=1,
        ))

    # --- PELVIS / LOWER TORSO ---
    parts.append(make_rock_block(
        "pelvis", (0.0, -0.04, 0.92), (1.02, 0.62, 0.52),
        bevel=0.08, jitter=j, block_seed=20, detail=1,
    ))

    # --- CHEST: big mass, leaning FORWARD (+Y) → negative X-rotation. ---
    parts.append(make_rock_block(
        "chest", (0.0, 0.10, 1.45), (1.16, 0.74, 0.78),
        rotation=(math.radians(-14.0), 0.0, 0.0),
        bevel=0.09, jitter=j, block_seed=21, detail=1,
    ))
    # upper-back hump (leans back over the spine → positive X-rotation).
    parts.append(make_rock_block(
        "back_hump", (0.0, -0.32, 1.78), (0.92, 0.46, 0.52),
        rotation=(math.radians(18.0), 0.0, 0.0),
        bevel=0.08, jitter=j, block_seed=22, detail=1,
    ))

    # --- SHOULDERS: high, hunched up. LEFT is the overgrown (bigger) side. ---
    parts.append(make_rock_block(  # left, overgrown
        "shoulder_L", (-0.66, 0.02, 1.82), (0.74, 0.70, 0.66),
        bevel=0.08, jitter=j, block_seed=30, detail=1,
    ))
    parts.append(make_rock_block(  # extra knob on the left (more moss surface)
        "shoulder_L_knob", (-0.74, -0.06, 2.06), (0.40, 0.40, 0.34),
        bevel=0.06, jitter=0.10, block_seed=31,
    ))
    parts.append(make_rock_block(  # right, cleaner / smaller
        "shoulder_R", (0.64, 0.02, 1.74), (0.62, 0.62, 0.56),
        bevel=0.08, jitter=j, block_seed=32, detail=1,
    ))

    # --- ARMS: long, heavy, hanging to ~knee (knuckle-drag). ---
    #     Splay outward via Y-axis rotation (tilts side X toward height Z).
    # KNUCKLE-DRAG arms (ref img 33): long, thick, hanging DOWN + FORWARD with big
    # fists resting near the ground in front of the legs. Turns it from a stocky
    # robot into a gorilla-like stone beast.
    arm_specs = [
        (-1, 40, 41, 42, 1.14),  # left arm bigger (overgrown side)
        (1, 43, 44, 45, 1.0),
    ]
    for sgn, us, fs, ks, sc in arm_specs:
        parts.append(make_rock_block(  # upper arm — thick, from the high shoulder
            f"uparm_{us}",
            (sgn * 0.98, 0.12, 1.46),
            (0.48 * sc, 0.48 * sc, 0.74 * sc),
            rotation=(math.radians(-6.0), math.radians(-6.0 * sgn), 0.0),
            bevel=0.07, jitter=0.09, block_seed=us, detail=1,
        ))
        parts.append(make_rock_block(  # forearm — long, dropping down and FORWARD
            f"forearm_{fs}",
            (sgn * 1.08, 0.26, 0.68),
            (0.48 * sc, 0.48 * sc, 0.82 * sc),
            rotation=(math.radians(10.0), 0.0, 0.0),
            bevel=0.06, jitter=0.09, block_seed=fs, detail=1,
        ))
        parts.append(make_rock_block(  # BIG fist resting near the ground, forward
            f"fist_{ks}",
            (sgn * 1.08, 0.40, 0.28),
            (0.66 * sc, 0.70 * sc, 0.60 * sc),
            bevel=0.08, jitter=0.11, block_seed=ks, detail=1,
        ))

    # --- NECK + HEAD: low, set forward between the shoulders. ---
    parts.append(make_rock_block(
        "neck", (0.0, 0.18, 1.86), (0.40, 0.40, 0.30),
        rotation=(math.radians(-18.0), 0.0, 0.0),
        bevel=0.05, jitter=0.05, block_seed=50,
    ))
    parts.append(make_rock_block(
        "head", (0.0, 0.30, 2.06), (0.66, 0.62, 0.60),
        rotation=(math.radians(-10.0), 0.0, 0.0),
        bevel=0.07, jitter=0.05, block_seed=51, detail=1,
    ))
    face_cx, face_cy, face_cz = 0.0, 0.46, 2.04
    fw, fh, fd = 0.58, 0.46, 0.30
    parts.extend(make_face_plate(  # carved face on the head front (+Y)
        "face", (face_cx, face_cy, face_cz), width=fw, height=fh, depth=fd, tilt_deg=-10.0,
    ))

    # --- RUBBLE: small rocks at joints/base/shoulders break the silhouette. ---
    parts.extend(scatter_detail_rocks())

    # --- EYE CORES: two small blocks proud of the sockets, on a SEPARATE material
    #     slot ("golem_eye_core") so Godot drives the cyan emissive glow. Baked into
    #     the GLB so placement is exact (no blind positioning in Godot).
    eyes: list[bpy.types.Object] = []
    for sgn, sd in ((-1, 905), (1, 906)):
        eyes.append(make_rock_block(
            f"eye_core_{'L' if sgn < 0 else 'R'}",
            (face_cx + sgn * fw * 0.27, face_cy + fd * 0.66, face_cz + fh * 0.06),
            (fw * 0.34, fd * 0.16, fh * 0.11),  # clean wide slit, flush in the face, nothing in front to split it
            bevel=0.03, jitter=0.0, block_seed=sd, rot_jitter_deg=0.0,
        ))

    return parts, eyes


# ---------------------------------------------------------------------------
# Scene helpers (mirrors gen_crystal.py)
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


def join_objects(objs: list[bpy.types.Object], final_name: str) -> bpy.types.Object:
    """Bake each part transform, then join all into a single mesh object."""
    for o in objs:
        try:
            bpy.context.collection.objects.link(o)
        except RuntimeError:
            pass  # already linked (e.g. the unioned stone)
    for o in objs:
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    golem = bpy.context.view_layer.objects.active
    golem.name = final_name
    return golem


def finalize_mesh(obj: bpy.types.Object) -> None:
    """Flat-shade every face + ground the model so its lowest point sits at Z=0."""
    me = obj.data
    for poly in me.polygons:
        poly.use_smooth = False
    me.validate(verbose=False)
    min_z = min(v.co.z for v in me.vertices)
    for v in me.vertices:
        v.co.z -= min_z


def add_neutral_material(obj: bpy.types.Object) -> None:
    mat = bpy.data.materials.new(name="golem_stone_neutral")
    mat.diffuse_color = (0.42, 0.40, 0.36, 1.0)  # warm stone gray; Godot overrides
    obj.data.materials.append(mat)


def count_tris(obj: bpy.types.Object) -> int:
    total = 0
    for poly in obj.data.polygons:
        total += len(poly.vertices) - 2
    return total


def solidify(obj: bpy.types.Object, voxel: float = 0.045, angle_deg: float = 9.0) -> None:
    """Turn the heap of interpenetrating blocks into ONE watertight shell.
    VOXEL remesh removes ALL internal/hidden faces (kills z-fighting + the
    'see inside' transparency); DECIMATE planar merges coplanar tris back into
    flat toon facets + cuts the voxel tri count. Result is a single solid 'monster'."""
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    rm = obj.modifiers.new("remesh", type="REMESH")
    rm.mode = "VOXEL"
    rm.voxel_size = voxel
    bpy.ops.object.modifier_apply(modifier=rm.name)
    dec = obj.modifiers.new("dec", type="DECIMATE")
    dec.decimate_type = "DISSOLVE"
    dec.angle_limit = math.radians(angle_deg)
    bpy.ops.object.modifier_apply(modifier=dec.name)
    me = obj.data
    for p in me.polygons:
        p.use_smooth = False
    me.validate(verbose=False)


def _face_vertex_colors(obj: bpy.types.Object) -> None:
    """Per-facet tonal variation (baked vertex colors) so the merged solid still
    reads as a pile of distinct stones, not one flat tan."""
    me = obj.data
    if not me.color_attributes:
        me.color_attributes.new(name="Col", type="BYTE_COLOR", domain="CORNER")
    ca = me.color_attributes[0]
    frng = random.Random(SEED * 7 + 9)
    for poly in me.polygons:
        t = frng.uniform(-0.11, 0.11)
        h = frng.uniform(-0.03, 0.03)
        col = (min(1.0, max(0.0, 0.42 + t + h)),
               min(1.0, max(0.0, 0.40 + t)),
               min(1.0, max(0.0, 0.36 + t - h)), 1.0)
        for li in poly.loop_indices:
            ca.data[li].color = col


def paint_moss(obj: bpy.types.Object) -> None:
    """Paint moss-green into the STONE on up-facing / high faces (fading to grey
    stone on sides + below) — so the moss is PART of the rock, not a stuck-on mesh
    (Joan: 'pintar la textura de las rocas arriba con colores musgo'). Per-face
    vertex color; Godot shows it via the toon use_vertex_color path. Z = up here."""
    me = obj.data
    if not me.color_attributes:
        me.color_attributes.new(name="Col", type="BYTE_COLOR", domain="CORNER")
    ca = me.color_attributes[0]
    zs = [v.co.z for v in me.vertices]
    zmin, zr = min(zs), max(1e-6, max(zs) - min(zs))
    stone = (0.44, 0.42, 0.40)
    moss = (0.30, 0.45, 0.24)
    prng = random.Random(SEED * 13)
    for poly in me.polygons:
        vs = [me.vertices[i].co for i in poly.vertices]
        nrm = (vs[1] - vs[0]).cross(vs[2] - vs[0])
        up = 0.0 if nrm.length < 1e-9 else max(0.0, nrm.normalized().z)
        cz = sum(v.z for v in vs) / len(vs)
        h = (cz - zmin) / zr
        amt = up * (0.30 + 0.85 * h) + prng.uniform(-0.30, 0.16)
        if amt < 0.22:
            amt = 0.0   # leave BARE stone patches — moss is patchy, not a full carpet
        amt = max(0.0, min(1.0, amt))
        col = (stone[0] * (1 - amt) + moss[0] * amt,
               stone[1] * (1 - amt) + moss[1] * amt,
               stone[2] * (1 - amt) + moss[2] * amt, 1.0)
        for li in poly.loop_indices:
            ca.data[li].color = col


def round_block(obj: bpy.types.Object, levels: int = 1) -> None:
    """Subdivision-surface a block into a smooth BOULDER mass (Joan's refs = rounded
    weathered rock, not hard cubes). Flat-shaded later -> faceted low-poly boulder."""
    try:
        bpy.context.collection.objects.link(obj)
    except RuntimeError:
        pass
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    m = obj.modifiers.new("subsurf", type="SUBSURF")
    m.levels = levels
    m.render_levels = levels
    bpy.ops.object.modifier_apply(modifier=m.name)


def boolean_union(objs: list[bpy.types.Object]) -> bpy.types.Object:
    """Weld the interpenetrating blocks into ONE watertight solid — no internal
    faces, no z-fighting (the cause of the 'transparent' patches). EXACT solver
    keeps sharp edges + carries the per-block vertex-color attribute onto the
    merged surface. Returns the single unioned object."""
    for o in objs:
        try:
            bpy.context.collection.objects.link(o)
        except RuntimeError:
            pass
    base = objs[0]
    bpy.ops.object.select_all(action="DESELECT")
    base.select_set(True)
    bpy.context.view_layer.objects.active = base
    for o in objs[1:]:
        m = base.modifiers.new(name="bool", type="BOOLEAN")
        m.operation = "UNION"
        m.solver = "EXACT"
        m.object = o
        bpy.ops.object.modifier_apply(modifier=m.name)
        bpy.data.objects.remove(o, do_unlink=True)
    return base


def _set_vertex_color(obj, rgba) -> None:
    me = obj.data
    if not me.color_attributes:
        me.color_attributes.new(name="Col", type="BYTE_COLOR", domain="CORNER")
    ca = me.color_attributes[0]
    for d in ca.data:
        d.color = rgba


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
    # Try to include vertex colors (per-block stone tones); degrade if unsupported.
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
    print(f"\n[gen_golem] seed={SEED}  output_dir={OUTPUT_DIR}\n")
    clear_scene()

    parts, eyes = build_golem()

    # Two material slots (shared datablocks → exactly 2 surfaces after join):
    #   slot 0 "golem_stone"     — body (Godot drives stone/moss look)
    #   slot 1 "golem_eye_core"  — eyes (Godot drives cyan emissive glow)
    stone_mat = bpy.data.materials.new("golem_stone")
    stone_mat.diffuse_color = (0.42, 0.40, 0.36, 1.0)
    for o in parts:
        o.data.materials.append(stone_mat)
    eye_mat = bpy.data.materials.new("golem_eye_core")
    eye_mat.diffuse_color = (0.37, 0.85, 1.0, 1.0)  # cyan; Godot overrides emissive
    for o in eyes:
        o.data.materials.append(eye_mat)

    # WEATHERED mottled stone (ref img 33): mostly grey stone, with some blocks
    # moss-stained (green) and some warm-weathered (tan), biased a touch darker so
    # it reads as solid heavy rock, not washed-out. Per-block, clean (not speckled).
    vrng = random.Random(SEED * 7 + 3)
    for o in parts:
        _set_vertex_color(o, (1.0, 1.0, 1.0, 1.0))  # placeholder; repainted after join
    for o in eyes:
        _set_vertex_color(o, (1.0, 1.0, 1.0, 1.0))

    # Round each block into a boulder mass (eyes stay sharp slits).
    for o in parts:
        round_block(o, 1)

    golem = join_objects(parts + eyes, "golem_dp_body")
    finalize_mesh(golem)
    # Moss is PAINTED into the rock (up-facing/high faces -> green) so it lives with
    # the stone; only small 3D flowers go on top (golem.gd). Joan's idea.
    paint_moss(golem)

    tris = count_tris(golem)
    me = golem.data
    zs = [v.co.z for v in me.vertices]
    xs = [v.co.x for v in me.vertices]
    height = max(zs) - min(zs)
    width = max(xs) - min(xs)

    out_path = os.path.join(OUTPUT_DIR, "golem_dp_body_01.glb")
    export_glb(out_path)

    print(f"[gen_golem] EXPORTED → {out_path}")
    print(f"[gen_golem] tris={tris}  height(Z)={height:.2f}m  width(X)={width:.2f}m")
    print(f"[gen_golem] budget <= 2500 tris : {'OK' if tris <= 2500 else 'OVER BUDGET!'}")
    print("\n[gen_golem] DONE ✓")


main()
