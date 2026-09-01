"""preview_zone -- orbit the ZONE being worked on, not the whole model.

WHY THIS EXISTS, stated plainly: Joan had already given this rule, more than
once, and it was not being followed. The warrior's face was judged almost
always from the front. He rotated the model himself, looked at a profile, and
found in one glance that the eyeball breaks through the eyelid -- a defect six
separate probes had missed, one of which measured protrusion along the WRONG
AXIS and reported "0 of 5672 vertices protrude".

His correction, verbatim: "tienes que siempre ver diferentes ángulos del
modelado, y si estás viendo algo específico de un modelado grande, tienes que
hacer zoom y definir el área que estás trabajando para que puedas tomar
diferentes vistas de lo que estás trabajando. Estás trabajando en la cara, no
me interesa ver cómo se ve la planta del pie."

So a judgement set is N views OF THE ZONE, framed on the zone, not N views of
the character at full height where the zone is forty pixels wide.

The orbit deliberately includes the angles that flatter least:
  - profile (90 deg), where anything protruding through a surface shows
  - three-quarter back, where glued-on geometry separates
  - from below, where floating objects reveal their gap

    blender -b scene.blend --python-exit-code 1 --python preview_zone.py -- \
        --obj face_m000 --anchor-group helper-l-eye --radius 0.05 \
        --out zone_eye

Anchor can be a vertex group (the usual case: helper-l-eye, lips, scalp) or
explicit world coordinates.
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

# label, azimuth (0 = front, +90 = the model's left), elevation
# Zone framing differs from the asset orbit, so this set is local -- but it is
# GUARDED by _canonical_views.require_views, which fails the run if an
# ungrateful angle goes missing. That guard exists because a sibling script
# copied this list, lost `bajo`, and a blank underside shipped (2026-08-25).
VIEWS = [
    ("frente", 0, 0),
    ("tresq", 40, 0),
    ("perfil", 90, 0),          # where protrusion shows
    ("tresq_atras", 130, 0),    # where stuck-on geometry separates
    ("alto", 30, 35),
    ("bajo", 30, -30),          # where floating objects reveal their gap
]
from _canonical_views import require_views  # noqa: E402
require_views(VIEWS)


def zone_centre(obj, group: str | None, coords):
    if coords:
        return np.array(coords, dtype=float)
    W, _ = morphed_coords(obj)
    gi = {g.name: g.index for g in obj.vertex_groups}
    k = gi.get(group)
    if k is None:
        raise SystemExit("no vertex group %r -- have: %s"
                         % (group, sorted(gi)[:20]))
    idx = [v.index for v in obj.data.vertices
           if any(e.group == k and e.weight > 0.01 for e in v.groups)]
    if not idx:
        raise SystemExit("group %r is empty" % group)
    return W[idx].mean(axis=0)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--obj", required=True)
    ap.add_argument("--anchor-group", default=None)
    ap.add_argument("--anchor-xyz", nargs=3, type=float, default=None)
    ap.add_argument("--radius", type=float, default=0.06,
                    help="half-width of the framing, in metres")
    ap.add_argument("--out", required=True)
    ap.add_argument("--res", type=int, default=640)
    ap.add_argument("--lit", action="store_true", default=True)
    args = ap.parse_args(argv)

    obj = bpy.data.objects.get(args.obj)
    if obj is None:
        raise SystemExit("no object %r -- have %s"
                         % (args.obj, sorted(o.name for o in bpy.data.objects
                                             if o.type == "MESH")))
    if not args.anchor_group and not args.anchor_xyz:
        raise SystemExit("give --anchor-group or --anchor-xyz")

    centre = zone_centre(obj, args.anchor_group, args.anchor_xyz)
    print("")
    print("  zone centre  x=%.4f y=%.4f z=%.4f   radius %.0f mm"
          % (centre[0], centre[1], centre[2], args.radius * 1000))

    sc = bpy.context.scene
    if args.lit:
        from fix_face_features import skin_material, light_scene
        if not obj.data.materials:
            obj.data.materials.append(skin_material())
        light_scene(sc, float(centre[2]))
    sc.render.engine = "BLENDER_EEVEE"
    sc.view_settings.view_transform = "Filmic"
    sc.render.resolution_x = sc.render.resolution_y = args.res

    cd = bpy.data.cameras.new("zone_cam")
    cam = bpy.data.objects.new("zone_cam", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cd.type = "ORTHO"
    cd.ortho_scale = args.radius * 2.0

    out_dir = os.path.abspath(args.out)
    os.makedirs(out_dir, exist_ok=True)
    written = []
    for label, az, el in VIEWS:
        a = math.radians(az)
        e = math.radians(el)
        d = 2.0
        cam.location = (
            centre[0] + d * math.sin(a) * math.cos(e),
            centre[1] - d * math.cos(a) * math.cos(e),
            centre[2] + d * math.sin(e),
        )
        cam.rotation_euler = (math.radians(90) - e, 0.0, a)
        path = os.path.join(out_dir, "%s.png" % label)
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        # Every shot is verified on disk. A run that prints six labels and
        # writes zero files happened before, on a relative render.filepath.
        if not (os.path.isfile(path) and os.path.getsize(path) > 0):
            raise SystemExit("shot %r was not written to %s" % (label, path))
        written.append(path)
        print("    %-12s az %+4d  el %+3d  -> %s" % (label, az, el,
                                                     os.path.basename(path)))

    print("")
    print("  %d/%d shots written to %s" % (len(written), len(VIEWS), out_dir))
    if len(written) != len(VIEWS):
        raise SystemExit("incomplete set -- do not judge from a partial orbit")


if __name__ == "__main__":
    main()
