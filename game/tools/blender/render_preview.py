"""Headless preview renderer: load a GLB, frame it, render a 3/4 PNG.
Usage: blender --background --python render_preview.py -- <input.glb> <output.png>
"""
import bpy, sys, os, math, mathutils

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
glb_path, out_path = argv[0], argv[1]

# Empty scene, import the GLB
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb_path)

meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
mins = [1e9] * 3
maxs = [-1e9] * 3
for o in meshes:
    for corner in o.bound_box:
        wc = o.matrix_world @ mathutils.Vector(corner)
        for i in range(3):
            mins[i] = min(mins[i], wc[i])
            maxs[i] = max(maxs[i], wc[i])
center = mathutils.Vector([(mins[i] + maxs[i]) / 2 for i in range(3)])
size = max(maxs[i] - mins[i] for i in range(3)) or 1.0

# Camera, 3/4 view, framed on the object
cam_data = bpy.data.cameras.new("cam")
cam = bpy.data.objects.new("cam", cam_data)
bpy.context.scene.collection.objects.link(cam)
bpy.context.scene.camera = cam
d = size * 2.4
cam.location = center + mathutils.Vector((d * 0.75, -d * 0.95, d * 0.65))
look = (center - cam.location).normalized()
cam.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()

# Warm key + cool fill (matches the game's D2 Act-1 hybrid)
key_d = bpy.data.lights.new("key", "SUN"); key_d.energy = 3.5; key_d.color = (1.0, 0.85, 0.6)
key = bpy.data.objects.new("key", key_d); bpy.context.scene.collection.objects.link(key)
key.rotation_euler = (math.radians(55), 0, math.radians(35))
fill_d = bpy.data.lights.new("fill", "SUN"); fill_d.energy = 1.2; fill_d.color = (0.5, 0.62, 0.85)
fill = bpy.data.objects.new("fill", fill_d); bpy.context.scene.collection.objects.link(fill)
fill.rotation_euler = (math.radians(60), 0, math.radians(-130))

# Dark cool background
world = bpy.data.worlds.new("w"); bpy.context.scene.world = world; world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.04, 0.05, 0.08, 1.0)

sc = bpy.context.scene
sc.render.engine = "CYCLES"
sc.cycles.samples = 24
sc.render.resolution_x = 640
sc.render.resolution_y = 640
sc.render.filepath = out_path
bpy.ops.render.render(write_still=True)
print("RENDERED:", out_path)
