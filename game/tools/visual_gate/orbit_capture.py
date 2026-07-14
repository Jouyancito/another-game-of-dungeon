"""orbit_capture.py — standard parametric multi-view capture (headless EEVEE).

Born from the Filomeno face failures (2026-07-03): verdicts were emitted from ONE
flattering wide/front frame at low res. Orbiting exposed defects (mouth under the
muzzle, black spilled onto the cranium, weird eyes) that the flattering angle hid.
This tool captures a FIXED, ANGLE-COMPLETE set every run so no defect can hide:
    N orbit steps  + worm's-eye (from below)  + face close-ups.
The worm's-eye is non-negotiable — it is the angle that catches paint spill and
under-muzzle geometry that a front 3/4 flatters away.

Runs against the CURRENTLY OPEN scene (launch Blender with the .blend), or import a
GLB with --import. EEVEE, resolution configurable. Standard view transform so the
pixels feed compare metrics without tonemap drift.

Run:
  blender.exe -b <scene.blend> --python orbit_capture.py -- \
      --target Bear_A_tufts --out ./out --frames 8 --res 640x800 \
      [--center x,y,z] [--radius R] [--elev 8] [--lens 60] \
      [--worm-elev -55] [--face-center x,y,z] [--face-frac 0.30] \
      [--import mesh.glb] [--engine eevee|cycles] [--samples 24]

Outputs into --out:  orbit_000.png .. orbit_NNN.png  worm_00..  face_00..
plus a manifest.json listing every shot (label, path, cam pos, aim) so
contact_sheet.py can lay them out with correct labels.
"""
import bpy, sys, os, math, json
from mathutils import Vector


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    d = {
        "target": None, "out": "./orbit_out", "frames": 8, "res": "640x800",
        "center": None, "radius": None, "elev": 8.0, "lens": 60.0,
        "worm_elev": -55.0, "face_center": None, "face_frac": 0.30,
        "import": None, "engine": "eevee", "samples": 24,
    }
    i = 0
    while i < len(argv):
        k = argv[i].lstrip("-")
        if k in d:
            d[k] = argv[i + 1]; i += 2
        else:
            i += 1
    d["frames"] = int(d["frames"]); d["samples"] = int(d["samples"])
    d["elev"] = float(d["elev"]); d["lens"] = float(d["lens"])
    d["worm_elev"] = float(d["worm_elev"]); d["face_frac"] = float(d["face_frac"])
    if d["radius"] is not None:
        d["radius"] = float(d["radius"])
    for key in ("center", "face_center"):
        if d[key]:
            d[key] = Vector([float(x) for x in d[key].split(",")])
    return d


def world_bbox(objs):
    """Union world-space vertex bbox over meshes (accurate — not object.location)."""
    mn = Vector((1e18,) * 3); mx = Vector((-1e18,) * 3)
    for o in objs:
        if o.type != "MESH":
            continue
        mw = o.matrix_world
        for v in o.data.vertices:
            w = mw @ v.co
            for j in range(3):
                mn[j] = min(mn[j], w[j]); mx[j] = max(mx[j], w[j])
    return mn, mx


def main():
    a = parse_args()
    os.makedirs(a["out"], exist_ok=True)

    if a["import"]:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=a["import"])

    sc = bpy.context.scene
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("[orbit] no meshes in scene")

    # target selection -----------------------------------------------------
    if a["target"]:
        tgt = bpy.data.objects.get(a["target"])
        if tgt is None:
            raise SystemExit("[orbit] target %r not found. meshes=%s"
                             % (a["target"], [m.name for m in meshes]))
        subject = [tgt]
    else:
        subject = meshes

    mn, mx = world_bbox(subject)
    ctr = a["center"] if a["center"] else (mn + mx) * 0.5
    rad = a["radius"] if a["radius"] else max((mx - mn).x, (mx - mn).y, (mx - mn).z)
    top = mx.z

    # face center: prefer eye_* objects centroid, else top slice of the bbox
    if a["face_center"]:
        fctr = a["face_center"]
    else:
        eyes = [o for o in bpy.data.objects
                if o.type == "MESH" and o.name.lower().startswith("eye_")]
        if eyes:
            emn, emx = world_bbox(eyes)
            fctr = (emn + emx) * 0.5
        else:
            fctr = Vector((ctr.x, ctr.y, top - (mx - mn).z * 0.18))
    face_rad = (mx - mn).z * a["face_frac"]

    # hide the OTHER body if this is an A/B file, so it never bleeds into frame
    for o in meshes:
        if o not in subject and o.name.lower().startswith("bear_"):
            o.hide_render = True

    # engine + color mgmt --------------------------------------------------
    eng = a["engine"].lower()
    if eng == "cycles":
        sc.render.engine = "CYCLES"; sc.cycles.samples = a["samples"]
        sc.cycles.use_denoising = True
    else:
        sc.render.engine = "BLENDER_EEVEE"  # 5.1.2 enum (EEVEE Next drops the suffix)
        try:
            sc.eevee.taa_render_samples = a["samples"]
        except Exception:
            pass
    rx, ry = (int(x) for x in a["res"].split("x"))
    sc.render.resolution_x = rx; sc.render.resolution_y = ry
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "Standard"

    # keep existing scene lights; only add a neutral rig if the scene is dark
    if not any(o.type == "LIGHT" for o in bpy.data.objects):
        for nm, loc, e, sz in (("K", (1.0, -1.4, 1.2), 160, rad * 2.4),
                               ("F", (-1.2, -0.7, 0.4), 90, rad * 2.6),
                               ("R", (0.2, 1.3, 0.9), 70, rad * 2.2)):
            ld = bpy.data.lights.new(nm, "AREA"); ld.energy = e; ld.size = sz
            lo = bpy.data.objects.new(nm, ld); sc.collection.objects.link(lo)
            lo.location = ctr + Vector(loc) * rad
            lo.rotation_euler = (ctr - lo.location).normalized() \
                .to_track_quat("-Z", "Y").to_euler()

    cd = bpy.data.cameras.new("GateCam"); cd.lens = a["lens"]
    cam = bpy.data.objects.new("GateCam", cd)
    sc.collection.objects.link(cam); sc.camera = cam

    manifest = {"target": a["target"], "center": list(ctr), "radius": rad, "shots": []}

    def shot(label, ang_deg, elev_deg, target, dist):
        aa = math.radians(ang_deg); e = math.radians(elev_deg)
        cam.location = target + Vector((math.sin(aa) * math.cos(e),
                                        -math.cos(aa) * math.cos(e),
                                        math.sin(e))) * dist
        cam.rotation_euler = (target - cam.location).normalized() \
            .to_track_quat("-Z", "Y").to_euler()
        path = os.path.join(a["out"], label + ".png")
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        manifest["shots"].append({"label": label, "angle": ang_deg,
                                  "elev": elev_deg, "path": path,
                                  "cam": list(cam.location)})
        print("[orbit] shot", label, "ang", ang_deg, "elev", elev_deg)

    dist = rad * 2.5
    # 1) full orbit at eye-ish elevation
    for i in range(a["frames"]):
        shot("orbit_%03d" % i, 360.0 * i / a["frames"], a["elev"], ctr, dist)
    # 2) worm's-eye (from below) — 3 angles, THE spill/under-muzzle catcher
    for j, ang in enumerate((0.0, -35.0, 35.0)):
        shot("worm_%02d" % j, ang, a["worm_elev"], ctr, dist)
    # 3) face close-ups — front + slight 3/4, tight on the face region
    for j, ang in enumerate((0.0, 20.0)):
        shot("face_%02d" % j, ang, 2.0, fctr, max(face_rad * 2.4, rad * 0.7))

    with open(os.path.join(a["out"], "manifest.json"), "w") as fh:
        json.dump(manifest, fh, indent=2)
    print("[orbit] DONE %d shots -> %s" % (len(manifest["shots"]), a["out"]))


if __name__ == "__main__":
    main()
