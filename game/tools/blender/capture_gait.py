"""capture_gait -- render one animation clip as a dense frame strip.

Motion cannot be judged from a still, and it cannot be judged from four sparse
frames either: that is the documented failure from the golem saga, where
"looks ok" was said repeatedly about a cycle that had no weight. The rule that
came out of it is 30+ frames of ONE clip, looked at in order.

For the turtle specifically there is a claim to check that a still cannot show:
the footfall order. A lateral-sequence gait puts ONE foot in the air at a time,
in the order front-left, hind-RIGHT, front-right, hind-left. A trot -- what this
build did before -- lifts diagonal PAIRS together. On a strip of frames the two
look completely different, and on a single frame they look the same.

    blender -b <mob>_wip.blend --python capture_gait.py -- --clip move-loop --out <dir>
"""
import argparse
import math
import os
import sys

import bpy


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    ap = argparse.ArgumentParser()
    ap.add_argument("--clip", default="move-loop")
    ap.add_argument("--out", required=True)
    ap.add_argument("--frames", type=int, default=16)
    ap.add_argument("--res", type=int, default=320)
    args = ap.parse_args(argv)

    obj = max((o for o in bpy.data.objects if o.type == "MESH"),
              key=lambda o: len(o.data.vertices))

    # The clip lives in an NLA track; mute every other track so only this one
    # drives the mesh, then scrub it frame by frame.
    tracks = []
    for holder in (obj.animation_data, obj.data.shape_keys.animation_data
                   if obj.data.shape_keys else None):
        if holder is None:
            continue
        for tr in holder.nla_tracks:
            tracks.append(tr)
            tr.mute = args.clip not in tr.name
    live = [t for t in tracks if not t.mute]
    if not live:
        raise SystemExit("no encuentro el clip '%s' en las pistas NLA: %s"
                         % (args.clip, [t.name for t in tracks]))
    lo = int(min(s.frame_start for t in live for s in t.strips))
    hi = int(max(s.frame_end for t in live for s in t.strips))
    print("  clip '%s' en frames %d-%d (%d pistas)" % (args.clip, lo, hi, len(live)))

    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x = args.res
    sc.render.resolution_y = args.res
    sc.view_settings.view_transform = "Standard"
    sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.20, 0.21, 0.24, 1)
    sc.world.node_tree.nodes["Background"].inputs[1].default_value = 0.9

    for loc, rot, energy in (((-1.4, -1.6, 1.4), (58, 0, -41), 90.0),
                             ((1.8, -1.0, 1.1), (72, 0, 60), 30.0)):
        d = bpy.data.lights.new("l", type="AREA")
        d.energy, d.size = energy, 2.0
        o = bpy.data.objects.new("l", d)
        sc.collection.objects.link(o)
        o.location = loc
        o.rotation_euler = tuple(math.radians(a) for a in rot)

    cam_d = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_d)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam_d.lens = 52.0
    # Three-quarter FRONT-HIGH: the angle where all four feet are visible at
    # once. A pure side view hides the far pair, which is exactly the pair you
    # need to see to tell a lateral sequence from a trot.
    cam.location = (0.95, -1.05, 0.62)
    cam.rotation_euler = (math.radians(68), 0.0, math.radians(42))

    os.makedirs(args.out, exist_ok=True)
    n = args.frames
    for k in range(n):
        f = lo + int(round((hi - lo) * k / n))
        sc.frame_set(f)
        sc.render.filepath = os.path.join(args.out, "gait_%02d.png" % k)
        bpy.ops.render.render(write_still=True)
    print("  %d frames -> %s" % (n, args.out))


if __name__ == "__main__":
    main()
