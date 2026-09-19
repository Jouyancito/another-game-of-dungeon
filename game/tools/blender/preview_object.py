"""preview_object -- frame ANY mesh by its own bounding box and orbit it.

The character previewers (`preview_char_head`, `preview_char_portrait`) locate
the subject through human landmarks -- the `scalp` vertex group, the jaw joint.
Point one at a turtle and it dies on a zero-size array, which is what happened
on 2026-08-24.

This one knows nothing about what it is looking at: it measures the bounding
box, backs the camera off far enough to hold it, and orbits. Includes the
top-down view on purpose -- it is the one that shows whether four legs point
into four quadrants or all the same way, and it is the view every eyeball
judgement skips.

    blender -b <file.blend> --python preview_object.py -- --out <dir> [--label x]
"""
import argparse
import math
import os
import sys

import bpy
from mathutils import Vector


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--label", default="obj")
    ap.add_argument("--res", type=int, default=420)
    ap.add_argument("--margin", type=float, default=1.5)
    args = ap.parse_args(argv)

    meshes = [o for o in bpy.data.objects if o.type == "MESH" and len(o.data.polygons)]
    if not meshes:
        raise SystemExit("no hay mallas")

    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in meshes:
        for corner in o.bound_box:
            w = o.matrix_world @ Vector(corner)
            for i in range(3):
                lo[i] = min(lo[i], w[i])
                hi[i] = max(hi[i], w[i])
    centre = (lo + hi) * 0.5
    size = max(hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2])
    dist = size * args.margin * 2.0
    print("  bbox %.3f x %.3f x %.3f   centro (%.3f %.3f %.3f)  dist %.3f"
          % (hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2], *centre, dist))

    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = sc.render.resolution_y = args.res
    sc.view_settings.view_transform = "Standard"
    sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.19, 0.20, 0.23, 1)
    sc.world.node_tree.nodes["Background"].inputs[1].default_value = 0.85

    for loc, rot, energy in ((( -1.6, -1.8, 1.9), (54, 0, -41), 110.0),
                             ((  2.0, -1.1, 1.3), (72, 0, 60), 38.0),
                             ((  0.4,  2.1, 1.7), (62, 0, 178), 60.0)):
        d = bpy.data.lights.new("l", type="AREA")
        d.energy, d.size = energy, 2.2
        o = bpy.data.objects.new("l", d)
        sc.collection.objects.link(o)
        o.location = (loc[0] * size + centre[0], loc[1] * size + centre[1],
                      loc[2] * size + centre[2])
        o.rotation_euler = tuple(math.radians(a) for a in rot)

    cam_d = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_d)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam_d.lens = 60.0

    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)
    shots = [("frente", 0.0, 8.0), ("tresq", 42.0, 18.0), ("perfil", 90.0, 8.0),
             ("tresq_atras", 140.0, 18.0), ("nuca", 180.0, 8.0)]
    written = []
    for label, yaw, pitch in shots:
        a = math.radians(yaw)
        e = math.radians(pitch)
        cam.location = (centre[0] + math.sin(a) * dist * math.cos(e),
                        centre[1] - math.cos(a) * dist * math.cos(e),
                        centre[2] + dist * math.sin(e))
        cam.rotation_euler = (math.radians(90) - e, 0.0, a)
        path = os.path.join(out, "%s_%s.png" % (args.label, label))
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        if os.path.isfile(path):
            written.append(label)

    # Straight down. For a quadruped this is the view that settles whether the
    # legs occupy four quadrants or repeat one direction.
    cam.location = (centre[0], centre[1], centre[2] + dist)
    cam.rotation_euler = (0.0, 0.0, 0.0)
    path = os.path.join(out, "%s_cenital.png" % args.label)
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    if os.path.isfile(path):
        written.append("cenital")

    print("  escritos %d: %s" % (len(written), ", ".join(written)))
    if len(written) != len(shots) + 1:
        raise SystemExit("faltan renders -- no hay evidencia que juzgar")


if __name__ == "__main__":
    main()
