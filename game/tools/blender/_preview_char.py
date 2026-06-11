"""Throwaway character-framed preview: eye-level 3/4 + pure side silhouette.
Usage: blender --background --python _preview_char.py -- <in.glb> <out_prefix>
Renders <out_prefix>_34.png (eye-level 3/4) and <out_prefix>_side.png (flat side silhouette).
"""
import bpy, sys, math, mathutils

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
glb_path, out_prefix = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb_path)

meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
mins = [1e9] * 3; maxs = [-1e9] * 3
for o in meshes:
    for c in o.bound_box:
        wc = o.matrix_world @ mathutils.Vector(c)
        for i in range(3):
            mins[i] = min(mins[i], wc[i]); maxs[i] = max(maxs[i], wc[i])
center = mathutils.Vector([(mins[i] + maxs[i]) / 2 for i in range(3)])
size = max(maxs[i] - mins[i] for i in range(3)) or 1.0

cam_data = bpy.data.cameras.new("cam")
cam = bpy.data.objects.new("cam", cam_data)
bpy.context.scene.collection.objects.link(cam)
bpy.context.scene.camera = cam

def look_at(obj, target):
    obj.rotation_euler = (target - obj.location).normalized().to_track_quat("-Z", "Y").to_euler()

# Lights: warm key + cool fill
key_d = bpy.data.lights.new("key", "SUN"); key_d.energy = 3.5; key_d.color = (1.0, 0.85, 0.6)
key = bpy.data.objects.new("key", key_d); bpy.context.scene.collection.objects.link(key)
key.rotation_euler = (math.radians(50), 0, math.radians(35))
fill_d = bpy.data.lights.new("fill", "SUN"); fill_d.energy = 1.1; fill_d.color = (0.5, 0.62, 0.85)
fill = bpy.data.objects.new("fill", fill_d); bpy.context.scene.collection.objects.link(fill)
fill.rotation_euler = (math.radians(60), 0, math.radians(-130))

world = bpy.data.worlds.new("w"); bpy.context.scene.world = world; world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.04, 0.05, 0.08, 1.0)

sc = bpy.context.scene
sc.render.engine = "CYCLES"; sc.cycles.samples = 24
sc.render.resolution_x = 560; sc.render.resolution_y = 640

d = size * 2.2
# Aim slightly below center so the figure stands tall in frame.
aim = mathutils.Vector((center.x, center.y * 0.92, center.z))

# --- eye-level 3/4 (low z so we don't flatten the standing figure) ---
cam.location = aim + mathutils.Vector((d * 0.62, -d * 1.0, d * 0.18))
look_at(cam, aim)
sc.render.filepath = out_prefix + "_34.png"
bpy.ops.render.render(write_still=True)

# --- front view (camera on +Y, the face side — shows eyes) ---
cam.location = aim + mathutils.Vector((d * 0.18, d * 1.05, d * 0.12))
look_at(cam, aim)
sc.render.filepath = out_prefix + "_front.png"
bpy.ops.render.render(write_still=True)

# --- pure side silhouette (the 20m readability test) ---
cam.location = aim + mathutils.Vector((d * 1.15, 0.0, d * 0.05))
look_at(cam, aim)
# Flatten lighting for a near-silhouette read.
key_d.energy = 1.5
sc.render.filepath = out_prefix + "_side.png"
bpy.ops.render.render(write_still=True)
print("RENDERED 34 + front + side")
