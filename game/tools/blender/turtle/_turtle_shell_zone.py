"""_turtle_shell_zone -- orbit the CARAPACE, framed on the carapace.

The scute pattern and the growth rings are judged from directly above and from
a macro crop of a single plate. A three-quarter body shot cannot show whether
rings are concentric per plate or shared with the shell's centre, which is the
open question about this asset.

    blender -b turtle_wip.blend --factory-startup --python-exit-code 1 \
        --python _turtle_shell_zone.py -- --out renders/shell_zone

`orbit()` is the reusable half: any script that has just built a shell can hand
it the shell's world coordinates and get the same judgement set back.
"""
from __future__ import annotations

import argparse
import math
import os
import sys

import bpy


# The view set is CANONICAL and lives in _canonical_views.py -- this file used
# to carry its own copy and the copy lost the from-below view, which is how a
# blank underside shipped. See that module's docstring for the full case.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from _canonical_views import VIEWS, require_views  # noqa: E402

require_views(VIEWS)


def shell_verts(obj):
    """Vertices of the carapace: the upper shell, above the limb line."""
    mw = obj.matrix_world
    co = [mw @ v.co for v in obj.data.vertices]
    zs = sorted(c.z for c in co)
    # The carapace occupies the upper band of the silhouette; the limbs and
    # plastron sit below it. Take the top 55% of the height range.
    zmin, zmax = zs[0], zs[-1]
    cut = zmin + 0.45 * (zmax - zmin)
    up = [c for c in co if c.z >= cut]
    return up if up else co


def orbit(co, out, res=900, prefix=""):
    """Frame on the points `co`, render VIEWS, return the paths written."""
    cx = sum(c.x for c in co) / len(co)
    cy = sum(c.y for c in co) / len(co)
    cz = sum(c.z for c in co) / len(co)
    # A 95th percentile, not the maximum: neck and tail reach out at carapace
    # height and would otherwise frame the shot around them, which is exactly
    # the "the zone is forty pixels wide" failure this script exists to avoid.
    spread = sorted(max(abs(c.x - cx), abs(c.y - cy)) for c in co)
    radius = spread[int(0.95 * (len(spread) - 1))] * 1.10
    print("  zone centre  x=%.4f y=%.4f z=%.4f   radius %.0f mm"
          % (cx, cy, cz, radius * 1000))

    sc = bpy.context.scene
    try:
        sc.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        sc.render.engine = "BLENDER_EEVEE"
    try:
        sc.eevee.taa_render_samples = 64
    except AttributeError:
        pass
    sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x = sc.render.resolution_y = res
    sc.render.film_transparent = False

    if not any(o.type == "LIGHT" for o in bpy.data.objects):
        ld = bpy.data.lights.new("key", type="AREA")
        ld.energy, ld.size = 160.0, 1.6
        lo = bpy.data.objects.new("key", ld)
        lo.location = (0.9, -1.1, 1.6)
        lo.rotation_euler = (math.radians(38), 0, math.radians(38))
        sc.collection.objects.link(lo)

    cd = bpy.data.cameras.new("zone_cam")
    cam = bpy.data.objects.new("zone_cam", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cd.type = "ORTHO"

    out_dir = os.path.abspath(out)
    os.makedirs(out_dir, exist_ok=True)
    written = []
    for label, az, el, mult in VIEWS:
        a, e = math.radians(az), math.radians(el)
        cd.ortho_scale = radius * 2.0 * mult
        d = 3.0
        cam.location = (cx + d * math.sin(a) * math.cos(e),
                        cy - d * math.cos(a) * math.cos(e),
                        cz + d * math.sin(e))
        cam.rotation_euler = (math.radians(90) - e, 0.0, a)
        path = os.path.join(out_dir, "%s%s.png" % (prefix, label))
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        # Every shot is verified on disk. A run that printed six labels and
        # wrote zero files happened before, on a relative render.filepath.
        if not (os.path.isfile(path) and os.path.getsize(path) > 0):
            raise SystemExit("shot %r was not written" % label)
        written.append(path)
        print("    %-14s az %+4d  el %+3d  -> %s"
              % (label, az, el, os.path.basename(path)))

    print("")
    print("  %d/%d shots -> %s" % (len(written), len(VIEWS), out_dir))
    if len(written) != len(VIEWS):
        raise SystemExit("incomplete orbit -- do not judge from a partial set")
    return written


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--res", type=int, default=900)
    args = ap.parse_args(argv)

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("no mesh in the file")
    obj = max(meshes, key=lambda o: len(o.data.vertices))
    print("  object %r  %d verts" % (obj.name, len(obj.data.vertices)))

    orbit(shell_verts(obj), args.out, args.res)


if __name__ == "__main__":
    main()
