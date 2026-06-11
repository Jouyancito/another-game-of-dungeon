"""Import a GLB and print its per-axis bounds (Blender space after import)."""
import bpy, sys, mathutils
glb = sys.argv[sys.argv.index("--") + 1:][0]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
mins = [1e9]*3; maxs = [-1e9]*3
for o in bpy.context.scene.objects:
    if o.type != "MESH": continue
    for c in o.bound_box:
        wc = o.matrix_world @ mathutils.Vector(c)
        for i in range(3):
            mins[i] = min(mins[i], wc[i]); maxs[i] = max(maxs[i], wc[i])
dims = [maxs[i]-mins[i] for i in range(3)]
print(f"BOUNDS x[{mins[0]:.2f},{maxs[0]:.2f}] y[{mins[1]:.2f},{maxs[1]:.2f}] z[{mins[2]:.2f},{maxs[2]:.2f}]")
print(f"DIMS  X={dims[0]:.2f}  Y={dims[1]:.2f}  Z={dims[2]:.2f}  (Blender Z=up)")
