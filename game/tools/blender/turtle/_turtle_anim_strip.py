"""_turtle_anim_strip -- dense frame strip of ONE clip, plus the foot's trace.

Motion cannot be judged from four sparse frames, and it cannot be judged from
a render alone either. So this does both halves:

  * renders N frames of a single clip from a FIXED camera, so what moves in the
    strip is the animal and not the framing;
  * measures one foot's fore-aft travel per frame, which is the number that
    settles whether the walk has a stride at all. A foot that does not travel
    backwards while planted is sliding, however good the strip looks.

    blender -b --factory-startup --python-exit-code 1 \
        --python _turtle_anim_strip.py -- \
        --glb ../../../assets/art/piso1_pradera/enemies/small/turtle_dp_01.glb \
        --clip move-loop --out renders/anim_move --frames 32
"""
from __future__ import annotations

import argparse
import math
import os
import sys

import bpy


def set_clip(obj, name):
    """Put `name` on both the object and its shape keys, and return its range."""
    act = bpy.data.actions.get(name)
    if act is None:
        raise SystemExit("no action %r -- have %s"
                         % (name, [a.name for a in bpy.data.actions]))
    for holder in (obj, obj.data.shape_keys):
        if holder is None:
            continue
        if holder.animation_data is None:
            holder.animation_data_create()
        # An NLA track left active evaluates on top of the action and silently
        # wins; mute every track so the strip shows the clip and nothing else.
        for tr in holder.animation_data.nla_tracks:
            tr.mute = True
        holder.animation_data.action = act
    return int(act.frame_range[0]), int(act.frame_range[1])


def foot_vertex(obj, front=True, left=True):
    """Index of the lowest vertex in one corner: that is a foot."""
    me = obj.data
    ys = [v.co.y for v in me.vertices]
    y_mid = 0.5 * (min(ys) + max(ys))
    best, best_z = None, 1e9
    for v in me.vertices:
        # The head points toward -Y, so the front of the body is -Y.
        if front and v.co.y > y_mid:
            continue
        if not front and v.co.y < y_mid:
            continue
        if left and v.co.x > 0.0:
            continue
        if not left and v.co.x < 0.0:
            continue
        if v.co.z < best_z:
            best, best_z = v.index, v.co.z
    if best is None:
        raise SystemExit("no vertex found in that corner")
    return best


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--glb", required=True)
    ap.add_argument("--clip", default="move-loop")
    ap.add_argument("--out", required=True)
    ap.add_argument("--frames", type=int, default=32)
    ap.add_argument("--res", type=int, default=520)
    ap.add_argument("--az", type=float, default=90.0, help="90 = pure profile")
    ap.add_argument("--el", type=float, default=6.0)
    args = ap.parse_args(argv)

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(args.glb))
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("the GLB imported no meshes")
    obj = max(meshes, key=lambda o: len(o.data.vertices))
    if obj.data.shape_keys is None:
        raise SystemExit("no shape keys: nothing to animate")

    f0, f1 = set_clip(obj, args.clip)
    fl = foot_vertex(obj, front=True, left=True)
    print("")
    print("  %s   clip %s   frames %d-%d   tracking vertex %d (front-left foot)"
          % (os.path.basename(args.glb), args.clip, f0, f1, fl))

    sc = bpy.context.scene
    try:
        sc.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        sc.render.engine = "BLENDER_EEVEE"
    try:
        sc.eevee.taa_render_samples = 32
    except AttributeError:
        pass
    sc.view_settings.view_transform = "Standard"
    sc.render.resolution_x = sc.render.resolution_y = args.res
    sc.render.film_transparent = False

    ld = bpy.data.lights.new("key", type="AREA")
    ld.energy, ld.size = 160.0, 1.6
    lo = bpy.data.objects.new("key", ld)
    lo.location = (0.9, -1.1, 1.6)
    lo.rotation_euler = (math.radians(38), 0, math.radians(38))
    sc.collection.objects.link(lo)

    # Fixed camera, framed on the REST pose with headroom. If the camera
    # re-framed per frame, a sliding foot and a striding foot would look alike.
    co = [obj.matrix_world @ v.co for v in obj.data.vertices]
    cx = sum(c.x for c in co) / len(co)
    cy = sum(c.y for c in co) / len(co)
    cz = sum(c.z for c in co) / len(co)
    radius = max(max(abs(c.x - cx), abs(c.y - cy)) for c in co) * 1.25

    cd = bpy.data.cameras.new("strip_cam")
    cam = bpy.data.objects.new("strip_cam", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    cd.type = "ORTHO"
    cd.ortho_scale = radius * 2.0
    a, e = math.radians(args.az), math.radians(args.el)
    d = 3.0
    cam.location = (cx + d * math.sin(a) * math.cos(e),
                    cy - d * math.cos(a) * math.cos(e),
                    cz + d * math.sin(e))
    cam.rotation_euler = (math.radians(90) - e, 0.0, a)

    out_dir = os.path.abspath(args.out)
    os.makedirs(out_dir, exist_ok=True)
    dg = bpy.context.evaluated_depsgraph_get()

    n = args.frames
    trace = []
    for k in range(n):
        fr = f0 + (f1 - f0) * k // max(1, n - 1)
        sc.frame_set(int(fr))
        dg = bpy.context.evaluated_depsgraph_get()
        ev = obj.evaluated_get(dg)
        w = ev.matrix_world @ ev.data.vertices[fl].co
        trace.append((int(fr), w.y, w.z))
        path = os.path.join(out_dir, "%s_%03d.png" % (args.clip.split("-")[0], k))
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        if not (os.path.isfile(path) and os.path.getsize(path) > 0):
            raise SystemExit("frame %d was not written" % k)

    ys = [t[1] for t in trace]
    zs = [t[2] for t in trace]
    # Stance and swing are defined by the FOOT'S OWN MOTION, not by a height
    # threshold. Forward is -Y, so the foot moves forward (y falling) only
    # while it is in the air, and backward (y rising) only while it is planted
    # and the body is passing over it. That definition needs no ground plane
    # and no tuned epsilon -- both of which failed here: a threshold measured
    # against the trace's own minimum moved with the signal, and one measured
    # against world z = 0 assumed all four feet are exactly coplanar.
    base = min(zs)
    # Longest run of consecutive frames in which y RISES = the stance.
    rise = [ys[k] > ys[k - 1] for k in range(1, len(ys))]
    best_len, best_end, run = 0, -1, 0
    for k, up in enumerate(rise):
        run = run + 1 if up else 0
        if run > best_len:
            best_len, best_end = run, k
    stance = list(range(best_end - best_len + 1, best_end + 2)) if best_len else None

    print("")
    print("  FOOT TRACE (front-left), fore-aft y and height over its lowest "
          "point, in mm:")
    for k, (fr, y, z) in enumerate(trace):
        tag = "APOYO" if stance and k in stance else "vuelo"
        print("    f%-3d  y %+7.1f   z %+6.1f   %s"
              % (fr, y * 1000, (z - base) * 1000, tag))
    print("")
    print("  recorrido de avance: %.1f mm   elevacion: %.1f mm"
          % ((max(ys) - min(ys)) * 1000, (max(zs) - base) * 1000))
    if stance:
        drag = (ys[stance[-1]] - ys[stance[0]]) * 1000
        hi = max(zs[k] - base for k in stance) * 1000
        print("  APOYO: %d de %d frames   arrastre hacia atras %+.1f mm   "
              "el pie se despega hasta %.1f mm durante el apoyo"
              % (len(stance), n, drag, hi))
        if drag <= 0.5:
            print("  GATE: el pie no arrastra -- patina")
        if hi > 4.0:
            print("  GATE: el pie flota %.1f mm mientras deberia estar "
                  "apoyado" % hi)
    else:
        print("  GATE: no hay fase de apoyo -- el pie nunca retrocede")
    print("  %d frames -> %s" % (n, out_dir))


if __name__ == "__main__":
    main()
