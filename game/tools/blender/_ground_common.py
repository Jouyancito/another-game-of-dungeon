# _ground_common.py — shared ground-plane utility for mob build scripts.
# Born from golem_guardian PASS 6 (2026-07-20+, PO Joan): "it's generating
# floating models — if a stone falls, it ends up floating in the air, not
# landing anywhere... generate a ground/floor reference... not just a flat
# floor, but a floor with irregularities, more realistic uneven terrain."
#
# Every mob's death/collapse clip (and any other falling-debris beat) should
# query ground_height() for where a piece actually rests, instead of
# assuming Z=0 or a hand-picked constant. FLAG FOR FUTURE WORK: audit
# slime/rat/wasp/turtle/bird/golem_floating death clips — they all predate
# this utility and were built assuming a flat Z=0 (or a guessed constant)
# ground, so they likely have the same floating-debris problem, just never
# checked against a real ground plane. See blender-asset-smith skill,
# 2026-07-20 golem_guardian entry.
#
# Usage from a build_*.py script:
#
#   import sys, os
#   sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
#   import _ground_common as groundlib
#
#   offset_z = groundlib.ground_height(0.0, 0.0)          # sample once, e.g.
#                                                          # to plant a rig
#   ground_obj = groundlib.build_ground(scene, size=9.0)  # visible mesh
#   z = groundlib.ground_height(piece_x, piece_y)         # per-piece resting Z
import bpy
import bmesh
import math
from mathutils import Vector
from mathutils import noise as mnoise

# Tuned for "uneven natural ground" (Joan: gentle irregularity, NOT dramatic
# hills) — a shallow two-octave noise field, not a single smooth wave (which
# would read as a flat tilted plane, not real terrain).
# GOTCHA (2026-07-20, golem_guardian first pass): scale=0.55/strength=0.14
# rendered as visually indistinguishable from a flat slab at normal showcase
# camera distance — the wavelength (2*pi/scale =~ 11 units) was close to the
# WHOLE ground tile's own width, so only a fraction of one gentle wave was
# ever in frame, reading as a faint tilt rather than "uneven terrain".
# Shorter wavelength (higher scale) fits several visible bumps in a typical
# framing; higher strength makes them actually read under the showcase
# lighting without going as far as "dramatic hills".
GROUND_NOISE_SCALE = 1.15       # world-units period of the base undulation
GROUND_NOISE_STRENGTH = 0.22    # base octave amplitude (world units)
GROUND_SEED = Vector((41.0, 7.0, 0.0))  # fixed offset — deterministic terrain


def ground_height(x, y, size=8.0, roughness=GROUND_NOISE_STRENGTH,
                   scale=GROUND_NOISE_SCALE, seed=GROUND_SEED):
    """Pure function: the ground mesh's ACTUAL height (world Z) at world
    (x, y) — samples the exact same noise formula build_ground() uses to
    displace its vertices, so 'where the mesh really is' and 'where a
    falling/resting object should target' can never drift out of sync (no
    separate approximation to go stale). Two octaves (base undulation + a
    finer wrinkle at 0.35x weight) so the terrain reads as genuinely uneven,
    not a single smooth sine wave. Falls off toward 0 near the tile's own
    edge (past 35% of `size`) so a large ground plane stays flush at its own
    boundary instead of ending in a hard cliff — cheap insurance for
    whatever gets placed near the edge of the tile, not load-bearing for
    THIS brief's golem-in-the-middle case."""
    co = Vector((x, y, 0.0)) * scale + seed
    base = mnoise.noise(co)
    fine = mnoise.noise(co * 2.7 + Vector((13.0, 4.0, 0.0))) * 0.35
    h = (base * 2.0 - 1.0) * roughness + (fine * 2.0 - 1.0) * roughness * 0.35
    r = math.sqrt(x * x + y * y)
    edge = max(0.0, 1.0 - max(0.0, r - size * 0.35) / max(1e-4, size * 0.65))
    return h * min(1.0, edge)


def _default_ground_material(name="ground_dirt_mat"):
    m = bpy.data.materials.get(name)
    if m is not None:
        return m
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n = m.node_tree.nodes["Principled BSDF"]
    n.inputs["Base Color"].default_value = (0.145, 0.115, 0.088, 1.0)  # neutral dirt/stone
    n.inputs["Roughness"].default_value = 0.92
    spec = n.inputs.get("Specular IOR Level")
    if spec is not None:
        spec.default_value = 0.1
    return m


def build_ground(scene, size=8.0, subdiv=48, roughness=GROUND_NOISE_STRENGTH,
                  scale=GROUND_NOISE_SCALE, seed=GROUND_SEED, material=None,
                  name="ground", center=(0.0, 0.0)):
    """Large subdivided ground plane (full width = 2*size, matching
    bmesh.ops.create_grid's own half-extent `size` convention), vertex Z
    displaced by ground_height() — the SAME formula, not a separate bake, so
    the visible mesh and the queryable height function can never disagree.
    Gentle irregularity by design (not a flat slab, not dramatic hills)."""
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=subdiv, y_segments=subdiv, size=size, calc_uvs=True)
    cx, cy = center
    for v in bm.verts:
        wx, wy = v.co.x + cx, v.co.y + cy
        v.co.x, v.co.y = wx, wy
        v.co.z = ground_height(wx, wy, size=size, roughness=roughness, scale=scale, seed=seed)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.normal_update()
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    obj = bpy.data.objects.new(name, me)
    scene.collection.objects.link(obj)
    obj.data.materials.append(material if material is not None else _default_ground_material())
    return obj
