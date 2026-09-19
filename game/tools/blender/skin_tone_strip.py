"""skin_tone_strip — render the same character across candidate skin tones.

A skin tone is a decision, not a deduction, so the useful thing is not for me
to pick one and defend it -- it is to put the real options side by side under
the game's own shading and let the choice be made by looking.

Rendered through the toon material from preview_char_toon, because a tone that
reads well under a soft studio light can fall apart once a 3-band ramp
quantises it. The face gets its own frame: skin tone reads on the face, and a
full-body shot at thumbnail size hides the difference between neighbours.

    blender.exe -b <char.blend> --python skin_tone_strip.py -- \
        --obj char_warrior_male_mh --out <dir>
"""

import argparse
import importlib.util
import math
import os
import sys

import bpy

TONES = [
    ("clara",   "#D9A88A"),
    ("media_c", "#C08E6A"),
    ("media",   "#A8724E"),
    ("actual",  "#96613F"),
    ("oscura",  "#7A4B30"),
]


def load_toon():
    here = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location(
        "toonmod", os.path.join(here, "preview_char_toon.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args(argv)

    toonmod = load_toon()
    obj = bpy.data.objects.get(args.obj)
    if obj is None:
        raise SystemExit("no existe %r" % args.obj)

    for ob in list(bpy.data.objects):
        if ob is not obj and ob.type in {"MESH", "LIGHT", "CAMERA"}:
            bpy.data.objects.remove(ob, do_unlink=True)

    bpy.ops.object.light_add(type="AREA", location=(2.2, -3.0, 3.0))
    key = bpy.context.object
    key.data.energy = 600
    key.data.size = 3.0
    key.rotation_euler = (math.radians(48), 0, math.radians(34))

    world = bpy.data.worlds.new("w")
    bpy.context.scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.07, 0.08, 0.10, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.35

    x0, x1, z0, z1 = toonmod.eval_bounds(obj)
    mid = (z0 + z1) / 2.0
    face_z = z0 + (z1 - z0) * 0.925

    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "Standard"

    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam

    # Absolute output path: a relative one made an earlier run print four
    # successful "render ->" lines into an empty directory, because makedirs
    # and Blender's filepath resolve against different bases.
    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)

    for name, hexcol in TONES:
        obj.data.materials.clear()
        obj.data.materials.append(toonmod.toon_material("skin_" + name, hexcol))

        # face
        sc.render.resolution_x, sc.render.resolution_y = 430, 520
        cam_data.type = "PERSP"
        cam_data.lens = 85.0
        cam.location = (0.40, -1.00, face_z + 0.02)
        cam.rotation_euler = tuple(math.radians(a) for a in (86, 0, 21))
        sc.render.filepath = os.path.join(out, "tone_%s_face.png" % name)
        bpy.ops.render.render(write_still=True)

        # body
        sc.render.resolution_x, sc.render.resolution_y = 430, 700
        cam_data.type = "ORTHO"
        cam_data.ortho_scale = max((z1 - z0), (x1 - x0) / (430 / 700.0)) * 1.10
        cam.location = (0.0, -4.0, mid)
        cam.rotation_euler = (math.radians(90), 0, 0)
        sc.render.filepath = os.path.join(out, "tone_%s_body.png" % name)
        bpy.ops.render.render(write_still=True)

        print("  %-8s %s" % (name, hexcol))

    print("\n  %d tonos -> %s" % (len(TONES), out))


if __name__ == "__main__":
    main()
