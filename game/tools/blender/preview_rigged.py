import bpy
import sys
import math

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

bpy.ops.import_scene.gltf(
    filepath='C:/Users/the_j/Desktop/Juego/DungeonParty-A/game/tools/blender/golem_rigged.glb',
    import_pack_images=False
)

armature = None
mesh_obj = None
for obj in bpy.context.scene.objects:
    if obj.type == 'ARMATURE':
        armature = obj
    elif obj.type == 'MESH':
        mesh_obj = obj

print(f'Armature found: {armature is not None}')
print(f'Mesh found: {mesh_obj is not None}')

if armature:
    print(f'Bone count: {len(armature.data.bones)}')
    for bone in armature.data.bones:
        head = armature.matrix_world @ bone.head_local
        parent_name = bone.parent.name if bone.parent else 'ROOT'
        print(f'  {bone.name:10s} parent={parent_name:10s} world_z={head.z:.3f} world_x={head.x:.3f}')

scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 4
scene.render.resolution_x = 512
scene.render.resolution_y = 768
scene.render.filepath = 'C:/Users/the_j/Desktop/Juego/DungeonParty-A/game/tools/blender/golem_rigged_preview.png'
scene.render.image_settings.file_format = 'PNG'

cam_data = bpy.data.cameras.new('PreviewCam')
cam_obj = bpy.data.objects.new('PreviewCam', cam_data)
scene.collection.objects.link(cam_obj)
scene.camera = cam_obj
cam_obj.location = (4.5, -5.0, 3.0)
cam_obj.rotation_euler = (math.radians(75), 0, math.radians(40))

world = bpy.data.worlds['World']
world.use_nodes = True
world.node_tree.nodes['Background'].inputs[0].default_value = (0.1, 0.1, 0.15, 1.0)

light_data = bpy.data.lights.new('Key', type='SUN')
light_data.energy = 5
light_obj = bpy.data.objects.new('Key', light_data)
scene.collection.objects.link(light_obj)
light_obj.location = (4, -4, 10)
light_obj.rotation_euler = (math.radians(55), 0, math.radians(30))

if mesh_obj:
    mat = bpy.data.materials.new('Preview')
    mat.diffuse_color = (0.45, 0.42, 0.38, 1.0)
    mesh_obj.data.materials.clear()
    mesh_obj.data.materials.append(mat)

bpy.ops.render.render(write_still=True)
print('RENDER DONE')
