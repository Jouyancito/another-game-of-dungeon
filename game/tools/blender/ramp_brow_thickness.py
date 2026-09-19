"""ramp_brow_thickness -- N heads, each with a thicker brow, side by side.

The generated brow measures 6.8 mm against Farkas's ~5.5 mm, so by the number
it is already in range -- yet it reads as plucked. That gap between "correct"
and "looks right" is exactly what a ramp is for, and the value is Joan's call:
every thickness I have picked by hand this project came in wrong, five for
five.

Rendered WITH LIGHT, always. A brow is a mass that catches the key light; flat
shading hides the only thing being judged.

    blender -b brows_source.blend --python-exit-code 1 \
        --python ramp_brow_thickness.py -- --out ramp.blend --strip strip.png
"""
from __future__ import annotations

import argparse
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy
import numpy as np

from _char_common import morphed_coords
from gen_char_brows import build_strip, glue_to_surface
from fix_face_features import skin_material, light_scene


def brow_material():
    m = bpy.data.materials.new("brow")
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Base Color"].default_value = (0.022, 0.016, 0.012, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.95
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.12
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return m


def eye_anchor(obj):
    W, _ = morphed_coords(obj)
    gi = {g.name: g.index for g in obj.vertex_groups}

    def centre(gname):
        k = gi[gname]
        idx = [v.index for v in obj.data.vertices
               if any(e.group == k and e.weight > 0.01 for e in v.groups)]
        return W[idx].mean(axis=0)

    cl, cr = centre("helper-l-eye"), centre("helper-r-eye")
    ipd = float(abs(cl[0] - cr[0]))
    pupil = (0.0, 0.5 * (cl[1] + cr[1]), 0.5 * (cl[2] + cr[2]))
    return ipd, pupil


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", default="face_m100")
    ap.add_argument("--out", required=True)
    ap.add_argument("--strip", required=True)
    ap.add_argument("--steps", type=int, default=5)
    ap.add_argument("--min", type=float, default=1.0)
    ap.add_argument("--max", type=float, default=2.2)
    ap.add_argument("--gap", type=float, default=0.28)
    args = ap.parse_args(argv)

    src = bpy.data.objects.get(args.obj)
    if src is None:
        raise SystemExit("no object %r -- have %s"
                         % (args.obj, sorted(o.name for o in bpy.data.objects
                                             if o.type == "MESH")))
    # The source blend already carries brows at thickness 1.0; they would sit
    # under every variant. Everything but the head goes.
    for o in list(bpy.data.objects):
        if o is not src:
            bpy.data.objects.remove(o, do_unlink=True)
    src.location = (0, 0, 0)
    bpy.context.view_layer.update()

    skin = skin_material()
    brow_mat = brow_material()
    ks = ([args.min] if args.steps < 2 else
          [args.min + (args.max - args.min) * i / (args.steps - 1)
           for i in range(args.steps)])
    print("")
    print("  thickness %.2f .. %.2f in %d steps" % (ks[0], ks[-1], len(ks)))

    heads = []
    for i, k in enumerate(ks):
        head = src.copy()
        head.data = src.data.copy()
        head.name = "brow_t%03d" % round(k * 100)
        bpy.context.scene.collection.objects.link(head)
        head.location.x = (i - (len(ks) - 1) / 2.0) * args.gap
        head.data.materials.clear()
        head.data.materials.append(skin)
        bpy.context.view_layer.update()

        ipd, pupil = eye_anchor(head)
        pupil = (head.location.x, pupil[1], pupil[2])
        made = []
        for side, nm in ((1.0, "%s_l" % head.name), (-1.0, "%s_r" % head.name)):
            b = build_strip(nm, side, ipd, pupil, k)
            # build_strip lays the strip out around x=0, so shift it onto this
            # head before gluing -- otherwise every brow snaps to the centre
            # head and four of the five variants come out bare.
            for v in b.data.vertices:
                v.co.x += head.location.x
            b.data.update()
            glue_to_surface(b, head)
            b.data.materials.append(brow_mat)
            sol = b.modifiers.new("thick", "SOLIDIFY")
            sol.thickness = 0.0016 * k
            sol.offset = 1.0
            made.append(b)
        hz = np.array([b.data.vertices[0].co.z for b in made]).mean()
        print("    %-12s x=%+.2f  thickness %.2f" % (head.name,
                                                     head.location.x, k))
        heads.append(head)

    bpy.data.objects.remove(src, do_unlink=True)

    sc = bpy.context.scene
    dg = bpy.context.evaluated_depsgraph_get()
    ev = heads[0].evaluated_get(dg)
    me = ev.to_mesh()
    top = max((heads[0].matrix_world @ v.co).z for v in me.vertices)
    ev.to_mesh_clear()
    hz = top - 0.112
    light_scene(sc, hz)

    xs = [h.location.x for h in heads]
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = 300 * len(heads)
    sc.render.resolution_y = 300
    sc.view_settings.view_transform = "Filmic"
    cd = bpy.data.cameras.new("c")
    cam = bpy.data.objects.new("c", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cd.type = "ORTHO"
    cd.ortho_scale = (max(xs) - min(xs)) + args.gap
    cam.location = ((max(xs) + min(xs)) / 2.0, -2.0, hz)
    cam.rotation_euler = (math.radians(90), 0.0, 0.0)
    strip = os.path.abspath(args.strip)
    sc.render.filepath = strip
    bpy.ops.render.render(write_still=True)
    if not (os.path.isfile(strip) and os.path.getsize(strip) > 0):
        raise SystemExit("strip not written")
    print("  strip -> %s" % strip)

    bpy.ops.wm.save_as_mainfile(filepath=bpy.path.abspath(args.out))
    print("  saved %s" % args.out)


if __name__ == "__main__":
    main()
