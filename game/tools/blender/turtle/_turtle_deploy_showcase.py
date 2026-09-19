"""_turtle_deploy_showcase -- judge the GLB THE GAME LOADS, from many angles.

The build script's own stills say nothing about what Godot receives: shader
graphs do not survive glTF, and the deployed copy can be an older build than
the one just rendered -- both happened to this asset. So this imports the
DEPLOYED file, puts the 1.75 m player reference beside it, and orbits it.

    blender -b --factory-startup --python-exit-code 1 \
        --python _turtle_deploy_showcase.py -- \
        --glb ../../../assets/art/piso1_pradera/enemies/small/turtle_dp_01.glb \
        --out renders/deploy_showcase
"""
from __future__ import annotations

import argparse
import math
import os
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path[:0] = [_HERE, os.path.dirname(_HERE)]

import bpy

import _ficha_common as ficha
from _turtle_shell_zone import orbit


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--glb", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--res", type=int, default=900)
    args = ap.parse_args(argv)

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)

    glb = os.path.abspath(args.glb)
    if not os.path.isfile(glb):
        raise SystemExit("no such GLB: %s" % glb)
    bpy.ops.import_scene.gltf(filepath=glb)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("the GLB imported no meshes")

    # What is actually inside the file. A mob with no COLOR_0 and one material
    # draws white in Godot however good the build render looked.
    co, tris, vcol, mats = [], 0, False, set()
    for o in meshes:
        mw = o.matrix_world
        co += [mw @ v.co for v in o.data.vertices]
        tris += len(o.data.loop_triangles) or sum(
            max(0, len(p.vertices) - 2) for p in o.data.polygons)
        if o.data.color_attributes:
            vcol = True
        mats |= {m.name for m in o.data.materials if m}
    zs = [c.z for c in co]
    height = max(zs) - min(zs)
    print("")
    print("  %s" % os.path.basename(glb))
    print("  VCOL %s   materials %d   tris %d   height %.3f m"
          % (vcol, len(mats), tris, height))
    print("  animations: %s" % ", ".join(sorted(a.name for a in bpy.data.actions))
          or "  animations: NONE")

    if not vcol:
        raise SystemExit("no colour attribute in the deployed GLB -- Godot "
                         "would draw this mob flat")

    # The orbit runs WITHOUT the scale reference: a post parked beside the mob
    # sits between camera and subject at some azimuth -- at 90 deg it covered
    # this turtle completely. So the orbit judges form, and one dedicated
    # elevation judges size. Both are required; neither substitutes.
    orbit(co, args.out, args.res, prefix="showcase_")

    # Size gets its own frame. This pack shipped at bush scale once because
    # every render framed the asset alone.
    xs = [c.x for c in co]
    zs2 = [c.z for c in co]
    sil_at = (max(xs) + max(0.5, height * 1.6), 0.0, min(zs2))
    ficha.add_scale_silhouette(location=sil_at)

    sc = bpy.context.scene
    cam = sc.camera
    cx = (min(xs) + sil_at[0]) * 0.5
    span = (sil_at[0] - min(xs)) + 0.9
    cam.data.ortho_scale = span * 1.15
    cam.location = (cx, min(c.y for c in co) - 3.0, min(zs2) + 0.85)
    cam.rotation_euler = (math.radians(88), 0.0, 0.0)
    path = os.path.join(os.path.abspath(args.out), "showcase_escala.png")
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    if not (os.path.isfile(path) and os.path.getsize(path) > 0):
        raise SystemExit("the scale shot was not written")
    print("    %-14s 1.75 m reference  -> %s" % ("escala", os.path.basename(path)))


if __name__ == "__main__":
    main()
