"""preview_char_head — head close-ups of whatever is in a character .blend.

Exists because gen_char_hair_plates.py builds geometry and renders nothing, so
a run that "succeeded" proves only that the script did not crash. Hair, brows
and beard are silhouette features: the only evidence that they landed is a
picture of the head from several angles.

Camera height is derived from the mesh, not typed, so it still frames the head
after the skull dials move -- which they did five times in one session.
"""
import argparse
import importlib.util
import math
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))


def eval_top(obj):
    dg = bpy.context.evaluated_depsgraph_get()
    ev = obj.evaluated_get(dg)
    me = ev.to_mesh()
    mw = ev.matrix_world
    zs = [(mw @ v.co).z for v in me.vertices]
    ev.to_mesh_clear()
    return max(zs)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--label", default="head")
    ap.add_argument("--res", type=int, default=560)
    args = ap.parse_args(argv)

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("no hay mallas en el archivo")
    body = max(meshes, key=lambda o: len(o.data.vertices))
    top = max(eval_top(o) for o in meshes)
    print("  mallas: %s" % ", ".join("%s(%d)" % (o.name, len(o.data.vertices))
                                     for o in meshes))
    print("  tope de la cabeza z=%.4f" % top)

    spec = importlib.util.spec_from_file_location(
        "toonmod", os.path.join(HERE, "preview_char_toon.py"))
    toon = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(toon)

    # Anything without a material renders as default grey and the plates would
    # be invisible against skin; give each mesh the toon material it needs.
    for o in meshes:
        if not o.data.materials:
            hexcol = "#241A14" if o is not body else "#A8724E"
            o.data.materials.append(toon.toon_material("prev_" + o.name, hexcol))

    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = args.res
    sc.render.resolution_y = int(args.res * 1.25)
    sc.view_settings.view_transform = "Standard"
    sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.10, 0.11, 0.13, 1)

    for name, loc, rot, energy, size in [
        ("key", (-2.2, -2.6, 2.6), (58, 0, -40), 260.0, 2.2),
        ("fill", (2.6, -1.4, 1.7), (76, 0, 62), 70.0, 3.0),
        ("back", (0.4, 2.8, 2.2), (64, 0, 178), 120.0, 2.4),
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
    cam_data.type = "PERSP"
    cam_data.lens = 85.0

    hz = top - 0.115
    # ABSOLUTE. Under `-b <file.blend>` Blender resolves a relative
    # render.filepath against its own notion of the working directory, not the
    # shell's -- the first run of this script printed "6 tomas" and wrote zero
    # files anywhere on disk.
    out_dir = os.path.abspath(args.out)
    os.makedirs(out_dir, exist_ok=True)
    # Back and top included on purpose: the v1 handoff closed with "la nuca del
    # peinado NO esta juzgada -- no hay toma de atras".
    shots = [
        ("frente",  (0.0, -1.05, hz), (90, 0, 0)),
        ("tresq",   (0.66, -0.86, hz), (90, 0, 37)),
        ("perfil",  (1.05, 0.0, hz), (90, 0, 90)),
        ("nuca",    (0.0, 1.05, hz), (90, 0, 180)),
        ("tresq_atras", (0.72, 0.80, hz), (90, 0, 138)),
        ("cenital", (0.0, -0.42, top + 0.62), (28, 0, 0)),
    ]
    written = []
    for label, loc, rot in shots:
        cam.location = loc
        cam.rotation_euler = tuple(math.radians(a) for a in rot)
        path = os.path.join(out_dir, "%s_%s.png" % (args.label, label))
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        # Check the FILE, not the call. render() returning {'FINISHED'} says the
        # operator ran, not that a PNG exists -- which is exactly how this
        # reported six shots while writing none.
        if os.path.isfile(path) and os.path.getsize(path) > 0:
            written.append(label)
        else:
            print("  *** no se escribio: %s" % path)
    print("  renders -> %s" % out_dir)
    print("  escritos %d de %d: %s" % (len(written), len(shots), ", ".join(written)))
    if len(written) != len(shots):
        raise SystemExit("faltan renders -- no hay evidencia que juzgar")


if __name__ == "__main__":
    main()
