"""
_preview_golem_assembly.py — Preview script for the chunked golem assembly.

Renders three states from golem_dp_chunks_01.glb:
  dormant  — chunks scattered/piled (pile offsets applied) = looks like a boulder
  mid      — chunks halfway between pile and stand (assembly in progress)
  alert    — chunks in their authored stand positions (assembled, upright)

Usage:
  blender --background --python _preview_golem_assembly.py -- <chunks.glb> <out_prefix>
  e.g.: ... -- game/assets/.../golem_dp_chunks_01.glb game/tools/godot/_golem_assembly

Outputs:
  <prefix>_dormant_34.png
  <prefix>_mid_34.png
  <prefix>_alert_34.png
  <prefix>_alert_front.png
"""

import bpy
import sys
import os
import math
import mathutils

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if len(argv) < 2:
    print("Usage: -- <chunks.glb> <out_prefix>")
    sys.exit(1)

glb_path = argv[0]
out_prefix = argv[1]

# ---------------------------------------------------------------------------
# Pile offsets matching golem_assembly.gd PILE_RULES.
# key fragment → (pos_offset, rot_offset_deg)
# ---------------------------------------------------------------------------
PILE_RULES = {
    "chunk_pelvis":       [(0.00,  0.00, -0.55), (8.0,  0.0,  3.0)],
    "chunk_chest":        [(0.04,  0.20, -0.70), (20.0, 5.0, -4.0)],
    "chunk_back_hump":    [(-0.06, -0.10, -0.55), (12.0, -3.0, 5.0)],
    "chunk_shoulder_l_k": [(-0.35, 0.05, -0.90), (20.0, 5.0, 22.0)],
    "chunk_shoulder_l":   [(-0.25, 0.10, -0.80), (15.0, 0.0, 18.0)],
    "chunk_shoulder_r":   [(0.22,  0.12, -0.75), (10.0, 0.0,-16.0)],
    "chunk_arm_l":        [(-0.45, 0.30, -0.85), (18.0,-8.0, 25.0)],
    "chunk_arm_r":        [(0.42,  0.28, -0.80), (14.0, 6.0,-22.0)],
    "chunk_leg_l":        [(-0.18, 0.15, -0.35), (5.0, -5.0, 12.0)],
    "chunk_leg_r":        [(0.16,  0.14, -0.32), (4.0,  5.0,-10.0)],
    "chunk_neck":         [(0.02,  0.15, -0.60), (30.0, 2.0,  0.0)],
    "chunk_head":         [(0.05,  0.25, -0.75), (35.0,-3.0,  6.0)],
    "chunk_face":         [(0.04,  0.30, -0.85), (40.0, 0.0,  4.0)],
    "chunk_eye":          [(0.05,  0.28, -0.82), (42.0, 0.0,  0.0)],
    "chunk_rubble":       [(0.0,   0.05, -0.08), (0.0,  0.0,  0.0)],
}


def get_pile_offset(name_lower):
    for key, rule in PILE_RULES.items():
        if key in name_lower:
            return rule
    return None


def lerp_v3(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def setup_lights_and_world():
    for obj in bpy.context.scene.objects:
        if obj.type in ("LIGHT",):
            bpy.data.objects.remove(obj, do_unlink=True)

    key_d = bpy.data.lights.new("key", "SUN")
    key_d.energy = 3.5
    key_d.color = (1.0, 0.85, 0.6)
    key = bpy.data.objects.new("key", key_d)
    bpy.context.scene.collection.objects.link(key)
    key.rotation_euler = (math.radians(50), 0, math.radians(35))

    fill_d = bpy.data.lights.new("fill", "SUN")
    fill_d.energy = 1.1
    fill_d.color = (0.5, 0.62, 0.85)
    fill = bpy.data.objects.new("fill", fill_d)
    bpy.context.scene.collection.objects.link(fill)
    fill.rotation_euler = (math.radians(60), 0, math.radians(-130))

    world = bpy.data.worlds.new("w")
    bpy.context.scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.62, 0.64, 0.68, 1.0)


def get_scene_aabb():
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    mins = [1e9] * 3
    maxs = [-1e9] * 3
    for o in meshes:
        for c in o.bound_box:
            wc = o.matrix_world @ mathutils.Vector(c)
            for i in range(3):
                mins[i] = min(mins[i], wc[i])
                maxs[i] = max(maxs[i], wc[i])
    return mins, maxs


def place_camera(angle, center, size):
    cam_data = bpy.data.cameras.get("cam")
    if cam_data is None:
        cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.get("Camera")
    if cam is None:
        cam = bpy.data.objects.new("Camera", cam_data)
        bpy.context.scene.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    aim = mathutils.Vector((center[0], center[1] * 0.92, center[2]))
    d = size * 2.2
    if angle == "34":
        cam.location = aim + mathutils.Vector((d * 0.62, -d * 1.0, d * 0.18))
    elif angle == "front":
        cam.location = aim + mathutils.Vector((d * 0.18, d * 1.05, d * 0.12))
    cam.rotation_euler = (aim - cam.location).normalized().to_track_quat("-Z", "Y").to_euler()


def render(out_path):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 32
    sc.render.resolution_x = 560
    sc.render.resolution_y = 640
    sc.render.filepath = out_path
    bpy.ops.render.render(write_still=True)
    print("RENDERED:", out_path)


# ---------------------------------------------------------------------------
# 1. Load the GLB fresh each pass to reset positions
# ---------------------------------------------------------------------------
def load_fresh():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=glb_path)
    setup_lights_and_world()


# ---------------------------------------------------------------------------
# PASS 1: Alert (standing) — chunks in authored positions
# ---------------------------------------------------------------------------
load_fresh()
mins, maxs = get_scene_aabb()
center = [(mins[i] + maxs[i]) / 2 for i in range(3)]
size = max(maxs[i] - mins[i] for i in range(3)) or 2.5

place_camera("34", center, size)
render(out_prefix + "_alert_34.png")
place_camera("front", center, size)
render(out_prefix + "_alert_front.png")

# ---------------------------------------------------------------------------
# PASS 2: Dormant (pile) — chunks displaced by pile offsets
# ---------------------------------------------------------------------------
load_fresh()

for obj in bpy.context.scene.objects:
    if obj.type != "MESH":
        continue
    nl = obj.name.lower()
    rule = get_pile_offset(nl)
    if rule is None:
        continue
    pos_off, rot_off = rule
    obj.location.x += pos_off[0]
    obj.location.y += pos_off[2]   # glTF Y-up → Blender Z-up, pile Y maps to Blender Z
    obj.location.z += pos_off[1]
    obj.rotation_euler.x += math.radians(rot_off[0])
    obj.rotation_euler.y += math.radians(rot_off[1])
    obj.rotation_euler.z += math.radians(rot_off[2])

# Recompute AABB after pile displacement for correct camera framing
mins2, maxs2 = get_scene_aabb()
center2 = [(mins2[i] + maxs2[i]) / 2 for i in range(3)]
size2 = max(maxs2[i] - mins2[i] for i in range(3)) or 2.5
place_camera("34", center2, size2)
render(out_prefix + "_dormant_34.png")

# ---------------------------------------------------------------------------
# PASS 3: Mid-assembly — chunks halfway between pile and stand
# ---------------------------------------------------------------------------
load_fresh()

for obj in bpy.context.scene.objects:
    if obj.type != "MESH":
        continue
    nl = obj.name.lower()
    rule = get_pile_offset(nl)
    if rule is None:
        continue
    pos_off, rot_off = rule
    # t=0.5: halfway between pile (full offset) and stand (zero offset)
    t = 0.5
    obj.location.x += pos_off[0] * (1 - t)
    obj.location.y += pos_off[2] * (1 - t)
    obj.location.z += pos_off[1] * (1 - t)
    obj.rotation_euler.x += math.radians(rot_off[0] * (1 - t))
    obj.rotation_euler.y += math.radians(rot_off[1] * (1 - t))
    obj.rotation_euler.z += math.radians(rot_off[2] * (1 - t))

mins3, maxs3 = get_scene_aabb()
center3 = [(mins3[i] + maxs3[i]) / 2 for i in range(3)]
size3 = max(maxs3[i] - mins3[i] for i in range(3)) or 2.5
place_camera("34", center3, size3)
render(out_prefix + "_mid_34.png")

print("ALL PASSES DONE")
