# closeups.py — loads the just-built golem_guardian_wip.blend (already at
# STANDING rest pose) and renders extra tight-crop stills for the fix
# verification loop (crystal, eyes, arm seam, leg). Not part of the main
# build/export pipeline — throwaway QA tool, safe to delete/regenerate.
# Run: blender.exe --background --python-exit-code 1 --python closeups.py
import bpy
import os
from mathutils import Vector

OUT_DIR = os.path.dirname(os.path.abspath(__file__))
REN_DIR = os.path.join(OUT_DIR, "renders")

bpy.ops.wm.open_mainfile(filepath=os.path.join(OUT_DIR, "golem_guardian_wip.blend"))
scene = bpy.context.scene
cam = scene.camera
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.frame_set(1)

SHOTS = {
    "closeup_crystal": (Vector((0.0, -3.0, 2.1)), Vector((0.0, -0.4, 1.90))),
    "closeup_eyes":    (Vector((0.0, -2.3, 3.75)), Vector((0.0, -0.3, 3.72))),
    "closeup_arm":     (Vector((-3.0, -3.6, 1.6)), Vector((-1.7, 0.0, 1.4))),
    "closeup_leg":     (Vector((-2.2, -3.2, 0.5)), Vector((-0.9, 0.0, 0.6))),
}

for name, (cam_loc, target_loc) in SHOTS.items():
    cam.location = cam_loc
    for c in list(cam.constraints):
        cam.constraints.remove(c)
    tgt = bpy.data.objects.new(f"tgt_{name}", None)
    tgt.location = target_loc
    bpy.context.collection.objects.link(tgt)
    cam.constraints.new(type='TRACK_TO').target = tgt
    cam.data.lens = 85
    scene.render.filepath = os.path.join(REN_DIR, f"{name}.png")
    bpy.ops.render.render(write_still=True)
    print(f"[closeups] wrote {name}")

print("[closeups] DONE")
