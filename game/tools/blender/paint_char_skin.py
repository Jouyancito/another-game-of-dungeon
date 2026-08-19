"""paint_char_skin — continuous skin colour as FLOAT_COLOR vertex paint.

WHY THIS EXISTS, next to paint_char_zones.py

`paint_char_zones.py` assigns a flat MATERIAL per zone: nine materials, each a
single uniform colour. That is exactly the flatness Joan named -- "espero
aprendas lo de no tener un color plano" -- and no amount of light fixes it,
because there is no variation inside the skin to light. It also does not
survive glTF: node materials collapse on export, which is how slime, snake,
wasp and turtle shipped WHITE into Godot.

Vertex colour fixes both. It carries continuous variation, and it travels
inside the GLB as COLOR_0.

THE TRAP THIS FILE IS BUILT AROUND

The base mesh has 19158 vertices; the evaluated mesh has 13380, because a MASK
modifier deletes the helper geometry. So:

  - indices from the evaluated mesh do NOT address the base mesh,
  - and base-mesh coordinates are the UNMORPHED body (bbox z 1.667 instead of
    1.800), because every MPFB macro and target is a shape key.

A mask built either way lands somewhere the body is not. The fix is to mute the
MASK, evaluate, and take the morphed coordinates while the counts still match
1:1 with the vertex groups. `morphed_coords()` does that and asserts it.

LANDMARKS ARE FOUND, NOT TYPED

Cheek, nose, beard and brow masks are anchored to the eye and lip groups that
actually exist on the mesh, so they follow the face instead of drifting when
the skull dials change -- which they did five times this session alone.
"""
import argparse
import importlib.util
import os
import sys

import bpy
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
MOTOR = os.path.join(os.path.expanduser("~"), "motor-blender", "recetas")

ATTR = "Col"

# Canon skin, fixed in _char_warrior_male_v1.md section 3. Written as sRGB
# because that is how it was picked; converted below. Feeding sRGB straight
# into a FLOAT_COLOR is the wash bug that survived three build iterations on
# sculpt2d3d -- Image.pixels and hex literals are both sRGB, the attribute is
# linear, and nothing errors.
SKIN_HEX = "#A8724E"

# Zone colours for the discrete features that own a vertex group.
ZONE_HEX = {
    "lips":     "#8E5A48",
    "nails":    "#B98A6C",
    "nipple":   "#7A4436",
    "scalp":    "#241A14",
    "teeth":    "#DCD6C8",
    "eye_white": "#E8E4DC",
    "eye_iris": "#3A2415",
    "lashes":   "#1A1512",
    "brows":    "#2A1F18",
}

GROUP_ZONES = {
    "lips": "lips",
    "fingernails": "nails",
    "toenails": "nails",
    "nipple": "nipple",
    "nippleTip": "nipple",
    "scalp": "scalp",
    "helper-upper-teeth": "teeth",
    "helper-lower-teeth": "teeth",
    "helper-l-eyelashes-1": "lashes",
    "helper-l-eyelashes-2": "lashes",
    "helper-r-eyelashes-1": "lashes",
    "helper-r-eyelashes-2": "lashes",
}
EYE_GROUPS = ("helper-l-eye", "helper-r-eye")


# --------------------------------------------------------------------- colour
def srgb_to_linear(c):
    c = np.asarray(c, dtype=np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def hex_lin(h):
    h = h.lstrip("#")
    srgb = np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])
    return srgb_to_linear(srgb)


# ------------------------------------------------------------------- geometry
class masks_muted:
    """Turn off MASK modifiers for the duration of a block.

    Anything that needs 1:1 correspondence with the base vertices has to run in
    here. The AO bake learned this the expensive way: bmesh.from_object() also
    goes through the depsgraph, so it came back with 13380 verts against 19158
    and the bake was silently skipped.
    """

    def __init__(self, obj):
        self.obj = obj
        self.muted = []

    def __enter__(self):
        for m in self.obj.modifiers:
            if m.type == "MASK" and m.show_viewport:
                m.show_viewport = False
                self.muted.append(m)
        bpy.context.view_layer.update()
        return self.obj

    def __exit__(self, *exc):
        for m in self.muted:
            m.show_viewport = True
        bpy.context.view_layer.update()
        return False


def morphed_coords(obj):
    """World-space coordinates that line up 1:1 with the BASE vertex indices."""
    with masks_muted(obj):
        dg = bpy.context.evaluated_depsgraph_get()
        ev = obj.evaluated_get(dg)
        me = ev.to_mesh()
        n = len(me.vertices)
        co = np.empty(n * 3, dtype=np.float32)
        me.vertices.foreach_get("co", co)
        no = np.empty(n * 3, dtype=np.float32)
        me.vertices.foreach_get("normal", no)
        ev.to_mesh_clear()

    nb = len(obj.data.vertices)
    if n != nb:
        raise RuntimeError(
            "el mask no se pudo silenciar: %d evaluados vs %d base. "
            "Sin correspondencia 1:1 las mascaras caen en el cuerpo equivocado." % (n, nb))

    M = np.array(obj.matrix_world)
    W = co.reshape(n, 3) @ M[:3, :3].T + M[:3, 3]
    N = no.reshape(n, 3) @ np.linalg.inv(M[:3, :3])
    N = N / np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-9)
    return W, N


def group_mask(obj, n, names):
    """Boolean mask over base vertices belonging to any of `names`."""
    idx = {g.name: g.index for g in obj.vertex_groups}
    want = {idx[nm] for nm in names if nm in idx}
    out = np.zeros(n, dtype=bool)
    if not want:
        return out
    for v in obj.data.vertices:
        for ge in v.groups:
            if ge.group in want and ge.weight > 0.01:
                out[v.index] = True
                break
    return out


def smoothstep(x):
    x = np.clip(x, 0.0, 1.0)
    return x * x * (3.0 - 2.0 * x)


def falloff(d, radius):
    """1 at the centre, 0 at `radius`, smooth between."""
    return smoothstep(1.0 - np.clip(d / max(radius, 1e-9), 0.0, 1.0))


# ----------------------------------------------------------------------- main
def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--blend", default=os.path.join(
        REPO, "game", "assets", "art", "characters", "char_warrior_male_mh.blend"))
    ap.add_argument("--out", default=None)
    ap.add_argument("--skin", default=SKIN_HEX)
    ap.add_argument("--ao-samples", type=int, default=16)
    ap.add_argument("--no-ao", action="store_true")
    ap.add_argument("--render", default=os.path.join(HERE, "_review_char_skin"))
    # Single knob over every CONTINUOUS effect (flush, beard, weathering,
    # grain, AO). The discrete zones keep their own colours -- scaling those
    # would confuse "how much variation" with "which features exist".
    #
    # 0.0 is the control, and it is the point of the ramp. Joan: "asi quizas
    # vemos si es el estilo o el valor, y no probamos 10 veces 1 cosa". A ramp
    # without its zero cannot answer that -- if every step looks wrong the
    # approach is wrong, and only the flat control makes that visible.
    ap.add_argument("--intensity", type=float, default=1.0)
    args = ap.parse_args(argv)

    bpy.ops.wm.open_mainfile(filepath=args.blend)
    obj = max((o for o in bpy.data.objects if o.type == "MESH"),
              key=lambda o: len(o.data.vertices))
    me = obj.data
    n = len(me.vertices)
    print("objeto %s   %d verts base" % (obj.name, n))

    W, N = morphed_coords(obj)
    x, y, z = W[:, 0], W[:, 1], W[:, 2]
    print("  coords morfeadas: z %.4f .. %.4f  (el cuerpo real, no la base)"
          % (z.min(), z.max()))

    # ---- landmarks, read off the mesh
    eye_m = group_mask(obj, n, EYE_GROUPS)
    lip_m = group_mask(obj, n, ("lips",))
    if not eye_m.any() or not lip_m.any():
        raise RuntimeError("faltan grupos de ojo o labio; sin landmarks no hay mascaras")
    eye_c = W[eye_m].mean(axis=0)
    lip_c = W[lip_m].mean(axis=0)
    eye_l = W[eye_m & (x < 0)].mean(axis=0)
    eye_r = W[eye_m & (x > 0)].mean(axis=0)
    head_h = z.max() - eye_c[2]
    print("  ojo z %.4f   labio z %.4f   separacion ocular %.4f m"
          % (eye_c[2], lip_c[2], abs(eye_r[0] - eye_l[0])))

    # ---- base colour
    skin = hex_lin(args.skin)
    cols = np.tile(np.append(skin, 1.0), (n, 1)).astype(np.float32)
    print("  piel base sRGB %s -> lineal (%.4f, %.4f, %.4f)"
          % (args.skin, skin[0], skin[1], skin[2]))
    K = float(args.intensity)
    print("  intensidad de variacion continua: %.2f%s"
          % (K, "   (CONTROL: piel plana)" if K == 0.0 else ""))

    tally = {}

    def report(name, mask):
        tally[name] = int(mask.sum())
        return mask

    # ---- continuous variation, applied BEFORE the discrete zones so a feature
    #      never gets repainted as the skin it sits in.
    front = N[:, 1] < -0.15          # surfaces facing the camera (-Y)

    # cheeks + nose + ears: warmer and more saturated, the way weathered faces
    # redden where the skin is thin and exposed
    d_cheek_l = np.linalg.norm(W - (eye_l + np.array([0.012, 0.006, -0.045])), axis=1)
    d_cheek_r = np.linalg.norm(W - (eye_r + np.array([-0.012, 0.006, -0.045])), axis=1)
    nose_c = np.array([0.0, min(y[eye_m].min(), lip_c[1]) - 0.012,
                       (eye_c[2] + lip_c[2]) * 0.5 + 0.012])
    d_nose = np.linalg.norm(W - nose_c, axis=1)
    flush = np.maximum.reduce([falloff(d_cheek_l, 0.045),
                               falloff(d_cheek_r, 0.045),
                               falloff(d_nose, 0.034)]) * front
    report("rubor", flush > 0.05)
    cols[:, 0] += flush * 0.055 * K
    cols[:, 1] -= flush * 0.012 * K
    cols[:, 2] -= flush * 0.014 * K

    # beard shadow: chin, jaw and the strip above the lip. VALUE, not geometry
    # -- Arthur Morgan's stubble is painted, and modelling it would cost
    # thousands of triangles for a face that is ~20 px in play.
    jaw_top = lip_c[2] + 0.030
    jaw_bot = lip_c[2] - 0.085
    band = smoothstep((jaw_top - z) / 0.030) * smoothstep((z - jaw_bot) / 0.045)
    d_jaw = np.abs(y - lip_c[1])
    beard = band * falloff(d_jaw, 0.085) * front
    beard = np.clip(beard, 0.0, 1.0)
    report("barba", beard > 0.08)
    cols[:, 0] -= beard * 0.075 * K
    cols[:, 1] -= beard * 0.058 * K
    cols[:, 2] -= beard * 0.030 * K

    # hands and forearms: the other skin the player actually sees once armour
    # is on, and the part that weathers hardest
    span = np.percentile(np.abs(x), 97)
    weather = smoothstep((np.abs(x) - span * 0.55) / max(span * 0.45, 1e-9))
    weather *= smoothstep((z - 0.80) / 0.25) * smoothstep((1.55 - z) / 0.25)
    report("curtido", weather > 0.1)
    cols[:, 0] -= weather * 0.030 * K
    cols[:, 1] -= weather * 0.026 * K
    cols[:, 2] -= weather * 0.018 * K

    # NO PORE GRAIN HERE. A per-vertex hash produces noise at the frequency of
    # the MESH, and MPFB's topology is regular, so it reads as a repeating
    # weave following the polygons -- which is exactly what Joan saw: "tiene un
    # patron repetido". Pores are far smaller than the ~5-10 mm spacing between
    # vertices, so vertex colour CANNOT represent them at any amplitude. They
    # belong in a normal map. Same limit that sent the brows to geometry.

    # ---- brows: no vertex group exists for them on this mesh (checked across
    #      all 152), so the band is generated over the supraorbital arch that
    #      pass 5 built.
    brow_z = eye_c[2] + head_h * 0.085
    bz = falloff(np.abs(z - brow_z), 0.011)
    bx = falloff(np.abs(np.abs(x) - abs(eye_l[0])) - 0.004, 0.026)
    brow = (bz * bx) * (N[:, 1] < -0.30)
    brow_m = report("cejas", brow > 0.30)

    # ---- discrete zones last, highest specificity wins
    zone_masks = {}
    for zname in ("nipple", "nails", "scalp", "teeth", "lips", "lashes"):
        names = [g for g, z_ in GROUP_ZONES.items() if z_ == zname]
        zone_masks[zname] = group_mask(obj, n, names)

    eye_white = eye_m.copy()
    iris = np.zeros(n, dtype=bool)
    for c in (eye_l, eye_r):
        d = np.linalg.norm(W - np.array([c[0], c[1] - 0.011, c[2]]), axis=1)
        iris |= eye_m & (d < 0.0075)

    order = [("brows", brow_m), ("scalp", zone_masks["scalp"]),
             ("nipple", zone_masks["nipple"]), ("nails", zone_masks["nails"]),
             ("lips", zone_masks["lips"]), ("teeth", zone_masks["teeth"]),
             ("eye_white", eye_white), ("eye_iris", iris),
             ("lashes", zone_masks["lashes"])]
    for zname, m in order:
        if not m.any():
            print("  AVISO zona vacia: %s" % zname)
        cols[m, :3] = hex_lin(ZONE_HEX[zname]).astype(np.float32)
        tally[zname] = int(m.sum())

    np.clip(cols[:, :3], 0.0, 1.0, out=cols[:, :3])

    # ---- ambient occlusion, from the motor's recipe
    if not args.no_ao and K > 0.0:
        import bmesh
        spec = importlib.util.spec_from_file_location(
            "biome_ao", os.path.join(MOTOR, "biome_ao.py"))
        ao = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(ao)

        bm = bmesh.new()
        with masks_muted(obj):
            dg = bpy.context.evaluated_depsgraph_get()
            bm.from_object(obj, dg)
        bm.verts.ensure_lookup_table()
        if len(bm.verts) == n:
            # The recipe keys vcol by the BMVert OBJECT, not by index -- the
            # documented gotcha from flower_pack, where BMVert.index reads back
            # as 0/garbage and the whole mesh rendered flat white. With the
            # MASK muted, bm.verts[i] does correspond to base vertex i, so the
            # dict is built and read back through the same lookup table.
            vcol = {v: tuple(float(c) for c in cols[i, :3])
                    for i, v in enumerate(bm.verts)}
            mean, low = ao.bake_vertex_ao(bm, vcol, samples=args.ao_samples,
                                          max_dist=0.11,
                                          strength=0.55 * K,
                                          min_factor=1.0 - 0.45 * K)
            before = cols[:, :3].copy()
            for i, v in enumerate(bm.verts):
                cols[i, :3] = vcol[v]
            moved = float(np.abs(cols[:, :3] - before).max())
            print("  AO: factor medio %.3f   minimo %.3f   delta max de color %.4f %s"
                  % (mean, low, moved,
                     "" if moved > 1e-4 else "*** EL AO NO TOCO NADA ***"))
        else:
            print("  AO SALTADO: bmesh %d verts vs %d base -- no mapean"
                  % (len(bm.verts), n))
        bm.free()

    # ---- write, in the FACE_CORNER domain
    #
    # POINT stores one colour per vertex and the face interpolates between its
    # corners, so the sharpest edge it can express is one edge wide -- about
    # 3-5 mm on this face. That is why the brows read as a smear no matter how
    # dark they are set: the limit is the domain, not the contrast.
    #
    # FACE_CORNER stores a colour per corner-of-face, so two neighbouring faces
    # can disagree at the same vertex. Deciding a zone PER FACE then gives a
    # hard edge exactly along the face boundary. Soft zones (flush, weathering,
    # AO) still get the interpolated per-vertex value, so nothing that should
    # be gradual becomes faceted.
    loops = me.loops
    nl = len(loops)
    lv = np.empty(nl, dtype=np.int32)
    loops.foreach_get("vertex_index", lv)
    ccols = cols[lv].copy()

    poly_starts = np.empty(len(me.polygons), dtype=np.int32)
    poly_totals = np.empty(len(me.polygons), dtype=np.int32)
    me.polygons.foreach_get("loop_start", poly_starts)
    me.polygons.foreach_get("loop_total", poly_totals)

    def stamp_faces(vert_mask, rgb, label):
        """Paint every face whose MAJORITY of corners is inside `vert_mask`.

        Majority rather than any-corner: any-corner bleeds the zone outward by
        a full ring of faces, which is how a 4 mm brow becomes a 12 mm slab.
        """
        hard = 0
        for pi in range(len(poly_starts)):
            s, t = int(poly_starts[pi]), int(poly_totals[pi])
            vs = lv[s:s + t]
            if int(vert_mask[vs].sum()) * 2 > t:
                ccols[s:s + t, :3] = rgb
                hard += 1
        print("    borde duro %-10s %5d caras" % (label, hard))
        return hard

    print("\n  zonas con borde duro (decididas por cara):")
    for zname, m in [("brows", brow_m), ("scalp", zone_masks["scalp"]),
                     ("lips", zone_masks["lips"]), ("nails", zone_masks["nails"]),
                     ("teeth", zone_masks["teeth"]), ("lashes", zone_masks["lashes"]),
                     ("eye_white", eye_white), ("eye_iris", iris)]:
        if m.any():
            stamp_faces(m, hex_lin(ZONE_HEX[zname]).astype(np.float32), zname)

    if me.color_attributes.get(ATTR):
        me.color_attributes.remove(me.color_attributes[ATTR])
    attr = me.color_attributes.new(name=ATTR, type="FLOAT_COLOR", domain="CORNER")
    attr.data.foreach_set("color", ccols.reshape(-1))
    me.update()
    me.color_attributes.active_color = attr
    me.attributes.default_color_name = ATTR
    me.attributes.active_color_name = ATTR

    back = np.empty(nl * 4, dtype=np.float32)
    me.color_attributes[ATTR].data.foreach_get("color", back)
    err = float(np.abs(back.reshape(nl, 4) - ccols).max())
    print("\n  dominio CORNER: %d esquinas   round-trip max error %.6f  %s"
          % (nl, err, "OK" if err < 1e-4 else "*** SE PIERDE COLOR ***"))

    # Does the hard edge actually exist? A zone painted per-face must produce
    # vertices whose corners DISAGREE -- that disagreement IS the sharp border.
    # If it comes back zero the domain change bought nothing, and a smooth
    # render would look like a colour-choice problem instead of a dead feature.
    order = np.argsort(lv, kind="stable")
    lvs, cs = lv[order], ccols[order, :3]
    bounds = np.flatnonzero(np.diff(lvs)) + 1
    split = sum(1 for g in np.split(cs, bounds)
                if len(g) > 1 and float((g.max(axis=0) - g.min(axis=0)).max()) > 0.01)
    print("  vertices con esquinas discrepantes: %d de %d  %s"
          % (split, n, "hay borde duro" if split else "*** NO SE FORMO NINGUN BORDE ***"))

    print("\n  vertices por zona:")
    for k in sorted(tally, key=lambda k: -tally[k]):
        print("    %-11s %6d" % (k, tally[k]))

    uniq = np.unique(np.round(cols[:, :3], 3), axis=0)
    print("\n  tonos distintos en la malla: %d   (el plano anterior tenia 1 por zona)"
          % len(uniq))

    # ---- material + render. An unjudged mutation does not close a turn, and
    #      the paint is invisible until something reads the attribute.
    spec = importlib.util.spec_from_file_location(
        "toonmod", os.path.join(HERE, "preview_char_toon.py"))
    toonmod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(toonmod)

    mat = toonmod.toon_material("skin_vcol", args.skin)
    nt = mat.node_tree
    vc = nt.nodes.new("ShaderNodeAttribute")
    vc.location = (-140, 220)
    vc.attribute_type = "GEOMETRY"
    vc.attribute_name = ATTR
    tintnode = next(nd for nd in nt.nodes
                    if nd.type == "MIX_RGB" and nd.blend_type == "MULTIPLY")
    nt.links.new(vc.outputs["Color"], tintnode.inputs["Color2"])
    me.materials.clear()
    me.materials.append(mat)
    for poly in me.polygons:
        poly.material_index = 0
    print("  material: albedo por vertex colour '%s' hacia el toon del juego" % ATTR)

    if args.render:
        render_dir = args.render
        os.makedirs(render_dir, exist_ok=True)
        blockspec = importlib.util.spec_from_file_location(
            "blockout", os.path.join(HERE, "gen_char_warrior_male.py"))
        blockout = importlib.util.module_from_spec(blockspec)
        blockspec.loader.exec_module(blockout)
        blockout.ref_post()
        blockout.setup_scene(obj)

        sc = bpy.context.scene
        sc.render.engine = "BLENDER_EEVEE"
        sc.render.resolution_x, sc.render.resolution_y = 720, 900
        cam_data = bpy.data.cameras.new("cam")
        cam = bpy.data.objects.new("cam", cam_data)
        sc.collection.objects.link(cam)
        sc.camera = cam
        cam_data.type = "PERSP"

        hz = float(eye_c[2]) - 0.02
        shots = [
            ("cara_frente",  85.0, (0.0, -1.05, hz), (90, 0, 0)),
            ("cara_tresq",   85.0, (0.62, -0.86, hz), (90, 0, 35)),
            ("cara_perfil",  85.0, (1.05, 0.0, hz), (90, 0, 90)),
            ("torso",        50.0, (1.35, -1.75, 1.30), (84, 0, 38)),
            ("manos",        85.0, (0.92, -0.72, 1.02), (86, 0, 52)),
            ("player_eye",   24.0, (0.9, -5.9, 1.65), (88.5, 0, 9)),
        ]
        for label, lens, loc, rot in shots:
            cam_data.lens = lens
            cam.location = loc
            cam.rotation_euler = tuple(np.radians(a) for a in rot)
            sc.render.filepath = os.path.join(render_dir, "skin_%s.png" % label)
            bpy.ops.render.render(write_still=True)
        print("  renders -> %s  (%d tomas)" % (render_dir, len(shots)))

    out = args.out or args.blend.replace(".blend", "_painted.blend")
    bpy.ops.wm.save_as_mainfile(filepath=out)
    print("  blend -> %s" % out)


if __name__ == "__main__":
    main()
