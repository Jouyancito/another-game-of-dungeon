# _glb_truth_render.py — render a GLB with ONLY what ships inside it.
#
# Why this exists (2026-07-29): the mob build scripts shade their hero stills
# with Blender shader-node graphs (TexNoise / TexVoronoi / Mix). Those graphs
# are procedural — glTF cannot express them, so `export_scene.gltf` drops them
# and writes a flat base color instead. A GLB probe confirmed it: slime,
# king_slime, snake, wasp, turtle and bird all export with NO COLOR_0 attribute
# and NO textures. Their showcase renders therefore show detail the game never
# receives, which makes those renders unusable as a quality verdict.
#
# This tool closes that gap. It imports the GLB and renders it with the
# materials that are actually inside the file, under an even neutral
# environment with view_transform='Standard' — the "viewer-faithful" setup the
# art-ref-critic skill defines as ground truth. What you see here is what
# Godot gets.
#
# Usage:
#   blender.exe --background --python game/tools/blender/_glb_truth_render.py -- \
#       --glb path/a.glb path/b.glb --outdir game/tools/blender/_truth/
#
# Optional: --no-silhouette to drop the 1.75m player scale reference.

import bpy
import os
import sys
import math

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _ficha_common as ficha

RES = (1024, 1280)
SAMPLES = 96
BG_COLOR = (0.30, 0.22, 0.48, 1.0)  # style-contract ficha purple


def parse_args():
    argv = sys.argv
    argv = argv[argv.index("--") + 1:] if "--" in argv else []
    glbs, outdir, silhouette = [], None, True
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--glb":
            i += 1
            while i < len(argv) and not argv[i].startswith("--"):
                glbs.append(argv[i])
                i += 1
            continue
        if a == "--outdir":
            outdir = argv[i + 1]
            i += 2
            continue
        if a == "--no-silhouette":
            silhouette = False
            i += 1
            continue
        i += 1
    if not glbs:
        sys.exit("_glb_truth_render: need --glb <path> [<path> ...]")
    return glbs, outdir or ".", silhouette


def wipe_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.images,
                 bpy.data.armatures, bpy.data.actions):
        for item in list(coll):
            if item.users == 0:
                coll.remove(item)


def setup_world():
    """Even, directionless fill so nothing is flattered or buried by a key
    light — the GLB's own base colors have to carry the image on their own."""
    world = bpy.data.worlds.get("truth_world") or bpy.data.worlds.new("truth_world")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (0.55, 0.56, 0.60, 1.0)
    bg.inputs[1].default_value = 1.0
    bpy.context.scene.world = world


def setup_render(outdir):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = SAMPLES
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = RES
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    # Standard, NOT AgX/Filmic: a film transform desaturates flat colors into
    # pastel and would soften exactly the defect this tool exists to expose.
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    os.makedirs(outdir, exist_ok=True)


def add_backdrop():
    bpy.ops.mesh.primitive_plane_add(size=200.0, location=(0.0, 12.0, 0.0))
    plane = bpy.context.active_object
    plane.name = "truth_backdrop"
    plane.rotation_euler = (math.radians(90.0), 0.0, 0.0)
    mat = bpy.data.materials.new("truth_bg")
    mat.use_nodes = True
    emit = mat.node_tree.nodes.new("ShaderNodeEmission")
    emit.inputs[0].default_value = BG_COLOR
    emit.inputs[1].default_value = 1.0
    out = mat.node_tree.nodes["Material Output"]
    mat.node_tree.links.new(emit.outputs[0], out.inputs[0])
    plane.data.materials.append(mat)
    return plane


def add_fill_lights():
    """Three soft area lights, deliberately low-contrast. Enough to read form,
    not enough to invent surface interest the material does not have."""
    specs = [
        ("key", (3.0, -4.0, 4.0), 220.0, 4.0),
        ("fill", (-3.5, -3.0, 2.0), 90.0, 5.0),
        ("rim", (0.0, 4.5, 3.5), 130.0, 4.0),
    ]
    for name, loc, power, size in specs:
        light = bpy.data.lights.new(f"truth_{name}", type="AREA")
        light.energy = power
        light.size = size
        obj = bpy.data.objects.new(f"truth_{name}", light)
        obj.location = loc
        bpy.context.collection.objects.link(obj)
        direction = -obj.location.normalized()
        obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def imported_bbox(objects):
    xs, ys, zs = [], [], []
    for obj in objects:
        if obj.type != "MESH":
            continue
        for corner in obj.bound_box:
            world = obj.matrix_world @ __import__("mathutils").Vector(corner)
            xs.append(world.x)
            ys.append(world.y)
            zs.append(world.z)
    if not xs:
        return None
    return (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs))


def probe_materials(objects):
    """Report what the GLB actually carries, so the PNG is never the only
    evidence — a number next to every verdict (visual_gate house rule)."""
    has_vcol, mats, tris = False, set(), 0
    for obj in objects:
        if obj.type != "MESH":
            continue
        mesh = obj.data
        if mesh.color_attributes:
            has_vcol = True
        for slot in obj.material_slots:
            if slot.material:
                mats.add(slot.material.name)
        mesh.calc_loop_triangles()
        tris += len(mesh.loop_triangles)
    return has_vcol, sorted(mats), tris


def render_one(glb_path, outdir, want_silhouette):
    wipe_scene()
    setup_world()
    add_backdrop()
    add_fill_lights()

    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=glb_path)
    imported = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in imported if o.type == "MESH"]
    if not meshes:
        print(f"[truth] {glb_path}: no meshes imported, skipped")
        return None

    has_vcol, mats, tris = probe_materials(meshes)
    box = imported_bbox(meshes)
    x_min, x_max, y_min, y_max, z_min, z_max = box
    height = z_max - z_min

    sil = None
    if want_silhouette:
        sil_x = x_max + max(0.6, height * 0.9)
        sil = ficha.add_scale_silhouette(location=(sil_x, 0.0, z_min))
        sx0, sx1, sy0, sy1, sz0, sz1 = ficha.silhouette_bbox(
            location=(sil_x, 0.0, z_min), height=1.75)
        x_min, x_max = min(x_min, sx0), max(x_max, sx1)
        y_min, y_max = min(y_min, sy0), max(y_max, sy1)
        z_min, z_max = min(z_min, sz0), max(z_max, sz1)

    # frame_hero_camera only repositions along the rig's EXISTING view
    # direction — it needs a TRACK_TO constraint to actually aim, and a
    # non-degenerate cam->target vector to read the angle from. Without both,
    # the camera lands in the right spot still pointing at the floor.
    target = bpy.data.objects.new("truth_target", None)
    bpy.context.collection.objects.link(target)
    target.location = (0.0, 0.0, z_min + max(0.1, height * 0.5))

    cam_data = bpy.data.cameras.new("truth_cam")
    cam_data.lens = 50.0
    cam = bpy.data.objects.new("truth_cam", cam_data)
    bpy.context.collection.objects.link(cam)
    bpy.context.scene.camera = cam
    # Slight 3/4 so form reads instead of a flat front elevation.
    cam.location = (-1.6, -3.0, z_min + max(0.35, height * 1.1))
    track = cam.constraints.new(type="TRACK_TO")
    track.target = target
    track.track_axis = "TRACK_NEGATIVE_Z"
    track.up_axis = "UP_Y"

    ficha.frame_hero_camera(cam, target, x_min, x_max, y_min, y_max,
                            z_min, z_max, margin=1.18)
    bpy.context.view_layer.update()

    name = os.path.splitext(os.path.basename(glb_path))[0]
    out_png = os.path.join(outdir, f"{name}_TRUTH.png")
    bpy.context.scene.render.filepath = os.path.abspath(out_png)
    bpy.ops.render.render(write_still=True)

    if sil is not None:
        ficha.remove_scale_silhouette(sil)

    print(f"[truth] {name}: VCOL={has_vcol} mats={len(mats)} tris={tris} "
          f"height={height:.2f}m -> {out_png}")
    return {"name": name, "vcol": has_vcol, "mats": mats, "tris": tris,
            "height": height, "png": out_png}


def main():
    glbs, outdir, want_silhouette = parse_args()
    setup_render(outdir)
    results = [r for r in (render_one(g, outdir, want_silhouette) for g in glbs) if r]

    report = os.path.join(outdir, "_truth_report.txt")
    with open(report, "w", encoding="utf-8") as fh:
        fh.write("=== GLB truth render — what Godot actually receives ===\n\n")
        fh.write(f"{'asset':22s} {'VCOL':6s} {'mats':5s} {'tris':7s} height\n")
        for r in results:
            fh.write(f"{r['name']:22s} {str(r['vcol']):6s} {len(r['mats']):<5d} "
                     f"{r['tris']:<7d} {r['height']:.2f}m\n")
        fh.write("\nVCOL=False + 0 textures means the asset ships as flat base\n"
                 "color only: every procedural shader-node detail visible in the\n"
                 "build script's own showcase render is absent in game.\n")
    print(f"[truth] report -> {report}")


if __name__ == "__main__":
    main()
