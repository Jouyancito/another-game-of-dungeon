# canonical_board.py — render the shared judgement view set (_canonical_views)
# around the WHOLE guardian in its saved rest pose (standing) from
# golem_guardian_wip.blend. One PNG per view into renders/board/.
#
#   blender.exe --background --factory-startup --python-exit-code 1 \
#       golem_guardian_wip.blend --python canonical_board.py
#
# Judgement input only — never shipped. Uses the scene's own lights (the
# showcase rig baked into the wip .blend) so boards stay comparable run-to-run.
import math
import os
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from _canonical_views import VIEWS

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "renders", "board")
os.makedirs(OUT_DIR, exist_ok=True)

scene = bpy.context.scene
scene.render.resolution_x = 720
scene.render.resolution_y = 720
scene.render.image_settings.file_format = "PNG"

# Bounding box over every mesh except the ground plane (it would dominate the
# frame and push the golem into a corner).
mins = Vector((1e9, 1e9, 1e9))
maxs = Vector((-1e9, -1e9, -1e9))
for obj in bpy.data.objects:
    if obj.type != "MESH" or obj.name.lower().startswith(("ground", "plane")):
        continue
    for corner in obj.bound_box:
        w = obj.matrix_world @ Vector(corner)
        mins = Vector(map(min, mins, w))
        maxs = Vector(map(max, maxs, w))
center = (mins + maxs) / 2
size = max(maxs - mins)

cam_data = bpy.data.cameras.new("board_cam")
cam_data.lens = 50
cam = bpy.data.objects.new("board_cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam

for label, azim, elev, mult in VIEWS:
    dist = size * 1.9 * mult
    a = math.radians(azim)
    e = math.radians(elev)
    offset = Vector((
        math.sin(a) * math.cos(e),
        -math.cos(a) * math.cos(e),
        math.sin(e),
    )) * dist
    cam.location = center + offset
    direction = center - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(OUT_DIR, f"board_{label}.png")
    bpy.ops.render.render(write_still=True)
    print(f"[board] {label} -> {scene.render.filepath}")

print("[board] DONE")
