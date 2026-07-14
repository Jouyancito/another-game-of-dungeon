"""measure_features.py — NUMERIC scene measurement -> JSON. The stop-condition engine.

The Filomeno oscillation (brows-eyes too far -> too close -> too far, 5 iterations)
had NO number to converge to. And the golem paint spill (a paint circle crossed the
skull and painted the cranium) was invisible in a front render — it was only ever
caught by a Z-distribution probe, NOT by looking. This tool produces both:

  * FEATURE GEOMETRY as RATIOS of the head bbox (resolution/scale independent):
    eye spacing, eye size, eye height, brow->eye gap, muzzle height, eye->muzzle gap.
    Ratios (not absolute mm) because the 2D reference is measured the same way.
  * PAINT-ZONE Z-DISTRIBUTION per material (nose/mouth/muzzle/ear): min/max/mean as
    a fraction of head height, plus a spill_score = fraction of the zone's verts up
    in the cranium band. This is the probe that catches spill a render hides.

Measures WORLD-SPACE vertex bounds (matrix_world @ co) per object — NOT object.location
(the brows in this file sit at origin ~0 but carry their offset in vertex data;
reading object.location would place them wrong).

Head bbox is self-calibrating: union of the face-feature objects (eye_*/brow_*) and
the face paint-zone verts (muzzle+ear give width/top, muzzle+nose give bottom/front).
Document this same region when hand-measuring the 2D ref so the ratios are comparable.

Run:
  blender.exe -b <scene.blend> --python measure_features.py -- \
      --target Bear_A_tufts --out measures.json \
      [--feature-prefixes eye_,brow_,face_] \
      [--paint-materials muzzle,nose,mouth,ear] \
      [--cranium-band 0.80] [--import mesh.glb]
"""
import bpy, sys, os, json
from mathutils import Vector


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    d = {"target": None, "out": "measures.json",
         "feature-prefixes": "eye_,brow_,face_",
         "paint-materials": "muzzle,nose,mouth,ear",
         "cranium-band": "0.80", "import": None}
    i = 0
    while i < len(argv):
        k = argv[i].lstrip("-")
        if k in d:
            d[k] = argv[i + 1]; i += 2
        else:
            i += 1
    return d


def obj_world_verts(o):
    mw = o.matrix_world
    return [mw @ v.co for v in o.data.vertices]


def bbox_of(points):
    mn = Vector((1e18,) * 3); mx = Vector((-1e18,) * 3)
    for w in points:
        for j in range(3):
            mn[j] = min(mn[j], w[j]); mx[j] = max(mx[j], w[j])
    return mn, mx


def center_dims(points):
    mn, mx = bbox_of(points)
    return (mn + mx) * 0.5, (mx - mn), mn, mx


def main():
    a = parse_args()
    if a["import"]:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=a["import"])

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("[measure] no meshes")

    tgt = bpy.data.objects.get(a["target"]) if a["target"] else meshes[0]
    if tgt is None:
        raise SystemExit("[measure] target %r not found. meshes=%s"
                         % (a["target"], [m.name for m in meshes]))

    prefixes = tuple(p for p in a["feature-prefixes"].split(",") if p)
    paint_kw = [p for p in a["paint-materials"].split(",") if p]
    cranium_band = float(a["cranium-band"])

    # body bbox (whole target) --------------------------------------------
    body_pts = obj_world_verts(tgt)
    body_ctr, body_dim, body_mn, body_mx = center_dims(body_pts)

    # named feature objects (skip *_outline duplicates) -------------------
    feature = {}
    head_pts = []
    for o in bpy.data.objects:
        if o.type != "MESH":
            continue
        nm = o.name.lower()
        if "outline" in nm:
            continue
        if nm.startswith(prefixes):
            pts = obj_world_verts(o)
            c, dim, mn, mx = center_dims(pts)
            feature[o.name] = {"center": list(c), "dims": list(dim),
                               "min": list(mn), "max": list(mx)}
            head_pts.extend(pts)

    # paint zones on the target: verts per material slot ------------------
    paint = {}
    me = tgt.data
    mw = tgt.matrix_world
    slot_names = [m.name if m else "" for m in me.materials]
    for si, sname in enumerate(slot_names):
        low = sname.lower()
        if not any(k in low for k in paint_kw):
            continue
        vset = set()
        for poly in me.polygons:
            if poly.material_index == si:
                vset.update(poly.vertices)
        if not vset:
            continue
        pts = [mw @ me.vertices[vi].co for vi in vset]
        c, dim, mn, mx = center_dims(pts)
        paint[sname] = {"pts": pts, "center": c, "dims": dim,
                        "min": mn, "max": mx, "nverts": len(pts)}
        head_pts.extend(pts)

    # head bbox = union of features + paint zones (fallback: top 28% body) --
    if head_pts:
        head_ctr, head_dim, head_mn, head_mx = center_dims(head_pts)
        head_src = "features+paint"
    else:
        head_mn = Vector((body_mn.x, body_mn.y, body_mn.z + body_dim.z * 0.72))
        head_mx = body_mx.copy()
        head_ctr = (head_mn + head_mx) * 0.5
        head_dim = head_mx - head_mn
        head_src = "fallback_top28pct"
    HW = head_dim.x or 1e-9   # head width  (X)
    HH = head_dim.z or 1e-9   # head height (Z)
    hz0 = head_mn.z

    def zfrac_head(z):
        return (z - hz0) / HH

    def zfrac_body(z):
        return (z - body_mn.z) / (body_dim.z or 1e-9)

    ratios = {}
    detail = {}

    # eyes ----------------------------------------------------------------
    eyeL = feature.get("eye_L_ball"); eyeR = feature.get("eye_R_ball")
    if eyeL and eyeR:
        cL = Vector(eyeL["center"]); cR = Vector(eyeR["center"])
        spacing = abs(cL.x - cR.x)
        eye_w = (eyeL["dims"][0] + eyeR["dims"][0]) * 0.5
        eye_cz = (cL.z + cR.z) * 0.5
        ratios["eye_spacing__head_w"] = spacing / HW
        ratios["eye_width__head_w"] = eye_w / HW
        ratios["eye_height__head_h"] = zfrac_head(eye_cz)
        detail["eye_center_z"] = eye_cz
        detail["eye_spacing_abs"] = spacing

    # brows + brow->eye gap ----------------------------------------------
    brows = [feature[k] for k in ("brow_L", "brow_R") if k in feature]
    if brows:
        brow_cz = sum(b["center"][2] for b in brows) / len(brows)
        ratios["brow_height__head_h"] = zfrac_head(brow_cz)
        detail["brow_center_z"] = brow_cz
        if eyeL and eyeR:
            gap = brow_cz - eye_cz
            ratios["brow_eye_gap__head_h"] = gap / HH
            detail["brow_eye_gap_abs"] = gap

    # paint-zone geometry + Z distribution (spill probe) ------------------
    paint_report = {}
    for sname, pz in paint.items():
        zs = [p.z for p in pz["pts"]]
        zmin, zmax = min(zs), max(zs)
        zmean = sum(zs) / len(zs)
        band_z = hz0 + cranium_band * HH
        spill = sum(1 for z in zs if z > band_z) / len(zs)
        entry = {
            "nverts": pz["nverts"],
            "center_z": pz["center"].z,
            "z_frac_head": [round(zfrac_head(zmin), 4), round(zfrac_head(zmax), 4)],
            "z_frac_head_mean": round(zfrac_head(zmean), 4),
            "z_frac_body": [round(zfrac_body(zmin), 4), round(zfrac_body(zmax), 4)],
            "height__head_h": round(zfrac_head(pz["center"].z), 4),
            "spill_score": round(spill, 4),   # frac of verts up in the cranium band
        }
        paint_report[sname] = entry
        # short key for the contract table
        short = next((k for k in paint_kw if k in sname.lower()), sname)
        ratios["%s_height__head_h" % short] = entry["height__head_h"]
        ratios["%s_spill_score" % short] = entry["spill_score"]

    # eye -> muzzle vertical gap -----------------------------------------
    muzzle = next((v for k, v in paint.items() if "muzzle" in k.lower()), None)
    if muzzle and eyeL and eyeR:
        gap = eye_cz - muzzle["max"].z   # eye center above muzzle top
        ratios["eye_muzzle_gap__head_h"] = gap / HH
        detail["eye_muzzle_gap_abs"] = gap

    out = {
        "target": tgt.name,
        "head_bbox": {"source": head_src, "min": list(head_mn),
                      "max": list(head_mx), "width_x": HW, "height_z": HH},
        "body_bbox": {"min": list(body_mn), "max": list(body_mx),
                      "dims": list(body_dim)},
        "cranium_band_frac": cranium_band,
        "ratios": {k: round(v, 4) for k, v in ratios.items()},
        "paint_zones": paint_report,
        "features_found": sorted(feature.keys()),
        "detail": {k: (round(v, 4) if isinstance(v, float) else v)
                   for k, v in detail.items()},
    }
    with open(a["out"], "w") as fh:
        json.dump(out, fh, indent=2)
    print("[measure] target=%s head=%s HW=%.4f HH=%.4f" % (tgt.name, head_src, HW, HH))
    print("[measure] ratios:")
    for k, v in out["ratios"].items():
        print("   %-28s %.4f" % (k, v))
    print("[measure] wrote", a["out"])


if __name__ == "__main__":
    main()
