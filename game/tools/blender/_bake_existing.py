"""Bake procedural shading to vertex colour on an already-built .blend, re-export.

Proof of concept for the fix in _bake_vcol.py, run against the *_wip.blend that
the build scripts already leave behind -- so the generators stay untouched until
the approach is proven on a real mob.
"""
import argparse
import importlib.util
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("bv", os.path.join(HERE, "_bake_vcol.py"))
bv = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bv)

argv = sys.argv[sys.argv.index("--") + 1:]
ap = argparse.ArgumentParser()
ap.add_argument("--glb", required=True)
ap.add_argument("--label", default="mob")
ap.add_argument("--need", type=int, default=600)
args = ap.parse_args(argv)

meshes = [o for o in bpy.data.objects if o.type == "MESH" and len(o.data.polygons)]
print("  mallas: %s" % ", ".join("%s(%d)" % (o.name, len(o.data.vertices)) for o in meshes))
done = 0
for o in meshes:
    if bv.bake_and_report(o, "%s/%s" % (args.label, o.name), need=args.need):
        done += 1
print("  bakeadas %d de %d" % (done, len(meshes)))
if done == 0:
    raise SystemExit("ninguna malla bakeada -- no hay nada que exportar distinto")

bpy.ops.export_scene.gltf(filepath=os.path.abspath(args.glb), export_format="GLB",
                          use_selection=False, export_animations=True,
                          export_morph=True, export_animation_mode="NLA_TRACKS")
print("  glb -> %s" % args.glb)
