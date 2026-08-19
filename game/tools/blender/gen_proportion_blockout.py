"""Proportion blockout — three 1.80 m class silhouettes side by side.

This is a MEASURING TOOL, not a shippable asset. It exists to answer one
question with the eye instead of with a number: does the warrior/archer/mage
contexture spread read as three distinct classes at a glance?

Every figure is the same height (1.80 m) because the player collider is a
1.8 m capsule (base_player.gd stand_height, player.tscn CapsuleShape3D). Class
contexture therefore lives ENTIRELY in width and volume — never in stature.

Landmarks follow a 7.5-head canon (head = 1.80 / 7.5 = 0.24 m). Widths below
are FRONT-VIEW spans in metres, which is what a silhouette actually reads.

Run:
    blender.exe --background --factory-startup --python-exit-code 1 \
        --python game/tools/blender/gen_proportion_blockout.py

Outputs three renders to game/tools/blender/out/proportions/:
    proportions_front.png       lit front orthographic — judge proportion
    proportions_silhouette.png  pure black on white — judge readability
    proportions_threequarter.png  eye-level 3/4 — the honest angle
"""

import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

HEIGHT = 1.80
HEAD = HEIGHT / 7.5  # 0.24 m

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", "proportions")

# Vertical landmarks, in metres from the ground. Shared by all three classes —
# only widths change, so the eye compares like with like.
Y_FOOT_TOP = 0.07
Y_KNEE = 0.50
Y_CROTCH = 0.90
Y_WAIST = 1.10
Y_CHEST = 1.32
Y_SHOULDER = 1.47
Y_CHIN = 1.56
Y_TOP = 1.80

# --- The numbers under discussion -------------------------------------------
# Front-view widths (m). Change these, re-run, look again. That is the whole
# point of this file.
CLASSES = [
    {
        "name": "warrior",
        "tint": (0.115, 0.052, 0.030),
        "shoulder": 0.62,
        "chest_depth": 0.30,
        "waist": 0.38,
        "hip": 0.38,
        "neck": 0.160,
        "upper_arm": 0.135,
        "forearm": 0.110,
        "thigh": 0.200,
        "shin": 0.140,
    },
    {
        "name": "archer",
        "tint": (0.045, 0.075, 0.038),
        "shoulder": 0.50,
        "chest_depth": 0.24,
        "waist": 0.30,
        "hip": 0.34,
        "neck": 0.130,
        "upper_arm": 0.100,
        "forearm": 0.082,
        "thigh": 0.160,
        "shin": 0.112,
    },
    {
        "name": "mage",
        "tint": (0.040, 0.048, 0.105),
        "shoulder": 0.44,
        "chest_depth": 0.21,
        "waist": 0.27,
        "hip": 0.32,
        "neck": 0.115,
        "upper_arm": 0.085,
        "forearm": 0.070,
        "thigh": 0.140,
        "shin": 0.100,
    },
]

SPACING = 1.05  # metres between figure centres


def wipe_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def box(bm, center, size, colour, layer):
    """Add an axis-aligned box. center/size are (x, y, z) in metres."""
    matrix = Matrix.Translation(Vector(center)) @ Matrix.Diagonal(
        Vector((size[0], size[1], size[2], 1.0))
    )
    res = bmesh.ops.create_cube(bm, size=1.0, matrix=matrix)
    faces = {f for v in res["verts"] for f in v.link_faces}
    for face in faces:
        face.smooth = False
        for loop in face.loops:
            loop[layer] = (colour[0], colour[1], colour[2], 1.0)


def tapered(bm, z_lo, z_hi, w_lo, w_hi, d_lo, d_hi, x_off, colour, layer, steps=4):
    """Stack of boxes approximating a taper — enough for a blockout."""
    for i in range(steps):
        t0 = i / steps
        t1 = (i + 1) / steps
        zc = z_lo + (z_hi - z_lo) * (t0 + t1) / 2
        h = (z_hi - z_lo) / steps
        t = (t0 + t1) / 2
        w = w_lo + (w_hi - w_lo) * t
        d = d_lo + (d_hi - d_lo) * t
        box(bm, (x_off, 0.0, zc), (w, d, h), colour, layer)


def build_figure(spec, x_off):
    mesh = bpy.data.meshes.new("body_%s" % spec["name"])
    bm = bmesh.new()
    layer = bm.loops.layers.float_color.new("Col")
    c = spec["tint"]

    # torso: hips -> waist -> chest -> shoulders
    tapered(bm, Y_CROTCH, Y_WAIST, spec["hip"], spec["waist"],
            spec["chest_depth"] * 0.80, spec["chest_depth"] * 0.78, x_off, c, layer, 2)
    tapered(bm, Y_WAIST, Y_CHEST, spec["waist"], spec["shoulder"] * 0.86,
            spec["chest_depth"] * 0.78, spec["chest_depth"], x_off, c, layer, 3)
    tapered(bm, Y_CHEST, Y_SHOULDER, spec["shoulder"] * 0.86, spec["shoulder"],
            spec["chest_depth"], spec["chest_depth"] * 0.88, x_off, c, layer, 2)

    # neck + head
    box(bm, (x_off, 0.0, (Y_SHOULDER + Y_CHIN) / 2),
        (spec["neck"], spec["neck"], Y_CHIN - Y_SHOULDER), c, layer)
    head_h = Y_TOP - Y_CHIN
    box(bm, (x_off, 0.0, (Y_CHIN + Y_TOP) / 2),
        (head_h * 0.72, head_h * 0.82, head_h), c, layer)

    # arms — hang at the sides, slightly clear of the torso
    for side in (-1, 1):
        ax = x_off + side * (spec["shoulder"] / 2 + spec["upper_arm"] / 2 - 0.01)
        tapered(bm, Y_CHEST, Y_SHOULDER, spec["upper_arm"], spec["upper_arm"],
                spec["upper_arm"], spec["upper_arm"], ax, c, layer, 1)
        tapered(bm, Y_WAIST, Y_CHEST, spec["upper_arm"] * 0.92, spec["upper_arm"],
                spec["upper_arm"] * 0.92, spec["upper_arm"], ax, c, layer, 2)
        tapered(bm, Y_CROTCH - 0.04, Y_WAIST, spec["forearm"], spec["upper_arm"] * 0.92,
                spec["forearm"], spec["upper_arm"] * 0.92, ax, c, layer, 2)
        # hand
        box(bm, (ax, 0.0, Y_CROTCH - 0.13),
            (spec["forearm"] * 1.05, spec["forearm"] * 0.65, 0.18), c, layer)

    # legs
    for side in (-1, 1):
        lx = x_off + side * (spec["hip"] / 2 - spec["thigh"] / 2)
        tapered(bm, Y_KNEE, Y_CROTCH, spec["shin"] * 1.05, spec["thigh"],
                spec["shin"] * 1.05, spec["thigh"], lx, c, layer, 3)
        tapered(bm, Y_FOOT_TOP, Y_KNEE, spec["shin"] * 0.72, spec["shin"],
                spec["shin"] * 0.72, spec["shin"], lx, c, layer, 3)
        box(bm, (lx, -0.035, Y_FOOT_TOP / 2),
            (spec["shin"] * 0.86, 0.26, Y_FOOT_TOP), c, layer)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("fig_%s" % spec["name"], mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def build_ruler(x_off):
    """A 1.80 m rod with a tick every head (0.24 m) — the scale witness."""
    mesh = bpy.data.meshes.new("ruler")
    bm = bmesh.new()
    layer = bm.loops.layers.float_color.new("Col")
    red = (0.28, 0.020, 0.016)
    box(bm, (x_off, 0.0, HEIGHT / 2), (0.028, 0.028, HEIGHT), red, layer)
    n = 0
    while n * HEAD <= HEIGHT + 1e-6:
        box(bm, (x_off - 0.055, 0.0, n * HEAD), (0.085, 0.030, 0.010), red, layer)
        n += 1
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("ruler", mesh)
    bpy.context.collection.objects.link(obj)
    return obj


def vcol_material(name="blockout"):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.85
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    nt.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def flat_material(name, rgb):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (rgb[0], rgb[1], rgb[2], 1.0)
    bsdf.inputs["Roughness"].default_value = 1.0
    return mat


def add_ground():
    mesh = bpy.data.meshes.new("ground")
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=14.0)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("ground", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(flat_material("ground_mat", (0.055, 0.052, 0.048)))
    return obj


def add_lights():
    key = bpy.data.lights.new("key", type="AREA")
    key.energy = 420.0
    key.size = 3.0
    key.color = (1.0, 0.86, 0.70)
    ko = bpy.data.objects.new("key", key)
    ko.location = (-2.6, -3.4, 3.4)
    ko.rotation_euler = (math.radians(52), 0.0, math.radians(-38))
    bpy.context.collection.objects.link(ko)

    fill = bpy.data.lights.new("fill", type="AREA")
    fill.energy = 110.0
    fill.size = 5.0
    fill.color = (0.62, 0.72, 1.0)
    fo = bpy.data.objects.new("fill", fill)
    fo.location = (3.4, -3.0, 2.0)
    fo.rotation_euler = (math.radians(72), 0.0, math.radians(46))
    bpy.context.collection.objects.link(fo)

    rim = bpy.data.lights.new("rim", type="AREA")
    rim.energy = 260.0
    rim.size = 2.0
    rim.color = (1.0, 0.93, 0.84)
    ro = bpy.data.objects.new("rim", rim)
    ro.location = (0.0, 4.2, 2.8)
    ro.rotation_euler = (math.radians(115), 0.0, 0.0)
    bpy.context.collection.objects.link(ro)


def set_world(rgb, strength=1.0):
    world = bpy.data.worlds.new("w") if not bpy.data.worlds else bpy.data.worlds[0]
    bpy.context.scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (rgb[0], rgb[1], rgb[2], 1.0)
    bg.inputs["Strength"].default_value = strength


def make_camera(name, location, rotation, ortho_scale=None):
    cam = bpy.data.cameras.new(name)
    if ortho_scale is not None:
        cam.type = "ORTHO"
        cam.ortho_scale = ortho_scale
    else:
        cam.lens = 55.0
    obj = bpy.data.objects.new(name, cam)
    obj.location = location
    obj.rotation_euler = rotation
    bpy.context.collection.objects.link(obj)
    return obj


def render(path, camera):
    scene = bpy.context.scene
    scene.camera = camera
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("WROTE %s" % path)


def main():
    wipe_scene()
    os.makedirs(OUT_DIR, exist_ok=True)

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 48
    scene.cycles.use_denoising = True
    scene.cycles.seed = 12345
    scene.render.resolution_x = 1700
    scene.render.resolution_y = 1000
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "Standard"

    n = len(CLASSES)
    span = (n - 1) * SPACING
    figures = []
    for i, spec in enumerate(CLASSES):
        x = -span / 2 + i * SPACING
        figures.append(build_figure(spec, x))
    ruler = build_ruler(-span / 2 - 0.62)

    body_mat = vcol_material()
    for obj in figures + [ruler]:
        obj.data.materials.append(body_mat)

    ground = add_ground()
    add_lights()
    set_world((0.020, 0.023, 0.030), 1.0)

    centre_z = 0.92
    front_cam = make_camera(
        "front", (0.0, -9.0, centre_z), (math.radians(90), 0.0, 0.0), ortho_scale=3.55
    )
    # Eye-level 3/4 — the honest angle. Pulled back to 40 mm at ~6.6 m so the
    # heads stay inside frame; the first pass at 55 mm from 4.3 m decapitated
    # all three and the defect was only visible in the render, not the numbers.
    tq_cam = make_camera(
        "tq", (3.80, -5.40, 1.45), (math.radians(85.2), 0.0, math.radians(35.0))
    )
    tq_cam.data.lens = 40.0

    # --- measured truth: no verdict without a number ------------------------
    deps = bpy.context.evaluated_depsgraph_get()
    print("\n=== MEASURED (metres) ===")
    print("%-9s %8s %8s %8s" % ("class", "height", "widest", "shoulder"))
    for spec, obj in zip(CLASSES, figures):
        ev = obj.evaluated_get(deps)
        verts = [obj.matrix_world @ v.co for v in ev.data.vertices]
        zs = [v.z for v in verts]
        xs = [v.x for v in verts]
        sh = [v.x for v in verts if Y_CHEST + 0.02 <= v.z <= Y_SHOULDER]
        print("%-9s %8.3f %8.3f %8.3f" % (
            spec["name"], max(zs) - min(zs), max(xs) - min(xs),
            (max(sh) - min(sh)) if sh else float("nan"),
        ))
    print("=========================\n")

    render(os.path.join(OUT_DIR, "proportions_front.png"), front_cam)
    render(os.path.join(OUT_DIR, "proportions_threequarter.png"), tq_cam)

    # --- silhouette pass: the honest readability test -----------------------
    black = flat_material("sil_black", (0.0, 0.0, 0.0))
    for obj in figures + [ruler]:
        obj.data.materials.clear()
        obj.data.materials.append(black)
    ground.hide_render = True
    set_world((1.0, 1.0, 1.0), 1.6)
    scene.cycles.samples = 24
    render(os.path.join(OUT_DIR, "proportions_silhouette.png"), front_cam)


if __name__ == "__main__":
    main()
