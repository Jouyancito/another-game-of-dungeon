"""preview_char_portrait -- head shots framed ON the head.

preview_char_head derives its camera height from the mesh top and then frames a
tall tile that includes shoulders, so the skull lands in the upper third and any
crop of it is guesswork. For judging a hairstyle the head has to fill the frame,
so this one aims at the CENTRE of the head and squares the tile.

The centre is measured from the `scalp` group plus the jaw joint when present,
not typed, so it still frames correctly after the skull dials move.
"""
import argparse
import importlib.util
import math
import os
import sys

import bpy
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location(
    "char_common", os.path.join(HERE, "_char_common.py"))
cc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(cc)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--label", default="p")
    ap.add_argument("--res", type=int, default=720)
    ap.add_argument("--dist", type=float, default=0.62)
    ap.add_argument("--lens", type=float, default=70.0)
    args = ap.parse_args(argv)

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    body = max(meshes, key=lambda o: len(o.data.vertices))
    W, _ = cc.morphed_coords(body)

    vg = body.vertex_groups.get("scalp")
    idx = [v.index for v in body.data.vertices
           if any(g.group == vg.index for g in v.groups)]
    S = W[idx]
    top = float(S[:, 2].max())
    jaw = body.vertex_groups.get("joint-jaw")
    if jaw is not None:
        ji = [v.index for v in body.data.vertices
              if any(g.group == jaw.index for g in v.groups)]
        chin = float(W[ji][:, 2].min())
    else:
        chin = top - 0.23
    cz = (top + chin) * 0.5
    cy = float(S[:, 1].mean())
    print("  cabeza: tope %.4f  mentón %.4f  centro z=%.4f y=%.4f" % (top, chin, cz, cy))

    spec = importlib.util.spec_from_file_location(
        "toonmod", os.path.join(HERE, "preview_char_toon.py"))
    toon = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(toon)
    for o in meshes:
        if not o.data.materials:
            o.data.materials.append(toon.toon_material(
                "prev_" + o.name, "#A8724E" if o is body else "#241A14"))

    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = args.res
    sc.render.resolution_y = args.res
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "Standard"
    sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.16, 0.17, 0.20, 1)
    sc.world.node_tree.nodes["Background"].inputs[1].default_value = 0.55

    for name, loc, rot, energy, size in [
        ("key", (-1.5, -1.7, 2.5), (52, 0, -40), 130.0, 1.6),
        ("fill", (1.9, -1.0, 1.8), (74, 0, 62), 45.0, 2.4),
        ("rim", (0.5, 2.0, 2.3), (58, 0, 178), 90.0, 1.8),
    ]:
        d = bpy.data.lights.new(name, type="AREA")
        d.energy, d.size = energy, size
        o = bpy.data.objects.new(name, d)
        sc.collection.objects.link(o)
        o.location = loc
        o.rotation_euler = tuple(math.radians(a) for a in rot)

    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam_data.lens = args.lens

    R = args.dist
    out_dir = os.path.abspath(args.out)
    os.makedirs(out_dir, exist_ok=True)
    shots = [
        ("frente", 0.0), ("tresq", 40.0), ("perfil", 90.0),
        ("tresq_atras", 138.0), ("nuca", 180.0),
    ]
    written = []
    for label, yaw in shots:
        a = math.radians(yaw)
        cam.location = (math.sin(a) * R, cy - math.cos(a) * R, cz)
        cam.rotation_euler = (math.radians(90), 0, a)
        path = os.path.join(out_dir, "%s_%s.png" % (args.label, label))
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        if os.path.isfile(path) and os.path.getsize(path) > 0:
            written.append(label)
    # Straight down, the view every eyeball judgement skips.
    cam.location = (0.0, cy, cz + R * 1.15)
    cam.rotation_euler = (0.0, 0.0, 0.0)
    path = os.path.join(out_dir, "%s_cenital.png" % args.label)
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    if os.path.isfile(path):
        written.append("cenital")
    print("  escritos %d: %s" % (len(written), ", ".join(written)))
    if len(written) != len(shots) + 1:
        raise SystemExit("faltan renders")


if __name__ == "__main__":
    main()
